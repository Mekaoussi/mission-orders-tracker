import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class StockProvider extends ChangeNotifier {
  Box<Product>? _box;
  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Product>('products');
      _products = _box!.values.toList();
    } on HiveError catch (e) {
      debugPrint('HiveError during StockProvider init: $e');
      // This can happen if the data model has changed and the on-disk data is incompatible.
      // For development, we can clear the box to resolve this.
      debugPrint('Clearing potentially corrupted "products" box.');
      if (Hive.isBoxOpen('products')) {
        await Hive.box('products').close();
      }
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Wait for lock release
      await Hive.deleteBoxFromDisk('products');
      // Retry opening the box
      _box = await Hive.openBox<Product>('products');
      _products = _box!.values.toList();
    }
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    if (_box == null) return;
    await _box!.add(product);
    _products = _box!.values.toList();
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    if (_box == null) return;
    await product.save();
    _products = _box!.values.toList();
    notifyListeners();
  }

  Future<void> deleteProduct(Product product) async {
    if (_box == null) return;
    await product.delete();
    _products = _box!.values.toList();
    notifyListeners();
  }

  // Called by SortieProvider when a mission starts
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      product.currentQuantity -= quantity;
      await product.save();
      notifyListeners();
    } catch (e) {
      debugPrint("Product not found for decrease: $productId");
    }
  }

  // Called by SortieProvider when items are returned
  Future<void> increaseStock(String productId, int quantity) async {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      product.currentQuantity += quantity;
      await product.save();
      notifyListeners();
    } catch (e) {
      debugPrint("Product not found for increase: $productId");
    }
  }
}
