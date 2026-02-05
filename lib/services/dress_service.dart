import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import 'error_logging_service.dart';

/// Dress model
class DressModel {
  final String id;
  final String? name;
  final List<String> images;
  final String? categoryId;
  final DateTime? createdAt;

  DressModel({
    required this.id,
    this.name,
    required this.images,
    this.categoryId,
    this.createdAt,
  });

  factory DressModel.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List?;
    return DressModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      images: imagesList != null ? List<String>.from(imagesList) : [],
      categoryId: json['category_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'images': images,
      'category_id': categoryId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Get image URL for display
  String getImageUrl(String path, SupabaseClient client) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return client.storage.from(AppConstants.dressStorageBucket).getPublicUrl(path);
  }

  /// Get the cover/first image URL
  String getCoverImageUrl(SupabaseClient client) {
    if (images.isEmpty) {
      return AppConstants.placeholderImageUrl;
    }
    return getImageUrl(images.first, client);
  }
}

/// Category model
class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

/// Service for managing dress operations
class DressService {
  static final DressService _instance = DressService._internal();
  factory DressService() => _instance;
  DressService._internal();

  final _errorLogger = ErrorLoggingService();
  Box<Map>? _cacheBox;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _cacheBox = await Hive.openBox<Map>('dresses_cache');
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'DressService.initialize');
    }
  }

  /// Fetch dresses with pagination and optional filtering
  Future<List<DressModel>> fetchDresses({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      final cacheKey = 'dresses_page_${page}_cat_${categoryId ?? 'all'}_q_${searchQuery ?? 'all'}';
      final cachedData = _cacheBox?.get(cacheKey);

      if (cachedData != null) {
        final lastUpdated = DateTime.parse(
          cachedData['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
        );

        if (DateTime.now().difference(lastUpdated) < AppConstants.dressCacheDuration) {
          final dresses = (cachedData['dresses'] as List)
              .map((d) => DressModel.fromJson(Map<String, dynamic>.from(d as Map)))
              .toList();
          return dresses;
        }
      }

      // Build query
      var query = Supabase.instance.client
          .from('dresses')
          .select('id,name,images,category_id,created_at');

      // Apply filters
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('name', '%${searchQuery.trim()}%');
      }

      // Apply pagination and ordering
      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final dresses = (data as List)
          .map((json) => DressModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Cache the results
      await _cacheBox?.put(cacheKey, {
        'dresses': dresses.map((d) => d.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      return dresses;
    } catch (e, stack) {
      await _errorLogger.logError(
        e,
        stack,
        context: 'DressService.fetchDresses',
        extras: {
          'page': page,
          'categoryId': categoryId,
          'searchQuery': searchQuery,
        },
      );
      rethrow;
    }
  }

  /// Fetch all categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      const cacheKey = 'categories';
      final cachedData = _cacheBox?.get(cacheKey);

      if (cachedData != null) {
        final lastUpdated = DateTime.parse(
          cachedData['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
        );

        if (DateTime.now().difference(lastUpdated) < AppConstants.dressCacheDuration) {
          final categories = (cachedData['categories'] as List)
              .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList();
          return categories;
        }
      }

      final data = await Supabase.instance.client
          .from('categories')
          .select('id,name')
          .order('name', ascending: true);

      final categories = (data as List)
          .map((json) => CategoryModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Cache the results
      await _cacheBox?.put(cacheKey, {
        'categories': categories.map((c) => c.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      return categories;
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'DressService.fetchCategories');
      rethrow;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cacheBox?.clear();
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'DressService.clearCache');
    }
  }
}
