
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'cart_screen.dart'; // Import del carrito


class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  void _showProductForm([DocumentSnapshot? product]) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        collectionName: 'Shop',
        product: product,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserProvider>(context).isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCustomHeader(isAdmin),
          _buildCategoryFilters(),
          Expanded(child: _buildProductGrid(isAdmin)),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(bool isAdmin) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF5BC8F0), // Azul cielo
          padding: const EdgeInsets.only(top: 25.0, left: 8.0, right: 8.0, bottom: 8.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
              const FaIcon(FontAwesomeIcons.shoppingBasket, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Shop', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  onPressed: () => _showProductForm(),
                  tooltip: 'Añadir Producto',
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: const Color(0xFF00A98F), // Turquesa
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Container(height: 4, color: Colors.amber[600]), // Línea amarilla
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final categories = {
      'panaderia': FontAwesomeIcons.breadSlice,
      'bebidas': FontAwesomeIcons.martiniGlassCitrus,
      'lacteos': FontAwesomeIcons.cheese,
      'botanas': FontAwesomeIcons.hotdog,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : entry.key;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                children: [
                  FaIcon(entry.value, color: isSelected ? const Color(0xFFE53935) : Colors.pink[200], size: 20),
                  const SizedBox(height: 4),
                  Text(entry.key, style: TextStyle(color: isSelected ? Colors.black : Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGrid(bool isAdmin) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Shop').orderBy('nombre').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay productos en la tienda. ¡Añade uno!'));
        }

        var products = snapshot.data!.docs;

        if (_selectedCategory != null) {
          products = products.where((doc) => (doc.data() as Map<String, dynamic>)['categoria']?.toLowerCase() == _selectedCategory).toList();
        }

        if (_searchQuery.isNotEmpty) {
          products = products.where((doc) => (doc.data() as Map<String, dynamic>)['nombre']?.toLowerCase().contains(_searchQuery) ?? false).toList();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              isAdmin: isAdmin,
              onEdit: () => _showProductForm(product),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: const Color(0xFF5BC8F0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Volver al Inicio',
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final DocumentSnapshot product;
  final VoidCallback onEdit;
  final bool isAdmin;

  const _ProductCard({required this.product, required this.onEdit, required this.isAdmin});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final data = widget.product.data() as Map<String, dynamic>;
    final imageUrl = data['imagen'] as String?;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final precio = (data['precio'] ?? 0).toDouble();
    final descripcion = data['descripcion'] ?? '';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 3,
        shadowColor: Colors.grey[200],
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.white,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          )
                        : const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('\$${precio.toStringAsFixed(2)}', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          descripcion,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Botón de editar para administradores
            if (widget.isAdmin && _isHovered)
              Positioned(
                top: 5,
                right: 5,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, color: Colors.white, size: 14),
                    onPressed: widget.onEdit,
                    tooltip: 'Editar Producto',
                  ),
                ),
              ),
            // Botón de añadir al carrito para clientes
            if (!widget.isAdmin)
              Positioned(
                bottom: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      cart.addItem(widget.product.id, nombre, precio);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$nombre añadido al carrito'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final String collectionName;
  final DocumentSnapshot? product;

  const _ProductFormDialog({required this.collectionName, this.product});

  @override
  _ProductFormDialogState createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final data = widget.product?.data() as Map<String, dynamic>?;

    _nameController = TextEditingController(text: data?['nombre'] ?? '');
    _categoryController = TextEditingController(text: data?['categoria'] ?? '');
    _priceController = TextEditingController(text: (data?['precio'] ?? '').toString());
    _stockController = TextEditingController(text: (data?['stock'] ?? '').toString());
    _imageController = TextEditingController(text: data?['imagen'] ?? '');
    _descriptionController = TextEditingController(text: data?['descripcion'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'nombre': _nameController.text,
        'categoria': _categoryController.text,
        'precio': num.tryParse(_priceController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'imagen': _imageController.text,
        'descripcion': _descriptionController.text,
      };

      try {
        if (widget.product == null) {
          await FirebaseFirestore.instance.collection(widget.collectionName).add(data);
        } else {
          await widget.product!.reference.update(data);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el producto: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm && widget.product != null) {
      try {
        await widget.product!.reference.delete();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el producto: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Añadir Producto' : 'Editar Producto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'URL de Imagen', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.product != null)
          TextButton(
            onPressed: _deleteProduct,
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
