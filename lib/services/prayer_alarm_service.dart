// ==============================================================================
// الملف: lib/services/prayer_alarm_service.dart
// الوظيفة: حساب مواقيت الصلاة الخمس عبر awqat (أو استخدام المواقيت اليدوية
//          المحفوظة)، وجدولة منبهات الأذان عبر android_alarm_manager_plus
//          لتشغيل الأذان والإشعار حتى لو كانت الشاشة مقفلة.
// ==============================================================================

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awqat/awqat.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_models.dart';
import 'audio_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> adhanAlarmCallback(int alarmId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String muadhinId = prefs.getString('selected_muadhin_id') ?? 'makkah';

  final PrayerName prayer = PrayerName.values.firstWhere(
    (PrayerName item) => item.alarmId == alarmId,
    orElse: () => PrayerName.fajr,
  );

  final MuadhinOption muadhin = AudioService.muadhins.firstWhere(
    (MuadhinOption item) => item.id == muadhinId,
    orElse: () => AudioService.muadhins.first,
  );

  await NotificationService.instance.showAdhanNotification(
    id: alarmId,
    prayerName: prayer.arabicName,
    muadhinName: muadhin.name,
  );

  await AudioService.instance.playAdhan(muadhinId: muadhinId);
}

class PrayerAlarmService {
  PrayerAlarmService._();
  static final PrayerAlarmService instance = PrayerAlarmService._();

  /// حساب مواقيت اليوم من الإحداثيات باستخدام حزمة awqat
  Map<PrayerName, DateTime> calculateFromCoordinates({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final DateTime targetDate = date ?? DateTime.now();
    final Awqat awqat = Awqat(
      latitude: latitude,
      longitude: longitude,
      date: targetDate,
      method: CalculationMethod.muslimWorldLeague,
    );

    final DateTime baseDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    DateTime toTodayDateTime(dynamic raw) {
      if (raw is DateTime) {
        return DateTime(
          baseDay.year,
          baseDay.month,
          baseDay.day,
          raw.hour,
          raw.minute,
        );
      }
      final String text = raw.toString();
      final RegExpMatch? match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
      if (match != null) {
        final int hour = int.tryParse(match.group(1) ?? '0') ?? 0;
        final int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
        return DateTime(baseDay.year, baseDay.month, baseDay.day, hour, minute);
      }
      return baseDay;
    }

    return <PrayerName, DateTime>{
      PrayerName.fajr: toTodayDateTime(awqat.fajr),
      PrayerName.dhuhr: toTodayDateTime(awqat.dhuhr),
      PrayerName.asr: toTodayDateTime(awqat.asr),
      PrayerName.maghrib: toTodayDateTime(awqat.maghrib),
      PrayerName.isha: toTodayDateTime(awqat.isha),
    };
  }

  /// تحويل المواقيت اليدوية إلى أوقات اليوم الحالي
  Map<PrayerName, DateTime> buildFromManual(
    Map<PrayerName, ManualPrayerTime> manualTimes, {
    DateTime? date,
  }) {
    final DateTime targetDate = date ?? DateTime.now();
    return <PrayerName, DateTime>{
      for (final PrayerName prayer in PrayerName.values)
        prayer: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          manualTimes[prayer]?.hour ?? 0,
          manualTimes[prayer]?.minute ?? 0,
        ),
    };
  }

  /// جدولة منبهات الأذان الخمسة بدقة (تعمل حتى مع قفل الشاشة)
  Future<void> scheduleAllPrayers(Map<PrayerName, DateTime> schedule) async {
    final DateTime now = DateTime.now();

    for (final PrayerName prayer in PrayerName.values) {
      DateTime? prayerTime = schedule[prayer];
      if (prayerTime == null) continue;

      if (!prayerTime.isAfter(now)) {
        prayerTime = prayerTime.add(const Duration(days: 1));
      }

      await AndroidAlarmManager.cancel(prayer.alarmId);
      await AndroidAlarmManager.oneShotAt(
        prayerTime,
        prayer.alarmId,
        adhanAlarmCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
    }
  }
}
