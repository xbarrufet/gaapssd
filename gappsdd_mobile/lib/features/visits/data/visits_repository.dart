import '../../../core/errors/app_error.dart';
import '../domain/client_visits_data.dart';

abstract class VisitsRepository {
  Future<ClientProfile> loadClientProfile();
  Future<List<VisitSummary>> loadCompletedVisits();
  Future<VisitReport> loadVisitReport(String visitId);
  Future<List<AssignedGardenVisitStatus>> loadAssignedGardensVisitStatus();
  Future<ActiveVisitSnapshot?> loadActiveVisit();
  Future<ActiveVisitSnapshot> openCompletedVisitForEditing({required String visitId});
  Future<ActiveVisitSnapshot> openLatestVisitForGarden({required String gardenId});
  Future<List<ManualStartCandidate>> loadNearbyManualStartCandidates();
  Future<ActiveVisitSnapshot> startVisitFromQr({required String gardenId});
  Future<ActiveVisitSnapshot> startManualVisit({
    required String gardenId,
    required bool isVerified,
  });
  Future<void> closeActiveVisit();

  // Photo management
  Future<void> addPhotoToActiveVisit({
    required String photoLabel,
    required String localPath,
    required String thumbnailPath,
  });
  Future<void> removePhotoFromActiveVisit({required String photoId});

  // Comment management
  Future<void> updatePublicComment({required String comment});

  // Timestamp editing (closed visits only)
  Future<void> updateVisitTimestamps({
    required DateTime newStartTime,
    required DateTime newEndTime,
  });

  // Location tracking (heatmap data collection)
  Future<void> recordLocationPoint({
    required String visitId,
    required double lat,
    required double lng,
    double? accuracy,
  });

  Future<List<VisitLocationPoint>> loadVisitLocationPoints(String visitId);

  /// Returns the active visit in any of the client's gardens, or null if none.
  Future<ActiveClientVisitInfo?> loadActiveVisitForClient();

  Future<ClientVisitsData> loadClientVisitsData() async {
    final results = await Future.wait([
      loadClientProfile(),
      loadCompletedVisits(),
      loadActiveVisitForClient(),
    ]);
    return ClientVisitsData(
      profile: results[0] as ClientProfile,
      visits: results[1] as List<VisitSummary>,
      activeVisit: results[2] as ActiveClientVisitInfo?,
    );
  }
}

class FakeVisitsRepository extends VisitsRepository {
  ActiveVisitSnapshot? _activeVisit;

  static final List<AssignedGardenVisitStatus> _assignedGardens = [
    AssignedGardenVisitStatus(
      id: 'garden-villa-hortensia',
      gardenName: 'Villa Hortensia',
      address: '122 Calle de las Rosas, Madrid',
      urgency: GardenVisitUrgency.urgent,
      lastVisitLabel: 'Last Visit',
      lastVisitAge: '24 days ago',
      evidence: VisitEvidence.verified,
      primaryActionLabel: 'Última Visita',
      lastVisitDate: DateTime(2026, 3, 15),
    ),
    AssignedGardenVisitStatus(
      id: 'garden-can-roca',
      gardenName: 'Can Roca',
      address: 'Av. Diagonal 450, Barcelona',
      urgency: GardenVisitUrgency.upcoming,
      lastVisitLabel: 'Last Visit',
      lastVisitAge: '12 days ago',
      evidence: VisitEvidence.manual,
      primaryActionLabel: 'Última Visita',
      lastVisitDate: DateTime(2026, 3, 27),
    ),
    AssignedGardenVisitStatus(
      id: 'garden-mas-de-mar',
      gardenName: 'Mas de Mar',
      address: 'Cami de Ronda s/n, Costa Brava',
      urgency: GardenVisitUrgency.maintained,
      lastVisitLabel: 'Last Visit',
      lastVisitAge: '3 days ago',
      evidence: VisitEvidence.verified,
      primaryActionLabel: 'Última Visita',
      lastVisitDate: DateTime(2026, 4, 5),
    ),
    AssignedGardenVisitStatus(
      id: 'garden-el-olivar',
      gardenName: 'El Olivar',
      address: 'Plaza Mayor, 12, Segovia',
      urgency: GardenVisitUrgency.maintained,
      lastVisitLabel: 'Last Visit',
      lastVisitAge: 'Yesterday',
      evidence: VisitEvidence.manual,
      primaryActionLabel: 'Última Visita',
      lastVisitDate: DateTime(2026, 4, 7),
    ),
  ];

  @override
  Future<ClientProfile> loadClientProfile() {
    return Future<ClientProfile>.delayed(
      const Duration(milliseconds: 180),
      () => const ClientProfile(
        appTitle: 'GAPP Garden',
        clientName: 'Casa Rural Puig',
        gardenerName: 'Xavier Barrufet',
        gardenerRole: 'Lead Gardener',
        gardenerAvatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBi8eJ6x5C8RS8VrQo1y-WZ2J9RagVqSJKeJPLNv2cdtltHfVxyVoZTA-GDif6vDDzOt-O0zK8fCcYVow_El-L3npzRl1PcWOUvCOZvdl-xH_Rs8f8UzsRejYgXpfCoEWlNNJmEV89uQNgQdkq3Do1vtTRvAyeHZflvzvfiyO-vO5bmLsPnFv3cLJ2gtz3R0G8NCjiQxfBIoDD1XGdtm5Oe9O5vE0gO_4immaPioJdYjbunqf-viXk7fZLs6qJDA1o1rYEiY0mww_Bu',
        heroImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAmFTSSW8e_0TjF79LBTTT4gkFYD0NtRdSqhMcyNbkyVCIryaNjBCrvm72BlmEFmXUjiDI9UzvDejqlrslDI1Maa5uBCTTA_1sNtBzwISUs3LmC_QZ-xib8DtI3WvsmJef7oIfFTN7YSXYS8oA-m3jTHnam5YQO_0DPpUfTxUFqq0935I4GIUOQ7L-_aRlxV3RWArG20M_LnaGUDF1Ffj6VDY3-dML118_1YfkoFv1IaGbJGRHFeb8Yh9Dpij2E36LnXWgKGHHwdyY6',
      ),
    );
  }

  @override
  Future<List<VisitSummary>> loadCompletedVisits() {
    return Future<List<VisitSummary>>.delayed(
      const Duration(milliseconds: 240),
      () => const [
        VisitSummary(
          id: 'visit-2026-04-08',
          gardenId: 'garden-villa-hortensia',
          durationMinutes: 98,
          dayLabel: '08',
          monthLabel: 'APR',
          title: 'Pruning and Clearing',
          description:
              'Pruned the ornamental shrubs along the main walkway and cleared seasonal debris from the perennial beds.',
          status: VisitVerificationStatus.verified,
          photoCount: 3,
        ),
        VisitSummary(
          id: 'visit-2026-04-02',
          gardenId: 'garden-can-roca',
          durationMinutes: 105,
          dayLabel: '02',
          monthLabel: 'APR',
          title: 'Lawn Mowing',
          description:
              'Standard lawn maintenance completed. Edges trimmed and fertilization applied to the north sector.',
          status: VisitVerificationStatus.verified,
          photoCount: 1,
        ),
        VisitSummary(
          id: 'visit-2026-03-26',
          gardenId: 'garden-mas-de-mar',
          durationMinutes: 58,
          dayLabel: '26',
          monthLabel: 'MAR',
          title: 'Irrigation Check',
          description:
              'Verified all sprinkler heads for proper coverage. Replaced one damaged valve in zone 3.',
          status: VisitVerificationStatus.manualEntry,
          photoCount: 1,
        ),
      ],
    );
  }

  @override
  Future<VisitReport> loadVisitReport(String visitId) {
    const reports = <String, VisitReport>{
      'visit-2026-04-08': VisitReport(
        visitId: 'visit-2026-04-08',
        locationName: 'Casa Rural Puig',
        locationContext: 'Estate Grounds',
        headerImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAli2862c54yIiShbdM8xpK1XhMWCkjrOkbOjtamFHt_A-N9YSPbgw68zEUlZNX8Zbe8oDmnrAHQS_cDB7eFzkw-JXyBBrYQAuz2AGv0Juxq3CMMHhv1lI8WOZghFd4hKE3SkJ0aRl40E-5PAacsvhrtlVrIsJM84cVw4ieacxenuNPGUA146-baaA_M1ilBh53wjHYipLMkEwk90YSMGhKkZ36uKRa6_lNNDIZKY2LQlbq0gJFV2VkMkGTnlYxrr9EYz560JgQk3w7',
        status: VisitVerificationStatus.verified,
        visitDate: 'April 08, 2026',
        duration: '01:37:42',
        entryTime: '09:12',
        exitTime: '10:49',
        gardenerName: 'Xavier Barrufet',
        gardenerRole: 'Lead Gardener',
        gardenerAvatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBi8eJ6x5C8RS8VrQo1y-WZ2J9RagVqSJKeJPLNv2cdtltHfVxyVoZTA-GDif6vDDzOt-O0zK8fCcYVow_El-L3npzRl1PcWOUvCOZvdl-xH_Rs8f8UzsRejYgXpfCoEWlNNJmEV89uQNgQdkq3Do1vtTRvAyeHZflvzvfiyO-vO5bmLsPnFv3cLJ2gtz3R0G8NCjiQxfBIoDD1XGdtm5Oe9O5vE0gO_4immaPioJdYjbunqf-viXk7fZLs6qJDA1o1rYEiY0mww_Bu',
        workPerformed:
            'The visit started with selective pruning of ornamental shrubs near the main access path. We removed dry branches from the perennial beds, cleaned seasonal debris, and rebalanced growth zones in the north corridor. Soil moisture and sprinkler coverage were checked and remained in optimal range after the cleanup.',
        publicComment: 'Poda completada y limpieza de zona de paso.',
        photos: [
          VisitPhoto(
            label: 'PRUNING',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBpOF9sGNJ_A9859YuXdtM2UVkRB69JHruJ7kkfY5LshbJcXDIjx_pGP7taQu3Zek0NpekcOA-aUvBBR-hh6MIUESky84CCzfuWbHIHpOWkyIDoxpdKSqW7JJzst2ZVYwPN5PheCrTOn_2EXyT9hKbM1bMf8Zp13ADZL28g3q9CeScroSoHq8YQjr7fJ0abjMrkyl-rk7KTI3Zr-q0wlZN-t-iwjgxmEm10fgxp9-D6Gxc_n45CajOOTcweZOyql12oWYw5quAMzcsE',
            featured: true,
          ),
          VisitPhoto(
            label: 'ROSE CARE',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCO6hHLuMizqGBuq374EyQOy6Px6Ywpt0VnK-mSnOTJLc-tJL2QtBYEQxSa7jkfnGc1YWw5UVJsvnnMuYWApslrLWFQP4fHdNUonPwoBP5ryLTikpCGh6D_kTOIR9iJzVMEPGnLBfQ5pkMyJvHNR0UfBdFy9jpJpErDs2-rQUlG4j7UtVeGqDTxGp8AmhxrzKs9hBe2iQvwXBLgAwOhFTYcLG9YPcUkG1gDzTIMFG2ERI6r503iRczIEL5IUNrszeX58l2wWBpVPi6n',
          ),
          VisitPhoto(
            label: 'FEEDING',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDXZ45acj23TYY0OWtsryJsI2m64WKNrju9AzE_kmgV3e4y1dHOsX3NwINt4UZ0b2_dewUl_qSc9urmMHX5Z1hoytU2S-4_y0NWMYZobYhQTxSrtJvb6e3I8eC3ZnCgWKlZccG0ZavUmSavkIqwsE1-MK3XbUatoieSv2r1pD89AInyEGzWoJkHJtvwYqArMt_EvFdb7EEzEYf2n770KjRr8qxymu96sLxLFDiOG4nOqaoLZImr_oi0OpFW8HAH-x9kuKjO4wVIRazm',
          ),
        ],
      ),
      'visit-2026-04-02': VisitReport(
        visitId: 'visit-2026-04-02',
        locationName: 'Casa Rural Puig',
        locationContext: 'Front Lawn',
        headerImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAli2862c54yIiShbdM8xpK1XhMWCkjrOkbOjtamFHt_A-N9YSPbgw68zEUlZNX8Zbe8oDmnrAHQS_cDB7eFzkw-JXyBBrYQAuz2AGv0Juxq3CMMHhv1lI8WOZghFd4hKE3SkJ0aRl40E-5PAacsvhrtlVrIsJM84cVw4ieacxenuNPGUA146-baaA_M1ilBh53wjHYipLMkEwk90YSMGhKkZ36uKRa6_lNNDIZKY2LQlbq0gJFV2VkMkGTnlYxrr9EYz560JgQk3w7',
        status: VisitVerificationStatus.verified,
        visitDate: 'April 02, 2026',
        duration: '01:45:12',
        entryTime: '08:30',
        exitTime: '10:15',
        gardenerName: 'Xavier Barrufet',
        gardenerRole: 'Lead Gardener',
        gardenerAvatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBi8eJ6x5C8RS8VrQo1y-WZ2J9RagVqSJKeJPLNv2cdtltHfVxyVoZTA-GDif6vDDzOt-O0zK8fCcYVow_El-L3npzRl1PcWOUvCOZvdl-xH_Rs8f8UzsRejYgXpfCoEWlNNJmEV89uQNgQdkq3Do1vtTRvAyeHZflvzvfiyO-vO5bmLsPnFv3cLJ2gtz3R0G8NCjiQxfBIoDD1XGdtm5Oe9O5vE0gO_4immaPioJdYjbunqf-viXk7fZLs6qJDA1o1rYEiY0mww_Bu',
        workPerformed:
            'Standard lawn maintenance was completed with edge trimming across stone borders and a light organic feed application on the north sector. Grass height was normalized and visual uniformity restored across the main client area.',
        publicComment: 'Mantenimiento general del cesped y bordes.',
        photos: [
          VisitPhoto(
            label: 'LAWN MOWING',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBpOF9sGNJ_A9859YuXdtM2UVkRB69JHruJ7kkfY5LshbJcXDIjx_pGP7taQu3Zek0NpekcOA-aUvBBR-hh6MIUESky84CCzfuWbHIHpOWkyIDoxpdKSqW7JJzst2ZVYwPN5PheCrTOn_2EXyT9hKbM1bMf8Zp13ADZL28g3q9CeScroSoHq8YQjr7fJ0abjMrkyl-rk7KTI3Zr-q0wlZN-t-iwjgxmEm10fgxp9-D6Gxc_n45CajOOTcweZOyql12oWYw5quAMzcsE',
            featured: true,
          ),
        ],
      ),
      'visit-2026-03-26': VisitReport(
        visitId: 'visit-2026-03-26',
        locationName: 'Casa Rural Puig',
        locationContext: 'Irrigation Zones',
        headerImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAli2862c54yIiShbdM8xpK1XhMWCkjrOkbOjtamFHt_A-N9YSPbgw68zEUlZNX8Zbe8oDmnrAHQS_cDB7eFzkw-JXyBBrYQAuz2AGv0Juxq3CMMHhv1lI8WOZghFd4hKE3SkJ0aRl40E-5PAacsvhrtlVrIsJM84cVw4ieacxenuNPGUA146-baaA_M1ilBh53wjHYipLMkEwk90YSMGhKkZ36uKRa6_lNNDIZKY2LQlbq0gJFV2VkMkGTnlYxrr9EYz560JgQk3w7',
        status: VisitVerificationStatus.manualEntry,
        visitDate: 'March 26, 2026',
        duration: '00:58:05',
        entryTime: '11:04',
        exitTime: '12:02',
        gardenerName: 'Xavier Barrufet',
        gardenerRole: 'Lead Gardener',
        gardenerAvatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBi8eJ6x5C8RS8VrQo1y-WZ2J9RagVqSJKeJPLNv2cdtltHfVxyVoZTA-GDif6vDDzOt-O0zK8fCcYVow_El-L3npzRl1PcWOUvCOZvdl-xH_Rs8f8UzsRejYgXpfCoEWlNNJmEV89uQNgQdkq3Do1vtTRvAyeHZflvzvfiyO-vO5bmLsPnFv3cLJ2gtz3R0G8NCjiQxfBIoDD1XGdtm5Oe9O5vE0gO_4immaPioJdYjbunqf-viXk7fZLs6qJDA1o1rYEiY0mww_Bu',
        workPerformed:
            'All sprinkler heads were verified for pressure and radius. One damaged valve in zone 3 was replaced manually. This report was uploaded without telemetric validation due to temporary connectivity loss during the field operation.',
        publicComment: 'Revision de riego y sustitucion de valvula.',
        photos: [
          VisitPhoto(
            label: 'IRRIGATION',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDXZ45acj23TYY0OWtsryJsI2m64WKNrju9AzE_kmgV3e4y1dHOsX3NwINt4UZ0b2_dewUl_qSc9urmMHX5Z1hoytU2S-4_y0NWMYZobYhQTxSrtJvb6e3I8eC3ZnCgWKlZccG0ZavUmSavkIqwsE1-MK3XbUatoieSv2r1pD89AInyEGzWoJkHJtvwYqArMt_EvFdb7EEzEYf2n770KjRr8qxymu96sLxLFDiOG4nOqaoLZImr_oi0OpFW8HAH-x9kuKjO4wVIRazm',
            featured: true,
          ),
        ],
      ),
    };

    return Future<VisitReport>.delayed(
      const Duration(milliseconds: 200),
      () => reports[visitId] ?? reports.values.first,
    );
  }

  @override
  Future<List<AssignedGardenVisitStatus>> loadAssignedGardensVisitStatus() {
    return Future<List<AssignedGardenVisitStatus>>.delayed(
      const Duration(milliseconds: 220),
      () => _assignedGardens,
    );
  }

  @override
  Future<ActiveVisitSnapshot?> loadActiveVisit() {
    return Future<ActiveVisitSnapshot?>.delayed(
      const Duration(milliseconds: 120),
      () => _activeVisit,
    );
  }

  @override
  Future<ActiveVisitSnapshot> openCompletedVisitForEditing({required String visitId}) {
    return Future<ActiveVisitSnapshot>.delayed(const Duration(milliseconds: 120), () {
      final summary = {
        'visit-2026-04-08': (
          gardenId: 'garden-villa-hortensia',
          startedAt: DateTime(2026, 4, 8, 9, 12),
          endedAt: DateTime(2026, 4, 8, 10, 49),
          verified: true,
          note: 'Poda completada y limpieza de zona de paso.',
        ),
        'visit-2026-04-02': (
          gardenId: 'garden-can-roca',
          startedAt: DateTime(2026, 4, 2, 8, 30),
          endedAt: DateTime(2026, 4, 2, 10, 15),
          verified: true,
          note: 'Mantenimiento general del cesped y bordes.',
        ),
        'visit-2026-03-26': (
          gardenId: 'garden-mas-de-mar',
          startedAt: DateTime(2026, 3, 26, 11, 4),
          endedAt: DateTime(2026, 3, 26, 12, 2),
          verified: false,
          note: 'Revision de riego y sustitucion de valvula.',
        ),
      }[visitId];

      if (summary == null) {
        throw const VisitNotFoundError();
      }

      final garden = _assignedGardens.firstWhere(
        (item) => item.id == summary.gardenId,
        orElse: () => _assignedGardens.first,
      );

      final snapshot = ActiveVisitSnapshot(
        garden: garden,
        startedAt: summary.startedAt,
        endedAt: summary.endedAt,
        isVerified: summary.verified,
        initiationMethod: VisitInitiationMethod.manual,
        publicComment: summary.note,
      );

      _activeVisit = snapshot;
      return snapshot;
    });
  }

  @override
  Future<ActiveVisitSnapshot> openLatestVisitForGarden({required String gardenId}) {
    return Future<ActiveVisitSnapshot>.delayed(const Duration(milliseconds: 120), () {
      final garden = _assignedGardens.firstWhere(
        (item) => item.id == gardenId,
        orElse: () => throw const GardenNotAssignedError(),
      );

      final now = DateTime.now();
      final snapshot = ActiveVisitSnapshot(
        garden: garden,
        startedAt: now.subtract(const Duration(hours: 2, minutes: 5)),
        endedAt: now.subtract(const Duration(minutes: 23)),
        isVerified: true,
        initiationMethod: VisitInitiationMethod.qrScan,
        publicComment: 'Ultima visita realizada para este cliente.',
      );

      _activeVisit = snapshot;
      return snapshot;
    });
  }

  @override
  Future<List<ManualStartCandidate>> loadNearbyManualStartCandidates() {
    return Future<List<ManualStartCandidate>>.delayed(
      const Duration(milliseconds: 160),
      () => [
        ManualStartCandidate(
          garden: _assignedGardens[0],
          distanceMeters: 5.6,
        ),
        ManualStartCandidate(
          garden: _assignedGardens[1],
          distanceMeters: 8.9,
        ),
      ],
    );
  }

  @override
  Future<ActiveVisitSnapshot> startVisitFromQr({required String gardenId}) async {
    _ensureNoActiveVisit();

    final garden = _assignedGardens.firstWhere(
      (item) => item.id == gardenId,
      orElse: () => throw const GardenNotAssignedError(),
    );

    final snapshot = ActiveVisitSnapshot(
      garden: garden,
      startedAt: DateTime.now(),
      endedAt: null,
      isVerified: true,
      initiationMethod: VisitInitiationMethod.qrScan,
    );

    _activeVisit = snapshot;
    return snapshot;
  }

  @override
  Future<ActiveVisitSnapshot> startManualVisit({
    required String gardenId,
    required bool isVerified,
  }) async {
    _ensureNoActiveVisit();

    final garden = _assignedGardens.firstWhere(
      (item) => item.id == gardenId,
      orElse: () => throw const GardenNotAssignedError(),
    );

    final snapshot = ActiveVisitSnapshot(
      garden: garden,
      startedAt: DateTime.now(),
      endedAt: null,
      isVerified: isVerified,
      initiationMethod: VisitInitiationMethod.manual,
    );

    _activeVisit = snapshot;
    return snapshot;
  }

  @override
  Future<void> closeActiveVisit() {
    return Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (_activeVisit != null) {
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
    });
  }

  @override
  Future<void> addPhotoToActiveVisit({
    required String photoLabel,
    required String localPath,
    required String thumbnailPath,
  }) {
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_activeVisit != null) {
        final newPhoto = LocalVisitPhoto(
          id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
          localPath: localPath,
          thumbnailPath: thumbnailPath,
          label: photoLabel,
          createdAt: DateTime.now(),
        );
        
        final updatedPhotos = [..._activeVisit!.photos, newPhoto];
        _activeVisit = ActiveVisitSnapshot(
          garden: _activeVisit!.garden,
          startedAt: _activeVisit!.startedAt,
          endedAt: _activeVisit!.endedAt,
          isVerified: _activeVisit!.isVerified,
          initiationMethod: _activeVisit!.initiationMethod,
          photos: updatedPhotos,
          publicComment: _activeVisit!.publicComment,
        );
      }
    });
  }

  @override
  Future<void> removePhotoFromActiveVisit({required String photoId}) {
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_activeVisit != null) {
        final updatedPhotos = _activeVisit!.photos.where((p) => p.id != photoId).toList();
        _activeVisit = ActiveVisitSnapshot(
          garden: _activeVisit!.garden,
          startedAt: _activeVisit!.startedAt,
          endedAt: _activeVisit!.endedAt,
          isVerified: _activeVisit!.isVerified,
          initiationMethod: _activeVisit!.initiationMethod,
          photos: updatedPhotos,
          publicComment: _activeVisit!.publicComment,
        );
      }
    });
  }

  @override
  Future<void> updatePublicComment({required String comment}) {
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_activeVisit != null) {
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
    });
  }

  @override
  Future<void> updateVisitTimestamps({
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) {
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_activeVisit != null && _activeVisit!.endedAt != null) {
        // Only allow editing closed visits
        _activeVisit = ActiveVisitSnapshot(
          garden: _activeVisit!.garden,
          startedAt: newStartTime,
          endedAt: newEndTime,
          isVerified: false, // Auto-unverify when timestamps change
          initiationMethod: _activeVisit!.initiationMethod,
          photos: _activeVisit!.photos,
          publicComment: _activeVisit!.publicComment,
        );
      }
    });
  }

  @override
  Future<ActiveClientVisitInfo?> loadActiveVisitForClient() {
    return Future.value(null);
  }

  @override
  Future<void> recordLocationPoint({
    required String visitId,
    required double lat,
    required double lng,
    double? accuracy,
  }) async {}

  @override
  Future<List<VisitLocationPoint>> loadVisitLocationPoints(String visitId) async {
    // Fake cluster around a Barcelona garden (41.3851° N, 2.1734° E)
    final base = DateTime(2026, 4, 8, 9, 12);
    final offsets = [
      (dlat: 0.0000, dlng: 0.0000),
      (dlat: 0.0001, dlng: 0.0001),
      (dlat: 0.0002, dlng: 0.0000),
      (dlat: 0.0001, dlng: -0.0001),
      (dlat: 0.0003, dlng: 0.0002),
      (dlat: 0.0001, dlng: 0.0003),
      (dlat: 0.0001, dlng: 0.0001), // duplicate → higher density
      (dlat: 0.0001, dlng: 0.0001),
      (dlat: 0.0004, dlng: 0.0004),
      (dlat: -0.0001, dlng: 0.0001),
    ];
    return offsets.indexed.map((entry) {
      final (i, o) = entry;
      return VisitLocationPoint(
        visitId: visitId,
        lat: 41.3851 + o.dlat,
        lng: 2.1734 + o.dlng,
        accuracy: 5.0,
        recordedAt: base.add(Duration(seconds: i * 30)),
      );
    }).toList();
  }

  void _ensureNoActiveVisit() {
    if (_activeVisit?.isActive == true) {
      throw const ActiveVisitExistsError();
    }
  }
}