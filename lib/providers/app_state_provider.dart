// ==============================================================================
// الملف: lib/providers/app_state_provider.dart
// الوظيفة: إدارة حالة التطبيق المركزية وحفظ جميع الإعدادات محلياً عبر
//          SharedPreferences (القارئ، المؤذن، الموقع، المواقيت اليدوية،
//          آخر صفحة قرآنية، الآيات المفضلة، وعداد المسبحة) وجدولة الأذان.
// ==============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_models.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';
import '../services/prayer_alarm_service.dart';

class AppStateProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final LocationService _locationService = LocationService();

  static const String _keyQariId = 'selected_qari_id';
  static const String _keyMuadhinId = 'selected_muadhin_id';
  static const String _keyUseManualTimes = 'use_manual_prayer_times';
  static const String _keyManualTimesJson = 'manual_prayer_times_json';
  static const String _keyLastQuranPage = 'last_quran_page';
  static const String _keyFavoriteAyahs = 'favorite_ayahs';
  static const String _keyTasbihCount = 'tasbih_count';
  static const String _keyTasbihPhrase = 'tasbih_phrase';

  AppStateProvider(this._prefs) {
    _loadInitialState();
  }

  int _navIndex = 0;
  int get navIndex => _navIndex;

  String _selectedQariId = 'alafasy';
  String get selectedQariId => _selectedQariId;

  String _selectedMuadhinId = 'makkah';
  String get selectedMuadhinId => _selectedMuadhinId;

  bool _useManualTimes = false;
  bool get useManualTimes => _useManualTimes;

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  bool _isUpdatingLocation = false;
  bool get isUpdatingLocation => _isUpdatingLocation;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  Map<PrayerName, ManualPrayerTime> _manualTimes =
      const <PrayerName, ManualPrayerTime>{
    PrayerName.fajr: ManualPrayerTime(hour: 5, minute: 0),
    PrayerName.dhuhr: ManualPrayerTime(hour: 12, minute: 15),
    PrayerName.asr: ManualPrayerTime(hour: 15, minute: 15),
    PrayerName.maghrib: ManualPrayerTime(hour: 17, minute: 30),
    PrayerName.isha: ManualPrayerTime(hour: 19, minute: 0),
  };
  Map<PrayerName, ManualPrayerTime> get manualTimes => _manualTimes;

  int _lastQuranPage = 1;
  int get lastQuranPage => _lastQuranPage;

  List<String> _favoriteAyahs = <String>[];
  List<String> get favoriteAyahs => List<String>.unmodifiable(_favoriteAyahs);

  int _tasbihCount = 0;
  int get tasbihCount => _tasbihCount;

  String _tasbihPhrase = 'سبحان الله';
  String get tasbihPhrase => _tasbihPhrase;

  bool _isPlayingAyah = false;
  bool get isPlayingAyah => _isPlayingAyah;

  String? _playingAyahLabel;
  String? get playingAyahLabel => _playingAyahLabel;

  Future<void> _loadInitialState() async {
    _selectedQariId = _prefs.getString(_keyQariId) ?? 'alafasy';
    _selectedMuadhinId = _prefs.getString(_keyMuadhinId) ?? 'makkah';
    _useManualTimes = _prefs.getBool(_keyUseManualTimes) ?? false;
    _lastQuranPage = _prefs.getInt(_keyLastQuranPage) ?? 1;
    _favoriteAyahs = _prefs.getStringList(_keyFavoriteAyahs) ?? <String>[];
    _tasbihCount = _prefs.getInt(_keyTasbihCount) ?? 0;
    _tasbihPhrase = _prefs.getString(_keyTasbihPhrase) ?? 'سبحان الله';

    final Map<String, double>? savedLoc = await _locationService.getSavedLocation();
    if (savedLoc != null) {
      _latitude = savedLoc['latitude'];
      _longitude = savedLoc['longitude'];
    }

    final String? rawManual = _prefs.getString(_keyManualTimesJson);
    if (rawManual != null && rawManual.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(rawManual) as Map<String, dynamic>;
        final Map<PrayerName, ManualPrayerTime> loaded =
            <PrayerName, ManualPrayerTime>{};
        for (final PrayerName prayer in PrayerName.values) {
          final dynamic entry = decoded[prayer.name];
          if (entry is Map<String, dynamic>) {
            loaded[prayer] = ManualPrayerTime.fromJson(entry);
          } else {
            loaded[prayer] = _manualTimes[prayer]!;
          }
        }
        _manualTimes = loaded;
      } catch (_) {}
    }

    notifyListeners();
    await reschedulePrayers();
  }

  void setNavIndex(int index) {
    _navIndex = index;
    notifyListeners();
  }

  Future<void> setQariId(String qariId) async {
    _selectedQariId = qariId;
    await _prefs.setString(_keyQariId, qariId);
    notifyListeners();
  }

  Future<void> setMuadhinId(String muadhinId) async {
    _selectedMuadhinId = muadhinId;
    await _prefs.setString(_keyMuadhinId, muadhinId);
    notifyListeners();
    await reschedulePrayers();
  }

  Future<void> setUseManualTimes(bool value) async {
    _useManualTimes = value;
    await _prefs.setBool(_keyUseManualTimes, value);
    notifyListeners();
    await reschedulePrayers();
  }

  Future<void> updateManualTime(PrayerName prayer, int hour, int minute) async {
    final Map<PrayerName, ManualPrayerTime> updated =
        Map<PrayerName, ManualPrayerTime>.from(_manualTimes);
    updated[prayer] = ManualPrayerTime(hour: hour, minute: minute);
    _manualTimes = updated;

    final Map<String, dynamic> encodedMap = <String, dynamic>{
      for (final MapEntry<PrayerName, ManualPrayerTime> e in _manualTimes.entries)
        e.key.name: e.value.toJson(),
    };
    await _prefs.setString(_keyManualTimesJson, jsonEncode(encodedMap));
    notifyListeners();

    if (_useManualTimes) {
      await reschedulePrayers();
    }
  }

  Future<bool> saveCurrentLocationAndSchedule() async {
    _isUpdatingLocation = true;
    _statusMessage = null;
    notifyListeners();

    final Map<String, double>? coords = await _locationService.getCurrentLocation();
    _isUpdatingLocation = false;

    if (coords == null) {
      _statusMessage = 'تعذر جلب الموقع؛ تأكد من تفعيل GPS ومنح الصلاحية.';
      notifyListeners();
      return false;
    }

    _latitude = coords['latitude'];
    _longitude = coords['longitude'];
    _useManualTimes = false;
    await _prefs.setBool(_keyUseManualTimes, false);
    _statusMessage = 'تم حفظ الموقع وتحديث مواقيت الصلاة تلقائياً.';
    notifyListeners();

    await reschedulePrayers();
    return true;
  }

  PrayerSchedule get todaySchedule {
    if (_useManualTimes) {
      return PrayerSchedule(
        times: PrayerAlarmService.instance.buildFromManual(_manualTimes),
        isManual: true,
      );
    }

    final double lat = _latitude ?? 36.2021;
    final double lng = _longitude ?? 37.1343;
    return PrayerSchedule(
      times: PrayerAlarmService.instance.calculateFromCoordinates(
        latitude: lat,
        longitude: lng,
      ),
      isManual: false,
    );
  }

  Future<void> reschedulePrayers() async {
    final PrayerSchedule schedule = todaySchedule;
    await PrayerAlarmService.instance.scheduleAllPrayers(schedule.times);
  }

  Future<void> saveLastQuranPage(int page) async {
    _lastQuranPage = page;
    await _prefs.setInt(_keyLastQuranPage, page);
    notifyListeners();
  }

  bool isAyahFavorite(String ayahKey) => _favoriteAyahs.contains(ayahKey);

  Future<void> toggleFavoriteAyah(String ayahKey) async {
    if (_favoriteAyahs.contains(ayahKey)) {
      _favoriteAyahs.remove(ayahKey);
    } else {
      _favoriteAyahs.add(ayahKey);
    }
    await _prefs.setStringList(_keyFavoriteAyahs, _favoriteAyahs);
    notifyListeners();
  }

  Future<void> playSingleAyah({
    required int surahNumber,
    required int ayahNumber,
    required String label,
  }) async {
    _isPlayingAyah = true;
    _playingAyahLabel = label;
    notifyListeners();

    try {
      await AudioService.instance.playSingleAyah(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        qariId: _selectedQariId,
      );
    } finally {
      _isPlayingAyah = false;
      _playingAyahLabel = null;
      notifyListeners();
    }
  }

  Future<void> stopSingleAyah() async {
    await AudioService.instance.stopAyah();
    _isPlayingAyah = false;
    _playingAyahLabel = null;
    notifyListeners();
  }

  Future<void> incrementTasbih() async {
    _tasbihCount += 1;
    await _prefs.setInt(_keyTasbihCount, _tasbihCount);
    notifyListeners();
  }

  Future<void> resetTasbih() async {
    _tasbihCount = 0;
    await _prefs.setInt(_keyTasbihCount, 0);
    notifyListeners();
  }

  Future<void> setTasbihPhrase(String phrase) async {
    _tasbihPhrase = phrase;
    await _prefs.setString(_keyTasbihPhrase, phrase);
    notifyListeners();
  }
}

