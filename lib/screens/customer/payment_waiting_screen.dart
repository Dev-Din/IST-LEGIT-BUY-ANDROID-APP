import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/payment_service.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final String checkoutRequestId;
  final String? customerMessage;
  final String? orderId;

  const PaymentWaitingScreen({
    super.key,
    required this.checkoutRequestId,
    this.customerMessage,
    this.orderId,
  });

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  bool _isLoading = true;
  String? _errorMessage;
  final PaymentService _paymentService = PaymentService();
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _startFirestoreListener();
    _startPolling();
    _startTimeout();
  }

  /// Primary detection: listen to the order document in real time.
  /// Fires within ~1-2 seconds of the backend updating paymentStatus.
  void _startFirestoreListener() {
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      _orderSubscription = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots()
          .listen((snapshot) {
        if (!mounted || !_isLoading) return;
        final data = snapshot.data();
        if (data == null) return;

        final paymentStatus = data['paymentStatus'] as String?;
        final mpesaReceipt = data['mpesaTransactionId'] as String?;

        if (paymentStatus == 'paid') {
          _onPaymentCompleted(mpesaReceipt);
        } else if (paymentStatus == 'failed') {
          _onPaymentFailed(null);
        }
      }, onError: (_) {
        // Listener error — polling fallback will handle it
      });
    } else {
      // No orderId available; do an immediate poll instead
      _checkStatus();
    }
  }

  /// Fallback: poll the paymentStatus HTTP endpoint every 3 seconds
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (!mounted || !_isLoading) return;

    try {
      final statusData = await _paymentService.getPaymentStatus(widget.checkoutRequestId);
      final status = statusData['status'] as String?;

      if (!mounted || !_isLoading) return;

      if (status == 'completed') {
        final mpesaReceipt = statusData['mpesa_receipt'] as String?;
        _onPaymentCompleted(mpesaReceipt);
      } else if (status == 'failed') {
        final message = statusData['message'] as String?;
        _onPaymentFailed(message);
      }
    } catch (e) {
      if (mounted && _isLoading) {
        setState(() {
          _errorMessage = 'Error checking status: ${e.toString()}';
        });
      }
    }
  }

  void _onPaymentCompleted(String? mpesaReceipt) {
    if (!_isLoading) return;
    _cancelAll();
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(mpesaReceipt: mpesaReceipt),
      ),
    );
  }

  void _onPaymentFailed(String? message) {
    if (!_isLoading) return;
    _cancelAll();
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentFailureScreen(message: message),
      ),
    );
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _isLoading) {
        _cancelAll();
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PaymentFailureScreen(
              message: 'Verification timeout – check M-Pesa or try again',
            ),
          ),
        );
      }
    });
  }

  void _cancelAll() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _orderSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waiting for Payment'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    widget.customerMessage ?? 'Please complete the payment on your phone.',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ] else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
