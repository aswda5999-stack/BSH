// ==============================================================================
// الملف: lib/screens/settings_screen.dart
// الوظيفة: شاشة الإعدادات لتطبيق "أثر مسلم"؛ تتيح اختيار القارئ (الشيخ)
//          للتلاوات، اختيار صوت الأذان ومعاينته، التبديل بين الحساب التلقائي
//          عبر الموقع أو الإدخال اليدوي لمواقيت الصلاة الخمس، وحفظ جميع
//          الخيارات تلقائياً في SharedPreferences.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../providers/app_state_provider.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickPrayerTime(
    BuildContext context,
    AppStateProvider state,
    PrayerName prayer,
  ) async {
    final ManualPrayerTime current =
        state.manualTimes[prayer] ?? const ManualPrayerTime(hour: 12, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'تحديد وقت صلاة ${prayer.arabicName}',
    );

    if (picked != null) {
      await state.updateManualTime(prayer, picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider state = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'قارئ القرآن الكريم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: state.selectedQariId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: AudioService.qaris
                        .map(
                          (QariOption qari) => DropdownMenuItem<String>(
                            value: qari.id,
                            child: Text(qari.name),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        state.setQariId(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'صوت الأذان',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: state.selectedMuadhinId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: AudioService.muadhins
                        .map(
                          (MuadhinOption m) => DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        state.setMuadhinId(value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => AudioService.instance.playAdhan(
                            muadhinId: state.selectedMuadhinId,
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('تجربة صوت الأذان'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: AudioService.instance.stopAdhan,
                        icon: const Icon(Icons.stop),
                        label: const Text('إيقاف'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'إدخال مواقيت الصلاة يدوياً',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF01579B),
                      ),
                    ),
                    subtitle: Text(
                      state.useManualTimes
                          ? 'يتم الاعتماد على المواقيت المدخلة يدوياً'
                          : 'يتم الحساب تلقائياً حسب الموقع المحفوظ',
                    ),
                    value: state.useManualTimes,
                    onChanged: state.setUseManualTimes,
                  ),
                  if (state.useManualTimes) ...<Widget>[
                    const Divider(),
                    for (final PrayerName prayer in PrayerName.values)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(prayer.arabicName),
                        trailing: TextButton.icon(
                          onPressed: () =>
                              _pickPrayerTime(context, state, prayer),
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            state.manualTimes[prayer]?.formatted ?? '00:00',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
