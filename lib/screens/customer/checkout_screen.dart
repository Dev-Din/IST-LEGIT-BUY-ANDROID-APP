import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PaymentWaitingDialog(
          orderId: orderId,
          customerMessage: customerMessage,
          orderProvider: orderProvider,
          onPaymentReceived: (transactionId) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            if (context.mounted) {
              final successMessage = transactionId != null
                  ? 'Payment successful! Receipt: $transactionId'
                  : 'Payment successful! Order confirmed.';
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          onPaymentFailed: () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment failed. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          onError: (error) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error checking payment status: $error'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Check History',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
          onTimeout: () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            if (context.mounted) {
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
            }
          },
        );
      },
    );
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

/// Stateful dialog widget for payment waiting with real-time status updates
class _PaymentWaitingDialog extends StatefulWidget {
  final String orderId;
  final String customerMessage;
  final OrderProvider orderProvider;
  final Function(String?) onPaymentReceived;
  final VoidCallback onPaymentFailed;
  final Function(Object) onError;
  final VoidCallback onTimeout;

  const _PaymentWaitingDialog({
    required this.orderId,
    required this.customerMessage,
    required this.orderProvider,
    required this.onPaymentReceived,
    required this.onPaymentFailed,
    required this.onError,
    required this.onTimeout,
  });

  @override
  State<_PaymentWaitingDialog> createState() => _PaymentWaitingDialogState();
}

class _PaymentWaitingDialogState extends State<_PaymentWaitingDialog> {
  StreamSubscription<OrderModel?>? _subscription;
  Timer? _timeoutTimer;
  bool _isPaymentReceived = false;
  bool _isPaymentFailed = false;
  bool _hasStreamError = false;
  String? _streamErrorMessage;
  String? _transactionId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  @override
  void initState() {
    super.initState();
    _startListening();
    _startTimeout();
  }

  void _startListening() {
    _subscription?.cancel(); // Cancel existing subscription if any
    
    _subscription = widget.orderProvider
        .listenToPaymentStatus(widget.orderId)
        .listen(
      (order) {
        if (order == null || !mounted) return;

        // Reset error state on successful data
        if (_hasStreamError) {
          setState(() {
            _hasStreamError = false;
            _streamErrorMessage = null;
            _reconnectAttempts = 0;
          });
        }

        final paymentStatus = order.paymentStatus;

        if (paymentStatus == AppConstants.paymentStatusPaid) {
          // Update state immediately for visual feedback
          setState(() {
            _isPaymentReceived = true;
            _transactionId = order.mpesaTransactionId;
          });

          // Cancel timeout since payment received
          _timeoutTimer?.cancel();

          // Close dialog after brief success display
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              widget.onPaymentReceived(_transactionId);
            }
          });
        } else if (paymentStatus == AppConstants.paymentStatusFailed) {
          // Update state immediately for visual feedback
          setState(() {
            _isPaymentFailed = true;
          });

          // Cancel timeout since payment failed
          _timeoutTimer?.cancel();

          // Close dialog after brief error display
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              widget.onPaymentFailed();
            }
          });
        }
      },
      onError: (error) {
        _reconnectAttempts++;
        
        if (_reconnectAttempts <= _maxReconnectAttempts) {
          // Try to reconnect
          setState(() {
            _hasStreamError = true;
            _streamErrorMessage = 'Connection issue. Reconnecting... (${_reconnectAttempts}/$_maxReconnectAttempts)';
          });
          
          // Wait a bit before reconnecting
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _reconnectAttempts <= _maxReconnectAttempts) {
              _startListening();
            }
          });
        } else {
          // Max reconnection attempts reached
          _timeoutTimer?.cancel();
          setState(() {
            _hasStreamError = true;
            _streamErrorMessage = 'Unable to connect. Please check your order status manually.';
          });
        }
      },
    );
  }

  Future<void> _refreshStatus() async {
    try {
      setState(() {
        _hasStreamError = false;
        _streamErrorMessage = 'Checking status...';
      });

      // Manually check order status by fetching the order document directly
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = OrderModel.fromJson(
        orderDoc.data() as Map<String, dynamic>,
        orderDoc.id,
      );

      if (order.paymentStatus == AppConstants.paymentStatusPaid) {
        setState(() {
          _isPaymentReceived = true;
          _transactionId = order.mpesaTransactionId;
          _hasStreamError = false;
        });
        _timeoutTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            widget.onPaymentReceived(_transactionId);
          }
        });
      } else if (order.paymentStatus == AppConstants.paymentStatusFailed) {
        setState(() {
          _isPaymentFailed = true;
          _hasStreamError = false;
        });
        _timeoutTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onPaymentFailed();
          }
        });
      } else {
        // Still pending, restart listening
        setState(() {
          _hasStreamError = false;
          _streamErrorMessage = null;
          _reconnectAttempts = 0;
        });
        _startListening();
      }
    } catch (e) {
      setState(() {
        _hasStreamError = true;
        _streamErrorMessage = 'Error checking status: $e';
      });
    }
  }

  void _startTimeout() {
    _timeoutTimer = Timer(AppConstants.mpesaCallbackTimeout, () {
      if (mounted) {
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _subscription?.cancel();
        }
      },
      child: AlertDialog(
        title: Text(_isPaymentReceived
            ? 'Payment Received!'
            : _isPaymentFailed
                ? 'Payment Failed'
                : 'Waiting for Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show success checkmark, error icon, or loading indicator
            if (_isPaymentReceived)
              Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment confirmed!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (_transactionId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Receipt: $_transactionId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              )
            else if (_isPaymentFailed)
              const Column(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Payment failed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              )
            else ...[
              if (_hasStreamError)
                Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _streamErrorMessage ?? 'Connection error',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(widget.customerMessage),
                const SizedBox(height: 8),
                const Text(
                  'Please complete the payment on your phone.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
        actions: [
          if (!_isPaymentReceived && !_isPaymentFailed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_hasStreamError)
                  TextButton.icon(
                    onPressed: _refreshStatus,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  )
                else
                  const SizedBox.shrink(),
                TextButton(
                  onPressed: () {
                    _subscription?.cancel();
                    Navigator.of(context).pop();
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
        ],
      ),
    );
  }
}
