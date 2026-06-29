import 'package:equatable/equatable.dart';

class FolderEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String creator;
  final String color;
  final String icon;
  final int lessonCount;
  final bool isOfficial;
  final DateTime createdAt;

  const FolderEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.creator,
    required this.color,
    required this.icon,
    required this.lessonCount,
    required this.isOfficial,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, creator, color, icon, lessonCount, isOfficial, createdAt];
}
