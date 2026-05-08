import 'package:AbarrotesApp/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class CrudScreen extends StatelessWidget {
  final String collection;

  const CrudScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isEmpleados = collection == 'empleados';

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar $collection'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.auto_mode),
            onPressed: () => themeProvider.setSystemTheme(),
            tooltip: 'Set System Theme',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection(collection).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar datos',
                    style: TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay datos disponibles.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              String subtitleText;
              if (isEmpleados) {
                subtitleText =
                    'Puesto: ${data['puesto'] ?? 'N/A'} - Salario: ${data['salario'] ?? 'N/A'}';
              } else {
                subtitleText =
                    'Precio: ${data['precio'] ?? 'N/A'} - Stock: ${data['stock'] ?? 'N/A'}';
              }

              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  title: Text(data['nombre'] ?? 'Sin nombre',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitleText),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    onPressed: () => doc.reference.delete(),
                  ),
                  onTap: () => _showEditDialog(context, doc, isEmpleados),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, db, collection, isEmpleados),
        tooltip: 'Añadir',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, FirebaseFirestore db, String collection, bool isEmpleados) {
    final nombreController = TextEditingController();
    final field1Controller = TextEditingController();
    final field2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Añadir a $collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(
                  controller: field1Controller,
                  decoration: InputDecoration(labelText: isEmpleados ? 'Puesto' : 'Precio'),
                  keyboardType: isEmpleados ? TextInputType.text : TextInputType.number),
              const SizedBox(height: 10),
              TextField(
                  controller: field2Controller,
                  decoration: InputDecoration(labelText: isEmpleados ? 'Salario' : 'Stock'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () {
                  final nombre = nombreController.text;
                  if (nombre.isNotEmpty) {
                    if (isEmpleados) {
                      final puesto = field1Controller.text;
                      final salario = double.tryParse(field2Controller.text) ?? 0.0;
                      if (puesto.isNotEmpty) {
                        db.collection(collection).add(
                            {'nombre': nombre, 'puesto': puesto, 'salario': salario});
                      }
                    } else {
                      final precio = double.tryParse(field1Controller.text) ?? 0.0;
                      final stock = int.tryParse(field2Controller.text) ?? 0;
                      db.collection(collection).add(
                          {'nombre': nombre, 'precio': precio, 'stock': stock});
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Añadir')),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot doc, bool isEmpleados) {
    final data = doc.data() as Map<String, dynamic>;
    final nombreController = TextEditingController(text: data['nombre']);

    final field1Controller = TextEditingController(
      text: (isEmpleados ? data['puesto'] : data['precio'])?.toString()
    );
    final field2Controller = TextEditingController(
      text: (isEmpleados ? data['salario'] : data['stock'])?.toString()
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar ${data['nombre']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(
                  controller: field1Controller,
                  decoration: InputDecoration(labelText: isEmpleados ? 'Puesto' : 'Precio'),
                  keyboardType: isEmpleados ? TextInputType.text : TextInputType.number),
              const SizedBox(height: 10),
              TextField(
                  controller: field2Controller,
                  decoration: InputDecoration(labelText: isEmpleados ? 'Salario' : 'Stock'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () {
                  final nombre = nombreController.text;
                   if (nombre.isNotEmpty) {
                    if (isEmpleados) {
                      final puesto = field1Controller.text;
                      final salario = double.tryParse(field2Controller.text) ?? 0.0;
                      if (puesto.isNotEmpty) {
                        doc.reference.update(
                          {'nombre': nombre, 'puesto': puesto, 'salario': salario});
                      }
                    } else {
                       final precio = double.tryParse(field1Controller.text) ?? 0.0;
                       final stock = int.tryParse(field2Controller.text) ?? 0;
                       doc.reference.update(
                         {'nombre': nombre, 'precio': precio, 'stock': stock});
                    }
                   }
                  Navigator.of(context).pop();
                },
                child: const Text('Actualizar')),
          ],
        );
      },
    );
  }
}
