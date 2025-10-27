import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/voelker_list_screen.dart';
import 'services/settings_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Services
  final settingsService = SettingsService();
  await settingsService.loadSettings();
  
  final authService = AuthService();
  await authService.init();
  
  runApp(ImkerTagebuchApp(
    settingsService: settingsService,
    authService: authService,
  ));
}

class ImkerTagebuchApp extends StatelessWidget {
  final SettingsService settingsService;
  final AuthService authService;
  
  const ImkerTagebuchApp({
    super.key,
    required this.settingsService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Honeypot',
          debugShowCheckedModeBanner: false,
          locale: settingsService.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('de'),
            Locale('en'),
            Locale('fr'),
            Locale('es'),
            Locale('it'),
            Locale('pl'),
            Locale('tr'),
            Locale('ru'),
            Locale('uk'),
            Locale('zh'),
          ],
          themeMode: settingsService.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFBB02),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Color(0xFFFFBB02),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFBB02),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: const Color(0xFFFFBB02).withOpacity(0.9),
            ),
          ),
          home: VoelkerListScreen(
            settingsService: settingsService,
            authService: authService,
          ),
        );
      },
    );
  }
}
