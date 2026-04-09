import '../data/visits_repository.dart';
import '../domain/client_visits_data.dart';

/// Thin wrapper around [VisitsRepository] that exposes the visit-starting
/// business logic so it can be tested independently of the UI.
class StartVisitUseCase {
  StartVisitUseCase(this._repository);

  final VisitsRepository _repository;

  /// Returns the currently active visit, or `null` if none exists.
  Future<ActiveVisitSnapshot?> checkActiveVisit() {
    return _repository.loadActiveVisit();
  }

  /// Starts a new visit initiated via QR scan for the given [gardenId].
  Future<ActiveVisitSnapshot> startFromQr(String gardenId) {
    return _repository.startVisitFromQr(gardenId: gardenId);
  }

  /// Starts a manual visit for the given [gardenId].
  ///
  /// [isVerified] indicates whether GPS proximity was confirmed.
  Future<ActiveVisitSnapshot> startManual({
    required String gardenId,
    required bool isVerified,
  }) {
    return _repository.startManualVisit(
      gardenId: gardenId,
      isVerified: isVerified,
    );
  }

  /// Loads the list of gardens assigned to the current gardener,
  /// together with their visit status information.
  Future<List<AssignedGardenVisitStatus>> loadAssignedGardens() {
    return _repository.loadAssignedGardensVisitStatus();
  }

  /// Loads nearby gardens that are candidates for a manual visit start.
  Future<List<ManualStartCandidate>> loadNearbyCandidates() {
    return _repository.loadNearbyManualStartCandidates();
  }
}
