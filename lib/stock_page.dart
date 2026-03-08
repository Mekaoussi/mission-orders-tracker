import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../stock_provider.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    // 1. If a category is selected, show the list
    if (_selectedCategory != null) {
      return WillPopScope(
        onWillPop: () async {
          setState(() => _selectedCategory = null);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedCategory = null),
            ),
            title: Text(_selectedCategory!.toUpperCase()),
            automaticallyImplyLeading: false,
          ),
          body: Consumer<StockProvider>(
            builder: (context, provider, child) {
              final products = provider.products
                  .where((p) => p.type == _selectedCategory)
                  .toList();

              if (products.isEmpty) {
                return const Center(
                  child: Text('No products in this category.'),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    trailing: Text(
                      '${product.currentQuantity} / ${product.initialQuantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    }

    // 2. Otherwise, show the Category Selection
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Viewer'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCategoryCard('equipment', Icons.build, Colors.blue),
            const SizedBox(height: 16),
            _buildCategoryCard('secs', Icons.grass, Colors.orange),
            const SizedBox(height: 16),
            _buildCategoryCard('frais', Icons.ac_unit, Colors.lightBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = title),
        child: Card(
          color: color.withOpacity(0.1),
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
