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
}

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
  });

  final String id;
  final String gardenName;
  final String address;
  final GardenVisitUrgency urgency;
  final String lastVisitLabel;
  final String lastVisitAge;
  final VisitEvidence evidence;
  final String primaryActionLabel;
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
    required this.garden,
    required this.startedAt,
    required this.endedAt,
    required this.isVerified,
    required this.initiationMethod,
    this.photos = const [],
    this.publicComment = '',
  });

  final AssignedGardenVisitStatus garden;
  final DateTime startedAt;
  final DateTime? endedAt; // NULL if active, set if closed
  final bool isVerified;
  final String initiationMethod; // QR_SCAN | MANUAL
  final List<LocalVisitPhoto> photos;
  final String publicComment;

  // Computed duration (only meaningful if endedAt is set)
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  bool get isActive => endedAt == null;
}

class ClientVisitsData {
  const ClientVisitsData({required this.profile, required this.visits});

  final ClientProfile profile;
  final List<VisitSummary> visits;
}