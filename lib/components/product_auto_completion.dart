import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;

  Product({required this.id, required this.name});
}

void showProductAutocompleteDialog(BuildContext context, List<Product> products, Function(String?) onProductSelected) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ProductAutocompleteDialog(
        products: products,
        onProductSelected: onProductSelected,
      );
    },
  );
}

class ProductAutocompleteDialog extends StatefulWidget {
  final List<Product> products;
  final ValueChanged<String> onProductSelected;

  const ProductAutocompleteDialog({
    Key? key,
    required this.products,
    required this.onProductSelected,
  }) : super(key: key);

  @override
  _ProductAutocompleteDialogState createState() =>
      _ProductAutocompleteDialogState();
}

class _ProductAutocompleteDialogState extends State<ProductAutocompleteDialog> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_filterProducts);
    _filteredProducts = widget.products; // Initialize with all products
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _controller.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = widget.products; // Show all products if query is empty
      });
    } else {
      setState(() {
        _filteredProducts = widget.products
            .where((product) =>
                product.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select a Product'),
      content: SizedBox(
        width: double.maxFinite, // Ensure content takes full width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(child: Text('No products found'))
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ListTile(
                          title: Text(product.name),
                          onTap: () {
                            widget.onProductSelected(product.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
