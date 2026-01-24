import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer/product_shimmer.dart';
import '../../core/utils/debug_logger.dart';
import 'product_list_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import '../shared/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // #region agent log
    DebugLogger.log(
      location: 'home_screen.dart:23',
      message: 'HomeScreen.initState() called',
      hypothesisId: 'E',
    );
    // #endregion
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    DebugLogger.log(
      location: 'home_screen.dart:30',
      message: 'HomeScreen.build() called',
      hypothesisId: 'E',
    );
    // #endregion
    
    try {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LegitBuy'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.itemCount > 0) {
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductListScreen(),
                      ),
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductListScreen(),
                  ),
                );
              },
            ),
          ),
          // Featured Products
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                // #region agent log
                DebugLogger.log(
                  location: 'home_screen.dart:120',
                  message: 'Consumer<ProductProvider> builder called',
                  data: {
                    'isLoading': productProvider.isLoading,
                    'productCount': productProvider.products.length,
                    'hasError': productProvider.error != null,
                  },
                  hypothesisId: 'E',
                );
                // #endregion
                
                if (productProvider.error != null) {
                  // #region agent log
                  DebugLogger.log(
                    location: 'home_screen.dart:132',
                    message: 'ProductProvider has error',
                    data: {'error': productProvider.error},
                    hypothesisId: 'E',
                  );
                  // #endregion
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading products',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            productProvider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<ProductProvider>(context, listen: false).loadProducts();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (productProvider.isLoading) {
                  // #region agent log
                  DebugLogger.log(
                    location: 'home_screen.dart:165',
                    message: 'Showing loading shimmer',
                    hypothesisId: 'E',
                  );
                  // #endregion
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const ProductShimmer(),
                  );
                }

                if (productProvider.products.isEmpty) {
                  // #region agent log
                  DebugLogger.log(
                    location: 'home_screen.dart:180',
                    message: 'No products available',
                    hypothesisId: 'E',
                  );
                  // #endregion
                  return const Center(
                    child: Text('No products available'),
                  );
                }

                // #region agent log
                DebugLogger.log(
                  location: 'home_screen.dart:190',
                  message: 'Building product grid',
                  data: {'productCount': productProvider.products.length},
                  hypothesisId: 'E',
                );
                // #endregion
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(productId: product.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
    } catch (e, stackTrace) {
      // #region agent log
      DebugLogger.log(
        location: 'home_screen.dart:200',
        message: 'HomeScreen.build() FAILED',
        data: {'error': e.toString(), 'stackTrace': stackTrace.toString()},
        hypothesisId: 'E',
      );
      // #endregion
      return Scaffold(
        appBar: AppBar(title: const Text('LegitBuy')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Home Screen',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
