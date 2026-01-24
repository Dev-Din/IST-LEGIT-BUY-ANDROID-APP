import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<OrderModel>> getUserOrdersStream(String userId) {
    return _firestoreService.getUserOrders(userId);
  }

  Stream<List<OrderModel>> getAllOrdersStream() {
    return _firestoreService.getAllOrders();
  }

  Future<void> loadUserOrders(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _orders = await _firestoreService
          .getUserOrders(userId)
          .first
          .timeout(const Duration(seconds: 10));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _orders = await _firestoreService
          .getAllOrders()
          .first
          .timeout(const Duration(seconds: 10));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createOrder(OrderModel order) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String orderId = await _firestoreService.createOrder(order);
      _isLoading = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.updateOrder(orderId, {'status': status});
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePaymentStatus(
    String orderId,
    String paymentStatus,
    String? transactionId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Map<String, dynamic> updates = {'paymentStatus': paymentStatus};
      if (transactionId != null) {
        updates['mpesaTransactionId'] = transactionId;
      }

      await _firestoreService.updateOrder(orderId, updates);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
