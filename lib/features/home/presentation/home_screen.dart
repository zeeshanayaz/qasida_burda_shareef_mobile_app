import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_service.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/verse.dart';

// Riverpod Provider to query and group Chapters and Verses
final qasidaDataProvider = FutureProvider<List<ChapterWithVerses>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final chaptersData = await dbService.getChapters();
  final versesData = await dbService.getAllVerses();

  final List<ChapterWithVerses> chaptersList = [];

  for (final chMap in chaptersData) {
    final chapterNumber = chMap['chapter_number'] as int;
    final chVersesMaps = versesData.where((v) => v['chapter_number'] == chapterNumber).toList();

    final List<Verse> verses = chVersesMaps.map((vMap) => Verse.fromMap(vMap)).toList();

    chaptersList.add(ChapterWithVerses(
      id: chMap['id'] as int,
      chapterNumber: chapterNumber,
      titleArabic: chMap['title_arabic'] as String,
      titleEnglish: chMap['title_english'] as String,
      titleUrdu: chMap['title_urdu'] as String,
      description: chMap['description'] as String?,
      verses: verses,
    ));
  }

  return chaptersList;
});

// UI State Providers for reading options
final showEnglishProvider = StateProvider<bool>((ref) => true);
final showUrduProvider = StateProvider<bool>((ref) => true);
final arabicFontSizeProvider = StateProvider<double>((ref) => 26.0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Map<int, GlobalKey> _chapterKeys = {};
  final ScrollController _scrollController = ScrollController();
  int _activeChapter = 1;

  void _scrollToChapter(int chapterNumber) {
    final key = _chapterKeys[chapterNumber];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      setState(() {
        _activeChapter = chapterNumber;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qasidaAsyncValue = ref.watch(qasidaDataProvider);
    final showEnglish = ref.watch(showEnglishProvider);
    final showUrdu = ref.watch(showUrduProvider);
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qasida Burda'),
        actions: [
          // Theme customization buttons (quick setting sheet)
          IconButton(
            icon: const Icon(Icons.text_format),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Text Settings',
          ),
        ],
      ),
      body: qasidaAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
        error: (err, stack) => Center(child: Text('Error loading data: $err')),
        data: (chaptersList) {
          if (chaptersList.isEmpty) {
            return const Center(child: Text('No data found in database.'));
          }

          return Column(
            children: [
              // Sticky Horizontal Chapter Selector Bar
              Container(
                height: 56,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: chaptersList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (context, index) {
                    final chapter = chaptersList[index];
                    final isActive = _activeChapter == chapter.chapterNumber;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('Chapter ${chapter.chapterNumber}'),
                        selected: isActive,
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isActive
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _scrollToChapter(chapter.chapterNumber);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Grouped Verses List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: chaptersList.length,
                  padding: const EdgeInsets.only(bottom: 40),
                  itemBuilder: (context, chapterIndex) {
                    final chapter = chaptersList[chapterIndex];
                    final chapterKey = _chapterKeys.putIfAbsent(
                      chapter.chapterNumber,
                      () => GlobalKey(),
                    );

                    return Column(
                      key: chapterKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chapter Header Banner
                        _buildChapterHeader(context, chapter),

                        // Chapter Verses
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chapter.verses.length,
                          itemBuilder: (context, verseIndex) {
                            final verse = chapter.verses[verseIndex];
                            return _buildVerseCard(
                              context,
                              verse,
                              showEnglish,
                              showUrdu,
                              arabicFontSize,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChapterHeader(BuildContext context, ChapterWithVerses chapter) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Chapter Number Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.goldAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'CHAPTER ${chapter.chapterNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkGreen,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Arabic Chapter Title
          Text(
            chapter.titleArabic,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.goldAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // English Title
          Text(
            chapter.titleEnglish,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Urdu Title
          Text(
            chapter.titleUrdu,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLightGreen,
            ),
            textAlign: TextAlign.center,
          ),

          if (chapter.description != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              chapter.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseCard(
    BuildContext context,
    Verse verse,
    bool showEnglish,
    bool showUrdu,
    double arabicFontSize,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verse Header Row (Number, Copy, Bookmark Actions)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Verse Number circular badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldAccent, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      verse.verseNumber.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldAccentDark,
                      ),
                    ),
                  ),
                ),
                // Copy/Action row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () {
                        final textToCopy = '${verse.textArabic}\n\n'
                            '${showUrdu ? "${verse.textUrdu}\n" : ""}'
                            '${showEnglish ? verse.textEnglish : ""}';
                        Clipboard.setData(ClipboardData(text: textToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Verse ${verse.verseNumber} copied to clipboard!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copy Verse',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Arabic Text
            Text(
              verse.textArabic,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: arabicFontSize,
                fontWeight: FontWeight.bold,
                height: 1.8,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),

            // Urdu Translation
            if (showUrdu) ...[
              const Divider(height: 12),
              const SizedBox(height: 8),
              Text(
                verse.textUrdu,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: AppColors.primaryLightGreen,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],

            // English Translation
            if (showEnglish) ...[
              const Divider(height: 12),
              const SizedBox(height: 8),
              Text(
                verse.textEnglish,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final showEnglish = ref.watch(showEnglishProvider);
            final showUrdu = ref.watch(showUrduProvider);
            final arabicFontSize = ref.watch(arabicFontSizeProvider);

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reader settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Arabic Font Size slider
                  Row(
                    children: [
                      const Text('Arabic Font Size:'),
                      Expanded(
                        child: Slider(
                          min: 20.0,
                          max: 36.0,
                          divisions: 8,
                          value: arabicFontSize,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) {
                            ref.read(arabicFontSizeProvider.notifier).state = value;
                          },
                        ),
                      ),
                      Text('${arabicFontSize.toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Translation Switch Toggles
                  SwitchListTile(
                    title: const Text('Show Urdu Translation'),
                    value: showUrdu,
                    onChanged: (value) {
                      ref.read(showUrduProvider.notifier).state = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Show English Translation'),
                    value: showEnglish,
                    onChanged: (value) {
                      ref.read(showEnglishProvider.notifier).state = value;
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
