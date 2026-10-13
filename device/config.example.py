# Contoh konfigurasi jembatan cloud — SALIN ke `config.py` DI ALAT SAJA.
#
#   cp config.example.py config.py   # di MaixCAM, via SSH/MaixVision
#   # lalu isi nilai asli di config.py
#
# ATURAN KERAS:
# - `config.py` berisi kredensial asli: TIDAK PERNAH di-commit, di-share,
#   atau di-log. Hanya hidup di filesystem MaixCAM.
# - Yang di-commit ke repo HANYA file ini (placeholder `??`).
# - Password Wi-Fi dan password akun alat tidak pernah masuk Firestore.

CONFIG = {
    # ID project Firebase (console -> Project settings -> Project ID).
    "project_id": "??",  # mis. "sigap-netra"

    # Web API Key Firebase (console -> Project settings -> General).
    # Identifier publik, bukan rahasia — tetapi tetap hanya di alat.
    "api_key": "??",

    # ID dokumen perangkat. FINAL dan stabil — jangan diubah setelah dipakai.
    "device_id": "??",  # mis. "sigap-maixcam-01"

    # Akun Auth khusus alat ini (console -> Authentication -> Users).
    # Dibuat sekali oleh owner; UID-nya dicatat di dokumen device (authUid).
    "device_email": "??",
    "device_password": "??",

    # Telemetri tampilan (ditulis ke dokumen device).
    "name": "??",  # mis. "Kacamata Cerdas 01"
    "model": "MaixCAM SG2002",
    "firmware_version": "v1.2.0-sg2002",
}
