
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Órdenes'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ordenes')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay ninguna orden registrada.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocurrió un error al cargar las órdenes.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderReportCard(orderData: order.data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }
}

class _OrderReportCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const _OrderReportCard({required this.orderData});

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
    final clientName = orderData['nombreCliente'] as String? ?? 'No especificado';
    final address = orderData['direccion'] as String? ?? 'No especificada';


    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: $clientName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
             Text('Dirección: $address'),
            const SizedBox(height: 8),
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
            const Text('Artículos:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...items.map((item) {
              final itemName = item['name'] ?? 'Producto desconocido';
              final quantity = item['quantity'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Text('• ${quantity}x $itemName'),
              );
            }).toList(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
