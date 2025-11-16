import 'package:satsang_admin/core/utils/json_utils.dart';

/// Category model matching backend API structure
class CategoryItem {
  CategoryItem({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    this.descriptionEn,
    this.descriptionHi,
    required this.sortOrder,
    required this.isActive,
    this.parentId,
    this.categoryMetadata,
    this.createdAt,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json.getInt('id')!,
      nameEn: json.getString('nameEn') ?? '',
      nameHi: json.getString('nameHi') ?? '',
      descriptionEn: json.getString('descriptionEn'),
      descriptionHi: json.getString('descriptionHi'),
      sortOrder: json.getInt('sortOrder') ?? 0,
      isActive: json.getBool('isActive', defaultValue: true),
      parentId: json.getInt('parentId'),
      categoryMetadata: json.getString('categoryMetadata'),
      createdAt: json.getDateTime('createdAt'),
    );
  }

  final int id;
  final String nameEn;
  final String nameHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final int sortOrder;
  final bool isActive;
  final int? parentId;
  final String? categoryMetadata;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameHi': nameHi,
      'descriptionEn': descriptionEn,
      'descriptionHi': descriptionHi,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'parentId': parentId,
      'categoryMetadata': categoryMetadata,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  CategoryItem copyWith({
    int? id,
    String? nameEn,
    String? nameHi,
    String? descriptionEn,
    String? descriptionHi,
    int? sortOrder,
    bool? isActive,
    int? parentId,
    String? categoryMetadata,
    DateTime? createdAt,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      parentId: parentId ?? this.parentId,
      categoryMetadata: categoryMetadata ?? this.categoryMetadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
