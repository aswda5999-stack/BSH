// ==============================================================================
// الملف: lib/services/notification_service.dart
// الوظيفة: تهيئة الإشعارات المحلية على Android وعرض إشعارات الأذان
//          بأولوية عالية عند دخول وقت الصلاة.
// ==============================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String adhanChannelId = 'athar_muslim_adhan_channel';
  static const String adhanChannelName = 'تنبيهات الأذان';
  static const String adhanChannelDescription =
      'إشعارات دخول أوقات الصلاة والأذان في أثر مسلم';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      adhanChannelId,
      adhanChannelName,
      description: adhanChannelDescription,
      importance: Importance.max,
      playSound: false, // تشغيل الصوت يتم عبر AudioService لدعم قفل الشاشة
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(adhanChannel);
    _initialized = true;
  }

  Future<void> showAdhanNotification({
    required int id,
    required String prayerName,
    required String muadhinName,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      adhanChannelId,
      adhanChannelName,
      channelDescription: adhanChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id,
      'حان الآن موعد أذان $prayerName',
      'أثر مسلم • بصوت المؤذن: $muadhinName',
      details,
    );
  }
}

