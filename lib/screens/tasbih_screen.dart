// ==============================================================================
// الملف: lib/screens/tasbih_screen.dart
// الوظيفة: شاشة المسبحة الإلكترونية البسيطة لعدّ التسبيح وتغيير الذكر
//          وتصفير العداد مع حفظ القيمة والذكر تلقائياً في SharedPreferences.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  static const List<String> _phrases = <String>[
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
  ];

  @override
  Widget build(BuildContext context) {
    final AppStateProvider state = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة الإلكترونية'),
        actions: <Widget>[
          IconButton(
            tooltip: 'تصفير العداد',
            icon: const Icon(Icons.refresh),
            onPressed: state.resetTasbih,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _phrases.map((String phrase) {
                final bool selected = state.tasbihPhrase == phrase;
                return ChoiceChip(
                  label: Text(phrase),
                  selected: selected,
                  selectedColor: const Color(0xFF81D4FA),
                  onSelected: (_) => state.setTasbihPhrase(phrase),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  children: <Widget>[
                    Text(
                      state.tasbihPhrase,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF01579B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${state.tasbihCount}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0288D1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: state.incrementTasbih,
                icon: const Icon(Icons.add_circle_outline, size: 28),
                label: const Text(
                  'سبّح',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

