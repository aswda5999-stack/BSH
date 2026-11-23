// ==============================================================================
// الملف: lib/services/audio_service.dart
// الوظيفة: إدارة تشغيل تلاوات الآيات القرآنية عبر الإنترنت (just_audio)
//          وتشغيل أصوات الأذان (من الأصول المحلية لدعم قفل الشاشة) مع دعم
//          اختيار القارئ والمؤذن وتهيئة جلسة الصوت (audio_session).
// ==============================================================================

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class QariOption {
  final String id;
  final String name;
  final String serverFolder;

  const QariOption({
    required this.id,
    required this.name,
    required this.serverFolder,
  });
}

class MuadhinOption {
  final String id;
  final String name;
  final String assetPath;

  const MuadhinOption({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _ayahPlayer = AudioPlayer();
  final AudioPlayer _adhanPlayer = AudioPlayer();

  bool _sessionConfigured = false;

  static const List<QariOption> qaris = <QariOption>[
    QariOption(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      serverFolder: 'Alafasy_128kbps',
    ),
    QariOption(
      id: 'husary',
      name: 'محمود خليل الحصري',
      serverFolder: 'Husary_128kbps',
    ),
    QariOption(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      serverFolder: 'Minshawy_Murattal_128kbps',
    ),
    QariOption(
      id: 'sudais',
      name: 'عبد الرحمن السديس',
      serverFolder: 'Abdurrahmaan_As-Sudais_192kbps',
    ),
  ];

  static const List<MuadhinOption> muadhins = <MuadhinOption>[
    MuadhinOption(
      id: 'makkah',
      name: 'أذان مكة المكرمة',
      assetPath: 'assets/audio/adhan_makkah.mp3',
    ),
    MuadhinOption(
      id: 'madinah',
      name: 'أذان المدينة المنورة',
      assetPath: 'assets/audio/adhan_madinah.mp3',
    ),
    MuadhinOption(
      id: 'egypt',
      name: 'أذان مصر',
      assetPath: 'assets/audio/adhan_egypt.mp3',
    ),
  ];

  Future<void> _ensureAudioSession() async {
    if (_sessionConfigured) return;
    final AudioSession session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    _sessionConfigured = true;
  }

  /// بناء رابط صوتي لآية محددة فقط (مثل 001001.mp3 للسورة 1 والآية 1)
  String buildAyahAudioUrl({
    required int surahNumber,
    required int ayahNumber,
    required String qariId,
  }) {
    final QariOption qari = qaris.firstWhere(
      (QariOption item) => item.id == qariId,
      orElse: () => qaris.first,
    );
    final String surahStr = surahNumber.toString().padLeft(3, '0');
    final String ayahStr = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${qari.serverFolder}/$surahStr$ayahStr.mp3';
  }

  /// تشغيل تلاوة الآية المحددة فقط وإيقافها تلقائياً عند انتهائها
  Future<void> playSingleAyah({
    required int surahNumber,
    required int ayahNumber,
    required String qariId,
  }) async {
    await _ensureAudioSession();
    await _adhanPlayer.stop();

    final String url = buildAyahAudioUrl(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      qariId: qariId,
    );

    await _ayahPlayer.setUrl(url);
    await _ayahPlayer.play();
  }

  Future<void> stopAyah() async {
    await _ayahPlayer.stop();
  }

  /// تشغيل صوت الأذان المختار (يدعم العمل والشاشة مقفلة عبر audio_session + wake_lock)
  Future<void> playAdhan({required String muadhinId}) async {
    await _ensureAudioSession();
    await _ayahPlayer.stop();

    final MuadhinOption muadhin = muadhins.firstWhere(
      (MuadhinOption item) => item.id == muadhinId,
      orElse: () => muadhins.first,
    );

    await _adhanPlayer.setAsset(muadhin.assetPath);
    await _adhanPlayer.play();
  }

  Future<void> stopAdhan() async {
    await _adhanPlayer.stop();
  }

  Future<void> dispose() async {
    await _ayahPlayer.dispose();
    await _adhanPlayer.dispose();
  }
}
