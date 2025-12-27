import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_category.dart';

class CategoryService {
  // Get portable data directory (app-relative, portable to USB/flashdisk)
  static Future<Directory> _getPortableDataDirectory() async {
    try {
      // PRIORITY 1: Portable folder next to executable: <exeDir>/data
      final exeDir = File(Platform.resolvedExecutable).parent;
      final dataDir = Directory('${exeDir.path}${Platform.pathSeparator}data');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      return dataDir;
    } catch (e) {
      print('Portable directory not available: $e, falling back to user documents');
    }

    // PRIORITY 2: Fallback to user documents
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/SekomCleaner');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } catch (e) {
      print('User documents not available: $e');
      return Directory.current;
    }
  }

  // Save categories to file
  static Future<void> saveCategories(List<AppCategory> categories) async {
    try {
      final appDir = await _getPortableDataDirectory();
      final file = File('${appDir.path}/app_categories.json');
      
      String jsonString = jsonEncode(categories.map((cat) => cat.toMap()).toList());
      await file.writeAsString(jsonString);
      
      print('✓ Saved ${categories.length} categories to: ${file.path}');
    } catch (e) {
      print('Error saving categories: $e');
      throw Exception('Failed to save categories: $e');
    }
  }

  // Load categories from file
  static Future<List<AppCategory>> loadCategories() async {
    try {
      final appDir = await _getPortableDataDirectory();
      final file = File('${appDir.path}/app_categories.json');
      
      if (await file.exists()) {
        String jsonString = await file.readAsString();
        
        if (jsonString.isNotEmpty) {
          List<dynamic> jsonList = jsonDecode(jsonString);
          List<AppCategory> result = jsonList.map((json) => AppCategory.fromMap(json)).toList();
          print('✓ Loaded ${result.length} categories from: ${file.path}');
          return result;
        }
      } else {
        print('⚠ Categories file not found at: ${file.path}, creating defaults');
        // Initialize with default categories
        await saveCategories(predefinedCategories);
        return predefinedCategories;
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
    
    // Return default categories if loading fails
    return predefinedCategories;
  }

  // Add app to category
  static Future<void> addAppToCategory(String appId, String categoryId) async {
    try {
      List<AppCategory> categories = await loadCategories();
      
      // Find the category
      int categoryIndex = categories.indexWhere((cat) => cat.id == categoryId);
      if (categoryIndex != -1) {
        // Add app to category if not already there
        if (!categories[categoryIndex].appIds.contains(appId)) {
          List<String> updatedAppIds = List.from(categories[categoryIndex].appIds)..add(appId);
          categories[categoryIndex] = categories[categoryIndex].copyWith(appIds: updatedAppIds);
          
          // Remove app from other categories
          for (int i = 0; i < categories.length; i++) {
            if (i != categoryIndex && categories[i].appIds.contains(appId)) {
              List<String> filteredAppIds = categories[i].appIds.where((id) => id != appId).toList();
              categories[i] = categories[i].copyWith(appIds: filteredAppIds);
            }
          }
          
          await saveCategories(categories);
        }
      }
    } catch (e) {
      print('Error adding app to category: $e');
      throw Exception('Failed to add app to category: $e');
    }
  }

  // Remove app from category
  static Future<void> removeAppFromCategory(String appId, String categoryId) async {
    try {
      List<AppCategory> categories = await loadCategories();
      
      // Find the category
      int categoryIndex = categories.indexWhere((cat) => cat.id == categoryId);
      if (categoryIndex != -1) {
        // Remove app from category
        List<String> updatedAppIds = categories[categoryIndex].appIds.where((id) => id != appId).toList();
        categories[categoryIndex] = categories[categoryIndex].copyWith(appIds: updatedAppIds);
        
        await saveCategories(categories);
      }
    } catch (e) {
      print('Error removing app from category: $e');
      throw Exception('Failed to remove app from category: $e');
    }
  }

  // Get category for app
  static Future<String> getCategoryForApp(String appId) async {
    try {
      List<AppCategory> categories = await loadCategories();
      
      // Find category containing the app
      for (AppCategory category in categories) {
        if (category.appIds.contains(appId)) {
          return category.id;
        }
      }
      
      // Return "other" category if not found
      return 'other';
    } catch (e) {
      print('Error getting category for app: $e');
      return 'other';
    }
  }

  // Add new category
  static Future<void> addCategory(AppCategory category) async {
    try {
      List<AppCategory> categories = await loadCategories();
      
      // Check if category with same ID already exists
      if (!categories.any((cat) => cat.id == category.id)) {
        categories.add(category);
        await saveCategories(categories);
      }
    } catch (e) {
      print('Error adding category: $e');
      throw Exception('Failed to add category: $e');
    }
  }

  // Update category
  static Future<void> updateCategory(AppCategory category) async {
    try {
      List<AppCategory> categories = await loadCategories();
      
      // Find and update the category
      int categoryIndex = categories.indexWhere((cat) => cat.id == category.id);
      if (categoryIndex != -1) {
        categories[categoryIndex] = category;
        await saveCategories(categories);
      }
    } catch (e) {
      print('Error updating category: $e');
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  static Future<void> deleteCategory(String categoryId) async {
    try {
      List<AppCategory> categories = await loadCategories();
      
      // Find the category
      int categoryIndex = categories.indexWhere((cat) => cat.id == categoryId);
      if (categoryIndex != -1) {
        // Move apps to "other" category
        List<String> appsToMove = List.from(categories[categoryIndex].appIds);
        if (appsToMove.isNotEmpty) {
          int otherIndex = categories.indexWhere((cat) => cat.id == 'other');
          if (otherIndex != -1) {
            List<String> updatedOtherAppIds = List.from(categories[otherIndex].appIds)..addAll(appsToMove);
            categories[otherIndex] = categories[otherIndex].copyWith(appIds: updatedOtherAppIds);
          }
        }
        
        // Remove the category
        categories.removeAt(categoryIndex);
        await saveCategories(categories);
      }
    } catch (e) {
      print('Error deleting category: $e');
      throw Exception('Failed to delete category: $e');
    }
  }
}
