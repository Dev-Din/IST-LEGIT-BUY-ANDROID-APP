import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to safely get document data as Map
  Map<String, dynamic> _getDocData(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) return <String, dynamic>{};
    return data as Map<String, dynamic>;
  }

  // Products
  Stream<List<ProductModel>> getProducts() {
    try {
      return _firestore
          .collection(AppConstants.productsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromJson(
                  _getDocData(doc), doc.id))
              .toList())
          .handleError((error) {
            // If index doesn't exist, try without orderBy
            if (error.toString().contains('index')) {
              return _firestore
                  .collection(AppConstants.productsCollection)
                  .snapshots()
                  .map((snapshot) => snapshot.docs
                      .map((doc) => ProductModel.fromJson(
                          _getDocData(doc), doc.id))
                      .toList());
            }
            throw error;
          });
    } catch (e) {
      // Return empty stream on error
      return Stream.value(<ProductModel>[]);
    }
  }

  Future<List<ProductModel>> getProductsOnce() async {
    try {
      // Try with orderBy first (requires index)
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => ProductModel.fromJson(
              _getDocData(doc), doc.id))
          .toList();
    } catch (e) {
      // If index doesn't exist or query fails, try without orderBy
      if (e.toString().contains('index') || 
          e.toString().contains('requires an index') ||
          e.toString().contains('permission') ||
          e.toString().contains('timeout')) {
        try {
          // Fallback: query without orderBy (no index needed)
          QuerySnapshot snapshot = await _firestore
              .collection(AppConstants.productsCollection)
              .get()
              .timeout(const Duration(seconds: 5));
          
          final products = snapshot.docs
              .map((doc) => ProductModel.fromJson(
                  _getDocData(doc), doc.id))
              .toList();
          
          // Sort manually if we have products
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        } catch (fallbackError) {
          // Collection might not exist yet - return empty list
          return [];
        }
      }
      // Any other error - return empty list
      return [];
    }
  }

  Future<ProductModel?> getProduct(String productId) async {
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();

    if (doc.exists) {
      return ProductModel.fromJson(_getDocData(doc), doc.id);
    }
    return null;
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore
        .collection(AppConstants.productsCollection)
        .add(product.toJson());
  }

  Future<void> updateProduct(String productId, ProductModel product) async {
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update(product.toJson());
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }

  // Orders
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromJson(
                _getDocData(doc), doc.id))
            .toList());
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromJson(
                _getDocData(doc), doc.id))
            .toList());
  }

  Future<String> createOrder(OrderModel order) async {
    DocumentReference docRef = await _firestore
        .collection(AppConstants.ordersCollection)
        .add(order.toJson());
    return docRef.id;
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update(updates);
  }

  // Users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(
                _getDocData(doc), doc.id))
            .toList());
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'role': role});
  }
}
