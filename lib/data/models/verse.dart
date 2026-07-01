class Verse {
  final int id;
  final int chapterNumber;
  final int verseNumber;
  final String textArabic;
  final String textEnglish;
  final String textUrdu;
  final String textTransliteration;

  Verse({
    required this.id,
    required this.chapterNumber,
    required this.verseNumber,
    required this.textArabic,
    required this.textEnglish,
    required this.textUrdu,
    required this.textTransliteration,
  });

  factory Verse.fromMap(Map<String, dynamic> map) {
    return Verse(
      id: map['id'] as int,
      chapterNumber: map['chapter_number'] as int,
      verseNumber: map['verse_number'] as int,
      textArabic: map['text_arabic'] as String,
      textEnglish: map['text_english'] as String,
      textUrdu: map['text_urdu'] as String,
      textTransliteration: map['text_transliteration'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_number': chapterNumber,
      'verse_number': verseNumber,
      'text_arabic': textArabic,
      'text_english': textEnglish,
      'text_urdu': textUrdu,
      'text_transliteration': textTransliteration,
    };
  }
}
