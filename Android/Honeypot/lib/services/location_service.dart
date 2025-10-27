import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String name;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'],
    longitude: json['longitude'],
    name: json['name'],
  );
}

class LocationService {
  static const String _keyLatitude = 'weather_location_lat';
  static const String _keyLongitude = 'weather_location_lon';
  static const String _keyLocationName = 'weather_location_name';

  // Gespeicherten Standort laden
  Future<LocationData?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLatitude);
    final lon = prefs.getDouble(_keyLongitude);
    final name = prefs.getString(_keyLocationName);

    if (lat != null && lon != null) {
      return LocationData(
        latitude: lat,
        longitude: lon,
        name: name ?? 'Gespeicherter Standort',
      );
    }
    return null;
  }

  // Standort speichern
  Future<void> saveLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLatitude, location.latitude);
    await prefs.setDouble(_keyLongitude, location.longitude);
    await prefs.setString(_keyLocationName, location.name);
  }

  // GPS-Standort abrufen (deaktiviert - erfordert zusätzliches Package)
  Future<LocationData?> getCurrentLocation() async {
    throw Exception('GPS-Funktion ist in dieser Version nicht verfügbar. Bitte wähle eine Stadt aus der Liste.');
  }

  // Bekannte deutsche Städte für Schnellauswahl
  static List<LocationData> getPopularLocations() {
    return [
      LocationData(latitude: 52.5200, longitude: 13.4050, name: 'Berlin'),
      LocationData(latitude: 48.1351, longitude: 11.5820, name: 'München'),
      LocationData(latitude: 53.5511, longitude: 9.9937, name: 'Hamburg'),
      LocationData(latitude: 50.1109, longitude: 8.6821, name: 'Frankfurt'),
      LocationData(latitude: 51.2277, longitude: 6.7735, name: 'Düsseldorf'),
      LocationData(latitude: 50.9375, longitude: 6.9603, name: 'Köln'),
      LocationData(latitude: 48.7758, longitude: 9.1829, name: 'Stuttgart'),
      LocationData(latitude: 51.0504, longitude: 13.7373, name: 'Dresden'),
      LocationData(latitude: 52.3759, longitude: 9.7320, name: 'Hannover'),
      LocationData(latitude: 49.4521, longitude: 11.0767, name: 'Nürnberg'),
      LocationData(latitude: 51.3397, longitude: 12.3731, name: 'Leipzig'),
      LocationData(latitude: 53.0793, longitude: 8.8017, name: 'Bremen'),
    ];
  }
}
