import 'package:flutter/material.dart';
import '../services/varroa_weather_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class VarroaWeatherScreen extends StatefulWidget {
  final AuthService authService;

  const VarroaWeatherScreen({super.key, required this.authService});

  @override
  State<VarroaWeatherScreen> createState() => _VarroaWeatherScreenState();
}

class _VarroaWeatherScreenState extends State<VarroaWeatherScreen> {
  final VarroaWeatherService _weatherService = VarroaWeatherService();
  final LocationService _locationService = LocationService();
  List<WeatherData> _forecast = [];
  List<VarroaTreatment> _treatments = [];
  bool _isLoading = true;
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);

    try {
      // Lade gespeicherten Standort oder frage nach
      LocationData? location = await _locationService.getSavedLocation();
      
      if (location == null) {
        // Zeige Standort-Auswahl-Dialog beim ersten Mal
        location = await _showLocationSelectionDialog();
        if (location == null) {
          // User hat abgebrochen, nutze Default (München)
          location = LocationData(latitude: 48.1351, longitude: 11.5820, name: 'München');
        }
        await _locationService.saveLocation(location);
      }

      setState(() => _currentLocation = location);
      
      final forecast = await _weatherService.fetch5DayForecast(location.latitude, location.longitude);
      
      // Berechne Durchschnittstemperatur und Regen
      final avgTemp = forecast.map((w) => w.temperature).reduce((a, b) => a + b) / forecast.length;
      final hasRain = forecast.any((w) => w.condition == 'rain' || w.condition == 'storm');

      final treatments = VarroaWeatherService.getRecommendedTreatments(
        avgTemp, 
        hasRain, 
        DateTime.now(),
      );

      setState(() {
        _forecast = forecast;
        _treatments = treatments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'storm':
        return Icons.flash_on;
      default:
        return Icons.cloud;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition) {
      case 'clear':
        return Colors.orange;
      case 'cloudy':
        return Colors.grey;
      case 'rain':
        return Colors.blue;
      case 'storm':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBestTreatmentTime() {
    if (!_isPremiumUser()) {
      _showPremiumDialog();
      return;
    }

    final recommendation = _weatherService.getBestTreatmentTime(_forecast);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌟 Bester Behandlungszeitpunkt'),
        content: Text(recommendation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyPlan() {
    if (!_isPremiumUser()) {
      _showPremiumDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Notfallplan'),
        content: SingleChildScrollView(
          child: Text(_weatherService.getEmergencyPlan()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Diese Funktion ist nur für Premium-Mitglieder verfügbar.\n\n'
          'Upgrade auf Premium für:\n'
          '• Behandlungs-Erinnerungen\n'
          '• Notfallpläne\n'
          '• Cloud-Backup\n'
          '• Und vieles mehr!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Premium-Upgrade-Screen öffnen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium-Upgrade in Entwicklung')),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  bool _isPremiumUser() {
    final user = widget.authService.currentUser;
    return user?.role == 'premium' || user?.role == 'admin';
  }

  Future<LocationData?> _showLocationSelectionDialog() async {
    return showDialog<LocationData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Standort wählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wähle deinen Standort für die Wettervorhersage:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final location = await _locationService.getCurrentLocation();
                  if (context.mounted) Navigator.pop(context, location);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('GPS verwenden'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final location = await _showCitySelection();
                if (context.mounted && location != null) {
                  Navigator.pop(context, location);
                }
              },
              icon: const Icon(Icons.edit_location),
              label: const Text('PLZ/Ort eingeben'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<LocationData?> _showCitySelection() async {
    final plzController = TextEditingController();
    final ortController = TextEditingController();
    
    return showDialog<LocationData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standort eingeben'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plzController,
              decoration: const InputDecoration(
                labelText: 'Postleitzahl',
                hintText: 'z.B. 10115',
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ortController,
              decoration: const InputDecoration(
                labelText: 'Ort',
                hintText: 'z.B. Berlin',
                prefixIcon: Icon(Icons.location_city),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final plz = plzController.text.trim();
              final ort = ortController.text.trim();
              
              if (plz.isEmpty || ort.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bitte fülle beide Felder aus')),
                );
                return;
              }
              
              if (plz.length != 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Postleitzahl muss 5 Ziffern haben')),
                );
                return;
              }
              
              // Hole Koordinaten über OpenWeatherMap Geocoding API
              try {
                final coords = await _weatherService.getCoordinatesFromPostalCode(plz, ort, 'DE');
                if (coords != null && context.mounted) {
                  Navigator.pop(context, LocationData(
                    latitude: coords['lat']!,
                    longitude: coords['lon']!,
                    name: '$plz $ort',
                  ));
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Standort konnte nicht gefunden werden')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLocation() async {
    final newLocation = await _showLocationSelectionDialog();
    if (newLocation != null) {
      await _locationService.saveLocation(newLocation);
      _loadWeatherData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐝 Varroa Wetter'),
            if (_currentLocation != null)
              Text(
                _currentLocation!.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _changeLocation,
            tooltip: 'Standort ändern',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeatherData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Wettervorhersage
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '5-Tage Wettervorhersage',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _forecast.length,
                              itemBuilder: (context, i) {
                                final weather = _forecast[i];
                                return Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    children: [
                                      Text(
                                        VarroaWeatherService.formatDateWithWeekday(weather.date),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 8),
                                      Icon(
                                        _getWeatherIcon(weather.condition),
                                        size: 40,
                                        color: _getWeatherColor(weather.condition),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${weather.temperature.toStringAsFixed(0)}°C',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Premium Features
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                'Premium Features',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showBestTreatmentTime,
                            icon: const Icon(Icons.event),
                            label: const Text('Bester Behandlungszeitpunkt'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showEmergencyPlan,
                            icon: const Icon(Icons.warning),
                            label: const Text('Notfallplan anzeigen'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Behandlungsempfehlungen
                  const Text(
                    'Empfohlene Behandlungen',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_treatments.isEmpty)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Keine passenden Behandlungen für aktuelles Wetter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bei den aktuellen Wetterbedingungen sind keine Behandlungen empfohlen. Nutze die Zeit für Gemüllkontrollen oder warte auf besseres Wetter.',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ..._treatments.map((treatment) {
                    final isSuitable = treatment.suitableForWeather;
                    final isEcological = treatment.category == 'ecological';

                    return Card(
                      color: isSuitable
                          ? Colors.green.shade50
                          : isEcological
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                      child: ExpansionTile(
                        leading: Icon(
                          isEcological ? Icons.eco : Icons.science,
                          color: isSuitable
                              ? Colors.green
                              : isEcological
                                  ? Colors.blue
                                  : Colors.grey.shade700,
                          size: 30,
                        ),
                        title: Text(
                          treatment.classicTreatment,
                          style: TextStyle(
                            fontWeight: isSuitable ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              treatment.weatherConditions,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (isSuitable)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Optimal für aktuelles Wetter',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  Icons.eco_outlined,
                                  'Schonende Alternative',
                                  treatment.gentleAlternative,
                                  Colors.green.shade700,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.lightbulb_outline,
                                  'Empfehlung',
                                  treatment.recommendation,
                                  Colors.orange.shade700,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.info_outline,
                                  'Grund',
                                  treatment.reason,
                                  Colors.blue.shade700,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

  // Info-Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Hinweise',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Alle Behandlungen sind in der EU zugelassen. Tippe auf eine Behandlung um Details zu sehen.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.eco, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              const Text('Ökologische/Biotechnische Methoden', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.science, color: Colors.grey.shade700, size: 18),
                              const SizedBox(width: 8),
                              const Text('Säurebasierte Behandlungen', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Optimal für aktuelles Wetter',
                                  style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
