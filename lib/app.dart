import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/profiles_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';
import 'platform/window_ops.dart';
import 'state/app_state.dart';
import 'widgets/app_shell.dart';
import 'widgets/nav_sidebar.dart';

class FloofApp extends StatelessWidget {
  final AppState state;
  final WindowOps window;

  const FloofApp({super.key, required this.state, required this.window});

  static ThemeData _theme(Brightness brightness, {bool oled = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFffb347),
      brightness: brightness,
    );
    final themed = oled
        ? scheme.copyWith(
            surface: Colors.black,
            surfaceContainerHighest: const Color(0xFF101010),
          )
        : scheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: themed,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: oled ? Colors.black : null,
    );
  }

  Locale? _resolveLocale() {
    if (state.localeTag.isEmpty) return null;
    final parts = state.localeTag.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    if (parts[0] == 'zh' && parts[1] == 'Hans') {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
    return Locale(parts[0], parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final l10n = AppLocalizations.of(context);
          return MaterialApp(
            title: 'floof',
            debugShowCheckedModeBanner: false,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: switch (state.theme) {
              AppTheme.system => ThemeMode.system,
              AppTheme.light => ThemeMode.light,
              AppTheme.dark => ThemeMode.dark,
              AppTheme.oled => ThemeMode.dark,
            },
            locale: _resolveLocale(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (device, supported) {
              if (state.localeTag.isNotEmpty) return _resolveLocale();
              for (final locale in supported) {
                if (locale.languageCode == device?.languageCode &&
                    (locale.countryCode == null ||
                        locale.countryCode == device?.countryCode)) {
                  return locale;
                }
              }
              return const Locale('en', 'GB');
            },
            builder: (context, child) {
              if (state.theme == AppTheme.oled) {
                return Theme(data: _theme(Brightness.dark, oled: true), child: child!);
              }
              return child!;
            },
            home: _FloofHome(window: window, l10nReady: l10n != null),
          );
        },
      ),
    );
  }
}

class _FloofHome extends StatelessWidget {
  final WindowOps window;
  final bool l10nReady;
  const _FloofHome({required this.window, required this.l10nReady});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppShell(
      title: 'floof',
      window: window,
      destinations: [
        NavDestination(Icons.home_outlined, l10n.navHome),
        NavDestination(Icons.search, l10n.navSearch),
        NavDestination(Icons.person_outline, l10n.navProfiles),
        NavDestination(Icons.history, l10n.navHistory),
        NavDestination(Icons.settings_outlined, l10n.navSettings),
      ],
      pages: const [
        HomePage(),
        SearchPage(),
        ProfilesPage(),
        HistoryPage(),
        SettingsPage(),
      ],
    );
  }
}
