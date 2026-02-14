import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final String checkoutRequestId;
  final String? customerMessage;

  const PaymentWaitingScreen({
    super.key,
    required this.checkoutRequestId,
    this.customerMessage,
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

  @override
  void initState() {
    super.initState();
    // Check immediately, then every 15 seconds
    _checkStatus();
    _startPolling();
    _startTimeout();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
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
        _pollTimer?.cancel();
        _timeoutTimer?.cancel();
        setState(() {
          _isLoading = false;
        });
        final mpesaReceipt = statusData['mpesa_receipt'] as String?;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(mpesaReceipt: mpesaReceipt),
          ),
        );
      } else if (status == 'failed') {
        _pollTimer?.cancel();
        _timeoutTimer?.cancel();
        setState(() {
          _isLoading = false;
        });
        final message = statusData['message'] as String?;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentFailureScreen(message: message),
          ),
        );
      }
      // If status is 'pending', continue polling (do nothing)
    } catch (e) {
      if (mounted && _isLoading) {
        setState(() {
          _errorMessage = 'Error checking status: ${e.toString()}';
        });
        // Continue polling despite error
      }
    }
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _isLoading) {
        _pollTimer?.cancel();
        setState(() {
          _isLoading = false;
        });
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
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
