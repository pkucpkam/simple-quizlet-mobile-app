import 'package:equatable/equatable.dart';

class VocabItemEntity extends Equatable {
  final String word;
  final String definition;
  final String? ipa;
  final String? wordType;
  final String? exampleEn;
  final String? exampleVi;

  const VocabItemEntity({
    required this.word,
    required this.definition,
    this.ipa,
    this.wordType,
    this.exampleEn,
    this.exampleVi,
  });

  @override
  List<Object?> get props => [word, definition, ipa, wordType, exampleEn, exampleVi];
}
