// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_deposit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalDepositModelAdapter extends TypeAdapter<GoalDepositModel> {
  @override
  final int typeId = 6;

  @override
  GoalDepositModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalDepositModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      title: fields[3] == null ? 'Deposit' : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GoalDepositModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalDepositModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
