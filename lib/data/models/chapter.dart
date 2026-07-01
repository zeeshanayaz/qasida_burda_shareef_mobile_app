import 'verse.dart';

class ChapterWithVerses {
  final int id;
  final int chapterNumber;
  final String titleArabic;
  final String titleEnglish;
  final String titleUrdu;
  final String? description;
  final List<Verse> verses;

  ChapterWithVerses({
    required this.id,
    required this.chapterNumber,
    required this.titleArabic,
    required this.titleEnglish,
    required this.titleUrdu,
    this.description,
    required this.verses,
  });

  factory ChapterWithVerses.fromMap(Map<String, dynamic> map, List<Verse> verses) {
    return ChapterWithVerses(
      id: map['id'] as int,
      chapterNumber: map['chapter_number'] as int,
      titleArabic: map['title_arabic'] as String,
      titleEnglish: map['title_english'] as String,
      titleUrdu: map['title_urdu'] as String,
      description: map['description'] as String?,
      verses: verses,
    );
  }
}
