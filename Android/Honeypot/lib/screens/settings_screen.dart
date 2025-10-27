import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsService settingsService;
  final AuthService authService;
  
  const SettingsScreen({
    super.key,
    required this.settingsService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(context, settingsService.locale?.languageCode)),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('App Mode'),
            subtitle: Text(_getThemeModeName(context, settingsService.themeMode)),
            onTap: () => _showThemeModeDialog(context),
          ),
          const Divider(),
          AnimatedBuilder(
            animation: authService,
            builder: (context, _) {
              final user = authService.currentUser;
              final isLoggedIn = authService.isAuthenticated;
              final isPremium = user?.role == 'premium' || user?.role == 'admin';
              final isEnabled = isLoggedIn && isPremium && (user?.cloudBackupEnabled ?? false);
              
              return SwitchListTile(
                secondary: Icon(
                  Icons.cloud_upload,
                  color: isPremium ? null : Colors.grey,
                ),
                title: Row(
                  children: [
                    const Text('Cloud Sicherung'),
                    if (!isPremium) const SizedBox(width: 8),
                    if (!isPremium) Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                  ],
                ),
                subtitle: Text(
                  !isLoggedIn
                    ? 'Nur für angemeldete Benutzer verfügbar'
                    : !isPremium
                      ? 'Premium Feature - Upgrade für Cloud-Backup'
                      : 'Automatische Synchronisation mit der Cloud'
                ),
                value: isEnabled,
                onChanged: (isLoggedIn && isPremium) ? (value) {
                  authService.updateCloudBackup(value);
                } : null,
              );
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageName(BuildContext context, String? code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'de': return l10n.german;
      case 'en': return l10n.english;
      case 'fr': return l10n.french;
      case 'es': return l10n.spanish;
      case 'it': return l10n.italian;
      case 'pl': return l10n.polish;
      case 'tr': return l10n.turkish;
      case 'ru': return l10n.russian;
      case 'uk': return l10n.ukrainian;
      case 'zh': return l10n.chinese;
      default: return l10n.system_default;
    }
  }
  
  String _getThemeModeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
      case ThemeMode.system:
        return 'System Standard';
    }
  }

  Widget _buildLanguageOption(BuildContext context, String title, String? code) {
    return RadioListTile<String?>(
      title: Text(title),
      value: code,
      groupValue: settingsService.locale?.languageCode,
      onChanged: (value) {
        settingsService.setLanguage(value);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, l10n.system_default, null),
              _buildLanguageOption(context, l10n.german, 'de'),
              _buildLanguageOption(context, l10n.english, 'en'),
              _buildLanguageOption(context, l10n.french, 'fr'),
              _buildLanguageOption(context, l10n.spanish, 'es'),
              _buildLanguageOption(context, l10n.italian, 'it'),
              _buildLanguageOption(context, l10n.polish, 'pl'),
              _buildLanguageOption(context, l10n.turkish, 'tr'),
              _buildLanguageOption(context, l10n.russian, 'ru'),
              _buildLanguageOption(context, l10n.ukrainian, 'uk'),
              _buildLanguageOption(context, l10n.chinese, 'zh'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildThemeModeOption(BuildContext context, String title, ThemeMode mode) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: mode,
      groupValue: settingsService.themeMode,
      onChanged: (value) {
        if (value != null) {
          settingsService.setThemeMode(value);
          Navigator.pop(context);
        }
      },
    );
  }
  
  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeModeOption(context, 'Hell', ThemeMode.light),
            _buildThemeModeOption(context, 'Dunkel', ThemeMode.dark),
            _buildThemeModeOption(context, 'System Standard', ThemeMode.system),
          ],
        ),
      ),
    );
  }
}
