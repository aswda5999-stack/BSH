// ==============================================================================
// الملف: lib/screens/quran_screen.dart
// الوظيفة: شاشة القرآن الكريم باستخدام حزمة flutter_quran كغلاف (Wrapper)
//          دون تعديل كود الحزمة، مع إظهار قائمة سفلية عند النقر على آية
//          تتيح: النسخ، المفضلة، المشاركة، التفسير، والاستماع لتلاوة الآية فقط.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quran/flutter_quran.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_state_provider.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _quranReady = false;

  @override
  void initState() {
    super.initState();
    _initQuran();
  }

  Future<void> _initQuran() async {
    try {
      await FlutterQuran.initialize();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _quranReady = true;
      });
    }
  }

  void _showAyahBottomSheet(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required String ayahText,
    String? tafsirText,
  }) {
    final String ayahKey = '$surahNumber:$ayahNumber';
    final String label = 'سورة $surahNumber • آية $ayahNumber';
    final AppStateProvider state = context.read<AppStateProvider>();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ayahText,
                  style: const TextStyle(fontSize: 17, height: 1.7),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ActionChip(
                      avatar: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: ayahText));
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ الآية')),
                          );
                        }
                      },
                    ),
                    Consumer<AppStateProvider>(
                      builder: (_, AppStateProvider s, __) {
                        final bool fav = s.isAyahFavorite(ayahKey);
                        return ActionChip(
                          avatar: Icon(
                            fav ? Icons.bookmark : Icons.bookmark_border,
                            size: 18,
                          ),
                          label: Text(fav ? 'في المفضلة' : 'مفضلة'),
                          onPressed: () => s.toggleFavoriteAyah(ayahKey),
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.share, size: 18),
                      label: const Text('مشاركة'),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await Share.share('$ayahText\n($label - أثر مسلم)');
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text('تفسير'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showDialog<void>(
                          context: context,
                          builder: (_) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: Text('تفسير • $label'),
                              content: SingleChildScrollView(
                                child: Text(
                                  (tafsirText != null && tafsirText.trim().isNotEmpty)
                                      ? tafsirText
                                      : 'الآية رقم $ayahNumber من السورة رقم $surahNumber. يمكنك مراجعة التفسير المعتمد لمتابعة المعاني التفصيلية.',
                                  style: const TextStyle(height: 1.7),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إغلاق'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('استماع'),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await state.playSingleAyah(
                          surahNumber: surahNumber,
                          ayahNumber: ayahNumber,
                          label: label,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider state = context.watch<AppStateProvider>();

    if (!_quranReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: <Widget>[
          if (state.isPlayingAyah)
            IconButton(
              tooltip: 'إيقاف التلاوة',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: state.stopSingleAyah,
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (state.isPlayingAyah && state.playingAyahLabel != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFB3E5FC),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'جاري الاستماع: ${state.playingAyahLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: state.stopSingleAyah,
                  ),
                ],
              ),
            ),
          Expanded(
            child: FlutterQuranScreen(
              onPageChanged: (int page) {
                state.saveLastQuranPage(page);
              },
              onAyahLongPress: (dynamic ayah) {
                final int surah = (ayah?.surahNumber as int?) ?? 1;
                final int verse = (ayah?.ayahNumber as int?) ?? 1;
                final String text = (ayah?.text as String?) ??
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
                final String? tafsir = ayah?.tafsir as String?;
                _showAyahBottomSheet(
                  context,
                  surahNumber: surah,
                  ayahNumber: verse,
                  ayahText: text,
                  tafsirText: tafsir,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
