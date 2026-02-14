import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/app_constants.dart';

class OrderManagementScreen extends StatelessWidget {
  final VoidCallback? openDrawer;

  const OrderManagementScreen({super.key, this.openDrawer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: openDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: openDrawer,
              )
            : null,
        title: const Text('Manage Orders'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: Provider.of<OrderProvider>(context, listen: false)
            .getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text('Order #${order.id.substring(0, 8)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KES ${order.total.toStringAsFixed(2)}'),
                      Text(
                        DateFormatter.formatDateTime(order.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: order.status,
                    items: [
                      AppConstants.orderStatusPending,
                      AppConstants.orderStatusProcessing,
                      AppConstants.orderStatusCompleted,
                      AppConstants.orderStatusCancelled,
                    ].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        Provider.of<OrderProvider>(context, listen: false)
                            .updateOrderStatus(order.id, newStatus);
                      }
                    },
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User ID: ${order.userId}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Items:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...order.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.quantity}x ${item.productName}'),
                                  Text(
                                    'KES ${(item.price * item.quantity).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'KES ${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Status: ${order.status}'),
                          Text('Payment: ${order.paymentStatus}'),
                          if (order.mpesaTransactionId != null)
                            Text('Transaction ID: ${order.mpesaTransactionId}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
