import 'dart:async';
import 'package:flutter/material.dart';
import 'order_history_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String? mpesaReceipt;

  const PaymentSuccessScreen({
    super.key,
    this.mpesaReceipt,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    // Auto-navigate to Order History after 3 seconds
    _autoNavigateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OrderHistoryScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Successful'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.mpesaReceipt != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Receipt: ${widget.mpesaReceipt}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _autoNavigateTimer?.cancel();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('View Order History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
