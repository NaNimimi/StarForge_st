import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'portal_app.dart';
import 'portal_i18n.dart';
import 'portal_preferences.dart';
import 'portal_state.dart';
import 'push_notification_service.dart';
import 'redesign_app.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await PortalPreferences.load();
  await PushNotificationService.instance.initialize();
  runApp(StarForgeApp(connected: true, preferences: preferences));
}

class StarForgeApp extends StatefulWidget {
  const StarForgeApp({super.key, this.connected = false, this.preferences});

  /// The executable entry point enables the authenticated backend portal.
  /// Keeping the local family experience selectable is useful for deterministic
  /// design-system and golden tests without network or secure-storage plugins.
  final bool connected;
  final PortalPreferences? preferences;

  @override
  State<StarForgeApp> createState() => _StarForgeAppState();
}

class _StarForgeAppState extends State<StarForgeApp> {
  late final PortalPreferences _preferences =
      widget.preferences ?? PortalPreferences.memory();
  late final AppState _state = AppState(preferences: _preferences);
  late final PortalController _portal = PortalController(
    preferences: _preferences,
    restoreSession: widget.connected,
  );

  @override
  void dispose() {
    _portal.dispose();
    _state.dispose();
    _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          final visualDensity = switch (_state.density) {
            PortalDensity.compact => VisualDensity.compact,
            PortalDensity.standard => VisualDensity.standard,
            PortalDensity.comfortable => VisualDensity.comfortable,
          };
          return MaterialApp(
            title: 'Starforge Family',
            debugShowCheckedModeBanner: false,
            locale: _state.locale,
            supportedLocales: PortalPreferences.supportedLocales,
            localizationsDelegates: const [
              PortalLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: Sf.theme(
              highContrast: _state.highContrast,
              paletteIndex: _state.paletteIndex,
              fontIndex: _state.fontIndex,
              visualDensity: visualDensity,
            ),
            darkTheme: Sf.darkTheme(
              highContrast: _state.highContrast,
              paletteIndex: _state.paletteIndex,
              fontIndex: _state.fontIndex,
              visualDensity: visualDensity,
            ),
            themeMode: _state.themeMode,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final systemScale = media.textScaler.scale(1);
              final brightness = Theme.of(context).brightness;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarColor: Theme.of(
                    context,
                  ).colorScheme.surface,
                  systemNavigationBarIconBrightness:
                      brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                ),
                child: MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(
                      systemScale * (_state.largeText ? 1.15 : 1),
                    ),
                    disableAnimations:
                        _state.reduceMotion || media.disableAnimations,
                  ),
                  child: child!,
                ),
              );
            },
            home: widget.connected
                ? ConnectedPortal(controller: _portal)
                : const FamilyExperience(),
          );
        },
      ),
    );
  }
}
