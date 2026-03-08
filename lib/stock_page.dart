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
            title: Text(_translateCategory(_selectedCategory!)),
            automaticallyImplyLeading: false,
          ),
          body: Consumer<StockProvider>(
            builder: (context, provider, child) {
              final products = provider.products
                  .where((p) => p.type == _selectedCategory)
                  .toList();

              if (products.isEmpty) {
                return const Center(
                  child: Text('Aucun produit dans cette catégorie.'),
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
        title: const Text('Visualiseur de Stock'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildCategoryCard(
              'Équipement',
              'equipment',
              Icons.construction,
              Theme.of(context).colorScheme.primary,
            ),
            _buildCategoryCard(
              'Secs',
              'secs',
              Icons.takeout_dining,
              Theme.of(context).colorScheme.secondary,
            ),
            _buildCategoryCard(
              'Frais',
              'frais',
              Icons.kitchen,
              Colors.lightBlue,
            ),
          ],
        ),
      ),
    );
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'equipment':
        return 'Équipement';
      case 'secs':
        return 'Secs';
      case 'frais':
        return 'Frais';
      default:
        return 'Catégorie';
    }
  }

  Widget _buildCategoryCard(
    String title,
    String categoryValue,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = categoryValue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 24),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
