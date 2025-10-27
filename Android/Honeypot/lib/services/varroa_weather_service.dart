import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final DateTime date;
  final double temperature;
  final String condition; // 'clear', 'cloudy', 'rain', 'storm'
  final String icon;

  WeatherData({
    required this.date,
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}

class VarroaTreatment {
  final String classicTreatment;
  final String gentleAlternative;
  final String recommendation;
  final String reason;
  final String weatherConditions;
  final bool suitableForWeather;
  final String category; // 'acid' or 'ecological'

  VarroaTreatment({
    required this.classicTreatment,
    required this.gentleAlternative,
    required this.recommendation,
    required this.reason,
    required this.weatherConditions,
    required this.suitableForWeather,
    required this.category,
  });
}

class VarroaWeatherService {
  // OpenWeatherMap API
  static const String _apiKey = 'a6f70bd757dc120e21c403aea2cc5469';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0/zip';

  // EU-zugelassene Varroa-Behandlungen: Säuren vs. Pflanzlich
  static List<VarroaTreatment> getAllTreatments() {
    return [
      // SOMMERBEHANDLUNG (20-30°C)
      VarroaTreatment(
        classicTreatment: 'Ameisensäure 60% (Nassenheider, Liebig-Dispenser)',
        gentleAlternative: 'Thymian (Thymus vulgaris)',
        recommendation: 'Pro Zarge: 3-4 frische Thymianzweige (ca. 20-30cm Länge) schräg auf die Oberträger legen. Alle 5-7 Tage erneuern. Besonders effektiv: Echter Thymian, Zitronenthymian oder Quendel (Thymus serpyllum). Wichtig: Nicht alle Thymiansorten enthalten ausreichend Thymol - Echter Thymian hat 40-60% Thymolgehalt, Zitronenthymian 30-40%, Kümmelthymian bis zu 70%. Im Zweifelsfall: Getrockneten Thymian aus der Apotheke nutzen.',
        reason: 'Thymol verdampft bei Wärme und verteilt sich in der Beute. Die Milben werden durch die ätherischen Öle getötet oder gelähmt und fallen ab. Thymian ist absolut natürlich, hinterlässt keine Rückstände im Honig und stört die Bienen kaum. Die Methode ist seit Jahrhunderten bekannt und in der ökologischen Imkerei etabliert.',
        weatherConditions: '20-30°C, warm und trocken',
        suitableForWeather: true,
        category: 'both',
      ),
      
      // ALTERNATIVE SOMMERBEHANDLUNG
      VarroaTreatment(
        classicTreatment: 'Milchsäure 15% (Sprühbehandlung)',
        gentleAlternative: 'Lavendel + Salbei Mischung',
        recommendation: 'Je Zarge: 2 Lavendelzweige + 2 Salbeizweige zwischen den Waben verteilen. Kombination steigert die Wirkung. Wechsel alle 7 Tage. Besonders Echter Lavendel (Lavandula angustifolia) und Echter Salbei (Salvia officinalis) haben hohen Gehalt an varroa-wirksamen Ätherischen Ölen.',
        reason: 'Lavendel enthält Linalool und Kampfer, Salbei Thujon und Kampfer. Die Kombination verschiedener ätherischer Öle verstärkt die Wirkung gegen Varroa. Beide Pflanzen sind bienenfreundlich und können sogar als Trachtpflanzen dienen.',
        weatherConditions: '18-28°C, sonnig',
        suitableForWeather: true,
        category: 'both',
      ),
      
      // WINTERBEHANDLUNG (unter 10°C, brutfrei)
      VarroaTreatment(
        classicTreatment: 'Oxalsäure 3,5% (Träufelmethode)',
        gentleAlternative: 'Drohnenbrut schneiden (präventiv im Sommer)',
        recommendation: 'Im Sommer konsequent alle 3 Wochen Drohnenbrut entfernen. Drohnenwaben am Rand einsetzen (Varroa bevorzugt Randwaben). Nach Verdeckelung ausschneiden und einschmelzen. Reduktion des Varroabefalls um bis zu 70% möglich.',
        reason: 'Drohnenbrut hat eine längere Entwicklungszeit (24 Tage) als Arbeiterinnenbrut (21 Tage). Varroa-Milben bevorzugen Drohnenbrut, da sie dort mehr Nachkommen produzieren können. Durch regelmäßiges Entfernen wird der Vermehrungszyklus unterbrochen. Chemiefrei und zu 100% natürlich.',
        weatherConditions: 'Vorbeugung im Sommer für Winter',
        suitableForWeather: true,
        category: 'acid',
      ),
      
      // GANZJÄHRIG BIO-TECHNISCH
      VarroaTreatment(
        classicTreatment: 'Ameisensäure Langzeitbehandlung',
        gentleAlternative: 'Brutentnahme + Kräutercocktail',
        recommendation: 'Brutpause erzwingen durch Brutentnahme (Mai-Juni). Entnommene Brutwaben für Ableger nutzen. Sowohl Muttervolk als auch Ableger mit frischem Kräutercocktail eindecken: Pro Zarge 3 Thymianzweige + 2 Lavendelzweige + 2 Salbeizweige. Die Kombination verschiedener ätherischer Öle verstärkt die Wirkung massiv. Alle 5-7 Tage erneuern. Wirksamkeit: bis zu 95% Milbenreduktion - komplett chemiefrei!',
        reason: 'Varroa vermehrt sich nur in verdeckelter Brut. Eine Brutpause unterbricht den Zyklus komplett. Während dieser Phase sind alle Milben außerhalb der Brut und damit maximal anfällig für ätherische Öle. Der Kräutercocktail aus Thymian (Thymol), Lavendel (Linalool) und Salbei (Thujon) bietet einen mehrschichtigen Angriff auf die Milben. Gleichzeitig vermehrt man seine Völkerzahl und bleibt komplett säurefrei.',
        weatherConditions: 'Mai-Juni, während Tracht',
        suitableForWeather: true,
        category: 'acid',
      ),
      
      // DIAGNOSE/PRÜFUNG
      VarroaTreatment(
        classicTreatment: 'Gemüllwindel-Kontrolle',
        gentleAlternative: 'Puderzucker-Test (Glasmethode)',
        recommendation: 'Etwa 300 Bienen (halbe Tasse) in ein Glas mit Deckel geben. 2-3 Esslöffel Puderzucker dazu, Glas 1 Minute schütteln. Bienen durch Gitter zurück in Stock, Milben bleiben im Zucker. Mit Wasser ausspülen und Milben zählen. Über 10 Milben = Behandlung nötig. Bienen überleben die Prozedur.',
        reason: 'Der Puderzucker-Test ist die schonendste Methode zur Befallskontrolle. Puderzucker macht die Milben rutschig, sie fallen ab ohne die Bienen zu schädigen. Die Bienen putzen sich gegenseitig sauber und fressen den Zucker. Gibt exakte Befallszahlen zur Behandlungsplanung.',
        weatherConditions: 'Ganzjährig zur Kontrolle',
        suitableForWeather: true,
        category: 'ecological',
      ),
    ];
  }

  // Empfohlene Behandlungen basierend auf Wetterbedingungen, Datum und Präferenz
  static List<VarroaTreatment> getRecommendedTreatments(
    double avgTemp, 
    bool hasRain, 
    DateTime currentDate,
    {String preference = 'both'}
  ) {
    final all = getAllTreatments();
    final month = currentDate.month;
    final applicable = <VarroaTreatment>[];

    for (var treatment in all) {
      bool isApplicable = false;
      bool isSuitable = false;

      // Prüfe Wetterbedingungen
      if (avgTemp >= 20 && avgTemp <= 30 && !hasRain) {
        // Sommerbehandlung
        if (treatment.weatherConditions.contains('20-30') || 
            treatment.weatherConditions.contains('18-28')) {
          isApplicable = true;
          isSuitable = true;
        }
      } else if (avgTemp >= 12 && avgTemp < 20) {
        // Frühjahr/Herbst
        if (treatment.weatherConditions.contains('18-28') ||
            treatment.weatherConditions.contains('12-20')) {
          isApplicable = true;
          isSuitable = avgTemp >= 15; // Optimal ab 15°C
        }
      } else if (avgTemp < 10) {
        // Winter
        if (treatment.weatherConditions.contains('Unter 10') ||
            treatment.weatherConditions.contains('Vorbeugung')) {
          isApplicable = true;
          isSuitable = true;
        }
      }

      // Prüfe Monats-Abhängigkeit
      if (treatment.weatherConditions.contains('Mai-Juni')) {
        isApplicable = (month >= 5 && month <= 6);
        isSuitable = isApplicable;
      }

      // Diagnose ist immer anwendbar
      if (treatment.weatherConditions.contains('Ganzjährig zur Kontrolle')) {
        isApplicable = true;
        isSuitable = true;
      }

      // Filtere nach Präferenz
      if (isApplicable) {
        if (preference == 'both' || 
            treatment.category == preference || 
            treatment.category == 'both') {
          applicable.add(VarroaTreatment(
            classicTreatment: treatment.classicTreatment,
            gentleAlternative: treatment.gentleAlternative,
            recommendation: treatment.recommendation,
            reason: treatment.reason,
            weatherConditions: treatment.weatherConditions,
            suitableForWeather: isSuitable,
            category: treatment.category,
          ));
        }
      }
    }

    // Sortiere: Optimal für Wetter zuerst
    applicable.sort((a, b) {
      if (a.suitableForWeather && !b.suitableForWeather) return -1;
      if (!a.suitableForWeather && b.suitableForWeather) return 1;
      return 0;
    });

    return applicable;
  }

  // 5-Tage Wettervorhersage abrufen
  Future<List<WeatherData>> fetch5DayForecast(double lat, double lon) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      // Fallback mit Mock-Daten wenn kein API Key
      return _getMockWeatherData();
    }

    try {
      final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=128');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];
        
        // Gruppiere nach Tagen und nehme Mittagswert
        final Map<String, WeatherData> dailyData = {};
        
        for (var item in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateKey = '${dt.year}-${dt.month}-${dt.day}';
          
          if (dt.hour >= 12 && dt.hour <= 15 && !dailyData.containsKey(dateKey)) {
            dailyData[dateKey] = WeatherData(
              date: dt,
              temperature: item['main']['temp'].toDouble(),
              condition: _mapWeatherCondition(item['weather'][0]['main']),
              icon: item['weather'][0]['icon'],
            );
          }
        }

        final results = dailyData.values.toList();
        results.sort((a, b) => a.date.compareTo(b.date));
        return results.take(5).toList();
      }
    } catch (e) {
      print('Fehler beim Abrufen der Wetterdaten: $e');
    }

    return _getMockWeatherData();
  }

  String _mapWeatherCondition(String apiCondition) {
    switch (apiCondition.toLowerCase()) {
      case 'clear':
        return 'clear';
      case 'clouds':
        return 'cloudy';
      case 'rain':
      case 'drizzle':
        return 'rain';
      case 'thunderstorm':
        return 'storm';
      default:
        return 'cloudy';
    }
  }

  // Mock-Daten für Tests ohne API Key
  List<WeatherData> _getMockWeatherData() {
    final now = DateTime.now();
    final random = [22, 24, 19, 18, 23];
    final conditions = ['clear', 'cloudy', 'rain', 'clear', 'clear'];
    
    return List.generate(5, (i) {
      return WeatherData(
        date: now.add(Duration(days: i)),
        temperature: random[i].toDouble(),
        condition: conditions[i],
        icon: conditions[i] == 'clear' ? '01d' : conditions[i] == 'rain' ? '10d' : '03d',
      );
    });
  }

  // Premium Feature: Beste Behandlungszeit ermitteln
  String getBestTreatmentTime(List<WeatherData> forecast) {
    // Suche nach stabilen Wetterperioden
    for (int i = 0; i < forecast.length - 3; i++) {
      final window = forecast.sublist(i, i + 4);
      final avgTemp = window.map((w) => w.temperature).reduce((a, b) => a + b) / 4;
      final hasRain = window.any((w) => w.condition == 'rain' || w.condition == 'storm');

      if (!hasRain && avgTemp >= 15 && avgTemp <= 25) {
        return 'Optimaler Zeitraum: ${_formatDate(window.first.date)} - ${_formatDate(window.last.date)}\n'
               'Durchschnittstemperatur: ${avgTemp.toStringAsFixed(1)}°C\n'
               'Empfehlung: Ameisensäure oder Thymol-Behandlung';
      }
    }

    return 'Kein optimales Zeitfenster in den nächsten 5 Tagen gefunden.\n'
           'Erwäge alternative Behandlungsmethoden oder warte auf besseres Wetter.';
  }

  // Premium Feature: Notfallplan
  String getEmergencyPlan() {
    return '''
🚨 VARROA-NOTFALLPLAN 🚨

Bei akutem Varroa-Befall (>10% befallene Bienen):

1. SOFORTMASSNAHMEN (Tag 1-3):
   • Drohnenbrut schneiden (sofern vorhanden)
   • Ameisensäure-Schnellbehandlung (60% Lösung)
   • Gemüllkontrolle täglich

2. MITTELFRISTIG (Woche 1-2):
   • Brutentnahme in Erwägung ziehen
   • Oxalsäure-Träufelung bei brutfreien Völkern
   • Käfigung der Königin erwägen

3. STABILISIERUNG (Woche 2-4):
   • Wiederholung der Ameisensäure-Behandlung
   • Thymol-Produkte als Follow-up
   • Engmaschige Kontrolle

4. UNTERSTÜTZUNG:
   • Fütterung mit Zuckerwasser
   • Varromed als schonende Ergänzung
   • Völkerverschmelzung bei zu schwachen Völkern

⚠️ WICHTIG: Bei Totalausfall sofort Imkerverein kontaktieren!
''';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  // Wochentag abkürzen
  static String getWeekdayShort(DateTime date) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[date.weekday - 1];
  }

  // Formatiertes Datum mit Wochentag
  static String formatDateWithWeekday(DateTime date) {
    return '${getWeekdayShort(date)}. ${date.day}.${date.month}';
  }

  // Koordinaten aus PLZ und Ort ermitteln
  Future<Map<String, double>?> getCoordinatesFromPostalCode(String postalCode, String city, String countryCode) async {
    try {
      final url = Uri.parse('$_geoUrl?zip=$postalCode,$countryCode&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'lat': data['lat'].toDouble(),
          'lon': data['lon'].toDouble(),
        };
      }
    } catch (e) {
      print('Fehler beim Geocoding: $e');
    }
    return null;
  }
}
