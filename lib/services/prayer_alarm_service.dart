// ==============================================================================
// الملف: lib/services/prayer_alarm_service.dart
// الوظيفة: حساب مواقيت الصلاة الخمس فلكياً بدقة (أو استخدام المواقيت اليدوية
//          المحفوظة)، وجدولة منبهات الأذان عبر android_alarm_manager_plus
//          لتشغيل الأذان والإشعار حتى لو كانت الشاشة مقفلة.
// ==============================================================================

import 'dart:math' as math;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
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

  double _deg2rad(double deg) => deg * (math.pi / 180.0);
  double _rad2deg(double rad) => rad * (180.0 / math.pi);

  double _fixHour(double h) {
    double res = h % 24.0;
    if (res < 0) res += 24.0;
    return res;
  }

  double _fixAngle(double a) {
    double res = a % 360.0;
    if (res < 0) res += 360.0;
    return res;
  }

  DateTime _hoursToDateTime(DateTime baseDay, double hours) {
    final double wrapped = _fixHour(hours);
    final int totalMinutes = (wrapped * 60.0).round();
    final int h = (totalMinutes ~/ 60) % 24;
    final int m = totalMinutes % 60;
    return DateTime(baseDay.year, baseDay.month, baseDay.day, h, m);
  }

  /// حساب مواقيت اليوم من الإحداثيات فلكياً
  Map<PrayerName, DateTime> calculateFromCoordinates({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final DateTime targetDate = date ?? DateTime.now();
    final DateTime baseDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    final double tzOffsetHours = targetDate.timeZoneOffset.inMinutes / 60.0;
    final int dayOfYear = int.parse(
      '${targetDate.year.toString().padLeft(4, '0')}',
    ) *
        0 +
        targetDate.difference(DateTime(targetDate.year, 1, 1)).inDays +
        1;

    final double jd = _julianDate(targetDate.year, targetDate.month, targetDate.day) -
        longitude / (15.0 * 24.0);

    final List<double> eqDecl = _sunEquationOfTimeAndDeclination(jd);
    final double eqTime = eqDecl[0]; // بالدقائق
    final double decl = eqDecl[1]; // بالدرجات

    // الظهر (Dhuhr)
    final double dhuhrHours = 12.0 + tzOffsetHours - (longitude / 15.0) - (eqTime / 60.0);

    // زوايا الفجر والعشاء (رابطة العالم الإسلامي: 18° للفجر و 17° للعشاء)
    final double fajrHours = dhuhrHours - _hourAngleForAngle(latitude, decl, 18.0) / 15.0;
    final double sunsetHours = dhuhrHours + _hourAngleForAngle(latitude, decl, 0.833) / 15.0;
    final double ishaHours = dhuhrHours + _hourAngleForAngle(latitude, decl, 17.0) / 15.0;

    // العصر (المذهب الشافعي/الجمهور: ظل المثل = 1)
    final double latRad = _deg2rad(latitude);
    final double declRad = _deg2rad(decl);
    final double cotArg = 1.0 + math.tan((latRad - declRad).abs());
    final double asrAltDeg = _rad2deg(math.atan(1.0 / cotArg));
    final double asrHours = dhuhrHours + _hourAngleForAngle(latitude, decl, asrAltDeg) / 15.0;

    // لضمان عدم خروج العصر عن المغرب في خطوط العرض القصوى
    final double safeAsrHours = asrHours < sunsetHours ? asrHours : (dhuhrHours + sunsetHours) / 2.0;

    return <PrayerName, DateTime>{
      PrayerName.fajr: _hoursToDateTime(baseDay, fajrHours),
      PrayerName.dhuhr: _hoursToDateTime(baseDay, dhuhrHours),
      PrayerName.asr: _hoursToDateTime(baseDay, safeAsrHours),
      PrayerName.maghrib: _hoursToDateTime(baseDay, sunsetHours),
      PrayerName.isha: _hoursToDateTime(baseDay, ishaHours),
    };
  }

  double _julianDate(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final int a = (y / 100.0).floor();
    final int b = 2 - a + (a / 4.0).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  List<double> _sunEquationOfTimeAndDeclination(double jd) {
    final double d = jd - 2451545.0;
    final double g = _fixAngle(357.529 + 0.98560028 * d);
    final double q = _fixAngle(280.459 + 0.98564736 * d);
    final double l = _fixAngle(
      q + 1.915 * math.sin(_deg2rad(g)) + 0.020 * math.sin(_deg2rad(2 * g)),
    );

    final double e = 23.439 - 0.00000036 * d;
    final double ra = _rad2deg(
          math.atan2(
            math.cos(_deg2rad(e)) * math.sin(_deg2rad(l)),
            math.cos(_deg2rad(l)),
          ),
        ) /
        15.0;
    final double fixedRa = _fixHour(ra);

    final double decl = _rad2deg(
      math.asin(math.sin(_deg2rad(e)) * math.sin(_deg2rad(l))),
    );

    final double eqTime = (q / 15.0 - fixedRa) * 60.0;
    return <double>[eqTime, decl];
  }

  double _hourAngleForAngle(double latDeg, double declDeg, double angleDeg) {
    final double latRad = _deg2rad(latDeg);
    final double declRad = _deg2rad(declDeg);
    final double angleRad = _deg2rad(angleDeg);

    final double cosVal = (-math.sin(angleRad) - math.sin(latRad) * math.sin(declRad)) /
        (math.cos(latRad) * math.cos(declRad));

    final double clamped = cosVal.clamp(-1.0, 1.0);
    return _rad2deg(math.acos(clamped));
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
