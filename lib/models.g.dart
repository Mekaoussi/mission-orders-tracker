// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      initialQuantity: fields[3] as int,
      currentQuantity: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.initialQuantity)
      ..writeByte(4)
      ..write(obj.currentQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 1;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      role: fields[3] as String,
      score: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.score);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SortieItemAdapter extends TypeAdapter<SortieItem> {
  @override
  final int typeId = 2;

  @override
  SortieItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SortieItem(
      productId: fields[0] as String,
      quantityTaken: fields[1] as int,
      quantityReturned: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SortieItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.quantityTaken)
      ..writeByte(2)
      ..write(obj.quantityReturned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortieItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SortieAdapter extends TypeAdapter<Sortie> {
  @override
  final int typeId = 3;

  @override
  Sortie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sortie(
      id: fields[0] as String,
      guideId: fields[1] as String,
      cuisinierId: fields[2] as String?,
      responsibleId: fields[3] as String,
      items: (fields[4] as List).cast<SortieItem>(),
      status: fields[5] as String,
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Sortie obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.guideId)
      ..writeByte(2)
      ..write(obj.cuisinierId)
      ..writeByte(3)
      ..write(obj.responsibleId)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
