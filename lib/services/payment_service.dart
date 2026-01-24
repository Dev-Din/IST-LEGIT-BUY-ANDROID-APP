import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // Replace with your actual backend API URL
  static const String baseUrl = 'https://your-backend-api.com/api';
  
  // Initiate M-Pesa STK Push
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/stk-push'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Payment initiation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment initiation error: $e');
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mpesa/status/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Status check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Status check error: $e');
    }
  }

  // Verify payment callback
  Future<bool> verifyPaymentCallback({
    required String transactionId,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transactionId': transactionId,
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['verified'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
