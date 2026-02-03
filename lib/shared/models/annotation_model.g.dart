// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnotationTypeAdapter extends TypeAdapter<AnnotationType> {
  @override
  final int typeId = 1;

  @override
  AnnotationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnnotationType.highlight;
      case 1:
        return AnnotationType.bookmark;
      case 2:
        return AnnotationType.stickyNote;
      case 3:
        return AnnotationType.underline;
      case 4:
        return AnnotationType.strikethrough;
      default:
        return AnnotationType.highlight;
    }
  }

  @override
  void write(BinaryWriter writer, AnnotationType obj) {
    switch (obj) {
      case AnnotationType.highlight:
        writer.writeByte(0);
        break;
      case AnnotationType.bookmark:
        writer.writeByte(1);
        break;
      case AnnotationType.stickyNote:
        writer.writeByte(2);
        break;
      case AnnotationType.underline:
        writer.writeByte(3);
        break;
      case AnnotationType.strikethrough:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnotationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HighlightColorAdapter extends TypeAdapter<HighlightColor> {
  @override
  final int typeId = 2;

  @override
  HighlightColor read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HighlightColor.yellow;
      case 1:
        return HighlightColor.green;
      case 2:
        return HighlightColor.blue;
      case 3:
        return HighlightColor.pink;
      case 4:
        return HighlightColor.orange;
      default:
        return HighlightColor.yellow;
    }
  }

  @override
  void write(BinaryWriter writer, HighlightColor obj) {
    switch (obj) {
      case HighlightColor.yellow:
        writer.writeByte(0);
        break;
      case HighlightColor.green:
        writer.writeByte(1);
        break;
      case HighlightColor.blue:
        writer.writeByte(2);
        break;
      case HighlightColor.pink:
        writer.writeByte(3);
        break;
      case HighlightColor.orange:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnnotationModelAdapter extends TypeAdapter<AnnotationModel> {
  @override
  final int typeId = 3;

  @override
  AnnotationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnotationModel(
      id: fields[0] as String,
      documentId: fields[1] as String,
      type: fields[2] as AnnotationType,
      pageNumber: fields[3] as int,
      selectedText: fields[4] as String?,
      noteContent: fields[5] as String?,
      colorIndex: fields[6] as int,
      positionX: fields[7] as double?,
      positionY: fields[8] as double?,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      title: fields[11] as String?,
      startIndex: fields[12] as int?,
      endIndex: fields[13] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AnnotationModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.pageNumber)
      ..writeByte(4)
      ..write(obj.selectedText)
      ..writeByte(5)
      ..write(obj.noteContent)
      ..writeByte(6)
      ..write(obj.colorIndex)
      ..writeByte(7)
      ..write(obj.positionX)
      ..writeByte(8)
      ..write(obj.positionY)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.title)
      ..writeByte(12)
      ..write(obj.startIndex)
      ..writeByte(13)
      ..write(obj.endIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnotationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
