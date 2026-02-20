import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'people_provider.dart';
import 'stock_provider.dart';

class SortieProvider extends ChangeNotifier {
  Box<Sortie>? _box;
  List<Sortie> _sorties = [];

  StockProvider? _stockProvider;
  PeopleProvider? _peopleProvider;

  List<Sortie> get sorties => _sorties;
  List<Sortie> get activeSorties =>
      _sorties.where((s) => s.status == 'active').toList();
  List<Sortie> get historySorties =>
      _sorties.where((s) => s.status == 'completed').toList();

  void updateDependencies(StockProvider stock, PeopleProvider people) {
    _stockProvider = stock;
    _peopleProvider = people;
  }

  Future<void> init() async {
    _box = await Hive.openBox<Sortie>('sorties');
    _sorties = _box!.values.toList();
    // Sort by date descending (newest first)
    _sorties.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> createSortie({
    required String guideId,
    String? cuisinierId,
    required String responsibleId,
    required List<SortieItem> items,
  }) async {
    if (_box == null || _stockProvider == null) return;

    final newSortie = Sortie(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      guideId: guideId,
      cuisinierId: cuisinierId,
      responsibleId: responsibleId,
      items: items,
      status: 'active',
      date: DateTime.now(),
    );

    // Decrease stock immediately
    for (var item in items) {
      await _stockProvider!.decreaseStock(item.productId, item.quantityTaken);
    }

    await _box!.add(newSortie);
    _sorties = _box!.values.toList();
    _sorties.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> completeSortie(
    Sortie sortie,
    Map<String, int> returnedQuantities,
  ) async {
    if (_peopleProvider == null || _stockProvider == null) return;

    int totalMissing = 0;

    for (var item in sortie.items) {
      final returned = returnedQuantities[item.productId] ?? 0;
      item.quantityReturned = returned;

      // Calculate missing
      final missing = (item.quantityTaken - returned).clamp(0, 9999);
      totalMissing += missing;

      // Return items to stock
      if (returned > 0) {
        await _stockProvider!.increaseStock(item.productId, returned);
      }
    }

    // Score logic
    final scoreDelta = (totalMissing == 0) ? 10 : -(totalMissing * 2);
    await _peopleProvider!.updateScore(sortie.responsibleId, scoreDelta);

    sortie.status = 'completed';
    await sortie.save();

    _sorties = _box!.values.toList();
    _sorties.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }
}
