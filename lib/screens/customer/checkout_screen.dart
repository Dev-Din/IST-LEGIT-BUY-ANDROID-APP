import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/debug_logger.dart';
import '../../services/payment_service.dart';
import 'payment_waiting_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (cartProvider.isEmpty || authProvider.user == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create order
      final order = OrderModel(
        id: '',
        userId: authProvider.user!.id,
        items: cartProvider.cartItems
            .map((item) => OrderItem.fromCartItem(item))
            .toList(),
        total: cartProvider.total,
        status: AppConstants.orderStatusPending,
        paymentStatus: AppConstants.paymentStatusPending,
        paymentMethod: AppConstants.paymentMethodMpesa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final orderId = await orderProvider.createOrder(order);

      if (orderId == null) {
        throw Exception('Failed to create order');
      }

      // Initiate M-Pesa payment (use KES 1.00 for testing in debug builds)
      final paymentAmount = kDebugMode ? 1.0 : cartProvider.total;
      final paymentResult = await _paymentService.initiateMpesaPayment(
        phoneNumber: _phoneController.text.trim(),
        amount: paymentAmount,
        orderId: orderId,
      );

      if (!mounted) return;

      // Get customer message and checkout request ID
      final customerMessage = paymentResult['customerMessage'] as String? ??
          'Please complete payment on your phone';
      final checkoutRequestId = paymentResult['checkoutRequestID'] as String?;

      if (checkoutRequestId == null) {
        throw Exception('Checkout request ID not received');
      }

      // Pre-flight check: verify the paymentStatus endpoint is reachable
      // and the order exists in Firestore before sending user to waiting screen
      try {
        await _paymentService
            .getPaymentStatus(checkoutRequestId)
            .timeout(const Duration(seconds: 5));
      } catch (preflightError) {
        if (!mounted) return;
        DebugLogger.log(
          location: 'checkout_screen.dart:_processOrder:preflight',
          message: 'Pre-flight status check failed',
          data: {'error': preflightError.toString()},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment started but status check failed. '
              'Restart Firebase emulators (ensure paymentStatus is listed '
              'in the startup log) and try again.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 8),
          ),
        );
        return;
      }

      // Clear cart
      cartProvider.clearCart();

      // Navigate to payment waiting screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentWaitingScreen(
            checkoutRequestId: checkoutRequestId,
            customerMessage: customerMessage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      DebugLogger.log(
        location: 'checkout_screen.dart:_processOrder',
        message: 'Checkout / payment error',
        data: {'error': e.toString()},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final displayTotal = kDebugMode ? 1.0 : cartProvider.total;
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...cartProvider.cartItems.map((item) {
                          return ListTile(
                            title: Text(item.product.name),
                            subtitle: Text('${item.quantity} x KES ${item.product.price.toStringAsFixed(2)}'),
                            trailing: Text(
                              'KES ${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'KES ${displayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Payment amount (test): KES 1.00',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Phone Number Input
                        const Text(
                          'M-Pesa Phone Number',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '254712345678',
                            prefixIcon: Icon(Icons.phone),
                            prefixText: '+',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 9) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Checkout Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
