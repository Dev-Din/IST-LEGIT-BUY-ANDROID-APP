import 'product_model.dart';

class CartItemModel {
  final String productId;
  final ProductModel product;
  final int quantity;

  CartItemModel({
    required this.productId,
    required this.product,
    required this.quantity,
  });

  double get total => product.price * quantity;

  CartItemModel copyWith({
    String? productId,
    ProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
