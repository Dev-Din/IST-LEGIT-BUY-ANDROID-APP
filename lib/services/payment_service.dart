import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class PaymentService {
  final FirebaseFunctions _functions;

  PaymentService() : _functions = FirebaseFunctions.instance {
    // Connect to local emulator in debug mode
    if (kDebugMode) {
      _functions.useFunctionsEmulator('localhost', 5001);
    }
  }

  /// Initiate M-Pesa STK Push payment
  /// 
  /// Returns a map containing:
  /// - success: bool
  /// - checkoutRequestID: String
  /// - merchantRequestID: String
  /// - customerMessage: String
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  }) async {
    try {
      final callable = _functions.httpsCallable('initiateMpesaPayment');
      
      final result = await callable.call({
        'phoneNumber': phoneNumber,
        'amount': amount,
        'orderId': orderId,
      });

      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return {
          'success': true,
          'checkoutRequestID': data['checkoutRequestID'],
          'merchantRequestID': data['merchantRequestID'],
          'customerMessage': data['customerMessage'] ?? 'Please complete payment on your phone',
        };
      } else {
        throw Exception(data['error'] ?? 'Payment initiation failed');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Payment error: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Payment initiation error: $e');
    }
  }
}
