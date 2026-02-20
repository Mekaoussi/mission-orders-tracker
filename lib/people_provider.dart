import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class PeopleProvider extends ChangeNotifier {
  Box<Person>? _box;
  List<Person> _people = [];

  List<Person> get people => _people;

  Future<void> init() async {
    _box = await Hive.openBox<Person>('people');
    _people = _box!.values.toList();
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
