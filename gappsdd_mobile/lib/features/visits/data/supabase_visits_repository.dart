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
    if (_activeVisit != null) return _activeVisit;

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
    final photos = (data['visit_photos'] as List? ?? [])
        .map((p) => LocalVisitPhoto(
              id: p['id'] as String,
              localPath: p['storage_path'] as String? ?? '',
              thumbnailPath: p['thumbnail_path'] as String? ?? '',
              label: p['label'] as String? ?? '',
              createdAt: DateTime.tryParse(p['created_at'] as String? ?? ''),
            ))
        .toList();

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
    if (_activeVisit == null) return;

    final gardenerId = await _getGardenerProfileId();
    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('visits')
        .update({'status': 'CLOSED', 'ended_at': now})
        .eq('gardener_id', gardenerId!)
        .eq('status', 'ACTIVE');

    _activeVisit = ActiveVisitSnapshot(
      garden: _activeVisit!.garden,
      startedAt: _activeVisit!.startedAt,
      endedAt: DateTime.now(),
      isVerified: _activeVisit!.isVerified,
      initiationMethod: _activeVisit!.initiationMethod,
      photos: _activeVisit!.photos,
      publicComment: _activeVisit!.publicComment,
    );
  }

  @override
  Future<void> addPhotoToActiveVisit({
    required String photoLabel,
    required String localPath,
    required String thumbnailPath,
  }) async {
    // TODO: Upload to Supabase Storage and save path
    // For now just store the reference
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
}
