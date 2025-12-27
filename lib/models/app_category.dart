class AppCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final List<String> appIds; // IDs of apps in this category

  AppCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.appIds = const [],
  });

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? 'folder',
      appIds: List<String>.from(map['appIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'appIds': appIds,
    };
  }

  AppCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    List<String>? appIds,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      appIds: appIds ?? this.appIds,
    );
  }
}

// Predefined categories
final List<AppCategory> predefinedCategories = [
  AppCategory(
    id: 'productivity',
    name: 'Produktivitas',
    description: 'Aplikasi untuk meningkatkan produktivitas kerja',
    iconName: 'work',
  ),
  AppCategory(
    id: 'browsers',
    name: 'Browser',
    description: 'Aplikasi browser untuk menjelajah internet',
    iconName: 'web',
  ),
  AppCategory(
    id: 'utilities',
    name: 'Utilitas',
    description: 'Aplikasi utilitas dan alat bantu sistem',
    iconName: 'build',
  ),
  AppCategory(
    id: 'media',
    name: 'Media',
    description: 'Aplikasi untuk multimedia dan hiburan',
    iconName: 'play_circle',
  ),
  AppCategory(
    id: 'development',
    name: 'Pengembangan',
    description: 'Aplikasi untuk pengembangan software',
    iconName: 'code',
  ),
  AppCategory(
    id: 'security',
    name: 'Keamanan',
    description: 'Aplikasi untuk keamanan dan perlindungan',
    iconName: 'security',
  ),
  AppCategory(
    id: 'other',
    name: 'Lainnya',
    description: 'Aplikasi lainnya',
    iconName: 'apps',
  ),
];
