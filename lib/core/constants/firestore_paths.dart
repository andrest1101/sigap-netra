/// Pembentuk path Firestore.
///
/// Satu-satunya tempat yang menyusun string path Firestore di seluruh aplikasi.
/// Widget dan repository tidak boleh menyalin path secara literal; itu membuat
/// refactor skema rawan dan mudah salah pada subkoleksi per-perangkat.
///
/// Bentuk path mengikuti `docs/firestore_schema.md`:
///
/// ```text
/// devices/{deviceId}
/// devices/{deviceId}/detections/{detectionId}
/// devices/{deviceId}/media/{mediaId}
/// devices/{deviceId}/events/{eventId}
/// devices/{deviceId}/commands/{commandId}
/// ```
library;

/// Path koleksi `devices`.
const String kDevicesCollection = 'devices';

/// Nama subkoleksi di bawah dokumen perangkat.
const String kDetectionsSubcollection = 'detections';
const String kMediaSubcollection = 'media';
const String kEventsSubcollection = 'events';
const String kCommandsSubcollection = 'commands';

/// Path ke dokumen satu perangkat.
String deviceDocPath(String deviceId) => '$kDevicesCollection/$deviceId';

/// Path ke koleksi `detections` milik satu perangkat.
String detectionsCollectionPath(String deviceId) =>
    '$kDevicesCollection/$deviceId/$kDetectionsSubcollection';

/// Path ke satu dokumen `detection`.
String detectionDocPath(String deviceId, String detectionId) =>
    '${detectionsCollectionPath(deviceId)}/$detectionId';

/// Path ke koleksi `media` milik satu perangkat.
String mediaCollectionPath(String deviceId) =>
    '$kDevicesCollection/$deviceId/$kMediaSubcollection';

/// Path ke satu dokumen `media`.
String mediaDocPath(String deviceId, String mediaId) =>
    '${mediaCollectionPath(deviceId)}/$mediaId';

/// Path ke koleksi `events` milik satu perangkat.
String eventsCollectionPath(String deviceId) =>
    '$kDevicesCollection/$deviceId/$kEventsSubcollection';

/// Path ke satu dokumen `event`.
String eventDocPath(String deviceId, String eventId) =>
    '${eventsCollectionPath(deviceId)}/$eventId';

/// Path ke koleksi `commands` milik satu perangkat.
String commandsCollectionPath(String deviceId) =>
    '$kDevicesCollection/$deviceId/$kCommandsSubcollection';

/// Path ke satu dokumen `command`.
String commandDocPath(String deviceId, String commandId) =>
    '${commandsCollectionPath(deviceId)}/$commandId';
