// ==============================================================================
// الملف: lib/services/location_service.dart
// الوظيفة: التعامل مع نظام تحديد المواقع (GPS)، جلب الإحداثيات الحالية،
//          وحفظها محلياً عبر SharedPreferences لاستخدامها في حساب مواقيت الصلاة.
// ==============================================================================

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String keyLatitude = 'user_latitude';
  static const String keyLongitude = 'user_longitude';

  /// التحقق من صلاحيات الموقع وتفعيل الخدمة
  Future<bool> _handleLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// جلب الموقع الحالي وحفظه في SharedPreferences
  Future?> getCurrentLocation() async {
    final bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(keyLatitude, position.latitude);
      await prefs.setDouble(keyLongitude, position.longitude);

      return <String, double>{
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (_) {
      return null;
    }
  }

  /// استرجاع الإحداثيات المخزنة مسبقاً
  Future?> getSavedLocation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble(keyLatitude);
    final double? lng = prefs.getDouble(keyLongitude);

    if (lat != null && lng != null) {
      return <String, double>{
        'latitude': lat,
        'longitude': lng,
      };
    }
    return null;
  }
}

