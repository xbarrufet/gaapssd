class ClientProfile {
  const ClientProfile({
    required this.appTitle,
    required this.clientName,
    required this.gardenerName,
    required this.gardenerRole,
    required this.gardenerAvatarUrl,
    required this.heroImageUrl,
  });

  final String appTitle;
  final String clientName;
  final String gardenerName;
  final String gardenerRole;
  final String gardenerAvatarUrl;
  final String heroImageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientProfile &&
          runtimeType == other.runtimeType &&
          clientName == other.clientName &&
          gardenerName == other.gardenerName;

  @override
  int get hashCode => Object.hash(clientName, gardenerName);
}

enum VisitVerificationStatus { verified, manualEntry }

// Local photo attached to an active or closed visit
class LocalVisitPhoto {
  const LocalVisitPhoto({
    required this.id,
    required this.localPath,
    required this.thumbnailPath,
    required this.label,
    this.createdAt,
  });

  final String id;
  final String localPath;
  final String thumbnailPath;
  final String label;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocalVisitPhoto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VisitSummary {
  const VisitSummary({
    required this.id,
    required this.gardenId,
    required this.durationMinutes,
    required this.dayLabel,
    required this.monthLabel,
    required this.title,
    required this.description,
    required this.status,
    this.photoCount = 0,
  });

  final String id;
  final String gardenId;
  final int durationMinutes;
  final String dayLabel;
  final String monthLabel;
  final String title;
  final String description;
  final VisitVerificationStatus status;
  final int photoCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VisitSummary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VisitPhoto {
  const VisitPhoto({
    required this.label,
    required this.imageUrl,
    this.featured = false,
  });

  final String label;
  final String imageUrl;
  final bool featured;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitPhoto &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(label, imageUrl);
}

class VisitReport {
  const VisitReport({
    required this.visitId,
    required this.locationName,
    required this.locationContext,
    required this.headerImageUrl,
    required this.status,
    required this.visitDate,
    required this.duration,
    required this.entryTime,
    required this.exitTime,
    required this.gardenerName,
    required this.gardenerRole,
    required this.gardenerAvatarUrl,
    required this.workPerformed,
    required this.publicComment,
    required this.photos,
  });

  final String visitId;
  final String locationName;
  final String locationContext;
  final String headerImageUrl;
  final VisitVerificationStatus status;
  final String visitDate;
  final String duration;
  final String entryTime;
  final String exitTime;
  final String gardenerName;
  final String gardenerRole;
  final String gardenerAvatarUrl;
  final String workPerformed;
  final String publicComment;
  final List<VisitPhoto> photos;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VisitReport && runtimeType == other.runtimeType && visitId == other.visitId;

  @override
  int get hashCode => visitId.hashCode;
}

enum VisitInitiationMethod { qrScan, manual }

enum GardenVisitUrgency { urgent, upcoming, maintained }

enum VisitEvidence { verified, manual }

class AssignedGardenVisitStatus {
  const AssignedGardenVisitStatus({
    required this.id,
    required this.gardenName,
    required this.address,
    required this.urgency,
    required this.lastVisitLabel,
    required this.lastVisitAge,
    required this.evidence,
    required this.primaryActionLabel,
    this.lastVisitDate,
  });

  final String id;
  final String gardenName;
  final String address;
  final GardenVisitUrgency urgency;
  final String lastVisitLabel;
  final String lastVisitAge;
  final DateTime? lastVisitDate;
  final VisitEvidence evidence;
  final String primaryActionLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignedGardenVisitStatus && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ManualStartCandidate {
  const ManualStartCandidate({
    required this.garden,
    required this.distanceMeters,
  });

  final AssignedGardenVisitStatus garden;
  final double distanceMeters;
}

class ActiveVisitSnapshot {
  const ActiveVisitSnapshot({
    this.id,
    required this.garden,
    required this.startedAt,
    required this.endedAt,
    required this.isVerified,
    required this.initiationMethod,
    this.photos = const [],
    this.publicComment = '',
  });

  /// Supabase visit row ID — null when using the SQLite or Fake repository.
  final String? id;
  final AssignedGardenVisitStatus garden;
  final DateTime startedAt;
  final DateTime? endedAt; // NULL if active, set if closed
  final bool isVerified;
  final VisitInitiationMethod initiationMethod;
  final List<LocalVisitPhoto> photos;
  final String publicComment;

  // Computed duration (only meaningful if endedAt is set)
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  bool get isActive => endedAt == null;
}

/// Info shown in the "Visita en Curso" banner on the client visits screen.
class ActiveClientVisitInfo {
  const ActiveClientVisitInfo({
    required this.visitId,
    required this.gardenerName,
    required this.startedAt,
  });

  final String visitId;
  final String gardenerName;
  final DateTime startedAt;
}

class ClientVisitsData {
  const ClientVisitsData({
    required this.profile,
    required this.visits,
    this.activeVisit,
  });

  final ClientProfile profile;
  final List<VisitSummary> visits;
  final ActiveClientVisitInfo? activeVisit;
}

/// A single GPS reading recorded during an active visit for heatmap generation.
class VisitLocationPoint {
  const VisitLocationPoint({
    required this.visitId,
    required this.lat,
    required this.lng,
    this.accuracy,
    required this.recordedAt,
  });

  final String visitId;
  final double lat;
  final double lng;
  final double? accuracy; // metres
  final DateTime recordedAt;
}