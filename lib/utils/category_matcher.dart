// utils/category_matcher.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import '../models/category_summary.dart';

class CategoryMatcher {
  List<Category> categories = [];

  // Default categories
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'groceries',
        name: 'Groceries',
        color: Colors.green,
        icon: Icons.shopping_cart,
        tags: ['grocery', 'supermarket', 'food', 'market'],
      ),
      Category(
        id: 'dining',
        name: 'Dining Out',
        color: Colors.orange,
        icon: Icons.restaurant,
        tags: ['restaurant', 'cafe', 'takeout', 'coffee', 'dining'],
      ),
      Category(
        id: 'transport',
        name: 'Transportation',
        color: Colors.blue,
        icon: Icons.directions_car,
        tags: ['gas', 'fuel', 'uber', 'taxi', 'transit', 'transport'],
      ),
      Category(
        id: 'utilities',
        name: 'Utilities',
        color: Colors.red,
        icon: Icons.lightbulb,
        tags: ['electric', 'water', 'utility', 'gas', 'phone', 'internet'],
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        color: Colors.purple,
        icon: Icons.movie,
        tags: ['movie', 'netflix', 'spotify', 'book', 'entertainment', 'game'],
      ),
      Category(
        id: 'health',
        name: 'Health',
        color: Colors.pink,
        icon: Icons.medical_services,
        tags: ['doctor', 'medication', 'pharmacy', 'health', 'medical'],
      ),
      Category(
        id: 'income',
        name: 'Income',
        color: Colors.green.shade800,
        icon: Icons.monetization_on,
        tags: ['salary', 'deposit', 'paycheck', 'income', 'payment received'],
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        color: Colors.teal,
        icon: Icons.shopping_bag,
        tags: ['amazon', 'walmart', 'target', 'shopping', 'store'],
      ),
    ];
  }

  // Get the path to the categories XML file
  Future<String> getCategoriesFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/categories.xml';
  }

  // Initialize with default categories if no file exists
  Future<void> initializeCategories() async {
    final filePath = await getCategoriesFilePath();
    final file = File(filePath);

    if (!await file.exists()) {
      categories = getDefaultCategories();
      await saveCategories();
    } else {
      await loadCategoriesFromFile();
    }
  }

  // Load categories from the XML file
  Future<void> loadCategoriesFromFile() async {
    try {
      final filePath = await getCategoriesFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Categories file not found');
      }

      final xmlString = await file.readAsString();
      loadCategoriesFromXml(xmlString);
    } catch (e) {
      // If loading fails, use default categories
      categories = getDefaultCategories();
      await saveCategories();
    }
  }

  // Parse XML string and load categories
  void loadCategoriesFromXml(String xmlString) {
    categories = [];
    try {
      final document = XmlDocument.parse(xmlString);
      final categoryElements = document.findAllElements('category');

      for (var element in categoryElements) {
        final categoryMap = <String, dynamic>{};

        for (var attribute in element.attributes) {
          categoryMap[attribute.name.local] = attribute.value;
        }

        // Tags are stored as child elements
        final tags =
            element.findElements('tag').map((tag) => tag.innerText).toList();
        categoryMap['tags'] = tags.join(',');

        categories.add(Category.fromXml(categoryMap));
      }
    } catch (e) {
      // If parsing fails, use default categories
      categories = getDefaultCategories();
    }
  }

  // Save categories to the XML file
  Future<void> saveCategories() async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element(
        'categories',
        nest: () {
          for (var category in categories) {
            builder.element(
              'category',
              nest: () {
                // Add attributes
                builder.attribute('id', category.id);
                builder.attribute('name', category.name);
                builder.attribute(
                  'color',
                  category.color.value.toRadixString(16),
                );
                builder.attribute('icon', category.icon.codePoint.toString());

                // Add tags as child elements
                for (var tag in category.tags) {
                  builder.element('tag', nest: tag);
                }
              },
            );
          }
        },
      );

      final document = builder.buildDocument();
      final filePath = await getCategoriesFilePath();
      final file = File(filePath);
      await file.writeAsString(document.toXmlString(pretty: true));
    } catch (e) {
      throw Exception('Failed to save categories: $e');
    }
  }

  // Add a new category
  Future<void> addCategory(Category category) async {
    // Check if category ID already exists
    if (categories.any((c) => c.id == category.id)) {
      throw Exception('Category ID already exists');
    }

    categories.add(category);
    await saveCategories();
  }

  // Update an existing category
  Future<void> updateCategory(Category updatedCategory) async {
    final index = categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index == -1) {
      throw Exception('Category not found');
    }

    categories[index] = updatedCategory;
    await saveCategories();
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    categories.removeWhere((c) => c.id == categoryId);
    await saveCategories();
  }

  // Match a transaction description to a category
  String matchCategory(String description) {
    final lowerDescription = description.toLowerCase();

    // Check each category's tags
    for (var category in categories) {
      for (var tag in category.tags) {
        if (lowerDescription.contains(tag.toLowerCase())) {
          return category.id;
        }
      }
    }

    // Default value if no match is found
    final parsedAmount = double.tryParse(
      description.replaceAll(RegExp(r'[^0-9.-]'), ''),
    );
    if (parsedAmount != null && parsedAmount > 0) {
      return 'income'; // Default income category
    }

    return 'Uncategorized'; // Default expense category
  }

  // Get a category by ID
  Category? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
