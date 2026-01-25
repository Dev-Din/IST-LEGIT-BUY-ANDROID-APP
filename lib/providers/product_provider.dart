import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _priceFilter; // 'low', 'high', null

  List<ProductModel> get products => _filteredProducts.isEmpty && _searchQuery.isEmpty && _selectedCategory == null && _priceFilter == null
      ? _products
      : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<String> get categories {
    Set<String> cats = _products.map((p) => p.category).toSet();
    return cats.toList()..sort();
  }

  String? get selectedCategory => _selectedCategory;
  String? get priceFilter => _priceFilter;

  ProductProvider() {
    // Load products asynchronously - don't block constructor
    // Errors will be caught in loadProducts()
    loadProducts().catchError((error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add timeout to prevent hanging
      _products = await _firestoreService.getProductsOnce()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              return <ProductModel>[];
            },
          );
      
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _products = []; // Ensure products list is initialized
      notifyListeners();
    }
  }

  Stream<List<ProductModel>> getProductsStream() {
    return _firestoreService.getProducts();
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void filterByPrice(String? filter) {
    _priceFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _priceFilter = null;
    _filteredProducts = [];
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery) ||
              product.description.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      _filteredProducts = _filteredProducts
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Apply price filter
    if (_priceFilter != null) {
      _filteredProducts.sort((a, b) {
        if (_priceFilter == 'low') {
          return a.price.compareTo(b.price);
        } else {
          return b.price.compareTo(a.price);
        }
      });
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.addProduct(product);
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(String productId, ProductModel product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.updateProduct(productId, product);
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.deleteProduct(productId);
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
