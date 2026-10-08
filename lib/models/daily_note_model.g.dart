// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyNoteModelAdapter extends TypeAdapter<DailyNoteModel> {
  @override
  final int typeId = 8;

  @override
  DailyNoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyNoteModel(
      dateKey: fields[0] as String,
      text: fields[1] as String,
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DailyNoteModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyNoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
