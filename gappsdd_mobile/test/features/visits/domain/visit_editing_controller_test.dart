import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/features/visits/data/visits_repository.dart';
import 'package:gappsdd/features/visits/domain/visit_editing_controller.dart';

void main() {
  late FakeVisitsRepository repository;
  late VisitEditingController controller;

  setUp(() {
    repository = FakeVisitsRepository();
    controller = VisitEditingController(repository);
  });

  group('VisitEditingController', () {
    test('visit getter returns null before loading', () {
      expect(controller.visit, isNull);
    });

    test('loadVisit with no selectedVisitId loads active visit', () async {
      await repository.startManualVisit(
        gardenId: 'garden-villa-hortensia',
        isVerified: true,
      );

      await controller.loadVisit();

      expect(controller.visit, isNotNull);
      expect(controller.visit!.garden.id, 'garden-villa-hortensia');
      expect(controller.visit!.isActive, isTrue);
    });

    test('loadVisit with selectedVisitId opens completed visit', () async {
      await controller.loadVisit(selectedVisitId: 'visit-2026-04-08');

      expect(controller.visit, isNotNull);
      expect(controller.visit!.garden.id, 'garden-villa-hortensia');
      expect(controller.visit!.endedAt, isNotNull);
    });

    test('loadVisit calls onChanged callback', () async {
      int callCount = 0;
      controller.onChanged = () => callCount++;

      await repository.startManualVisit(
        gardenId: 'garden-villa-hortensia',
        isVerified: true,
      );
      await controller.loadVisit();

      expect(callCount, 1);
    });

    test('closeVisit calls repository and reloads', () async {
      await repository.startManualVisit(
        gardenId: 'garden-villa-hortensia',
        isVerified: true,
      );
      await controller.loadVisit();
      expect(controller.visit!.isActive, isTrue);

      int callCount = 0;
      controller.onChanged = () => callCount++;

      await controller.closeVisit();

      // After closing, the visit should have endedAt set
      expect(controller.visit, isNotNull);
      expect(controller.visit!.endedAt, isNotNull);
      expect(callCount, 1);
    });

    test('addPhoto adds photo and calls onChanged', () async {
      await repository.startManualVisit(
        gardenId: 'garden-can-roca',
        isVerified: true,
      );
      await controller.loadVisit();
      expect(controller.visit!.photos, isEmpty);

      int callCount = 0;
      controller.onChanged = () => callCount++;

      await controller.addPhoto(
        photoLabel: 'TEST',
        localPath: '/tmp/test.jpg',
        thumbnailPath: '/tmp/test_thumb.jpg',
      );

      expect(controller.visit!.photos, hasLength(1));
      expect(controller.visit!.photos.first.label, 'TEST');
      expect(callCount, 1);
    });

    test('removePhoto removes photo and calls onChanged', () async {
      await repository.startManualVisit(
        gardenId: 'garden-can-roca',
        isVerified: true,
      );
      await controller.loadVisit();

      await controller.addPhoto(
        photoLabel: 'TO_REMOVE',
        localPath: '/tmp/remove.jpg',
        thumbnailPath: '/tmp/remove_thumb.jpg',
      );
      final photoId = controller.visit!.photos.first.id;

      int callCount = 0;
      controller.onChanged = () => callCount++;

      await controller.removePhoto(photoId);

      expect(controller.visit!.photos, isEmpty);
      expect(callCount, 1);
    });

    test('saveComment persists comment and calls onChanged', () async {
      await repository.startManualVisit(
        gardenId: 'garden-villa-hortensia',
        isVerified: true,
      );
      await controller.loadVisit();

      int callCount = 0;
      controller.onChanged = () => callCount++;

      await controller.saveComment('Great progress today');

      expect(controller.visit!.publicComment, 'Great progress today');
      expect(callCount, 1);
    });

    test('deleteComment clears comment and calls onChanged', () async {
      await repository.startManualVisit(
        gardenId: 'garden-villa-hortensia',
        isVerified: true,
      );
      await controller.loadVisit();
      await controller.saveComment('Some comment');

      int callCount = 0;
      controller.onChanged = () => callCount++;

      await controller.deleteComment();

      expect(controller.visit!.publicComment, isEmpty);
      expect(callCount, 1);
    });

    test('updateTimestamps updates times and calls onChanged', () async {
      // Open a completed visit (which has endedAt set)
      await controller.loadVisit(selectedVisitId: 'visit-2026-04-08');
      expect(controller.visit!.endedAt, isNotNull);

      int callCount = 0;
      controller.onChanged = () => callCount++;

      final newStart = DateTime(2026, 4, 8, 10, 0);
      final newEnd = DateTime(2026, 4, 8, 12, 0);

      await controller.updateTimestamps(newStart: newStart, newEnd: newEnd);

      expect(controller.visit!.startedAt, newStart);
      expect(controller.visit!.endedAt, newEnd);
      expect(callCount, 1);
    });
  });
}
