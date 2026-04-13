import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_error.dart';
import '../domain/client_visits_data.dart';
import 'visits_seed_data.dart';
import 'visits_repository.dart';

class SqliteVisitsRepository extends VisitsRepository {
  static const _dbName = 'gappsdd.sqlite';
  static const _dbVersion = 3;

  Database? _database;
  Future<Database>? _opening;

  Future<Database> _db() async {
    if (_database != null) {
      return _database!;
    }
    if (_opening != null) {
      return _opening!;
    }

    _opening = _open();
    _database = await _opening!;
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateSchema(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        await VisitsSeedDataLoader.loadForAppStartup(db);
      },
    );
  }

  Future<void> _migrateSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE client_profile ADD COLUMN gardener_role TEXT NOT NULL DEFAULT 'Lead Gardener'",
      );
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE app_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE client_profile (
        id TEXT PRIMARY KEY,
        app_title TEXT NOT NULL,
        client_name TEXT NOT NULL,
        gardener_name TEXT NOT NULL,
        gardener_role TEXT NOT NULL,
        gardener_avatar_url TEXT NOT NULL,
        hero_image_url TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assigned_gardens (
        id TEXT PRIMARY KEY,
        garden_name TEXT NOT NULL,
        address TEXT NOT NULL,
        urgency TEXT NOT NULL,
        last_visit_label TEXT NOT NULL,
        last_visit_age TEXT NOT NULL,
        evidence TEXT NOT NULL,
        primary_action_label TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id TEXT PRIMARY KEY,
        garden_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        is_verified INTEGER NOT NULL,
        initiation_method TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        public_comment TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (garden_id) REFERENCES assigned_gardens(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE visit_photos (
        id TEXT PRIMARY KEY,
        visit_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        label TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (visit_id) REFERENCES visits(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_visits_garden ON visits(garden_id);');
    await db.execute('CREATE INDEX idx_visits_started_at ON visits(started_at DESC);');
    await db.execute('CREATE INDEX idx_visit_photos_visit_id ON visit_photos(visit_id);');

    // Enforce one active visit at DB level.
    await db.execute('''
      CREATE UNIQUE INDEX ux_one_active_visit
      ON visits((ended_at IS NULL))
      WHERE ended_at IS NULL
    ''');
  }

  Future<void> _setCurrentVisitId(String? visitId) async {
    final db = await _db();
    await db.insert(
      'app_state',
      {'key': 'current_visit_id', 'value': visitId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getCurrentVisitId() async {
    final db = await _db();
    final rows = await db.query(
      'app_state',
      where: 'key = ?',
      whereArgs: ['current_visit_id'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<AssignedGardenVisitStatus> _gardenById(String id) async {
    final db = await _db();
    final rows = await db.query(
      'assigned_gardens',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const GardenNotAssignedError();
    }
    return _mapGarden(rows.first);
  }

  Future<List<LocalVisitPhoto>> _photosByVisitId(String visitId) async {
    final db = await _db();
    final rows = await db.query(
      'visit_photos',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map(
          (row) => LocalVisitPhoto(
            id: row['id'] as String,
            localPath: row['local_path'] as String,
            thumbnailPath: row['thumbnail_path'] as String,
            label: row['label'] as String,
            createdAt: DateTime.tryParse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<ActiveVisitSnapshot?> _loadVisitSnapshotById(String visitId) async {
    final db = await _db();
    final rows = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [visitId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final garden = await _gardenById(row['garden_id'] as String);
    final photos = await _photosByVisitId(visitId);

    return ActiveVisitSnapshot(
      garden: garden,
      startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
      endedAt: (row['ended_at'] as String?) != null
          ? DateTime.parse(row['ended_at'] as String).toLocal()
          : null,
      isVerified: (row['is_verified'] as int) == 1,
      initiationMethod: _toInitiationMethod(row['initiation_method'] as String),
      photos: photos,
      publicComment: row['public_comment'] as String,
    );
  }

  VisitVerificationStatus _toVerificationStatus(bool isVerified) {
    return isVerified ? VisitVerificationStatus.verified : VisitVerificationStatus.manualEntry;
  }

  VisitInitiationMethod _toInitiationMethod(String raw) {
    switch (raw) {
      case 'QR_SCAN':
        return VisitInitiationMethod.qrScan;
      case 'MANUAL':
      default:
        return VisitInitiationMethod.manual;
    }
  }

  String _fromInitiationMethod(VisitInitiationMethod method) {
    switch (method) {
      case VisitInitiationMethod.qrScan:
        return 'QR_SCAN';
      case VisitInitiationMethod.manual:
        return 'MANUAL';
    }
  }

  GardenVisitUrgency _toUrgency(String raw) {
    switch (raw) {
      case 'urgent':
        return GardenVisitUrgency.urgent;
      case 'upcoming':
        return GardenVisitUrgency.upcoming;
      default:
        return GardenVisitUrgency.maintained;
    }
  }

  VisitEvidence _toEvidence(String raw) {
    return raw == 'verified' ? VisitEvidence.verified : VisitEvidence.manual;
  }

  AssignedGardenVisitStatus _mapGarden(Map<String, Object?> row) {
    final lastVisitDateRaw = row['last_visit_date'] as String?;
    return AssignedGardenVisitStatus(
      id: row['id'] as String,
      gardenName: row['garden_name'] as String,
      address: row['address'] as String,
      urgency: _toUrgency(row['urgency'] as String),
      lastVisitLabel: row['last_visit_label'] as String,
      lastVisitAge: row['last_visit_age'] as String,
      evidence: _toEvidence(row['evidence'] as String),
      primaryActionLabel: row['primary_action_label'] as String,
      lastVisitDate: lastVisitDateRaw != null ? DateTime.tryParse(lastVisitDateRaw)?.toLocal() : null,
    );
  }

  String _formatLastVisitAge(DateTime endedAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDay = DateTime(endedAt.year, endedAt.month, endedAt.day);
    final dayDiff = today.difference(visitDay).inDays;

    if (dayDiff <= 0) {
      return 'Today';
    }
    if (dayDiff == 1) {
      return 'Yesterday';
    }
    return '$dayDiff days ago';
  }

  String _monthLabel(DateTime value) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[value.month - 1];
  }

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  String _timeLabel(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _currentVisitIdOrThrow() async {
    final visitId = await _getCurrentVisitId();
    if (visitId == null) {
      throw const VisitNotFoundError();
    }
    return visitId;
  }

  @override
  Future<ClientProfile> loadClientProfile() async {
    final db = await _db();
    final rows = await db.query('client_profile', limit: 1);
    if (rows.isEmpty) {
      throw const UnexpectedError('Perfil de cliente no configurado');
    }

    final row = rows.first;
    return ClientProfile(
      appTitle: row['app_title'] as String,
      clientName: row['client_name'] as String,
      gardenerName: row['gardener_name'] as String,
      gardenerRole: row['gardener_role'] as String,
      gardenerAvatarUrl: row['gardener_avatar_url'] as String,
      heroImageUrl: row['hero_image_url'] as String,
    );
  }

  @override
  Future<List<VisitSummary>> loadCompletedVisits() async {
    final db = await _db();
    final rows = await db.query(
      'visits',
      where: 'ended_at IS NOT NULL',
      orderBy: 'started_at DESC',
    );

    final summaries = <VisitSummary>[];
    for (final row in rows) {
      final visitId = row['id'] as String;
      final startedAt = DateTime.parse(row['started_at'] as String).toLocal();
      final endedAt = DateTime.parse(row['ended_at'] as String).toLocal();
      final duration = endedAt.difference(startedAt);

      final photoRows = await db.query(
        'visit_photos',
        columns: ['id'],
        where: 'visit_id = ?',
        whereArgs: [visitId],
      );

      summaries.add(
        VisitSummary(
          id: visitId,
          gardenId: row['garden_id'] as String,
          durationMinutes: duration.inMinutes,
          dayLabel: startedAt.day.toString().padLeft(2, '0'),
          monthLabel: _monthLabel(startedAt),
          title: row['title'] as String,
          description: row['description'] as String,
          status: _toVerificationStatus((row['is_verified'] as int) == 1),
          photoCount: photoRows.length,
        ),
      );
    }
    return summaries;
  }

  @override
  Future<VisitReport> loadVisitReport(String visitId) async {
    final db = await _db();
    final visits = await db.query('visits', where: 'id = ?', whereArgs: [visitId], limit: 1);
    if (visits.isEmpty) {
      throw const VisitNotFoundError();
    }

    final profile = await loadClientProfile();
    final visit = visits.first;
    final garden = await _gardenById(visit['garden_id'] as String);
    final photos = await _photosByVisitId(visitId);

    final startedAt = DateTime.parse(visit['started_at'] as String).toLocal();
    final endedAt = (visit['ended_at'] as String?) != null
        ? DateTime.parse(visit['ended_at'] as String).toLocal()
        : DateTime.now();

    final reportPhotos = photos
        .map(
          (photo) => VisitPhoto(
            label: photo.label.isEmpty ? 'PHOTO' : photo.label,
            imageUrl: photo.localPath,
            featured: false,
          ),
        )
        .toList();

    return VisitReport(
      visitId: visitId,
      locationName: garden.gardenName,
      locationContext: garden.address,
      headerImageUrl: profile.heroImageUrl,
      status: _toVerificationStatus((visit['is_verified'] as int) == 1),
      visitDate: '${_monthLabel(startedAt)} ${startedAt.day}, ${startedAt.year}',
      duration: _durationLabel(endedAt.difference(startedAt)),
      entryTime: _timeLabel(startedAt),
      exitTime: _timeLabel(endedAt),
      gardenerName: profile.gardenerName,
      gardenerRole: profile.gardenerRole,
      gardenerAvatarUrl: profile.gardenerAvatarUrl,
      workPerformed: (visit['description'] as String).isNotEmpty
          ? visit['description'] as String
          : 'Trabajo registrado por el jardinero.',
      publicComment: visit['public_comment'] as String? ?? '',
      photos: reportPhotos,
    );
  }

  @override
  Future<List<AssignedGardenVisitStatus>> loadAssignedGardensVisitStatus() async {
    final db = await _db();
    final rows = await db.query('assigned_gardens', orderBy: 'garden_name ASC');

    final gardens = <AssignedGardenVisitStatus>[];

    for (final row in rows) {
      final base = _mapGarden(row);
      final latestVisitRows = await db.query(
        'visits',
        columns: ['ended_at', 'is_verified'],
        where: 'garden_id = ? AND ended_at IS NOT NULL',
        whereArgs: [base.id],
        orderBy: 'ended_at DESC',
        limit: 1,
      );

      if (latestVisitRows.isEmpty) {
        gardens.add(base);
        continue;
      }

      final latestVisit = latestVisitRows.first;
      final endedAt = DateTime.parse(latestVisit['ended_at'] as String).toLocal();
      final isVerified = (latestVisit['is_verified'] as int) == 1;

      gardens.add(
        AssignedGardenVisitStatus(
          id: base.id,
          gardenName: base.gardenName,
          address: base.address,
          urgency: base.urgency,
          lastVisitLabel: 'Last Visit',
          lastVisitAge: _formatLastVisitAge(endedAt),
          evidence: isVerified ? VisitEvidence.verified : VisitEvidence.manual,
          primaryActionLabel: base.primaryActionLabel,
          lastVisitDate: endedAt,
        ),
      );
    }

    return gardens;
  }

  @override
  Future<ActiveVisitSnapshot?> loadActiveVisit() async {
    final visitId = await _getCurrentVisitId();
    if (visitId != null) {
      final selected = await _loadVisitSnapshotById(visitId);
      if (selected != null && selected.isActive) {
        return selected;
      }
      await _setCurrentVisitId(null);
    }

    final db = await _db();
    final activeRows = await db.query(
      'visits',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );

    if (activeRows.isEmpty) {
      return null;
    }

    final activeId = activeRows.first['id'] as String;
    await _setCurrentVisitId(activeId);
    return _loadVisitSnapshotById(activeId);
  }

  @override
  Future<ActiveVisitSnapshot> openCompletedVisitForEditing({required String visitId}) async {
    final db = await _db();
    final rows = await db.query(
      'visits',
      where: 'id = ? AND ended_at IS NOT NULL',
      whereArgs: [visitId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const VisitNotFoundError();
    }

    await _setCurrentVisitId(visitId);
    final snapshot = await _loadVisitSnapshotById(visitId);
    if (snapshot == null) {
      throw const VisitNotFoundError();
    }
    return snapshot;
  }

  @override
  Future<ActiveVisitSnapshot> openLatestVisitForGarden({required String gardenId}) async {
    final db = await _db();
    final rows = await db.query(
      'visits',
      where: 'garden_id = ?',
      whereArgs: [gardenId],
      orderBy: 'started_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      final now = DateTime.now();
      final syntheticId = 'visit-${now.millisecondsSinceEpoch}';
      await db.insert('visits', {
        'id': syntheticId,
        'garden_id': gardenId,
        'title': 'Última Visita',
        'description': 'Ultima visita realizada para este cliente.',
        'is_verified': 1,
        'initiation_method': 'QR_SCAN',
        'started_at': now.subtract(const Duration(hours: 2, minutes: 5)).toUtc().toIso8601String(),
        'ended_at': now.subtract(const Duration(minutes: 23)).toUtc().toIso8601String(),
        'public_comment': 'Ultima visita realizada para este cliente.',
      });
      await _setCurrentVisitId(syntheticId);
      final snapshot = await _loadVisitSnapshotById(syntheticId);
      if (snapshot == null) {
        throw const VisitNotFoundError();
      }
      return snapshot;
    }

    final visitId = rows.first['id'] as String;
    await _setCurrentVisitId(visitId);
    final snapshot = await _loadVisitSnapshotById(visitId);
    if (snapshot == null) {
      throw const VisitNotFoundError();
    }
    return snapshot;
  }

  @override
  Future<List<ManualStartCandidate>> loadNearbyManualStartCandidates() async {
    final gardens = await loadAssignedGardensVisitStatus();
    if (gardens.length < 2) {
      return gardens
          .map((garden) => ManualStartCandidate(garden: garden, distanceMeters: 5.0))
          .toList();
    }

    return [
      ManualStartCandidate(garden: gardens[0], distanceMeters: 5.6),
      ManualStartCandidate(garden: gardens[1], distanceMeters: 8.9),
    ];
  }

  Future<void> _ensureNoActiveVisit(DatabaseExecutor db) async {
    final rows = await db.query('visits', where: 'ended_at IS NULL', limit: 1);
    if (rows.isNotEmpty) {
      throw const ActiveVisitExistsError();
    }
  }

  @override
  Future<ActiveVisitSnapshot> startVisitFromQr({required String gardenId}) async {
    final db = await _db();
    await db.transaction((txn) async {
      await _ensureNoActiveVisit(txn);
      final exists = await txn.query(
        'assigned_gardens',
        where: 'id = ?',
        whereArgs: [gardenId],
        limit: 1,
      );
      if (exists.isEmpty) {
        throw const GardenNotAssignedError();
      }

      final now = DateTime.now();
      final visitId = 'visit-${now.millisecondsSinceEpoch}';
      await txn.insert('visits', {
        'id': visitId,
        'garden_id': gardenId,
        'title': 'Nueva visita',
        'description': 'Visita iniciada por QR',
        'is_verified': 1,
        'initiation_method': 'QR_SCAN',
        'started_at': now.toUtc().toIso8601String(),
        'ended_at': null,
        'public_comment': '',
      });

      await txn.insert(
        'app_state',
        {'key': 'current_visit_id', 'value': visitId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    final currentId = await _currentVisitIdOrThrow();
    final snapshot = await _loadVisitSnapshotById(currentId);
    if (snapshot == null) {
      throw const VisitNotFoundError();
    }
    return snapshot;
  }

  @override
  Future<ActiveVisitSnapshot> startManualVisit({
    required String gardenId,
    required bool isVerified,
  }) async {
    final db = await _db();
    await db.transaction((txn) async {
      await _ensureNoActiveVisit(txn);
      final exists = await txn.query(
        'assigned_gardens',
        where: 'id = ?',
        whereArgs: [gardenId],
        limit: 1,
      );
      if (exists.isEmpty) {
        throw const GardenNotAssignedError();
      }

      final now = DateTime.now();
      final visitId = 'visit-${now.millisecondsSinceEpoch}';
      await txn.insert('visits', {
        'id': visitId,
        'garden_id': gardenId,
        'title': 'Nueva visita',
        'description': isVerified ? 'Visita manual validada por GPS' : 'Visita manual no verificada',
        'is_verified': isVerified ? 1 : 0,
        'initiation_method': 'MANUAL',
        'started_at': now.toUtc().toIso8601String(),
        'ended_at': null,
        'public_comment': '',
      });

      await txn.insert(
        'app_state',
        {'key': 'current_visit_id', 'value': visitId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    final currentId = await _currentVisitIdOrThrow();
    final snapshot = await _loadVisitSnapshotById(currentId);
    if (snapshot == null) {
      throw const VisitNotFoundError();
    }
    return snapshot;
  }

  @override
  Future<void> closeActiveVisit() async {
    final db = await _db();
    final currentId = await _currentVisitIdOrThrow();
    final visit = await _loadVisitSnapshotById(currentId);
    if (visit == null || !visit.isActive) {
      await _setCurrentVisitId(null);
      return;
    }

    await db.update(
      'visits',
      {
        'ended_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [currentId],
    );

    await _setCurrentVisitId(null);
  }

  @override
  Future<void> addPhotoToActiveVisit({
    required String photoLabel,
    required String localPath,
    required String thumbnailPath,
  }) async {
    final db = await _db();
    final currentId = await _currentVisitIdOrThrow();

    final photoId = 'photo-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('visit_photos', {
      'id': photoId,
      'visit_id': currentId,
      'local_path': localPath,
      'thumbnail_path': thumbnailPath,
      'label': photoLabel,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    final snapshot = await _loadVisitSnapshotById(currentId);
    if (snapshot != null && !snapshot.isActive) {
      await db.update(
        'visits',
        {'is_verified': 0},
        where: 'id = ?',
        whereArgs: [currentId],
      );
    }
  }

  @override
  Future<void> removePhotoFromActiveVisit({required String photoId}) async {
    final db = await _db();
    final currentId = await _currentVisitIdOrThrow();

    await db.delete('visit_photos', where: 'id = ?', whereArgs: [photoId]);

    final snapshot = await _loadVisitSnapshotById(currentId);
    if (snapshot != null && !snapshot.isActive) {
      await db.update(
        'visits',
        {'is_verified': 0},
        where: 'id = ?',
        whereArgs: [currentId],
      );
    }
  }

  @override
  Future<void> updatePublicComment({required String comment}) async {
    final db = await _db();
    final currentId = await _currentVisitIdOrThrow();

    await db.update(
      'visits',
      {'public_comment': comment},
      where: 'id = ?',
      whereArgs: [currentId],
    );

    final snapshot = await _loadVisitSnapshotById(currentId);
    if (snapshot != null && !snapshot.isActive) {
      await db.update(
        'visits',
        {'is_verified': 0},
        where: 'id = ?',
        whereArgs: [currentId],
      );
    }
  }

  @override
  Future<void> updateVisitTimestamps({
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    final db = await _db();
    final currentId = await _currentVisitIdOrThrow();
    final snapshot = await _loadVisitSnapshotById(currentId);

    if (snapshot == null || snapshot.isActive) {
      return;
    }

    await db.update(
      'visits',
      {
        'started_at': newStartTime.toUtc().toIso8601String(),
        'ended_at': newEndTime.toUtc().toIso8601String(),
        'is_verified': 0,
      },
      where: 'id = ?',
      whereArgs: [currentId],
    );
  }

  @override
  Future<ActiveClientVisitInfo?> loadActiveVisitForClient() async {
    // Client visits always load from Supabase when authenticated.
    // SQLite does not store client-side active visit info.
    return null;
  }

  @override
  Future<void> recordLocationPoint({
    required String visitId,
    required double lat,
    required double lng,
    double? accuracy,
  }) async {
    // Location points are stored in Supabase only.
  }

  @override
  Future<List<VisitLocationPoint>> loadVisitLocationPoints(String visitId) async => [];
}
