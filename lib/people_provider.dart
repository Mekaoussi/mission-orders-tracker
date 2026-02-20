import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class PeopleProvider extends ChangeNotifier {
  Box<Person>? _box;
  List<Person> _people = [];

  List<Person> get people => _people;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Person>('people');
      _people = _box!.values.toList();
    } on HiveError catch (e) {
      debugPrint('HiveError during PeopleProvider init: $e');
      // This can happen if the data model has changed and the on-disk data is incompatible.
      // For development, we can clear the box to resolve this.
      debugPrint('Clearing potentially corrupted "people" box.');
      if (Hive.isBoxOpen('people')) {
        await Hive.box('people').close();
      }
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Wait for lock release
      await Hive.deleteBoxFromDisk('people');
      // Retry opening the box
      _box = await Hive.openBox<Person>('people');
      _people = _box!.values.toList();
    }
    notifyListeners();
  }

  Future<void> addPerson(Person person) async {
    if (_box == null) return;
    await _box!.add(person);
    _people = _box!.values.toList();
    notifyListeners();
  }

  Future<void> updatePerson(Person person) async {
    if (_box == null) return;
    await person.save();
    _people = _box!.values.toList();
    notifyListeners();
  }

  Future<void> deletePerson(Person person) async {
    if (_box == null) return;
    await person.delete();
    _people = _box!.values.toList();
    notifyListeners();
  }

  // Called by SortieProvider to update score
  Future<void> updateScore(String personId, int pointsDelta) async {
    try {
      final person = _people.firstWhere((p) => p.id == personId);
      person.score += pointsDelta;
      await person.save();
      notifyListeners();
    } catch (e) {
      debugPrint("Person not found for score update: $personId");
    }
  }
}
