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

  Person({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.score = 0,
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

  SortieItem({
    required this.productId,
    required this.quantityTaken,
    this.quantityReturned = 0,
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
  DateTime date;

  Sortie({
    required this.id,
    required this.guideId,
    this.cuisinierId,
    required this.responsibleId,
    required this.items,
    required this.status,
    required this.date,
  });
}
