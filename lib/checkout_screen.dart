
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_screen.dart'; // Importamos el provider del carrito

enum PaymentMethod { cash, card }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para los campos del formulario
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cardController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // Si no es válido, no hacer nada
    }

    setState(() {
      _isLoading = true;
    });

    final cart = Provider.of<CartProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Debes estar autenticado para comprar.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      const shippingFee = 40.0;
      final subtotal = cart.totalAmount;
      final total = subtotal + shippingFee;
      final itemsList = cart.items.values.map((item) => item.toMap()).toList();

      // 2. Registrar la orden con TODOS los datos en Firestore
      await FirebaseFirestore.instance.collection('ordenes').add({
        'userId': user.uid,
        'items': itemsList,
        'costoTotal': total,
        'fecha': FieldValue.serverTimestamp(),
        // Nuevos campos del formulario
        'nombreCliente': _nameController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _addressController.text.trim(),
        'metodoPago': _paymentMethod == PaymentMethod.card ? 'Tarjeta' : 'Efectivo',
      });

      // 3. Limpiar el carrito
      cart.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu compra!'), backgroundColor: Colors.green),
        );
        // 4. Regresar a la pantalla principal (Home)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error al procesar la compra: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información de Entrega', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Número de Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null || value.length < 10) ? 'Ingresa un número válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección de Entrega', border: OutlineInputBorder()),
                 validator: (value) => (value == null || value.isEmpty) ? 'Ingresa tu dirección' : null,
              ),
              const Divider(height: 40),
              Text('Método de Pago', style: Theme.of(context).textTheme.titleLarge),
              RadioListTile<PaymentMethod>(
                title: const Text('Efectivo'),
                value: PaymentMethod.cash,
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              RadioListTile<PaymentMethod>(
                title: const Text('Tarjeta de Crédito/Débito'),
                value: PaymentMethod.card,
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              if (_paymentMethod == PaymentMethod.card)
                TextFormField(
                  controller: _cardController,
                  decoration: const InputDecoration(labelText: 'Número de Tarjeta', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.length < 16) ? 'Ingresa un número de tarjeta válido' : null,
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Pagar Ahora'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
