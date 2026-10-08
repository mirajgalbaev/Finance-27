// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeModelAdapter extends TypeAdapter<TradeModel> {
  @override
  final int typeId = 9;

  @override
  TradeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradeModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      timeText: fields[2] as String,
      exchange: fields[3] as String,
      market: fields[4] as String,
      pair: fields[5] as String,
      type: fields[6] as String,
      leverage: fields[7] as String,
      capitalAllocated: fields[8] as double,
      entryPrice: fields[9] as double,
      exitPrice: fields[10] as double?,
      stopLoss: fields[11] as double?,
      takeProfit: fields[12] as double?,
      takeProfits: (fields[17] as List?)?.cast<double>(),
      buyTargets: (fields[18] as List?)?.cast<double>(),
      sellTargets: (fields[19] as List?)?.cast<double>(),
      pnlPercent: fields[13] as double?,
      pnlAmount: fields[14] as double?,
      notes: fields[15] as String?,
      exitDate: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TradeModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.timeText)
      ..writeByte(3)
      ..write(obj.exchange)
      ..writeByte(4)
      ..write(obj.market)
      ..writeByte(5)
      ..write(obj.pair)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.leverage)
      ..writeByte(8)
      ..write(obj.capitalAllocated)
      ..writeByte(9)
      ..write(obj.entryPrice)
      ..writeByte(10)
      ..write(obj.exitPrice)
      ..writeByte(11)
      ..write(obj.stopLoss)
      ..writeByte(12)
      ..write(obj.takeProfit)
      ..writeByte(13)
      ..write(obj.pnlPercent)
      ..writeByte(14)
      ..write(obj.pnlAmount)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.exitDate)
      ..writeByte(17)
      ..write(obj.takeProfits)
      ..writeByte(18)
      ..write(obj.buyTargets)
      ..writeByte(19)
      ..write(obj.sellTargets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
