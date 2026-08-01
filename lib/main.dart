import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'portal_app.dart';
import 'portal_state.dart';
import 'redesign_app.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StarForgeApp(connected: true));
}

class StarForgeApp extends StatefulWidget {
  const StarForgeApp({super.key, this.connected = false});

  /// The executable entry point enables the authenticated backend portal.
  /// Keeping the local family experience selectable is useful for deterministic
  /// design-system and golden tests without network or secure-storage plugins.
  final bool connected;

  @override
  State<StarForgeApp> createState() => _StarForgeAppState();
}

class _StarForgeAppState extends State<StarForgeApp> {
  final AppState _state = AppState();
  late final PortalController _portal = PortalController(
    restoreSession: widget.connected,
  );

  @override
  void dispose() {
    _portal.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          title: 'StarForge Family',
          debugShowCheckedModeBanner: false,
          theme: Sf.theme(highContrast: _state.highContrast),
          darkTheme: Sf.darkTheme(highContrast: _state.highContrast),
          themeMode: _state.darkMode ? ThemeMode.dark : ThemeMode.light,
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
                systemNavigationBarColor: Theme.of(context).colorScheme.surface,
                systemNavigationBarIconBrightness: brightness == Brightness.dark
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
        ),
      ),
    );
  }
}
