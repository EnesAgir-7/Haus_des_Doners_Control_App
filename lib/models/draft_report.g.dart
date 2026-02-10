// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DraftReportAdapter extends TypeAdapter<DraftReport> {
  @override
  final int typeId = 0;

  @override
  DraftReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DraftReport(
      branchId: fields[0] as String,
      branchTemplateId: fields[1] as String,
      scores: (fields[2] as Map).cast<String, int>(),
      notes: (fields[3] as Map).cast<String, String>(),
      photoPaths: (fields[4] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      inspectorSignaturePath: fields[5] as String?,
      branchSignaturePath: fields[6] as String?,
      overallNotes: fields[7] as String?,
      enabledCategories: (fields[8] as Map).cast<String, bool>(),
      savedAt: fields[9] as DateTime,
      branchRepName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DraftReport obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.branchId)
      ..writeByte(1)
      ..write(obj.branchTemplateId)
      ..writeByte(2)
      ..write(obj.scores)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.photoPaths)
      ..writeByte(5)
      ..write(obj.inspectorSignaturePath)
      ..writeByte(6)
      ..write(obj.branchSignaturePath)
      ..writeByte(7)
      ..write(obj.overallNotes)
      ..writeByte(8)
      ..write(obj.enabledCategories)
      ..writeByte(9)
      ..write(obj.savedAt)
      ..writeByte(10)
      ..write(obj.branchRepName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
