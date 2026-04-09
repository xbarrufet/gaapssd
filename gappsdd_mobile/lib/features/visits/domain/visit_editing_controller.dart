import 'dart:ui';

import '../data/visits_repository.dart';
import '../domain/client_visits_data.dart';

/// Controller that encapsulates all visit-editing data operations
/// extracted from the visit details screen.
///
/// The screen should call the appropriate method and the controller
/// will update its internal [visit] state and invoke [onChanged] so
/// the screen can rebuild.
class VisitEditingController {
  VisitEditingController(this._repository);

  final VisitsRepository _repository;

  /// Optional callback invoked after every state mutation so the
  /// hosting widget can call `setState`.
  VoidCallback? onChanged;

  ActiveVisitSnapshot? _visit;

  /// The currently loaded visit snapshot (may be `null` before loading
  /// or if no visit exists).
  ActiveVisitSnapshot? get visit => _visit;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Loads a visit from the repository.
  ///
  /// If [selectedVisitId] is provided the corresponding completed visit is
  /// opened for editing; otherwise the active visit is loaded.
  Future<void> loadVisit({String? selectedVisitId}) async {
    if (selectedVisitId != null) {
      _visit = await _repository.openCompletedVisitForEditing(
        visitId: selectedVisitId,
      );
    } else {
      _visit = await _repository.loadActiveVisit();
    }
    onChanged?.call();
  }

  // ---------------------------------------------------------------------------
  // Close
  // ---------------------------------------------------------------------------

  /// Closes the currently active visit.
  Future<void> closeVisit() async {
    await _repository.closeActiveVisit();
    await _reload();
  }

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  /// Adds a photo to the active visit and reloads the snapshot.
  Future<void> addPhoto({
    required String photoLabel,
    required String localPath,
    required String thumbnailPath,
  }) async {
    await _repository.addPhotoToActiveVisit(
      photoLabel: photoLabel,
      localPath: localPath,
      thumbnailPath: thumbnailPath,
    );
    await _reload();
  }

  /// Removes the photo identified by [photoId] and reloads the snapshot.
  Future<void> removePhoto(String photoId) async {
    await _repository.removePhotoFromActiveVisit(photoId: photoId);
    await _reload();
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  /// Persists [comment] as the public comment and reloads.
  Future<void> saveComment(String comment) async {
    await _repository.updatePublicComment(comment: comment);
    await _reload();
  }

  /// Deletes the public comment (sets it to empty) and reloads.
  Future<void> deleteComment() async {
    await _repository.updatePublicComment(comment: '');
    await _reload();
  }

  // ---------------------------------------------------------------------------
  // Timestamps
  // ---------------------------------------------------------------------------

  /// Updates the start/end timestamps for a closed visit and reloads.
  Future<void> updateTimestamps({
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    await _repository.updateVisitTimestamps(
      newStartTime: newStart,
      newEndTime: newEnd,
    );
    await _reload();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _reload() async {
    _visit = await _repository.loadActiveVisit();
    onChanged?.call();
  }
}
