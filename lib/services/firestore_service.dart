import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products
  Stream<List<ProductModel>> getProducts() {
    return _firestore
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromJson(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<List<ProductModel>> getProductsOnce() async {
    QuerySnapshot snapshot = await _firestore
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<ProductModel?> getProduct(String productId) async {
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();

    if (doc.exists) {
      return ProductModel.fromJson(
          doc.data() as Map<String, dynamic>, doc.id);
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
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromJson(
                doc.data() as Map<String, dynamic>, doc.id))
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
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'role': role});
  }
}
