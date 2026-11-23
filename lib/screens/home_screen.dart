// ==============================================================================
// الملف: lib/screens/home_screen.dart
// الوظيفة: الشاشة الرئيسية لتطبيق "أثر مسلم"؛ تعرض شريط صور دواراً (10 صور)
//          يتبدل تلقائياً كل 4 ثوانٍ باستخدام carousel_slider، وبطاقة مواقيت
//          الصلاة الخمس مع زر حفظ الموقع الحالي وإيقاف صوت الأذان عند الحاجة.
// ==============================================================================

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../providers/app_state_provider.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<String> _sliderImages = <String>[
    'assets/images/slide_1.jpg',
    'assets/images/slide_2.jpg',
    'assets/images/slide_3.jpg',
    'assets/images/slide_4.jpg',
    'assets/images/slide_5.jpg',
    'assets/images/slide_6.jpg',
    'assets/images/slide_7.jpg',
    'assets/images/slide_8.jpg',
    'assets/images/slide_9.jpg',
    'assets/images/slide_10.jpg',
  ];

  static const List<String> _sliderTitles = <String>[
    'أثر مسلم • سكينة وطمأنينة',
    'القرآن الكريم رفيق القلب',
    'حافظ على صلواتك في أوقاتها',
    'ذكر الله حياة للقلوب',
    'تلاوات خاشعة بأصوات مختارة',
    'الأذان في وقته أينما كنت',
    'سبّح بحمد ربك بكرة وأصيلاً',
    'خطوة مباركة كل يوم',
    'بساطة ووضوح بلا تعقيد',
    'نسأل الله القبول والتوفيق',
  ];

  String _formatTime(DateTime dt) {
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider state = context.watch<AppStateProvider>();
    final PrayerSchedule schedule = state.todaySchedule;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أثر مسلم'),
        actions: <Widget>[
          IconButton(
            tooltip: 'إيقاف صوت الأذان',
            icon: const Icon(Icons.volume_off),
            onPressed: () async {
              await AudioService.instance.stopAdhan();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إيقاف صوت الأذان')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.saveCurrentLocationAndSchedule(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            CarouselSlider.builder(
              itemCount: _sliderImages.length,
              options: CarouselOptions(
                height: 190,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: true,
                viewportFraction: 0.92,
              ),
              itemBuilder: (BuildContext context, int index, int realIndex) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.asset(
                          _sliderImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color(0xFF4FC3F7),
                                  Color(0xFF0288D1),
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.mosque,
                                size: 54,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Text(
                            _sliderTitles[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'مواقيت الصلاة اليوم',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        Chip(
                          label: Text(
                            schedule.isManual ? 'إدخال يدوي' : 'حسب الموقع',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFFE1F5FE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final PrayerName prayer in PrayerName.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              prayer.arabicName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              schedule.timeFor(prayer) != null
                                  ? _formatTime(schedule.timeFor(prayer)!)
                                  : '--:--',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0288D1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: state.isUpdatingLocation
                          ? null
                          : () async {
                              await state.saveCurrentLocationAndSchedule();
                              if (context.mounted && state.statusMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.statusMessage!)),
                                );
                              }
                            },
                      icon: state.isUpdatingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        state.isUpdatingLocation
                            ? 'جاري تحديد الموقع...'
                            : 'حفظ الموقع الحالي وتحديث المواقيت',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
