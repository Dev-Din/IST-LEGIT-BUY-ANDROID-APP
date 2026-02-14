import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

import '../core/utils/debug_logger.dart';

class PaymentService {
  final FirebaseFunctions _functions;

  PaymentService() : _functions = FirebaseFunctions.instance {
    // Connect to local emulator in debug mode
    if (kDebugMode) {
      final emulatorHost = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';
      _functions.useFunctionsEmulator(emulatorHost, 5001);
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
      DebugLogger.log(
        location: 'payment_service.dart:initiateMpesaPayment',
        message: 'M-Pesa API / Firebase Functions error',
        data: {
          'error': e.toString(),
          'code': e.code,
          'details': e.details?.toString(),
          'message': e.message,
        },
      );
      throw Exception('Payment error: ${e.message ?? e.code}');
    } catch (e, stackTrace) {
      DebugLogger.log(
        location: 'payment_service.dart:initiateMpesaPayment',
        message: 'Payment initiation error',
        data: {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      throw Exception('Payment initiation error: $e');
    }
  }

  /// Get payment status by checkout request ID
  /// 
  /// Returns a map containing:
  /// - status: "pending" | "completed" | "failed"
  /// - message: String
  /// - mpesa_receipt?: String
  Future<Map<String, dynamic>> getPaymentStatus(String checkoutRequestId) async {
    try {
      String baseUrl;
      if (kDebugMode) {
        final emulatorHost = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';
        // Get project ID from Firebase app; emulator HTTP functions use region in path
        final projectId = Firebase.app().options.projectId;
        const region = 'us-central1';
        baseUrl = 'http://$emulatorHost:5001/$projectId/$region/paymentStatus';
      } else {
        // Production: use Cloud Functions URL
        final projectId = Firebase.app().options.projectId;
        final region = 'us-central1'; // Default region, adjust if different
        baseUrl = 'https://$region-$projectId.cloudfunctions.net/paymentStatus';
      }

      final url = Uri.parse('$baseUrl?checkout_request_id=$checkoutRequestId');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        throw Exception('Payment not found');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to get payment status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      DebugLogger.log(
        location: 'payment_service.dart:getPaymentStatus',
        message: 'Error getting payment status',
        data: {'error': e.toString(), 'checkoutRequestId': checkoutRequestId},
      );
      rethrow;
    }
  }
}
