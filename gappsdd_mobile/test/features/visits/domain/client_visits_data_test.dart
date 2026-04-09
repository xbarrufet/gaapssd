import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/features/visits/domain/client_visits_data.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  VisitSummary _visitSummary({String id = 'v1'}) => VisitSummary(
        id: id,
        gardenId: 'g1',
        durationMinutes: 60,
        dayLabel: '08',
        monthLabel: 'Apr',
        title: 'Lawn care',
        description: 'Mowed the lawn',
        status: VisitVerificationStatus.verified,
      );

  LocalVisitPhoto _localPhoto({String id = 'p1'}) => LocalVisitPhoto(
        id: id,
        localPath: '/tmp/photo.jpg',
        thumbnailPath: '/tmp/thumb.jpg',
        label: 'Before',
      );

  AssignedGardenVisitStatus _gardenStatus({String id = 'ag1'}) =>
      AssignedGardenVisitStatus(
        id: id,
        gardenName: 'Rose Garden',
        address: '123 Main St',
        urgency: GardenVisitUrgency.upcoming,
        lastVisitLabel: '2 days ago',
        lastVisitAge: '2d',
        evidence: VisitEvidence.verified,
        primaryActionLabel: 'Start visit',
      );

  VisitReport _visitReport({String visitId = 'vr1'}) => VisitReport(
        visitId: visitId,
        locationName: 'Rose Garden',
        locationContext: 'Front yard',
        headerImageUrl: 'https://example.com/img.jpg',
        status: VisitVerificationStatus.verified,
        visitDate: '2026-04-08',
        duration: '1h',
        entryTime: '09:00',
        exitTime: '10:00',
        gardenerName: 'Alice',
        gardenerRole: 'Head gardener',
        gardenerAvatarUrl: 'https://example.com/avatar.jpg',
        workPerformed: 'Mowed lawn',
        publicComment: 'Looks great',
        photos: const [],
      );

  VisitPhoto _visitPhoto({
    String label = 'Before',
    String imageUrl = 'https://example.com/photo.jpg',
  }) =>
      VisitPhoto(label: label, imageUrl: imageUrl);

  ClientProfile _clientProfile({
    String clientName = 'Bob',
    String gardenerName = 'Alice',
  }) =>
      ClientProfile(
        appTitle: 'GAPP',
        clientName: clientName,
        gardenerName: gardenerName,
        gardenerRole: 'Head gardener',
        gardenerAvatarUrl: 'https://example.com/avatar.jpg',
        heroImageUrl: 'https://example.com/hero.jpg',
      );

  // ---------------------------------------------------------------------------
  // Equality tests
  // ---------------------------------------------------------------------------

  group('VisitSummary equality', () {
    test('same id are equal', () {
      expect(_visitSummary(id: 'x'), equals(_visitSummary(id: 'x')));
    });

    test('different ids are not equal', () {
      expect(_visitSummary(id: 'a'), isNot(equals(_visitSummary(id: 'b'))));
    });
  });

  group('LocalVisitPhoto equality', () {
    test('same id are equal', () {
      expect(_localPhoto(id: 'p1'), equals(_localPhoto(id: 'p1')));
    });
  });

  group('AssignedGardenVisitStatus equality', () {
    test('same id are equal', () {
      expect(_gardenStatus(id: 'ag1'), equals(_gardenStatus(id: 'ag1')));
    });
  });

  group('VisitReport equality', () {
    test('same visitId are equal', () {
      expect(
          _visitReport(visitId: 'vr1'), equals(_visitReport(visitId: 'vr1')));
    });
  });

  group('VisitPhoto equality', () {
    test('same label + imageUrl are equal', () {
      expect(
        _visitPhoto(label: 'A', imageUrl: 'url1'),
        equals(_visitPhoto(label: 'A', imageUrl: 'url1')),
      );
    });
  });

  group('ClientProfile equality', () {
    test('same clientName + gardenerName are equal', () {
      expect(
        _clientProfile(clientName: 'Bob', gardenerName: 'Alice'),
        equals(_clientProfile(clientName: 'Bob', gardenerName: 'Alice')),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Enum tests
  // ---------------------------------------------------------------------------

  group('Enums', () {
    test('VisitVerificationStatus has verified and manualEntry', () {
      expect(VisitVerificationStatus.values,
          containsAll([VisitVerificationStatus.verified, VisitVerificationStatus.manualEntry]));
    });

    test('VisitInitiationMethod has qrScan and manual', () {
      expect(VisitInitiationMethod.values,
          containsAll([VisitInitiationMethod.qrScan, VisitInitiationMethod.manual]));
    });

    test('GardenVisitUrgency has urgent, upcoming, maintained', () {
      expect(
          GardenVisitUrgency.values,
          containsAll([
            GardenVisitUrgency.urgent,
            GardenVisitUrgency.upcoming,
            GardenVisitUrgency.maintained,
          ]));
    });

    test('VisitEvidence has verified and manual', () {
      expect(VisitEvidence.values,
          containsAll([VisitEvidence.verified, VisitEvidence.manual]));
    });
  });

  // ---------------------------------------------------------------------------
  // ActiveVisitSnapshot tests
  // ---------------------------------------------------------------------------

  group('ActiveVisitSnapshot', () {
    final garden = _gardenStatus();
    final start = DateTime(2026, 4, 8, 9, 0);

    test('isActive returns true when endedAt is null', () {
      final snap = ActiveVisitSnapshot(
        garden: garden,
        startedAt: start,
        endedAt: null,
        isVerified: true,
        initiationMethod: VisitInitiationMethod.qrScan,
      );
      expect(snap.isActive, isTrue);
    });

    test('isActive returns false when endedAt is set', () {
      final snap = ActiveVisitSnapshot(
        garden: garden,
        startedAt: start,
        endedAt: start.add(const Duration(hours: 1)),
        isVerified: true,
        initiationMethod: VisitInitiationMethod.qrScan,
      );
      expect(snap.isActive, isFalse);
    });

    test('duration returns null when endedAt is null', () {
      final snap = ActiveVisitSnapshot(
        garden: garden,
        startedAt: start,
        endedAt: null,
        isVerified: true,
        initiationMethod: VisitInitiationMethod.manual,
      );
      expect(snap.duration, isNull);
    });

    test('duration calculates correctly when endedAt is set', () {
      final end = start.add(const Duration(hours: 1, minutes: 30));
      final snap = ActiveVisitSnapshot(
        garden: garden,
        startedAt: start,
        endedAt: end,
        isVerified: true,
        initiationMethod: VisitInitiationMethod.manual,
      );
      expect(snap.duration, equals(const Duration(hours: 1, minutes: 30)));
    });
  });
}
