import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/payment_service.dart';
import 'order_history_screen.dart';

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

      // Initiate M-Pesa payment
      final paymentResult = await _paymentService.initiateMpesaPayment(
        phoneNumber: _phoneController.text.trim(),
        amount: cartProvider.total,
        orderId: orderId,
      );

      if (!mounted) return;

      // Show payment waiting dialog
      final customerMessage = paymentResult['customerMessage'] as String? ??
          'Please complete payment on your phone';

      // Clear cart
      cartProvider.clearCart();

      // Show waiting dialog and listen for payment status
      _showPaymentWaitingDialog(
        context,
        orderId,
        customerMessage,
        orderProvider,
      );
    } catch (e) {
      if (!mounted) return;
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

  void _showPaymentWaitingDialog(
    BuildContext context,
    String orderId,
    String customerMessage,
    OrderProvider orderProvider,
  ) {
    StreamSubscription<OrderModel?>? subscription;
    Timer? timeoutTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Start listening to payment status
        subscription = orderProvider.listenToPaymentStatus(orderId).listen(
          (order) {
            if (order == null) return;

            final paymentStatus = order.paymentStatus;

            if (paymentStatus == AppConstants.paymentStatusPaid) {
              // Payment successful
              subscription?.cancel();
              timeoutTimer?.cancel();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment successful! Order confirmed.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else if (paymentStatus == AppConstants.paymentStatusFailed) {
              // Payment failed
              subscription?.cancel();
              timeoutTimer?.cancel();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment failed. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );

        // Set timeout
        timeoutTimer = Timer(AppConstants.mpesaCallbackTimeout, () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment timeout. Please check your order status in Order History.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen(),
              ),
            );
            subscription?.cancel();
          }
        });

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              subscription?.cancel();
              timeoutTimer?.cancel();
            }
          },
          child: AlertDialog(
            title: const Text('Waiting for Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(customerMessage),
                const SizedBox(height: 8),
                const Text(
                  'Please complete the payment on your phone.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  subscription?.cancel();
                  timeoutTimer?.cancel();
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen(),
                    ),
                  );
                },
                child: const Text('Check Order History'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Cleanup when dialog is dismissed
      subscription?.cancel();
      timeoutTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
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
                              'KES ${cartProvider.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
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
