// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jar_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JarModelAdapter extends TypeAdapter<JarModel> {
  @override
  final int typeId = 1;

  @override
  JarModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JarModel(
      type: fields[0] as JarType,
      balances: (fields[1] as Map?)?.cast<String, double>(),
      customPercentage: fields[2] as double?,
      customName: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JarModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.balances)
      ..writeByte(2)
      ..write(obj.customPercentage)
      ..writeByte(3)
      ..write(obj.customName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JarModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JarTypeAdapter extends TypeAdapter<JarType> {
  @override
  final int typeId = 0;

  @override
  JarType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return JarType.necessities;
      case 1:
        return JarType.financialFreedom;
      case 2:
        return JarType.longTermSavings;
      case 3:
        return JarType.education;
      case 4:
        return JarType.play;
      case 5:
        return JarType.giving;
      default:
        return JarType.necessities;
    }
  }

  @override
  void write(BinaryWriter writer, JarType obj) {
    switch (obj) {
      case JarType.necessities:
        writer.writeByte(0);
        break;
      case JarType.financialFreedom:
        writer.writeByte(1);
        break;
      case JarType.longTermSavings:
        writer.writeByte(2);
        break;
      case JarType.education:
        writer.writeByte(3);
        break;
      case JarType.play:
        writer.writeByte(4);
        break;
      case JarType.giving:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JarTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
