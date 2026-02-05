import 'package:flutter/foundation.dart';
import '../services/dress_service.dart';

/// Provider for dress catalog state management
class DressProvider with ChangeNotifier {
  final DressService _dressService = DressService();

  List<DressModel> _dresses = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _selectedCategoryId;
  String? _searchQuery;

  List<DressModel> get dresses => _dresses;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get searchQuery => _searchQuery;

  /// Load initial dresses and categories
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _dresses = [];
    notifyListeners();

    try {
      // Load categories and first page of dresses in parallel
      final results = await Future.wait([
        _dressService.fetchCategories(),
        _dressService.fetchDresses(
          page: 0,
          pageSize: 20,
          categoryId: _selectedCategoryId,
          searchQuery: _searchQuery,
        ),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _dresses = results[1] as List<DressModel>;
      _hasMore = _dresses.length == 20;
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل البيانات: ${e.toString()}';
      _dresses = [];
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more dresses (pagination)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentPage++;
      final newDresses = await _dressService.fetchDresses(
        page: _currentPage,
        pageSize: 20,
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
      );

      _dresses.addAll(newDresses);
      _hasMore = newDresses.length == 20;
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل المزيد: ${e.toString()}';
      _currentPage--; // Revert page increment
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String? categoryId) async {
    if (_selectedCategoryId == categoryId) return;

    _selectedCategoryId = categoryId;
    _currentPage = 0;
    _dresses = [];
    _hasMore = true;
    
    await loadInitialData();
  }

  /// Search dresses
  Future<void> searchDresses(String? query) async {
    if (_searchQuery == query) return;

    _searchQuery = query?.trim().isEmpty == true ? null : query?.trim();
    _currentPage = 0;
    _dresses = [];
    _hasMore = true;
    
    await loadInitialData();
  }

  /// Refresh data
  Future<void> refresh() async {
    await _dressService.clearCache();
    _currentPage = 0;
    _dresses = [];
    _hasMore = true;
    await loadInitialData();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _dressService.clearCache();
  }
}
