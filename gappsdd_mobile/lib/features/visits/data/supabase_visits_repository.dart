import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/client_visits_data.dart';
import 'visits_repository.dart';

class SupabaseVisitsRepository extends VisitsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  ActiveVisitSnapshot? _activeVisit;

  String get _userId => _client.auth.currentUser!.id;

  Future<String?> _getGardenerProfileId() async {
    final data = await _client
        .from('gardener_profiles')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  Future<String?> _getClientProfileId() async {
    final data = await _client
        .from('client_profiles')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  @override
  Future<ClientProfile> loadClientProfile() async {
    final profile = await _client
        .from('user_profiles')
        .select('*')
        .eq('id', _userId)
        .single();

    return ClientProfile(
      appTitle: 'GAPP Garden',
      clientName: profile['display_name'] as String? ?? 'Client',
      gardenerName: '',
      gardenerRole: '',
      gardenerAvatarUrl: profile['avatar_url'] as String? ?? '',
      heroImageUrl: '',
    );
  }

  @override
  Future<List<VisitSummary>> loadCompletedVisits() async {
    // Determine if user is client or gardener
    final clientId = await _getClientProfileId();
    final gardenerId = await _getGardenerProfileId();

    List<Map<String, dynamic>> visits;
    if (gardenerId != null) {
      visits = await _client
          .from('visits')
          .select('*, visit_photos(count)')
          .eq('gardener_id', gardenerId)
          .eq('status', 'CLOSED')
          .order('started_at', ascending: false);
    } else if (clientId != null) {
      // Client sees visits for their gardens
      final gardens = await _client
          .from('gardens')
          .select('id')
          .eq('client_id', clientId);
      final gardenIds = (gardens as List).map((g) => g['id'] as String).toList();
      if (gardenIds.isEmpty) return [];

      visits = await _client
          .from('visits')
          .select('*, visit_photos(count)')
          .inFilter('garden_id', gardenIds)
          .eq('status', 'CLOSED')
          .order('started_at', ascending: false);
    } else {
      return [];
    }

    return visits.map((v) {
      final startedAt = DateTime.parse(v['started_at'] as String);
      final endedAt = v['ended_at'] != null ? DateTime.parse(v['ended_at'] as String) : null;
      final durationMinutes = endedAt != null ? endedAt.difference(startedAt).inMinutes : 0;
      final photoCount = (v['visit_photos'] as List?)?.isNotEmpty == true
          ? (v['visit_photos'][0]['count'] as int? ?? 0)
          : 0;

      return VisitSummary(
        id: v['id'] as String,
        gardenId: v['garden_id'] as String,
        durationMinutes: durationMinutes,
        dayLabel: startedAt.day.toString().padLeft(2, '0'),
        monthLabel: _monthLabel(startedAt.month),
        title: v['title'] as String? ?? '',
        description: v['description'] as String? ?? '',
        status: v['verification_status'] == 'VERIFIED'
            ? VisitVerificationStatus.verified
            : VisitVerificationStatus.manualEntry,
        photoCount: photoCount,
      );
    }).toList();
  }

  @override
  Future<VisitReport> loadVisitReport(String visitId) async {
    final v = await _client
        .from('visits')
        .select('*, visit_photos(*), gardens(*)')
        .eq('id', visitId)
        .single();

    final startedAt = DateTime.parse(v['started_at'] as String);
    final endedAt = v['ended_at'] != null ? DateTime.parse(v['ended_at'] as String) : startedAt;
    final duration = endedAt.difference(startedAt);

    final garden = v['gardens'] as Map<String, dynamic>?;
    final photos = (v['visit_photos'] as List? ?? [])
        .map((p) => VisitPhoto(
              label: p['label'] as String? ?? '',
              imageUrl: p['storage_path'] as String? ?? '',
              featured: false,
            ))
        .toList();

    // Get gardener info
    final gardener = await _client
        .from('gardener_profiles')
        .select('display_name, avatar_url')
        .eq('id', v['gardener_id'] as String)
        .maybeSingle();

    return VisitReport(
      visitId: visitId,
      locationName: garden?['name'] as String? ?? '',
      locationContext: garden?['address'] as String? ?? '',
      headerImageUrl: '',
      status: v['verification_status'] == 'VERIFIED'
          ? VisitVerificationStatus.verified
          : VisitVerificationStatus.manualEntry,
      visitDate: _formatDate(startedAt),
      duration: _formatDuration(duration),
      entryTime: '${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}',
      exitTime: '${endedAt.hour.toString().padLeft(2, '0')}:${endedAt.minute.toString().padLeft(2, '0')}',
      gardenerName: gardener?['display_name'] as String? ?? '',
      gardenerRole: 'Gardener',
      gardenerAvatarUrl: gardener?['avatar_url'] as String? ?? '',
      workPerformed: v['description'] as String? ?? '',
      publicComment: v['public_comment'] as String? ?? '',
      photos: photos,
    );
  }

  @override
  Future<List<AssignedGardenVisitStatus>> loadAssignedGardensVisitStatus() async {
    final gardenerId = await _getGardenerProfileId();
    if (gardenerId == null) return [];

    final assignments = await _client
        .from('garden_assignments')
        .select('garden_id, gardens(*)')
        .eq('gardener_id', gardenerId)
        .eq('is_active', true);

    return (assignments as List).map((a) {
      final garden = a['gardens'] as Map<String, dynamic>;
      return AssignedGardenVisitStatus(
        id: garden['id'] as String,
        gardenName: garden['name'] as String,
        address: garden['address'] as String,
        urgency: GardenVisitUrgency.maintained,
        lastVisitLabel: 'Last Visit',
        lastVisitAge: '',
        evidence: VisitEvidence.verified,
        primaryActionLabel: 'Ver Jardín',
      );
    }).toList();
  }

  @override
  Future<ActiveVisitSnapshot?> loadActiveVisit() async {
    // Do not short-circuit from cache: always fetch fresh data so that
    // photos and comments added since the last load are reflected in the UI.

    final gardenerId = await _getGardenerProfileId();
    if (gardenerId == null) return null;

    final data = await _client
        .from('visits')
        .select('*, gardens(*), visit_photos(*)')
        .eq('gardener_id', gardenerId)
        .eq('status', 'ACTIVE')
        .maybeSingle();

    if (data == null) return null;

    final garden = data['gardens'] as Map<String, dynamic>;
    final photos = await _resolvePhotoUrls(data['visit_photos'] as List? ?? []);

    _activeVisit = ActiveVisitSnapshot(
      id: data['id'] as String,
      garden: AssignedGardenVisitStatus(
        id: garden['id'] as String,
        gardenName: garden['name'] as String,
        address: garden['address'] as String,
        urgency: GardenVisitUrgency.maintained,
        lastVisitLabel: '',
        lastVisitAge: '',
        evidence: VisitEvidence.verified,
        primaryActionLabel: '',
      ),
      startedAt: DateTime.parse(data['started_at'] as String),
      endedAt: null,
      isVerified: data['verification_status'] == 'VERIFIED',
      initiationMethod: data['initiation_method'] == 'QR_SCAN'
          ? VisitInitiationMethod.qrScan
          : VisitInitiationMethod.manual,
      photos: photos,
      publicComment: data['public_comment'] as String? ?? '',
    );
    return _activeVisit;
  }

  @override
  Future<ActiveVisitSnapshot> startVisitFromQr({required String gardenId}) async {
    return _startVisit(gardenId: gardenId, isVerified: true, method: 'QR_SCAN');
  }

  @override
  Future<ActiveVisitSnapshot> startManualVisit({
    required String gardenId,
    required bool isVerified,
  }) async {
    return _startVisit(gardenId: gardenId, isVerified: isVerified, method: 'MANUAL');
  }

  Future<ActiveVisitSnapshot> _startVisit({
    required String gardenId,
    required bool isVerified,
    required String method,
  }) async {
    if (_activeVisit?.isActive == true) throw const ActiveVisitExistsError();

    final gardenerId = await _getGardenerProfileId();
    if (gardenerId == null) throw const GardenNotAssignedError();

    final garden = await _client
        .from('gardens')
        .select('*')
        .eq('id', gardenId)
        .single();

    final visit = await _client.from('visits').insert({
      'garden_id': gardenId,
      'gardener_id': gardenerId,
      'status': 'ACTIVE',
      'verification_status': isVerified ? 'VERIFIED' : 'NOT_VERIFIED',
      'initiation_method': method,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    _activeVisit = ActiveVisitSnapshot(
      id: visit['id'] as String,
      garden: AssignedGardenVisitStatus(
        id: garden['id'] as String,
        gardenName: garden['name'] as String,
        address: garden['address'] as String,
        urgency: GardenVisitUrgency.maintained,
        lastVisitLabel: '',
        lastVisitAge: '',
        evidence: isVerified ? VisitEvidence.verified : VisitEvidence.manual,
        primaryActionLabel: '',
      ),
      startedAt: DateTime.parse(visit['started_at'] as String),
      endedAt: null,
      isVerified: isVerified,
      initiationMethod: method == 'QR_SCAN'
          ? VisitInitiationMethod.qrScan
          : VisitInitiationMethod.manual,
    );
    return _activeVisit!;
  }

  @override
  Future<void> closeActiveVisit() async {
    final gardenerId = await _getGardenerProfileId();
    if (gardenerId == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('visits')
        .update({'status': 'CLOSED', 'ended_at': now})
        .eq('gardener_id', gardenerId)
        .eq('status', 'ACTIVE');

    _activeVisit = null;
  }

  @override
  Future<void> addPhotoToActiveVisit({
    required String photoLabel,
    required String localPath,
    required String thumbnailPath,
  }) async {
    if (_activeVisit == null) throw const VisitNotFoundError();

    final gardenerId = await _getGardenerProfileId();
    if (gardenerId == null) throw const VisitNotFoundError();

    // Find the active visit id
    final visitData = await _client
        .from('visits')
        .select('id')
        .eq('gardener_id', gardenerId)
        .eq('status', 'ACTIVE')
        .maybeSingle();
    if (visitData == null) throw const VisitNotFoundError();
    final visitId = visitData['id'] as String;

    // Compress and upload both full and thumbnail versions
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fullPath = 'visits/$visitId/full_$ts.jpg';
    final thumbPath = 'visits/$visitId/thumb_$ts.jpg';

    final rawBytes = await File(localPath).readAsBytes();
    Uint8List fullBytes;
    Uint8List thumbBytes;
    try {
      fullBytes = await FlutterImageCompress.compressWithFile(
            localPath,
            minWidth: 1280,
            minHeight: 1280,
            quality: 80,
            keepExif: false,
          ) ??
          rawBytes;
      thumbBytes = await FlutterImageCompress.compressWithFile(
            localPath,
            minWidth: 400,
            minHeight: 400,
            quality: 65,
            keepExif: false,
          ) ??
          rawBytes;
    } catch (_) {
      // Compression not available (simulator / plugin not registered) — upload original.
      fullBytes = rawBytes;
      thumbBytes = rawBytes;
    }

    await Future.wait([
      _client.storage.from('visit-photos').uploadBinary(
        fullPath,
        fullBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
      ),
      _client.storage.from('visit-photos').uploadBinary(
        thumbPath,
        thumbBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
      ),
    ]);

    // Insert photo record
    final photo = await _client.from('visit_photos').insert({
      'visit_id': visitId,
      'storage_path': fullPath,
      'thumbnail_path': thumbPath,
      'label': photoLabel,
    }).select().single();

    // Update in-memory cache — use local path so the thumbnail renders instantly
    // without a network round-trip (the file is still on disk at this point).
    final newPhoto = LocalVisitPhoto(
      id: photo['id'] as String,
      localPath: localPath,
      thumbnailPath: localPath,
      label: photoLabel,
      createdAt: DateTime.now(),
    );
    _activeVisit = ActiveVisitSnapshot(
      garden: _activeVisit!.garden,
      startedAt: _activeVisit!.startedAt,
      endedAt: _activeVisit!.endedAt,
      isVerified: _activeVisit!.isVerified,
      initiationMethod: _activeVisit!.initiationMethod,
      photos: [..._activeVisit!.photos, newPhoto],
      publicComment: _activeVisit!.publicComment,
    );
  }

  @override
  Future<void> removePhotoFromActiveVisit({required String photoId}) async {
    await _client.from('visit_photos').delete().eq('id', photoId);
  }

  @override
  Future<void> updatePublicComment({required String comment}) async {
    if (_activeVisit == null) return;
    final gardenerId = await _getGardenerProfileId();

    await _client
        .from('visits')
        .update({'public_comment': comment})
        .eq('gardener_id', gardenerId!)
        .eq('status', 'ACTIVE');

    _activeVisit = ActiveVisitSnapshot(
      garden: _activeVisit!.garden,
      startedAt: _activeVisit!.startedAt,
      endedAt: _activeVisit!.endedAt,
      isVerified: _activeVisit!.isVerified,
      initiationMethod: _activeVisit!.initiationMethod,
      photos: _activeVisit!.photos,
      publicComment: comment,
    );
  }

  @override
  Future<void> updateVisitTimestamps({
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    // Only closed visits — auto-unverify
    if (_activeVisit?.endedAt == null) return;
    final gardenerId = await _getGardenerProfileId();

    await _client.from('visits').update({
      'started_at': newStartTime.toUtc().toIso8601String(),
      'ended_at': newEndTime.toUtc().toIso8601String(),
      'verification_status': 'NOT_VERIFIED',
    }).eq('gardener_id', gardenerId!).eq('status', 'CLOSED');

    _activeVisit = ActiveVisitSnapshot(
      garden: _activeVisit!.garden,
      startedAt: newStartTime,
      endedAt: newEndTime,
      isVerified: false,
      initiationMethod: _activeVisit!.initiationMethod,
      photos: _activeVisit!.photos,
      publicComment: _activeVisit!.publicComment,
    );
  }

  @override
  Future<ActiveVisitSnapshot> openCompletedVisitForEditing({required String visitId}) async {
    final v = await _client
        .from('visits')
        .select('*, gardens(*), visit_photos(*)')
        .eq('id', visitId)
        .single();

    final garden = v['gardens'] as Map<String, dynamic>;
    final photos = await _resolvePhotoUrls(v['visit_photos'] as List? ?? []);
    _activeVisit = ActiveVisitSnapshot(
      garden: AssignedGardenVisitStatus(
        id: garden['id'] as String,
        gardenName: garden['name'] as String,
        address: garden['address'] as String,
        urgency: GardenVisitUrgency.maintained,
        lastVisitLabel: '',
        lastVisitAge: '',
        evidence: VisitEvidence.verified,
        primaryActionLabel: '',
      ),
      startedAt: DateTime.parse(v['started_at'] as String),
      endedAt: v['ended_at'] != null ? DateTime.parse(v['ended_at'] as String) : null,
      isVerified: v['verification_status'] == 'VERIFIED',
      initiationMethod: v['initiation_method'] == 'QR_SCAN'
          ? VisitInitiationMethod.qrScan
          : VisitInitiationMethod.manual,
      photos: photos,
      publicComment: v['public_comment'] as String? ?? '',
    );
    return _activeVisit!;
  }

  @override
  Future<ActiveVisitSnapshot> openLatestVisitForGarden({required String gardenId}) async {
    final v = await _client
        .from('visits')
        .select('*, gardens(*)')
        .eq('garden_id', gardenId)
        .order('started_at', ascending: false)
        .limit(1)
        .single();

    final garden = v['gardens'] as Map<String, dynamic>;
    _activeVisit = ActiveVisitSnapshot(
      garden: AssignedGardenVisitStatus(
        id: garden['id'] as String,
        gardenName: garden['name'] as String,
        address: garden['address'] as String,
        urgency: GardenVisitUrgency.maintained,
        lastVisitLabel: '',
        lastVisitAge: '',
        evidence: VisitEvidence.verified,
        primaryActionLabel: '',
      ),
      startedAt: DateTime.parse(v['started_at'] as String),
      endedAt: v['ended_at'] != null ? DateTime.parse(v['ended_at'] as String) : null,
      isVerified: v['verification_status'] == 'VERIFIED',
      initiationMethod: v['initiation_method'] == 'QR_SCAN'
          ? VisitInitiationMethod.qrScan
          : VisitInitiationMethod.manual,
      publicComment: v['public_comment'] as String? ?? '',
    );
    return _activeVisit!;
  }

  @override
  Future<List<ManualStartCandidate>> loadNearbyManualStartCandidates() async {
    final gardens = await loadAssignedGardensVisitStatus();
    return gardens.map((g) => ManualStartCandidate(garden: g, distanceMeters: 0)).toList();
  }

  @override
  Future<List<VisitLocationPoint>> loadVisitLocationPoints(String visitId) async {
    final rows = await _client
        .from('visit_location_points')
        .select('visit_id, lat, lng, accuracy, recorded_at')
        .eq('visit_id', visitId)
        .order('recorded_at');
    return (rows as List).map((r) => VisitLocationPoint(
      visitId: r['visit_id'] as String,
      lat: (r['lat'] as num).toDouble(),
      lng: (r['lng'] as num).toDouble(),
      accuracy: (r['accuracy'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(r['recorded_at'] as String),
    )).toList();
  }

  @override
  Future<void> recordLocationPoint({
    required String visitId,
    required double lat,
    required double lng,
    double? accuracy,
  }) async {
    await _client.from('visit_location_points').insert({
      'visit_id': visitId,
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
    });
  }

  /// Resolves a list of visit_photos DB rows into [LocalVisitPhoto] objects
  /// with signed URLs valid for 1 hour. Uses a batch call to minimise round-trips.
  Future<List<LocalVisitPhoto>> _resolvePhotoUrls(List<dynamic> rows) async {
    if (rows.isEmpty) return [];

    // Collect the unique storage paths that need signing.
    final storagePaths = rows.map((p) => p['storage_path'] as String? ?? '').toList();
    final thumbPaths = rows.map((p) => p['thumbnail_path'] as String? ?? '').toList();

    final allPaths = {...storagePaths, ...thumbPaths}
        .where((p) => p.isNotEmpty && !p.startsWith('http'))
        .toList();

    // Batch-sign in one request.
    final Map<String, String> urlMap = {};
    if (allPaths.isNotEmpty) {
      final signed = await _client.storage
          .from('visit-photos')
          .createSignedUrls(allPaths, 3600);
      for (final item in signed) {
        urlMap[item.path] = item.signedUrl;
      }
    }

    String resolve(String path) {
      if (path.isEmpty) return '';
      if (path.startsWith('http')) return path; // already a URL (e.g. local file was cached)
      return urlMap[path] ?? path;
    }

    return rows.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      return LocalVisitPhoto(
        id: p['id'] as String,
        localPath: resolve(storagePaths[i]),
        thumbnailPath: resolve(thumbPaths[i]),
        label: p['label'] as String? ?? '',
        createdAt: DateTime.tryParse(p['created_at'] as String? ?? ''),
      );
    }).toList();
  }

  // --- Helpers ---
  String _monthLabel(int month) {
    const months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month];
  }

  String _formatDate(DateTime d) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Future<ActiveClientVisitInfo?> loadActiveVisitForClient() async {
    final clientId = await _getClientProfileId();
    if (clientId == null) return null;

    // Get this client's garden IDs
    final gardens = await _client
        .from('gardens')
        .select('id')
        .eq('client_id', clientId);
    final gardenIds = (gardens as List).map((g) => g['id'] as String).toList();
    if (gardenIds.isEmpty) return null;

    // Find active visit in those gardens
    final visitData = await _client
        .from('visits')
        .select('id, started_at, gardener_id')
        .eq('status', 'ACTIVE')
        .inFilter('garden_id', gardenIds)
        .maybeSingle();
    if (visitData == null) return null;

    // Resolve gardener display name via gardener_profiles → user_profiles
    final gardenerId = visitData['gardener_id'] as String;
    final gardenerProfile = await _client
        .from('gardener_profiles')
        .select('user_id')
        .eq('id', gardenerId)
        .maybeSingle();

    String gardenerName = 'Jardinero';
    if (gardenerProfile != null) {
      final userProfile = await _client
          .from('user_profiles')
          .select('display_name')
          .eq('id', gardenerProfile['user_id'] as String)
          .maybeSingle();
      gardenerName = userProfile?['display_name'] as String? ?? gardenerName;
    }

    return ActiveClientVisitInfo(
      visitId: visitData['id'] as String,
      gardenerName: gardenerName,
      startedAt: DateTime.parse(visitData['started_at'] as String),
    );
  }
}
