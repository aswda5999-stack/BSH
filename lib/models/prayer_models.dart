// ==============================================================================
// الملف: lib/models/prayer_models.dart
// الوظيفة: تعريف نماذج البيانات البسيطة لمواقيت الصلاة الخمس، المواقيت
//          اليدوية، وجدول الصلاة اليومي.
// ==============================================================================

enum PrayerName {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  int get alarmId {
    switch (this) {
      case PrayerName.fajr:
        return 1001;
      case PrayerName.dhuhr:
        return 1002;
      case PrayerName.asr:
        return 1003;
      case PrayerName.maghrib:
        return 1004;
      case PrayerName.isha:
        return 1005;
    }
  }
}

class ManualPrayerTime {
  final int hour;
  final int minute;

  const ManualPrayerTime({
    required this.hour,
    required this.minute,
  });

  String get formatted {
    final String h = hour.toString().padLeft(2, '0');
    final String m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, int> toJson() => <String, int>{
        'hour': hour,
        'minute': minute,
      };

  factory ManualPrayerTime.fromJson(Map<String, dynamic> json) {
    return ManualPrayerTime(
      hour: (json['hour'] as int?) ?? 0,
      minute: (json['minute'] as int?) ?? 0,
    );
  }
}

class PrayerSchedule {
  final Map<PrayerName, DateTime> times;
  final bool isManual;

  const PrayerSchedule({
    required this.times,
    required this.isManual,
  });

  DateTime? timeFor(PrayerName prayer) => times[prayer];
}

