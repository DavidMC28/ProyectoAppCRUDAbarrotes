
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Inicializar datos de localización para el formato de fecha
    initializeDateFormatting('es', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial de Compras'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Inicia sesión para ver tu historial.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ordenes')
                  .where('userId', isEqualTo: _currentUser!.uid)
                  //.orderBy('fecha', descending: true) // Se elimina para evitar problemas con datos inconsistentes
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aún no has realizado ninguna compra.'));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Ocurrió un error al cargar el historial.'));
                }

                final orders = snapshot.data!.docs;

                // Ordenar los documentos por fecha en el lado del cliente para mayor robustez
                orders.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>? ?? {};
                  final bData = b.data() as Map<String, dynamic>? ?? {};
                  final aDate = aData['fecha'] as Timestamp?;
                  final bDate = bData['fecha'] as Timestamp?;

                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  
                  return bDate.compareTo(aDate); // Orden descendente
                });


                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(orderData: order.data() as Map<String, dynamic>, orderId: index + 1);
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final int orderId;

  const _OrderCard({required this.orderData, required this.orderId});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    final date = timestamp.toDate();
    return DateFormat("d 'de' MMMM, y - HH:mm", 'es').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final items = (orderData['items'] as List<dynamic>?) ?? [];
    final total = (orderData['costoTotal'] as num?)?.toDouble() ?? 0.0;
    final date = orderData['fecha'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Pedido #${orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(date),
                   style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.map((item) {
              final itemName = item['name'] ?? 'Producto desconocido';
              final quantity = item['quantity'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('${quantity}x $itemName'),
              );
            }).toList(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
