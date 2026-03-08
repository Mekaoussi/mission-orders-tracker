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
    try {
      _box = await Hive.openBox<Sortie>('sorties');
      _sorties = _box!.values.toList();
      // Sort by date descending (newest first)
      _sorties.sort((a, b) => b.date.compareTo(a.date));
    } on HiveError catch (e) {
      debugPrint('HiveError during SortieProvider init: $e');
      // This can happen if the data model has changed and the on-disk data is incompatible.
      // For development, we can clear the box to resolve this.
      debugPrint('Clearing potentially corrupted "sorties" box.');
      if (Hive.isBoxOpen('sorties')) {
        await Hive.box('sorties').close();
      }
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Wait for lock release
      await Hive.deleteBoxFromDisk('sorties');
      // Retry opening the box
      _box = await Hive.openBox<Sortie>('sorties');
      _sorties = _box!.values.toList();
      _sorties.sort((a, b) => b.date.compareTo(a.date));
    }
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
    List<SortieItem> updatedItems,
  ) async {
    if (_peopleProvider == null || _stockProvider == null) return;

    int scorePenalty = 0;
    List<String> incidentNotes = [];

    for (var item in updatedItems) {
      // Update the original item with return details
      final originalItem = sortie.items.firstWhere(
        (i) => i.productId == item.productId,
      );
      originalItem.quantityReturned = item.quantityReturned;
      originalItem.note = item.note;
      originalItem.isExcused = item.isExcused;

      // Calculate missing
      final missing =
          (originalItem.quantityTaken - originalItem.quantityReturned).clamp(
            0,
            9999,
          );

      // Return items to stock
      if (originalItem.quantityReturned > 0) {
        await _stockProvider!.increaseStock(
          originalItem.productId,
          originalItem.quantityReturned,
        );
      }

      // Logic: If missing > 0 and NOT excused, apply penalty and log history
      if (missing > 0 && !originalItem.isExcused) {
        scorePenalty += missing; // -1 point per missing item
        incidentNotes.add(
          "${DateTime.now().toString().split(' ')[0]}: Missing $missing x (Prod ID: ${originalItem.productId}). Note: ${originalItem.note ?? 'No details'}",
        );
      }
    }

    // Apply Score (If clean, maybe +1 bonus? Or just 0. Here we only deduct for faults)
    if (scorePenalty > 0) {
      await _peopleProvider!.updateScore(sortie.responsibleId, -scorePenalty);
      for (var note in incidentNotes) {
        await _peopleProvider!.addHistory(sortie.responsibleId, note);
      }
    }

    sortie.status = 'completed';
    await sortie.save();

    _sorties = _box!.values.toList();
    _sorties.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }
}
