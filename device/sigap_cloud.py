"""Jembatan cloud SIGAP-NETRA: MaixCAM -> Cloud Firestore via REST.

Modul ini berjalan sebagai background thread di dalam `main.py` perangkat.
Tugasnya HANYA telemetri: heartbeat, upload deteksi, polling perintah.
Fungsi inti (deteksi -> bicara) TIDAK PERNAH menunggu modul ini.

Arsitektur sesuai `docs/device_protocol.md`:
- Auth: akun Firebase Auth (Email/Password) khusus per alat, login via
  Identity Toolkit REST, `idToken` 1 jam dipakai sebagai Bearer untuk
  Firestore REST. Refresh berkala di thread ini. Tanpa private key /
  service account di perangkat (DIPUTUSKAN 2026-10-13).
- Heartbeat: PATCH `devices/{deviceId}` tiap 60 detik (bukan 30 — hemat
  kuota, tetap di bawah ambang online 90 detik yang dihitung app).
- Deteksi: POST `detections/{id}` dengan `validationStatus: pending`.
  Throttle: minimal 5 detik antar upload; selebihnya digabung/dijatuhkan.
  Gagal upload = hilang diam-diam, tidak pernah memblokir bicara.
- Perintah: poll `runQuery` tiap 30 detik, filter status pending/sent,
  eksekusi ringan (sync_now, speak_text via antrean audio, set_volume,
  restart, reprovision -> mode pairing QR), update status maju satu arah.

Kebutuhan: CPython 3.8+ di MaixCAM (Linux penuh). `requests` bila ada,
jatuh ke `urllib` bawaan bila tidak. Tanpa dependensi maix: logika murni
HTTP + JSON sehingga bisa di-probe dari PC.

 TIDAK PERNAH ditulis modul ini ke Firestore / log:
  password Wi-Fi, token, email penuh, lokasi, audio, video, foto penuh.
  Thumbnail JPEG <= 60 KB hanya bila settings.uploadThumbnails true
  (default false) — dan modul ini sengaja BELUM mengimplementasikan
  upload thumbnail (Fase 6, menunggu keputusan opt-in + retensi).
"""

import json
import random
import threading
import time

try:
    import requests as _requests
except Exception:
    _requests = None

try:
    import urllib.request as _urllib_request
    import urllib.error as _urllib_error
except Exception:
    _urllib_request = None

FIRESTORE_BASE = "https://firestore.googleapis.com/v1"
IDENTITY_BASE = "https://identitytoolkit.googleapis.com/v1"
FIREBASE_API_KEY = "AIzaSyDdUMMY-REPLACE-VIA-CONFIG"  # di-override config.py

HEARTBEAT_DETIK = 60
POLL_PERINTAH_DETIK = 30
UPLOAD_MIN_INTERVAL_DETIK = 5
BACKOFF_BASE_DETIK = 2
BACKOFF_CAP_DETIK = 300

TIMEOUT_DETIK = 15


def _log(tag, msg):
    print("[CLOUD %s] %s" % (tag, msg), flush=True)


class _Http(object):
    """POST/PATCH JSON minimal: `requests` bila ada, `urllib` bila tidak."""

    def __init__(self, timeout=TIMEOUT_DETIK):
        self.timeout = timeout

    def post(self, url, payload, headers=None):
        body = json.dumps(payload).encode("utf-8")
        return self._kirim("POST", url, body, headers or {})

    def patch(self, url, payload, headers=None):
        body = json.dumps(payload).encode("utf-8")
        return self._kirim("PATCH", url, body, headers or {})

    def _kirim(self, method, url, body, headers):
        heads = dict(headers)
        heads["Content-Type"] = "application/json"
        if _requests is not None:
            resp = _requests.request(
                method, url, data=body, headers=heads, timeout=self.timeout
            )
            return resp.status_code, resp.text
        if _urllib_request is None:
            raise RuntimeError("tidak ada pustaka HTTP di perangkat")
        req = _urllib_request.Request(url, data=body, headers=heads, method=method)
        try:
            with _urllib_request.urlopen(req, timeout=self.timeout) as resp:
                return resp.status, resp.read().decode("utf-8", "ignore")
        except _urllib_error.HTTPError as e:
            return e.code, e.read().decode("utf-8", "ignore")


def _backoff(gagal_beruntun):
    delay = min(BACKOFF_CAP_DETIK, BACKOFF_BASE_DETIK * (2 ** gagal_beruntun))
    return random.uniform(0, delay)


def _encode_value(v):
    """Python -> Firestore REST Value (subset yang dipakai kontrak)."""
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, str):
        return {"stringValue": v}
    if isinstance(v, dict):
        return {
            "mapValue": {
                "fields": {k: _encode_value(x) for k, x in v.items()}
            }
        }
    raise TypeError("tipe tidak didukung kontrak: %r" % type(v))


def _doc_name(project_id, device_id, *parts):
    base = "projects/%s/databases/(default)/documents/devices/%s" % (
        project_id,
        device_id,
    )
    if parts:
        base += "/" + "/".join(parts)
    return base


class SigapCloud(object):
    """Jembatan cloud satu instance per perangkat. Thread-safe."""

    def __init__(self, config, hooks):
        """
        config: dict dari config.py (project_id, api_key, device_id,
            device_email, device_password, name, model, firmware_version).
        hooks: dict callback baca-tanpa-blokir:
            get_battery_pct() -> int 0-100 atau None
            get_wifi_ssid() -> str atau None
            on_command(type, payload) -> str resultNote atau None
        """
        self.cfg = dict(config)
        self.hooks = dict(hooks or {})
        self.http = _Http()
        self._stop = threading.Event()
        self._thread = None
        self._kunci = threading.Lock()
        self._id_token = None
        self._token_exp = 0.0
        self._gagal_auth_beruntun = 0
        self._next_auth_boleh = 0.0
        self._upload_terakhir = 0.0
        self.boot_count = 0

    # ---------- siklus hidup ----------

    def start(self):
        if self._thread is not None:
            return
        self._stop.clear()
        self._thread = threading.Thread(
            target=self._lingkar, name="sigap-cloud", daemon=True
        )
        self._thread.start()
        _log("INIT", "thread cloud jalan (device=%s)" % self.cfg.get("device_id"))

    def stop(self):
        self._stop.set()

    # ---------- API untuk main.py ----------

    def catat_uang(self, daftar_nominal, conf=1.0, jarak_cm=None):
        """Hook setelah YOLO sukses + bicara. Tidak pernah melempar."""
        try:
            if not daftar_nominal:
                return
            total = sum(int(n) for n in daftar_nominal)
            self._antre_upload(
                {
                    "type": "money",
                    "amount": total,
                    "currency": "IDR",
                    "confidence": max(0.0, min(1.0, float(conf))),
                    "distanceCm": jarak_cm,
                    "ocrText": None,
                }
            )
        except Exception as e:
            _log("HOOK", "catat_uang diabaikan: %s" % e)

    def catat_teks(self, baris_list, conf=1.0, jarak_cm=None):
        """Hook setelah OCR sukses + bicara. Potong 500 char (kontrak)."""
        try:
            teks = "\n".join(baris_list or [])
            if not teks.strip():
                return
            self._antre_upload(
                {
                    "type": "text",
                    "amount": None,
                    "currency": "IDR",
                    "confidence": max(0.0, min(1.0, float(conf))),
                    "distanceCm": jarak_cm,
                    "ocrText": teks[:500],
                }
            )
        except Exception as e:
            _log("HOOK", "catat_teks diabaikan: %s" % e)

    # ---------- internal ----------

    def _auth_header(self):
        now = time.time()
        if self._id_token and now < self._token_exp - 60:
            return {"Authorization": "Bearer " + self._id_token}
        if now < self._next_auth_boleh:
            return None
        try:
            url = "%s/accounts:signInWithPassword?key=%s" % (
                IDENTITY_BASE,
                self.cfg.get("api_key", FIREBASE_API_KEY),
            )
            code, text = self.http.post(
                url,
                {
                    "email": self.cfg.get("device_email"),
                    "password": self.cfg.get("device_password"),
                    "returnSecureToken": True,
                },
            )
            if code != 200:
                raise RuntimeError("login %s" % code)
            data = json.loads(text)
            with self._kunci:
                self._id_token = data["idToken"]
                self._token_exp = now + int(data.get("expiresIn", "3600"))
                self._gagal_auth_beruntun = 0
            _log("AUTH", "login OK, token 1 jam")
            return {"Authorization": "Bearer " + self._id_token}
        except Exception as e:
            with self._kunci:
                self._gagal_auth_beruntun += 1
                n = self._gagal_auth_beruntun
            wait = _backoff(n)
            with self._kunci:
                self._next_auth_boleh = time.time() + wait
            # 401 tidak di-retry berulang: short circuit sampai jendela lewat.
            _log("AUTH", "gagal (%s), jeda %.0fs" % (e, wait))
            return None

    def _antre_upload(self, deteksi):
        now = time.time()
        with self._kunci:
            if now - self._upload_terakhir < UPLOAD_MIN_INTERVAL_DETIK:
                _log("THROTTLE", "deteksi digabung/dijatuhkan (hemat kuota)")
                return
            self._upload_terakhir = now
        heads = self._auth_header()
        if not heads:
            return
        det_id = "det_%d" % int(now * 1000)
        name = _doc_name(
            self.cfg["project_id"], self.cfg["device_id"], "detections", det_id
        )
        fields = {
            "type": deteksi["type"],
            "amount": deteksi["amount"],
            "currency": deteksi["currency"],
            "confidence": deteksi["confidence"],
            "distanceCm": deteksi["distanceCm"],
            "ocrText": deteksi["ocrText"],
            "thumbnailId": None,
            "validationStatus": "pending",
            "createdAt": None,
        }
        # createdAt + lastSeen memakai server timestamp via commit transform;
        # deteksi memakai createDocument biasa + createdAt diisi server
        # lewat update mask? Tidak — kontrak: createdAt server. Karena PATCH
        # biasa tak bisa server timestamp, kirim tanpa createdAt lalu server
        # mengisi updateTime; app mengurutkan via createdAt bila ada,
        # fallback updateTime. (Disederhanakan Fase 1: kirim ISO lokal
        # sebagai penanda, kebenaran urutan tetap updateTime server.)
        import datetime

        fields["createdAt"] = datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat()
        url = "%s/%s" % (FIRESTORE_BASE, name)
        try:
            code, _ = self.http.patch(
                url + "?updateMask.fieldPaths=" + "&updateMask.fieldPaths=".join(
                    sorted(fields.keys())
                ),
                {"fields": {k: _encode_value(v) for k, v in fields.items()}},
                headers=heads,
            )
            if code not in (200, 201):
                _log("UPLOAD", "deteksi gagal HTTP %s (dijatuhkan diam)" % code)
        except Exception as e:
            _log("UPLOAD", "deteksi gagal (%s), dijatuhkan diam" % e)

    def _heartbeat(self):
        heads = self._auth_header()
        if not heads:
            return
        bat = None
        try:
            fn = self.hooks.get("get_battery_pct")
            bat = fn() if fn else None
        except Exception:
            bat = None
        ssid = None
        try:
            fn = self.hooks.get("get_wifi_ssid")
            ssid = fn() if fn else None
        except Exception:
            ssid = None
        name = _doc_name(self.cfg["project_id"], self.cfg["device_id"])
        import datetime

        now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
        fields = {
            "name": self.cfg.get("name", self.cfg["device_id"]),
            "model": self.cfg.get("model", "MaixCAM SG2002"),
            "firmwareVersion": self.cfg.get("firmware_version", "?"),
            "lastSeen": now_iso,
            "bootCount": self.boot_count,
            "batteryPct": bat,
            "updatedAt": now_iso,
        }
        if ssid:
            fields["wifiSsid"] = ssid
        url = "%s/%s?updateMask.fieldPaths=" % (FIRESTORE_BASE, name) + (
            "&updateMask.fieldPaths=".join(sorted(fields.keys()))
        )
        try:
            code, _ = self.http.patch(
                url,
                {"fields": {k: _encode_value(v) for k, v in fields.items()}},
                headers=heads,
            )
            if code not in (200, 201):
                _log("HEARTBEAT", "gagal HTTP %s" % code)
        except Exception as e:
            _log("HEARTBEAT", "gagal (%s)" % e)

    def _poll_perintah(self):
        heads = self._auth_header()
        if not heads:
            return
        parent = _doc_name(self.cfg["project_id"], self.cfg["device_id"])
        url = "%s/%s/documents:runQuery" % (
            FIRESTORE_BASE,
            "projects/%s/databases/(default)" % self.cfg["project_id"],
        )
        query = {
            "structuredQuery": {
                "from": [{"collectionId": "commands"}],
                "where": {
                    "fieldFilter": {
                        "field": {"fieldPath": "status"},
                        "op": "IN",
                        "value": {
                            "arrayValue": {
                                "values": [
                                    {"stringValue": "pending"},
                                    {"stringValue": "sent"},
                                ]
                            }
                        },
                    }
                },
                "orderBy": [{"field": {"fieldPath": "createdAt"}}],
                "limit": 5,
            },
            # Batasi ke subkoleksi device ini: parent prefix tidak didukung
            # runQuery langsung — sebagai gantinya query collectionGroup
            # difilter client-side per document name. Fase 1: ambil lalu
            # saring `name` yang mengandung /devices/{id}/commands/.
            "parent": parent,
        }
        try:
            code, text = self.http.post(url, query, headers=heads)
            if code != 200:
                _log("POLL", "gagal HTTP %s" % code)
                return
            for row in json.loads(text or "[]"):
                doc = (row.get("document") or {})
                doc_name = doc.get("name", "")
                if "/devices/%s/commands/" % self.cfg["device_id"] not in doc_name:
                    continue
                fs = doc.get("fields", {})
                status = (fs.get("status") or {}).get("stringValue")
                if status not in ("pending", "sent"):
                    continue
                ctype = (fs.get("type") or {}).get("stringValue")
                payload = self._decode_map(fs.get("payload"))
                self._tangani_perintah(doc_name, status, ctype, payload, heads)
        except Exception as e:
            _log("POLL", "gagal (%s)" % e)

    @staticmethod
    def _decode_map(v):
        if not isinstance(v, dict):
            return {}
        fields = (v.get("mapValue") or {}).get("fields", {})
        out = {}
        for k, x in fields.items():
            if "stringValue" in x:
                out[k] = x["stringValue"]
            elif "integerValue" in x:
                out[k] = int(x["integerValue"])
            elif "doubleValue" in x:
                out[k] = float(x["doubleValue"])
            elif "booleanValue" in x:
                out[k] = bool(x["booleanValue"])
        return out

    def _set_status(self, doc_name, status_lama, status_baru, note, heads):
        order = ["pending", "sent", "acked", "done", "failed"]
        if order.index(status_baru) <= order.index(status_lama):
            return
        import datetime

        fields = {
            "status": status_baru,
            "updatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }
        if note is not None:
            fields["resultNote"] = str(note)[:200]
        url = "%s/%s?updateMask.fieldPaths=" % (FIRESTORE_BASE, doc_name) + (
            "&updateMask.fieldPaths=".join(sorted(fields.keys()))
        )
        try:
            self.http.patch(
                url,
                {"fields": {k: _encode_value(v) for k, v in fields.items()}},
                headers=heads,
            )
        except Exception as e:
            _log("CMD", "update status gagal (%s)" % e)

    def _tangani_perintah(self, doc_name, status, ctype, payload, heads):
        _log("CMD", "diterima %s (%s)" % (ctype, status))
        self._set_status(doc_name, status, "sent", None, heads)
        note = None
        try:
            fn = self.hooks.get("on_command")
            if ctype == "reprovision":
                # Kredensial Wi-Fi TIDAK PERNAH lewat Firestore: perintah ini
                # hanya memicu mode pairing QR di alat.
                if fn:
                    fn("reprovision", {})
                note = "mode pairing QR aktif"
                self._set_status(doc_name, "sent", "acked", None, heads)
                self._set_status(doc_name, "acked", "done", note, heads)
                return
            self._set_status(doc_name, "sent", "acked", None, heads)
            if fn:
                note = fn(ctype, payload)
            self._set_status(doc_name, "acked", "done", note, heads)
        except Exception as e:
            try:
                self._set_status(
                    doc_name, "acked", "failed", "gagal: %s" % type(e).__name__, heads
                )
            except Exception:
                pass

    def _lingkar(self):
        hb_next = 0.0
        poll_next = 0.0
        while not self._stop.is_set():
            now = time.time()
            if now >= hb_next:
                self._heartbeat()
                hb_next = now + HEARTBEAT_DETIK
            if now >= poll_next:
                self._poll_perintah()
                poll_next = now + POLL_PERINTAH_DETIK
            self._stop.wait(5.0)
