import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;

  Product({required this.id, required this.name});
}

class SearchableDropdown extends StatefulWidget {
  final List<Product> products;
  final String? selectedValue;
  final void Function(String?)? onChanged;

  const SearchableDropdown({
    Key? key,
    required this.products,
    this.selectedValue,
    this.onChanged, required List items, String? value, required Text searchHint, required Text hint, required bool isExpanded,
  }) : super(key: key);

  @override
  _SearchableDropdownState createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  late TextEditingController _searchController;
  late List<Product> _filteredProducts;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredProducts = widget.products;
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = widget.products
          .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: widget.selectedValue,
      items: _filteredProducts.map((Product product) {
        return DropdownMenuItem<String>(
          value: product.id,
          child: Text(product.name),
        );
      }).toList(),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        prefixIcon: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Products',
            border: InputBorder.none,
          ),
          onChanged: _filterProducts,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
