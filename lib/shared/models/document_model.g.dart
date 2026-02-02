// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 0;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String,
      thumbnailPath: fields[3] as String?,
      fileSize: fields[4] as int,
      fileExtension: fields[5] as String,
      pageCount: fields[6] as int,
      currentPage: fields[7] as int,
      createdAt: fields[8] as DateTime,
      lastOpenedAt: fields[9] as DateTime,
      tags: (fields[10] as List).cast<String>(),
      folderId: fields[11] as String?,
      isFavorite: fields[12] as bool,
      lastZoomLevel: fields[13] as double,
      lastScrollPosition: fields[14] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.thumbnailPath)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.fileExtension)
      ..writeByte(6)
      ..write(obj.pageCount)
      ..writeByte(7)
      ..write(obj.currentPage)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastOpenedAt)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.folderId)
      ..writeByte(12)
      ..write(obj.isFavorite)
      ..writeByte(13)
      ..write(obj.lastZoomLevel)
      ..writeByte(14)
      ..write(obj.lastScrollPosition);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
