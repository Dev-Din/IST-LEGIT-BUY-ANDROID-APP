import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import 'product_management_screen.dart';
import 'order_management_screen.dart';
import 'user_management_screen.dart';
import '../shared/settings_screen.dart';

class AdminDashboard extends StatelessWidget {
  final VoidCallback? openDrawer;

  const AdminDashboard({super.key, this.openDrawer});

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
        title: const Text('LegitBuy Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Provider.of<OrderProvider>(context, listen: false)
            .getAllOrdersStream(),
        builder: (context, ordersSnapshot) {
          return StreamBuilder(
            stream: Provider.of<ProductProvider>(context, listen: false)
                .getProductsStream(),
            builder: (context, productsSnapshot) {
              final orders = ordersSnapshot.data ?? [];
              final products = productsSnapshot.data ?? [];
              
              final totalRevenue = orders
                  .where((o) => o.paymentStatus == 'paid')
                  .fold(0.0, (sum, order) => sum + order.total);
              
              final pendingOrders = orders
                  .where((o) => o.status == 'pending')
                  .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stats Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          title: 'Total Products',
                          value: '${products.length}',
                          icon: Icons.inventory,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          title: 'Total Orders',
                          value: '${orders.length}',
                          icon: Icons.shopping_bag,
                          color: Colors.green,
                        ),
                        _StatCard(
                          title: 'Pending Orders',
                          value: '$pendingOrders',
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          title: 'Total Revenue',
                          value: 'KES ${totalRevenue.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _ActionCard(
                          title: 'Manage Products',
                          icon: Icons.inventory_2,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProductManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'Manage Orders',
                          icon: Icons.shopping_cart,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const OrderManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'Manage Users',
                          icon: Icons.people,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          title: 'Settings',
                          icon: Icons.settings,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
