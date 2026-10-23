// Uji Security Rules SIGAP-NETRA di Firestore emulator.
//
// Jalankan dari akar repo (butuh Java + firebase-tools; `npm install` sekali
// di folder ini):
//   firebase emulators:exec --only firestore --project demo-sigap-netra \
//     "node --test firebase/tests/rules.test.mjs"
//
// Daftar kasus bersumber dari `docs/firestore_schema.md` bagian 9 (inventaris
// rules) dan `AGENTS.md` bagian 11 (daftar uji rules), ditambah regresi
// bootstrap device 2026-10-18.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-sigap-netra';
const DEVICE_ID = 'dev-1';
const DEVICE_UID = 'uid-device-1';
const MEMBER_UID = 'uid-member-1';
const OUTSIDER_UID = 'uid-outsider-1';

const devicePath = `devices/${DEVICE_ID}`;
const detectionPath = `${devicePath}/detections/det-1`;
const mediaPath = `${devicePath}/media/det-1`;
const eventPath = `${devicePath}/events/ev-1`;
const commandPath = `${devicePath}/commands/cmd-1`;

const rules = readFileSync(
  new URL('../firestore.rules', import.meta.url),
  'utf8',
);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules,
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// ---------- Helper ----------

const deviceFirestore = () =>
  testEnv.authenticatedContext(DEVICE_UID).firestore();
const memberFirestore = () =>
  testEnv.authenticatedContext(MEMBER_UID).firestore();
const outsiderFirestore = () =>
  testEnv.authenticatedContext(OUTSIDER_UID).firestore();
const anonymousFirestore = () => testEnv.unauthenticatedContext().firestore();

/// Tanam dokumen memakai jalur admin (bypass rules) — sama dengan console.
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

function deviceData(overrides = {}) {
  return {
    deviceId: DEVICE_ID,
    authUid: DEVICE_UID,
    name: 'SIGAP-01',
    model: 'MaixCAM',
    firmwareVersion: '0.1.0',
    wifiSsid: 'rumah',
    lastSeen: new Date('2026-10-18T12:00:00.000Z'),
    bootCount: 3,
    batteryPct: null,
    settings: { uploadThumbnails: false, uploadText: false },
    members: { [MEMBER_UID]: 'owner' },
    createdAt: new Date('2026-10-01T00:00:00.000Z'),
    updatedAt: new Date('2026-10-18T12:00:00.000Z'),
    ...overrides,
  };
}

/// Payload create device oleh device sendiri: tanpa `members` (hanya console
/// yang menulis keanggotaan, di luar allow-list create).
function deviceCreateData(overrides = {}) {
  const data = deviceData();
  delete data.members;
  return { ...data, ...overrides };
}

function detectionData(overrides = {}) {
  return {
    type: 'money',
    amount: 50000,
    currency: 'IDR',
    confidence: 0.92,
    distanceCm: null,
    ocrText: null,
    thumbnailId: null,
    validationStatus: 'pending',
    createdAt: new Date('2026-10-18T12:00:00.000Z'),
    ...overrides,
  };
}

function eventData(overrides = {}) {
  return {
    type: 'boot',
    severity: 'info',
    message: 'Perangkat menyala',
    createdAt: new Date('2026-10-18T12:00:00.000Z'),
    ...overrides,
  };
}

function commandData(overrides = {}) {
  return {
    type: 'sync_now',
    payload: {},
    status: 'pending',
    requestedBy: MEMBER_UID,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

/// Command tersimpan (dibuat anggota, ditanam via admin untuk uji update).
function storedCommand(overrides = {}) {
  return {
    type: 'sync_now',
    payload: {},
    status: 'pending',
    requestedBy: MEMBER_UID,
    createdAt: new Date('2026-10-18T12:00:00.000Z'),
    ...overrides,
  };
}

// ---------- devices/{deviceId} ----------

describe('devices/{deviceId}', () => {
  test('anggota boleh baca; outsider dan anon ditolak', async () => {
    await seed(devicePath, deviceData());
    await assertSucceeds(getDoc(doc(memberFirestore(), devicePath)));
    await assertFails(getDoc(doc(outsiderFirestore(), devicePath)));
    await assertFails(getDoc(doc(anonymousFirestore(), devicePath)));
  });

  test('anggota boleh query daftar perangkat dengan filter members', async () => {
    // Regresi 2026-10-22: app Beranda memakai query koleksi
    // `where('members.<uid>', isNull: false)`. Aturan read tidak boleh
    // bergantung pada get() per dokumen untuk query ber-wildcard ini.
    await seed(devicePath, deviceData());
    await assertSucceeds(
      getDocs(
        query(
          collection(memberFirestore(), 'devices'),
          where(`members.${MEMBER_UID}`, '!=', null),
        ),
      ),
    );
    await assertFails(
      getDocs(
        query(
          collection(outsiderFirestore(), 'devices'),
          where(`members.${MEMBER_UID}`, '!=', null),
        ),
      ),
    );
  });

  test('regresi 2026-10-18: device self-bootstrap create boleh', async () => {
    // Sebelum perbaikan, `create` memakai `isDevice()` yang memanggil `get()`
    // pada dokumen yang belum ada → selalu ditolak.
    await assertSucceeds(
      setDoc(doc(deviceFirestore(), devicePath), deviceCreateData()),
    );
  });

  test('create dengan authUid orang lain atau key di luar allow-list ditolak', async () => {
    await assertFails(
      setDoc(
        doc(deviceFirestore(), devicePath),
        deviceCreateData({ authUid: 'uid-lain' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), devicePath),
        deviceCreateData({ members: { [DEVICE_UID]: 'owner' } }),
      ),
    );
  });

  test('create dengan settings bukan bool atau oleh anon ditolak', async () => {
    await assertFails(
      setDoc(
        doc(deviceFirestore(), devicePath),
        deviceCreateData({
          settings: { uploadThumbnails: 'ya', uploadText: false },
        }),
      ),
    );
    await assertFails(
      setDoc(doc(anonymousFirestore(), devicePath), deviceCreateData()),
    );
  });

  test('device update lastSeen boleh; ubah members ditolak', async () => {
    await seed(devicePath, deviceData());
    await assertSucceeds(
      updateDoc(doc(deviceFirestore(), devicePath), {
        lastSeen: new Date('2026-10-18T12:00:30.000Z'),
      }),
    );
    await assertFails(
      updateDoc(doc(deviceFirestore(), devicePath), {
        members: { [MEMBER_UID]: 'owner', 'uid-2': 'viewer' },
      }),
    );
  });

  test('pengecualian owner: ubah members boleh; outsider ditolak', async () => {
    await seed(devicePath, deviceData());
    await assertSucceeds(
      updateDoc(doc(memberFirestore(), devicePath), {
        members: { [MEMBER_UID]: 'owner', 'uid-2': 'viewer' },
      }),
    );
    await assertFails(
      updateDoc(doc(outsiderFirestore(), devicePath), {
        members: { [OUTSIDER_UID]: 'owner' },
      }),
    );
  });

  test('delete dokumen device selalu ditolak', async () => {
    await seed(devicePath, deviceData());
    await assertFails(deleteDoc(doc(memberFirestore(), devicePath)));
    await assertFails(deleteDoc(doc(deviceFirestore(), devicePath)));
  });
});

// ---------- detections ----------

describe('detections', () => {
  beforeEach(async () => {
    await seed(devicePath, deviceData());
  });

  test('device create sah boleh; ocrText null eksplisit tidak ditolak', async () => {
    // `detectionData()` mengirim `ocrText: null` seperti device sungguhan:
    // regresi emulator — rules lama gagal evaluasi pada nilai null.
    await assertSucceeds(
      setDoc(doc(deviceFirestore(), detectionPath), detectionData()),
    );
  });

  test('status awal bukan pending / ada validatedBy / validatedAt ditolak', async () => {
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ validationStatus: 'match' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ validatedBy: DEVICE_UID }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ validatedAt: new Date('2026-10-18T12:00:00.000Z') }),
      ),
    );
  });

  test('ocrText > 500 karakter / non-string dan confidence di luar 0..1 ditolak', async () => {
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ ocrText: 'a'.repeat(501) }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ ocrText: 42 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ confidence: 1.5 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), detectionPath),
        detectionData({ confidence: 'tinggi' }),
      ),
    );
  });

  test('app tidak boleh create deteksi', async () => {
    await assertFails(
      setDoc(doc(memberFirestore(), detectionPath), detectionData()),
    );
  });

  test('anggota update hanya field validasi dengan nilai sah', async () => {
    await seed(detectionPath, detectionData());
    await assertSucceeds(
      updateDoc(doc(memberFirestore(), detectionPath), {
        validationStatus: 'match',
        validatedBy: MEMBER_UID,
        validatedAt: new Date('2026-10-18T12:05:00.000Z'),
      }),
    );
    await assertFails(
      updateDoc(doc(memberFirestore(), detectionPath), { amount: 100000 }),
    );
    await assertFails(
      updateDoc(doc(memberFirestore(), detectionPath), {
        validationStatus: 'verified',
      }),
    );
  });

  test('device tidak bisa update/hapus; anggota hapus boleh; outsider baca ditolak', async () => {
    await seed(detectionPath, detectionData());
    await assertFails(
      updateDoc(doc(deviceFirestore(), detectionPath), {
        validationStatus: 'match',
      }),
    );
    await assertFails(deleteDoc(doc(deviceFirestore(), detectionPath)));
    await assertFails(getDoc(doc(outsiderFirestore(), detectionPath)));
    await assertSucceeds(deleteDoc(doc(memberFirestore(), detectionPath)));
  });

  test('anggota boleh query daftar deteksi; outsider ditolak', async () => {
    await seed(detectionPath, detectionData());
    await assertSucceeds(
      getDocs(collection(memberFirestore(), `${devicePath}/detections`)),
    );
    await assertFails(
      getDocs(collection(outsiderFirestore(), `${devicePath}/detections`)),
    );
  });
});

// ---------- media ----------

describe('media', () => {
  const uploadOn = {
    settings: { uploadThumbnails: true, uploadText: false },
  };

  test('device create thumbnail sah saat opt-in aktif', async () => {
    await seed(devicePath, deviceData(uploadOn));
    await assertSucceeds(
      setDoc(doc(deviceFirestore(), mediaPath), {
        mime: 'image/jpeg',
        size: 60000,
        bytes: 'A'.repeat(81920),
      }),
    );
  });

  test('opt-in mati, size lebih, mime salah, bytes terlalu panjang ditolak', async () => {
    await seed(devicePath, deviceData());
    await assertFails(
      setDoc(doc(deviceFirestore(), mediaPath), {
        mime: 'image/jpeg',
        size: 1000,
        bytes: 'A'.repeat(10),
      }),
    );

    await seed(devicePath, deviceData(uploadOn));
    await assertFails(
      setDoc(doc(deviceFirestore(), mediaPath), {
        mime: 'image/jpeg',
        size: 60001,
        bytes: 'A'.repeat(10),
      }),
    );
    await assertFails(
      setDoc(doc(deviceFirestore(), mediaPath), {
        mime: 'image/png',
        size: 1000,
        bytes: 'A'.repeat(10),
      }),
    );
    await assertFails(
      setDoc(doc(deviceFirestore(), mediaPath), {
        mime: 'image/jpeg',
        size: 1000,
        bytes: 'A'.repeat(81921),
      }),
    );
  });

  test('anggota hapus boleh; update oleh siapa pun ditolak', async () => {
    await seed(devicePath, deviceData(uploadOn));
    await seed(mediaPath, {
      mime: 'image/jpeg',
      size: 1000,
      bytes: 'A'.repeat(10),
    });
    await assertFails(
      updateDoc(doc(memberFirestore(), mediaPath), { size: 1 }),
    );
    await assertFails(
      updateDoc(doc(deviceFirestore(), mediaPath), { size: 1 }),
    );
    await assertSucceeds(deleteDoc(doc(memberFirestore(), mediaPath)));
  });
});

// ---------- events ----------

describe('events', () => {
  beforeEach(async () => {
    await seed(devicePath, deviceData());
  });

  test('device create sah boleh; severity dan message tidak sah ditolak', async () => {
    await assertSucceeds(setDoc(doc(deviceFirestore(), eventPath), eventData()));
    await assertFails(
      setDoc(
        doc(deviceFirestore(), eventPath),
        eventData({ severity: 'kritis' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(deviceFirestore(), eventPath),
        eventData({ message: 'x'.repeat(201) }),
      ),
    );
  });

  test('app hanya bisa baca: create/update/delete ditolak', async () => {
    await seed(eventPath, eventData());
    await assertSucceeds(getDoc(doc(memberFirestore(), eventPath)));
    await assertFails(setDoc(doc(memberFirestore(), eventPath), eventData()));
    await assertFails(
      updateDoc(doc(memberFirestore(), eventPath), { message: 'diubah' }),
    );
    await assertFails(deleteDoc(doc(memberFirestore(), eventPath)));
  });

  test('anggota boleh query daftar event; outsider ditolak', async () => {
    await seed(eventPath, eventData());
    await assertSucceeds(
      getDocs(collection(memberFirestore(), `${devicePath}/events`)),
    );
    await assertFails(
      getDocs(collection(outsiderFirestore(), `${devicePath}/events`)),
    );
  });
});

// ---------- commands ----------

describe('commands', () => {
  beforeEach(async () => {
    await seed(devicePath, deviceData());
  });

  test('anggota create sync_now dengan createdAt server boleh', async () => {
    await assertSucceeds(
      setDoc(doc(memberFirestore(), commandPath), commandData()),
    );
  });

  test('createdAt jam klien / status bukan pending / requestedBy lain ditolak', async () => {
    await assertFails(
      setDoc(
        doc(memberFirestore(), commandPath),
        commandData({ createdAt: new Date('2026-10-18T12:00:00.000Z') }),
      ),
    );
    await assertFails(
      setDoc(
        doc(memberFirestore(), commandPath),
        commandData({ status: 'sent' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(memberFirestore(), commandPath),
        commandData({ requestedBy: 'uid-lain' }),
      ),
    );
  });

  test('payload tidak sah / memuat nama field kredensial ditolak', async () => {
    await assertFails(
      setDoc(
        doc(memberFirestore(), commandPath),
        commandData({ type: 'speak_text', payload: { text: '' } }),
      ),
    );
    await assertFails(
      setDoc(
        doc(memberFirestore(), commandPath),
        commandData({
          type: 'speak_text',
          payload: { text: 'halo', token: 'x' },
        }),
      ),
    );
    await assertFails(
      setDoc(
        doc(memberFirestore(), commandPath),
        commandData({ type: 'set_volume', payload: { level: 101 } }),
      ),
    );
  });

  test('device tidak boleh create command (aturan 4)', async () => {
    await assertFails(
      setDoc(doc(deviceFirestore(), commandPath), commandData()),
    );
  });

  test('device memajukan status satu arah; mundur dan failed tanpa catatan ditolak', async () => {
    await seed(commandPath, storedCommand());
    await assertSucceeds(
      updateDoc(doc(deviceFirestore(), commandPath), {
        status: 'sent',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(deviceFirestore(), commandPath), {
        status: 'pending',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(deviceFirestore(), commandPath), {
        status: 'acked',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(deviceFirestore(), commandPath), {
        status: 'failed',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(deviceFirestore(), commandPath), {
        status: 'failed',
        resultNote: 'wifi tidak ditemukan',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('anggota tidak bisa update status; delete ditolak; outsider baca ditolak', async () => {
    await seed(commandPath, storedCommand());
    await assertSucceeds(getDoc(doc(memberFirestore(), commandPath)));
    await assertFails(getDoc(doc(outsiderFirestore(), commandPath)));
    await assertFails(
      updateDoc(doc(memberFirestore(), commandPath), { status: 'sent' }),
    );
    await assertFails(deleteDoc(doc(deviceFirestore(), commandPath)));
    await assertFails(deleteDoc(doc(memberFirestore(), commandPath)));
  });

  test('anggota boleh query daftar command; outsider ditolak', async () => {
    await seed(commandPath, storedCommand());
    await assertSucceeds(
      getDocs(collection(memberFirestore(), `${devicePath}/commands`)),
    );
    await assertFails(
      getDocs(collection(outsiderFirestore(), `${devicePath}/commands`)),
    );
  });
});

// ---------- catch-all ----------

describe('catch-all deny-by-default', () => {
  test('koleksi di luar skema ditolak untuk siapa pun', async () => {
    await assertFails(
      setDoc(doc(memberFirestore(), 'random/koleksi'), { a: 1 }),
    );
    await assertFails(getDoc(doc(memberFirestore(), 'random/koleksi')));
    await assertFails(
      setDoc(doc(deviceFirestore(), 'random/koleksi'), { a: 1 }),
    );
  });
});
