enum SyncStatus { pending, synced, failed }

class Inspection {
  final String id;
  final String placeName;
  final String category;
  final String? observation;
  final String photoPath;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Inspection({
    required this.id,
    required this.placeName,
    required this.category,
    this.observation,
    required this.photoPath,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  Inspection copyWith({
    String? placeName,
    String? category,
    String? observation,
    String? photoPath,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return Inspection(
      id: id,
      placeName: placeName ?? this.placeName,
      category: category ?? this.category,
      observation: observation ?? this.observation,
      photoPath: photoPath ?? this.photoPath,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'placeName': placeName,
        'category': category,
        'observation': observation,
        'photoPath': photoPath,
        'syncStatus': syncStatus.index,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Inspection.fromMap(Map<String, dynamic> map) => Inspection(
        id: map['id'] as String,
        placeName: map['placeName'] as String,
        category: map['category'] as String,
        observation: map['observation'] as String?,
        photoPath: map['photoPath'] as String,
        syncStatus: SyncStatus.values[map['syncStatus'] as int],
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  // Payload sent to backend mock (no local file paths)
  Map<String, dynamic> toJson() => {
        'id': id,
        'placeName': placeName,
        'category': category,
        'observation': observation,
        'syncStatus': syncStatus.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
