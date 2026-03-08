import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // "equipment", "secs", "frais"

  @HiveField(3)
  int initialQuantity;

  @HiveField(4)
  int currentQuantity;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.initialQuantity,
    required this.currentQuantity,
  });
}

@HiveType(typeId: 1)
class Person extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String role; // "guide", "cuisinier"

  @HiveField(4)
  int score;

  @HiveField(5)
  List<String> history;

  Person({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.score = 0,
    this.history = const [],
  });
}

@HiveType(typeId: 2)
class SortieItem {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  int quantityTaken;

  @HiveField(2)
  int quantityReturned;

  @HiveField(3)
  String? note;

  @HiveField(4)
  bool isExcused;

  SortieItem({
    required this.productId,
    required this.quantityTaken,
    this.quantityReturned = 0,
    this.note,
    this.isExcused = false,
  });
}

@HiveType(typeId: 3)
class Sortie extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String guideId;

  @HiveField(2)
  String? cuisinierId;

  @HiveField(3)
  String responsibleId;

  @HiveField(4)
  List<SortieItem> items;

  @HiveField(5)
  String status; // "active", "completed"

  @HiveField(6)
  DateTime creationDate;

  @HiveField(7)
  DateTime departureDate;

  @HiveField(8)
  DateTime returnDate;

  @HiveField(9)
  String displayId;

  Sortie({
    required this.id,
    required this.guideId,
    this.cuisinierId,
    required this.responsibleId,
    required this.items,
    required this.status,
    required this.creationDate,
    required this.departureDate,
    required this.returnDate,
    required this.displayId,
  });

  bool get hasMissingItems {
    if (status != 'completed') return false;
    for (final item in items) {
      // If any item was not fully returned, there are missing items.
      if (item.quantityReturned < item.quantityTaken) {
        return true;
      }
    }
    return false;
  }
}
