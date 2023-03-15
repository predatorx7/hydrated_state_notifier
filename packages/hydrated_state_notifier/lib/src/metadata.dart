class StorageMetadata {
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration? validity;
  final int version;

  const StorageMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.validity,
    required this.version,
  });

  bool get isValid {
    final validity = this.validity;
    if (validity == null) return true;
    final expiry = updatedAt.add(validity);
    final now = DateTime.now();
    return now.isBefore(expiry);
  }

  StorageMetadata copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? validity,
    int? version,
  }) {
    return StorageMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validity: validity ?? this.validity,
      version: version ?? this.version,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'validity': validity?.inMicroseconds,
      'version': version,
    };
  }

  factory StorageMetadata.fromJson(Map<String?, Object?> json) {
    final validity = _getValue<int>(json, 'validity');
    return StorageMetadata(
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      validity: validity == null ? null : Duration(microseconds: validity),
      version: json['version'] as int,
    );
  }
}

T? _getValue<T>(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  return value as T;
}
