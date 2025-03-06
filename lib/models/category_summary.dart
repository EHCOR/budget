// models/category_summary.dart
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final List<String> tags;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.tags,
  });

  // For XML serialization
  Map<String, dynamic> toXml() {
    return {
      'id': id,
      'name': name,
      'color': color.value.toRadixString(16),
      'icon': icon.codePoint.toString(),
      'tags': tags.join(','),
    };
  }

  // From XML serialization
  factory Category.fromXml(Map<String, dynamic> xml) {
    return Category(
      id: xml['id'] ?? '',
      name: xml['name'] ?? 'Uncategorized',
      color: Color(int.parse(xml['color'] ?? 'FF2196F3', radix: 16)),
      icon: IconData(
        int.parse(xml['icon'] ?? '58136'),
        fontFamily: 'MaterialIcons',
      ),
      tags:
          (xml['tags'] ?? '')
              .split(',')
              .where((tag) => tag.isNotEmpty)
              .toList(),
    );
  }

  // Create a copy with changes
  Category copyWith({
    String? name,
    Color? color,
    IconData? icon,
    List<String>? tags,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
    );
  }
}

class CategorySummary {
  final String categoryId;
  final String category;
  double totalAmount;
  final Color color;
  final IconData icon;
  final bool isIncome;

  CategorySummary({
    required this.categoryId,
    required this.category,
    required this.totalAmount,
    required this.color,
    required this.icon,
    required this.isIncome,
  });
}
