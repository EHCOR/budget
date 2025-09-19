// models/category.dart
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final List<String> keywords;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.keywords,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'keywords': keywords,
    };
  }

  // Create from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Uncategorized',
      color: Color(json['color'] ?? Colors.grey.toARGB32()),
      icon: IconData(
        json['icon'] ?? Icons.category.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  // Default categories
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'groceries',
        name: 'Groceries',
        color: Colors.green,
        icon: Icons.shopping_cart,
        keywords: ['grocery', 'supermarket', 'food', 'market', 'store'],
      ),
      Category(
        id: 'dining',
        name: 'Dining Out',
        color: Colors.orange,
        icon: Icons.restaurant,
        keywords: ['restaurant', 'cafe', 'coffee', 'dining', 'food', 'eat'],
      ),
      Category(
        id: 'transport',
        name: 'Transportation',
        color: Colors.blue,
        icon: Icons.directions_car,
        keywords: ['gas', 'fuel', 'uber', 'taxi', 'bus', 'train', 'transport'],
      ),
      Category(
        id: 'utilities',
        name: 'Utilities',
        color: Colors.red,
        icon: Icons.lightbulb,
        keywords: ['electric', 'water', 'utility', 'phone', 'internet', 'bill'],
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        color: Colors.purple,
        icon: Icons.movie,
        keywords: ['movie', 'netflix', 'spotify', 'game', 'entertainment', 'show'],
      ),
      Category(
        id: 'health',
        name: 'Healthcare',
        color: Colors.pink,
        icon: Icons.medical_services,
        keywords: ['doctor', 'medicine', 'pharmacy', 'health', 'medical', 'hospital'],
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        color: Colors.teal,
        icon: Icons.shopping_bag,
        keywords: ['amazon', 'walmart', 'target', 'shopping', 'buy', 'purchase'],
      ),
      Category(
        id: 'income',
        name: 'Income',
        color: Colors.green.shade800,
        icon: Icons.attach_money,
        keywords: ['salary', 'deposit', 'paycheck', 'income', 'payment', 'transfer'],
      ),
      Category(
        id: 'uncategorized',
        name: 'Uncategorized',
        color: Colors.grey,
        icon: Icons.help_outline,
        keywords: [],
      ),
    ];
  }

  // Copy with modifications
  Category copyWith({
    String? name,
    Color? color,
    IconData? icon,
    List<String>? keywords,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      keywords: keywords ?? this.keywords,
    );
  }
}