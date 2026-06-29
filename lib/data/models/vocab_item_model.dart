import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';

class VocabItemModel extends VocabItemEntity {
  const VocabItemModel({
    required super.word,
    required super.definition,
    super.ipa,
    super.wordType,
    super.exampleEn,
    super.exampleVi,
  });

  factory VocabItemModel.fromMap(Map<String, dynamic> map) {
    return VocabItemModel(
      word: map['word'] ?? '',
      definition: map['definition'] ?? '',
      ipa: map['ipa'],
      wordType: map['wordType'],
      exampleEn: map['exampleEn'],
      exampleVi: map['exampleVi'],
    );
  }
}
