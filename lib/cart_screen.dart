
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'checkout_screen.dart'; // Importar la nueva pantalla de checkout

// 1. Modelo para un item en el carrito
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  // Método para convertir a un mapa, útil para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

// 2. Provider para gestionar el estado del carrito
class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(String productId, String name, double price) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(id: existing.id, name: existing.name, price: existing.price, quantity: existing.quantity + 1),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(id: productId, name: name, price: price),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(id: existing.id, name: existing.name, price: existing.price, quantity: existing.quantity - 1),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

// 3. Pantalla que muestra el carrito
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const double _shippingFee = 40.0;

  // Navega a la pantalla de checkout
  void _navigateToCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text('Carrito vacío', style: TextStyle(fontSize: 24, color: Colors.grey)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) => CartListItem(cartItem: cartItems[i]),
                  ),
                ),
                const Divider(height: 1),
                _buildTotalSection(context, cart),
              ],
            ),
    );
  }

  Widget _buildTotalSection(BuildContext context, CartProvider cart) {
    final subtotal = cart.totalAmount;
    final bool cartHasItems = subtotal > 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (cartHasItems) ...[
             _buildTotalRow('Subtotal:', subtotal),
            const SizedBox(height: 8),
            _buildTotalRow('Tarifa de Envío:', _shippingFee),
            const Divider(thickness: 1, height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Chip(
                label: Text(
                  '\$${(cartHasItems ? subtotal + _shippingFee : 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // CAMBIO: Al presionar, navega a la pantalla de Checkout
              onPressed: cartHasItems ? () => _navigateToCheckout(context) : null,
              child: const Text('Proceder al Pago'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTotalRow(String title, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class CartListItem extends StatelessWidget {
  final CartItem cartItem;

  const CartListItem({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Dismissible(
      key: ValueKey(cartItem.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: const Icon(Icons.delete, color: Colors.white, size: 40),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(cartItem.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cartItem.name} eliminado del carrito.')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FittedBox(child: Text('\$${cartItem.price.toStringAsFixed(2)}')),
              ),
            ),
            title: Text(cartItem.name),
            subtitle: Text('Total: \$${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () => cart.removeSingleItem(cartItem.id)),
                Text('${cartItem.quantity}x'),
                IconButton(icon: const Icon(Icons.add), onPressed: () => cart.addItem(cartItem.id, cartItem.name, cartItem.price)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
