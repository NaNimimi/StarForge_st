import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'notification_service.dart';
import 'platform_file_bytes.dart';
import 'portal_i18n.dart';
import 'portal_preferences.dart';
import 'portal_state.dart';
import 'push_notification_service.dart';
import 'starforge_api.dart';
import 'theme.dart';

part 'portal_pages.dart';
part 'portal_identity_pages.dart';
part 'portal_visuals.dart';
part 'portal_communications.dart';

final class PortalScope extends InheritedNotifier<PortalController> {
  const PortalScope({
    super.key,
    required PortalController controller,
    required super.child,
  }) : super(notifier: controller);

  static PortalController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PortalScope>();
    assert(scope != null, 'PortalScope is missing.');
    return scope!.notifier!;
  }

  static PortalController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<PortalScope>();
    final scope = element?.widget as PortalScope?;
    assert(scope != null, 'PortalScope is missing.');
    return scope!.notifier!;
  }
}

class ConnectedPortal extends StatelessWidget {
  const ConnectedPortal({super.key, required this.controller});

  final PortalController controller;

  @override
  Widget build(BuildContext context) {
    return PortalScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => switch (controller.phase) {
          AuthPhase.restoring => const _PortalSplash(),
          AuthPhase.signedOut => const _LoginScreen(),
          AuthPhase.signedIn when controller.mustChangePassword =>
            const _RequiredPasswordChange(),
          AuthPhase.signedIn => const _PortalShell(),
        },
      ),
    );
  }
}

class _PortalSplash extends StatelessWidget {
  const _PortalSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PortalBrandMark(size: 64),
            const SizedBox(height: 24),
            Text(
              'Starforge Family',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _server;
  bool _obscure = true;
  bool _showServer = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: defaultApiBaseUrl);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await PortalScope.read(context).login(
      baseUrl: _server.text,
      username: _username.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final form = AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('login.title'),
              style: Sf.serif(size: 31, color: colors.onSurface, height: 1.05),
            ),
            const SizedBox(height: 7),
            Text(
              context.tr('login.subtitle'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('portal-login-username'),
              controller: _username,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: context.tr('login.username'),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? context.tr('login.usernameRequired')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('portal-login-password'),
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: context.tr('login.password'),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? context.tr('login.showPassword')
                      : context.tr('login.hidePassword'),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value ?? '').isEmpty
                  ? context.tr('login.passwordRequired')
                  : null,
            ),
            if (portal.authenticationError case final error?) ...[
              const SizedBox(height: 12),
              _InlineMessage(text: error, error: true),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('portal-login-submit'),
              onPressed: portal.authenticationBusy ? null : _submit,
              icon: portal.authenticationBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                portal.authenticationBusy
                    ? context.tr('login.submitting')
                    : context.tr('login.submit'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: portal.authenticationBusy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PortalScope(
                          controller: portal,
                          child: _PasswordResetScreen(
                            initialServer: _server.text,
                          ),
                        ),
                      ),
                    ),
              child: Text(context.tr('login.forgotPassword')),
            ),
            const SizedBox(height: 4),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 2),
            TextButton.icon(
              onPressed: () => setState(() => _showServer = !_showServer),
              icon: Icon(
                _showServer ? Icons.expand_less_rounded : Icons.dns_outlined,
                size: 18,
              ),
              label: Text(
                _showServer
                    ? context.tr('login.hideServer')
                    : context.tr('login.centerServer'),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _showServer
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: _server,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: context.tr('login.serverAddress'),
                    prefixIcon: const Icon(Icons.language_rounded),
                  ),
                  validator: (value) {
                    try {
                      normalizeApiBaseUrl(
                        value ?? '',
                        language: portal.preferences.language.code,
                      );
                      return null;
                    } on FormatException catch (error) {
                      return error.message;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  children: [
                    Row(
                      children: [
                        const _PortalBrandMark(size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starforge Family',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                context.tr('brand.familyPortal'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PortalLanguageMenu(preferences: portal.preferences),
                      ],
                    ),
                    const SizedBox(height: 34),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: colors.outlineVariant),
                        boxShadow:
                            Theme.of(context).brightness == Brightness.light
                            ? Sf.shadowMd
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: form,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: Sf.success,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            context.tr('brand.sessionVerified'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ClipRect(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: _glow(310, Sf.primary.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: -150,
            left: -110,
            child: _glow(350, Sf.accent.withValues(alpha: 0.18)),
          ),
        ],
      ),
    ),
  );

  Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

class _PortalLanguageMenu extends StatelessWidget {
  const _PortalLanguageMenu({required this.preferences});

  final PortalPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<PortalLanguage>(
      key: const ValueKey('portal-language-menu'),
      tooltip: context.tr('language.choose'),
      initialValue: preferences.language,
      onSelected: preferences.setLanguage,
      itemBuilder: (context) => [
        for (final language in PortalLanguage.values)
          PopupMenuItem(
            value: language,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    language.code.toUpperCase(),
                    style: Sf.monoStyle(size: 11, color: colors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(language.label),
                if (language == preferences.language) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 18, color: colors.primary),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          preferences.language.code.toUpperCase(),
          style: Sf.monoStyle(size: 11, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PasswordResetScreen extends StatefulWidget {
  const _PasswordResetScreen({required this.initialServer});

  final String initialServer;

  @override
  State<_PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<_PasswordResetScreen> {
  late final TextEditingController _server;
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  String _accountType = 'student';
  bool _codeSent = false;
  bool _busy = false;
  String? _message;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.initialServer);
  }

  @override
  void dispose() {
    _server.dispose();
    _identifier.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_identifier.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await PortalScope.read(context).requestPasswordReset(
        baseUrl: _server.text,
        identifier: _identifier.text,
        accountType: _accountType,
      );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _message = context.tr('passwordReset.codeSent');
        _error = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _errorText(error);
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_code.text.trim().isEmpty || _newPassword.text.length < 8) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await PortalScope.read(context).confirmPasswordReset(
        baseUrl: _server.text,
        identifier: _identifier.text,
        accountType: _accountType,
        code: _code.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('passwordReset.updated'))),
      );
      Navigator.pop(context);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _errorText(error);
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('passwordReset.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'student',
                label: Text(context.tr('role.student')),
              ),
              ButtonSegment(
                value: 'parent',
                label: Text(context.tr('role.parent')),
              ),
            ],
            selected: {_accountType},
            onSelectionChanged: _busy
                ? null
                : (value) => setState(() => _accountType = value.first),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _identifier,
            enabled: !_codeSent,
            decoration: InputDecoration(
              labelText: context.tr('passwordReset.identifier'),
              prefixIcon: const Icon(Icons.person_search_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _server,
            enabled: !_codeSent,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: context.tr('login.serverAddress'),
              prefixIcon: const Icon(Icons.language_rounded),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('passwordReset.code'),
                prefixIcon: const Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr('passwordReset.newPassword'),
                helperText: context.tr('passwordReset.minimum'),
                prefixIcon: const Icon(Icons.password_rounded),
              ),
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: 14),
            _InlineMessage(text: message, error: _error),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : (_codeSent ? _confirm : _request),
            child: Text(
              _busy
                  ? context.tr('passwordReset.wait')
                  : _codeSent
                  ? context.tr('passwordReset.update')
                  : context.tr('passwordReset.sendCode'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredPasswordChange extends StatefulWidget {
  const _RequiredPasswordChange();

  @override
  State<_RequiredPasswordChange> createState() =>
      _RequiredPasswordChangeState();
}

class _RequiredPasswordChangeState extends State<_RequiredPasswordChange> {
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8 || _next.text != _confirm.text) {
      setState(() => _error = context.tr('passwordChange.invalid'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PortalScope.read(
        context,
      ).changePassword(oldPassword: _old.text, newPassword: _next.text);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('passwordChange.title')),
        actions: [
          TextButton(
            onPressed: _busy ? null : PortalScope.read(context).logout,
            child: Text(context.tr('action.logout')),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 46,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('passwordChange.prompt'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _old,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('passwordChange.current'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _next,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('passwordReset.newPassword'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('passwordChange.repeat'),
                      ),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 14),
                      _InlineMessage(text: error, error: true),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(
                        _busy
                            ? context.tr('passwordChange.saving')
                            : context.tr('passwordChange.save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _PortalDestination {
  const _PortalDestination(this.section, this.label, this.icon);

  final PortalSection section;
  final String label;
  final IconData icon;
}

class _PortalNavigationScope extends InheritedWidget {
  const _PortalNavigationScope({
    required this.onNavigate,
    required super.child,
  });

  final ValueChanged<PortalSection> onNavigate;

  static void go(BuildContext context, PortalSection section) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PortalNavigationScope>();
    assert(scope != null, 'Portal navigation scope is missing.');
    scope!.onNavigate(section);
  }

  @override
  bool updateShouldNotify(_PortalNavigationScope oldWidget) =>
      onNavigate != oldWidget.onNavigate;
}

class _PortalShell extends StatefulWidget {
  const _PortalShell();

  @override
  State<_PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<_PortalShell> {
  PortalSection _section = PortalSection.home;
  final List<PortalSection> _sectionHistory = [];
  DateTime? _lastHomeBackPress;
  bool _messagesVisited = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<Map<String, dynamic>>? _notificationTapSubscription;
  Timer? _notificationRefreshTimer;

  void _openSection(PortalSection section) {
    if (section == _section) return;
    setState(() {
      _sectionHistory.add(_section);
      if (_sectionHistory.length > 24) _sectionHistory.removeAt(0);
      _section = section;
      if (section == PortalSection.messages) _messagesVisited = true;
    });
  }

  void _handleSystemBack(PortalController portal) {
    if (_section != PortalSection.home) {
      final available = _destinations(
        portal,
      ).map((item) => item.section).toSet();
      PortalSection target = PortalSection.home;
      while (_sectionHistory.isNotEmpty) {
        final candidate = _sectionHistory.removeLast();
        if (available.contains(candidate) && candidate != _section) {
          target = candidate;
          break;
        }
      }
      setState(() => _section = target);
      return;
    }

    final now = DateTime.now();
    final previous = _lastHomeBackPress;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastHomeBackPress = now;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            _familyCopy(
              context,
              uz: 'Ilovadan chiqish uchun yana bir marta bosing.',
              ru: 'Нажмите ещё раз, чтобы выйти из приложения.',
              en: 'Press back again to exit the app.',
            ),
          ),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    _notificationTapSubscription = DeviceNotificationService
        .instance
        .notificationTaps
        .listen(_openNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = DeviceNotificationService.instance
          .takePendingTapPayload();
      if (pending != null) _openNotificationPayload(pending);
      _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 45), (
        _,
      ) {
        if (!mounted) return;
        unawaited(
          PortalScope.read(
            context,
          ).loadSection(PortalSection.notifications, force: true),
        );
      });
    });
  }

  void _openNotificationPayload(Map<String, dynamic> payload) {
    if (!mounted) return;
    _PortalCommunicationRouter.capture(payload);
    final portal = PortalScope.read(context);
    final route = notificationRouteFromPayload(payload);
    final section =
        _completeNotificationDestination(<String, Object?>{
          ...payload,
          'event_type': payload['event_type'] ?? payload['type'] ?? '',
        }, portal) ??
        switch (route) {
          'messages' => PortalSection.messages,
          'assignments' => PortalSection.assignments,
          'schedule' || 'calendar' => PortalSection.schedule,
          'attendance' => PortalSection.attendance,
          'academics' || 'grades' || 'exams' => PortalSection.academics,
          'placement' || 'level-test' => PortalSection.placement,
          'content' || 'courses' || 'materials' => PortalSection.content,
          'ai' || 'assistant' => PortalSection.ai,
          'forms' => PortalSection.forms,
          'achievements' => PortalSection.achievements,
          'discipline' || 'rules' || 'penalties' => PortalSection.discipline,
          'finance' || 'payments' => PortalSection.finance,
          'cards' || 'wallet' => PortalSection.cards,
          'account' => PortalSection.account,
          'students' || 'parents' || 'identity' => PortalSection.identity,
          _ => PortalSection.notifications,
        };
    if (!_destinations(portal).any((item) => item.section == section)) {
      _openSection(PortalSection.notifications);
      unawaited(portal.loadSection(PortalSection.notifications, force: true));
      return;
    }
    _openSection(section);
    unawaited(portal.loadSection(section, force: true));
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  List<_PortalDestination> _destinations(PortalController portal) {
    if (portal.isStudent) {
      return [
        const _PortalDestination(
          PortalSection.home,
          'Bugun',
          Icons.auto_graph_rounded,
        ),
        const _PortalDestination(
          PortalSection.identity,
          'Mening profilim',
          Icons.badge_outlined,
        ),
        if (portal.can('assignments:read'))
          const _PortalDestination(
            PortalSection.assignments,
            'Vazifalar',
            Icons.assignment_outlined,
          ),
        if (portal.can('schedule:read'))
          const _PortalDestination(
            PortalSection.schedule,
            'Dars jadvali',
            Icons.calendar_month_outlined,
          ),
        if (portal.can('attendance:read'))
          const _PortalDestination(
            PortalSection.attendance,
            'Davomatim',
            Icons.fact_check_outlined,
          ),
        if (portal.can('academics:read'))
          const _PortalDestination(
            PortalSection.academics,
            'Natijalarim',
            Icons.school_outlined,
          ),
        const _PortalDestination(
          PortalSection.placement,
          'Daraja sinovi',
          Icons.psychology_alt_outlined,
        ),
        if (portal.can('content:read'))
          const _PortalDestination(
            PortalSection.content,
            'Kutubxona',
            Icons.local_library_outlined,
          ),
        const _PortalDestination(
          PortalSection.ai,
          'AI yordamchi',
          Icons.auto_awesome_outlined,
        ),
        if (portal.can('messaging:read'))
          const _PortalDestination(
            PortalSection.messages,
            'Chat',
            Icons.send_outlined,
          ),
        const _PortalDestination(
          PortalSection.notifications,
          'Bildirishnomalar',
          Icons.notifications_outlined,
        ),
        if (portal.can('forms:read'))
          const _PortalDestination(
            PortalSection.forms,
            'So‘rovnomalar',
            Icons.dynamic_form_outlined,
          ),
        if (portal.can('achievements:read'))
          const _PortalDestination(
            PortalSection.achievements,
            'Yutuqlarim',
            Icons.emoji_events_outlined,
          ),
        if (portal.can('penalty:read'))
          const _PortalDestination(
            PortalSection.discipline,
            'Qoidalar',
            Icons.gavel_outlined,
          ),
        if (portal.can('card:read'))
          const _PortalDestination(
            PortalSection.cards,
            'Karta va hamyon',
            Icons.credit_card_outlined,
          ),
        const _PortalDestination(
          PortalSection.account,
          'Sozlamalar',
          Icons.settings_outlined,
        ),
      ];
    }
    return [
      const _PortalDestination(
        PortalSection.home,
        'Oilam',
        Icons.family_restroom_rounded,
      ),
      const _PortalDestination(
        PortalSection.identity,
        'Farzandlarim',
        Icons.supervisor_account_outlined,
      ),
      if (portal.can('attendance:read'))
        const _PortalDestination(
          PortalSection.attendance,
          'Davomat nazorati',
          Icons.fact_check_outlined,
        ),
      if (portal.can('academics:read'))
        const _PortalDestination(
          PortalSection.academics,
          'O‘zlashtirish',
          Icons.query_stats_outlined,
        ),
      if (portal.can('assignments:read'))
        const _PortalDestination(
          PortalSection.assignments,
          'Farzand vazifalari',
          Icons.assignment_outlined,
        ),
      if (portal.can('schedule:read'))
        const _PortalDestination(
          PortalSection.schedule,
          'Oila taqvimi',
          Icons.calendar_month_outlined,
        ),
      if (portal.can('finance:read_own'))
        const _PortalDestination(
          PortalSection.finance,
          'To‘lovlar',
          Icons.account_balance_wallet_outlined,
        ),
      if (portal.can('content:read'))
        const _PortalDestination(
          PortalSection.content,
          'O‘quv materiallari',
          Icons.library_books_outlined,
        ),
      const _PortalDestination(
        PortalSection.ai,
        'AI yordamchi',
        Icons.auto_awesome_outlined,
      ),
      if (portal.can('messaging:read'))
        const _PortalDestination(
          PortalSection.messages,
          'Maktab bilan chat',
          Icons.forum_outlined,
        ),
      const _PortalDestination(
        PortalSection.notifications,
        'Muhim xabarlar',
        Icons.notifications_active_outlined,
      ),
      if (portal.can('forms:read'))
        const _PortalDestination(
          PortalSection.forms,
          'Rozilik va so‘rovlar',
          Icons.fact_check_outlined,
        ),
      if (portal.can('achievements:read'))
        const _PortalDestination(
          PortalSection.achievements,
          'Farzand yutuqlari',
          Icons.workspace_premium_outlined,
        ),
      if (portal.can('penalty:read'))
        const _PortalDestination(
          PortalSection.discipline,
          'Qoidalar va holatlar',
          Icons.policy_outlined,
        ),
      if (portal.can('card:read'))
        const _PortalDestination(
          PortalSection.cards,
          'Karta va hamyon',
          Icons.credit_card_outlined,
        ),
      const _PortalDestination(
        PortalSection.account,
        'Profil va xavfsizlik',
        Icons.manage_accounts_outlined,
      ),
    ];
  }

  List<_PortalDestination> _mobileDestinations(
    PortalController portal,
    List<_PortalDestination> destinations,
  ) {
    final preferred = portal.isStudent
        ? const [
            PortalSection.home,
            PortalSection.assignments,
            PortalSection.schedule,
            PortalSection.messages,
            PortalSection.identity,
          ]
        : const [
            PortalSection.home,
            PortalSection.identity,
            PortalSection.finance,
            PortalSection.messages,
            PortalSection.account,
          ];
    return [
      for (final section in preferred)
        ...destinations
            .where((item) => item.section == section)
            .take(1)
            .map(
              (item) => _PortalDestination(
                item.section,
                _destinationLabel(
                  portal.preferences.language,
                  item.section,
                  portal.isParent,
                  mobile: true,
                ),
                item.icon,
              ),
            ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final destinations = _destinations(portal);
    if (!destinations.any((item) => item.section == _section)) {
      _section = PortalSection.home;
    }
    final selected = destinations.indexWhere(
      (item) => item.section == _section,
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final mobileDestinations = _mobileDestinations(portal, destinations);
    final mobileSelected = mobileDestinations.indexWhere(
      (item) => item.section == _section,
    );
    final drawer = _PortalNavigation(
      destinations: destinations,
      selectedIndex: selected,
      onSelected: (index) => _openSection(destinations[index].section),
    );
    final baseTheme = Theme.of(context);
    final dark = baseTheme.brightness == Brightness.dark;
    final accent = dark
        ? (portal.isStudent
              ? baseTheme.colorScheme.primary
              : baseTheme.colorScheme.secondary)
        : portal.isStudent
        ? const Color(0xFF4F6A3A)
        : const Color(0xFF8D5E2E);
    final accentSoft = dark
        ? (portal.isStudent
              ? baseTheme.colorScheme.primaryContainer
              : baseTheme.colorScheme.secondaryContainer)
        : portal.isStudent
        ? const Color(0xFFDBE5C7)
        : const Color(0xFFF0E1BB);
    final accentInk = dark
        ? (portal.isStudent
              ? baseTheme.colorScheme.onPrimaryContainer
              : baseTheme.colorScheme.onSecondaryContainer)
        : portal.isStudent
        ? const Color(0xFF324D22)
        : const Color(0xFF674A0D);
    final onAccent = dark && portal.isParent
        ? baseTheme.colorScheme.onSecondary
        : Colors.white;
    final roleScheme = baseTheme.colorScheme.copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accentSoft,
      onPrimaryContainer: accentInk,
      secondary: portal.isStudent
          ? const Color(0xFFBA8C2C)
          : const Color(0xFF4F6A3A),
      tertiary: portal.isStudent
          ? const Color(0xFF77551B)
          : const Color(0xFF8B6A29),
    );
    final roleTheme = baseTheme.copyWith(
      colorScheme: roleScheme,
      scaffoldBackgroundColor: roleScheme.surfaceContainerLowest,
    );
    final connectionColor = portal.connectionIssue
        ? roleScheme.error
        : portal.lastSuccessfulSyncAt == null
        ? Sf.warn
        : Sf.success;
    final connectionLabel = portal.connectionIssue
        ? 'ALOQA MUAMMOSI'
        : portal.lastSuccessfulSyncAt == null
        ? 'ULANMOQDA'
        : 'MARKAZGA ULANGAN';

    return Theme(
      data: roleTheme,
      child: Builder(
        builder: (roleContext) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleSystemBack(portal);
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: wide
                ? null
                : Drawer(
                    width: 300,
                    backgroundColor: roleScheme.surface,
                    child: SafeArea(child: drawer),
                  ),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: wide ? 60 : 68,
              backgroundColor: roleScheme.surface,
              shape: Border(
                bottom: BorderSide(color: roleScheme.outlineVariant),
              ),
              leadingWidth: wide ? null : 54,
              leading: wide
                  ? null
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
                      child: IconButton.filledTonal(
                        tooltip: 'Barcha bo‘limlar',
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        icon: const Icon(Icons.grid_view_rounded, size: 20),
                      ),
                    ),
              titleSpacing: wide ? 20 : 6,
              title: Row(
                children: [
                  if (wide)
                    Text(
                      portal.isParent ? 'OILA PORTALI' : 'O‘QUVCHI PORTALI',
                      style: Sf.eyebrow(color: roleScheme.primary),
                    ),
                  if (!wide) ...[
                    const _PortalBrandMark(size: 32),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            portal.isParent
                                ? 'STARFORGE OILA'
                                : 'STARFORGE O‘QUVCHI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Sf.eyebrow(
                              color: roleScheme.primary,
                            ).copyWith(fontSize: 10.5, letterSpacing: 0.9),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            portal.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(roleContext).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (wide && portal.isParent && portal.children.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 210),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: _ChildContextSelector(portal: portal),
                    ),
                  ),
                if (wide && portal.isParent && portal.children.isNotEmpty)
                  const SizedBox(width: 10),
                if (wide)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: roleScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: roleScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: connectionColor),
                        const SizedBox(width: 7),
                        Text(
                          connectionLabel,
                          style: Sf.eyebrow(color: roleScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Badge(
                    isLabelVisible: portal.unreadNotificationCount > 0,
                    label: Text('${portal.unreadNotificationCount}'),
                    child: IconButton(
                      tooltip: 'Bildirishnomalar',
                      onPressed: () =>
                          _openSection(PortalSection.notifications),
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                ),
                if (wide)
                  IconButton.filledTonal(
                    tooltip: 'Ma’lumotlarni yangilash',
                    onPressed: portal.isLoading(_section)
                        ? null
                        : () => portal.refresh(_section),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: portal.isLoading(_section)
                          ? const SizedBox(
                              key: ValueKey('refresh-loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              key: ValueKey('refresh-ready'),
                            ),
                    ),
                  ),
                IconButton(
                  tooltip: portal.isStudent
                      ? 'Mening profilim'
                      : 'Profil va xavfsizlik',
                  onPressed: () => _openSection(
                    portal.isStudent
                        ? PortalSection.identity
                        : PortalSection.account,
                  ),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
                SizedBox(width: wide ? 14 : 4),
              ],
            ),
            body: Row(
              children: [
                if (wide) SizedBox(width: 272, child: drawer),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.45,
                        colors: [
                          Color.alphaBlend(
                            roleScheme.primary.withValues(alpha: 0.06),
                            roleScheme.surfaceContainerLowest,
                          ),
                          roleScheme.surfaceContainerLowest,
                        ],
                      ),
                    ),
                    child: _PortalNavigationScope(
                      onNavigate: _openSection,
                      child: !_messagesVisited
                          ? _SectionHost(
                              key: ValueKey(
                                '${_section.name}-${portal.selectedStudentId ?? 0}',
                              ),
                              section: _section,
                            )
                          : IndexedStack(
                              index: _section == PortalSection.messages ? 1 : 0,
                              children: [
                                TickerMode(
                                  enabled: _section != PortalSection.messages,
                                  child: _section == PortalSection.messages
                                      ? const SizedBox.shrink()
                                      : _SectionHost(
                                          key: ValueKey(
                                            '${_section.name}-${portal.selectedStudentId ?? 0}',
                                          ),
                                          section: _section,
                                        ),
                                ),
                                TickerMode(
                                  enabled: _section == PortalSection.messages,
                                  child: const _SectionHost(
                                    key: ValueKey('retained-messages-section'),
                                    section: PortalSection.messages,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: wide
                ? null
                : _PortalMobileNavigation(
                    destinations: mobileDestinations,
                    selectedIndex: mobileSelected,
                    onSelected: (index) {
                      _openSection(mobileDestinations[index].section);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _PortalMobileNavigation extends StatelessWidget {
  const _PortalMobileNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_PortalDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final itemCount = destinations.length;
    final hasSelection = selectedIndex >= 0 && selectedIndex < itemCount;
    final selected = hasSelection ? selectedIndex : 0;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('portal-bottom-navigation'),
        height: 72,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.98),
          border: Border(top: BorderSide(color: colors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / itemCount;
            return Stack(
              children: [
                if (hasSelection)
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    left: selected * itemWidth + 4,
                    top: 2,
                    width: itemWidth - 8,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: _PortalBubbleNavItem(
                          key: ValueKey(
                            'portal-bottom-${destinations[index].section.name}',
                          ),
                          icon: destinations[index].icon,
                          label: destinations[index].label,
                          active: hasSelection && selected == index,
                          duration: duration,
                          onTap: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PortalBubbleNavItem extends StatelessWidget {
  const _PortalBubbleNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.duration,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedSlide(
            duration: duration,
            curve: Curves.easeOutBack,
            offset: active ? const Offset(0, -0.08) : Offset.zero,
            child: AnimatedScale(
              duration: duration,
              curve: Curves.easeOutBack,
              scale: active ? 1.08 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: active ? 22 : 20,
                    color: active ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: TextStyle(
                      fontFamily: Sf.ui,
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? colors.primary : colors.onSurfaceVariant,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalNavigation extends StatelessWidget {
  const _PortalNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_PortalDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    return Material(
      color: colors.surface,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Sf.ink,
                  Color.alphaBlend(accent.withValues(alpha: 0.54), Sf.ink),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                const _PortalBrandMark(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StarForge',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        portal.isParent ? 'OILA KABINETI' : 'O‘QUVCHI KABINETI',
                        style: TextStyle(
                          color: colors.secondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: ListView.builder(
              key: const ValueKey('portal-navigation-list'),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final group = _navigationGroup(
                  item.section,
                  portal.isParent,
                  portal.preferences.language,
                );
                final previousGroup = index == 0
                    ? null
                    : _navigationGroup(
                        destinations[index - 1].section,
                        portal.isParent,
                        portal.preferences.language,
                      );
                final selected = index == selectedIndex;
                final badge = switch (item.section) {
                  PortalSection.assignments =>
                    valueInt(portal.dashboard['open_homework_count']) ?? 0,
                  PortalSection.messages => portal.threads.fold<int>(
                    0,
                    (total, thread) =>
                        total + (valueInt(thread['unread_count']) ?? 0),
                  ),
                  PortalSection.notifications => portal.unreadNotificationCount,
                  _ => 0,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (group != previousGroup)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          10,
                          index == 0 ? 2 : 12,
                          10,
                          7,
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10.5,
                            letterSpacing: 1.7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        key: ValueKey('portal-nav-${item.section.name}'),
                        selected: selected,
                        selectedTileColor: colors.primaryContainer,
                        tileColor: Colors.transparent,
                        hoverColor: selected
                            ? colors.primaryContainer
                            : colors.surfaceContainerLow,
                        focusColor: selected
                            ? colors.primaryContainer
                            : colors.surfaceContainer,
                        leading: Icon(
                          item.icon,
                          size: 20,
                          color: selected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        title: Text(
                          _destinationLabel(
                            portal.preferences.language,
                            item.section,
                            portal.isParent,
                          ),
                          style: TextStyle(
                            color: selected
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                            fontSize: 12.5,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: badge > 0
                            ? Container(
                                constraints: const BoxConstraints(minWidth: 22),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colors.primary.withValues(alpha: 0.14)
                                      : accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  badge > 99 ? '99+' : '$badge',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            : null,
                        minTileHeight: 42,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          final scaffold = Scaffold.maybeOf(context);
                          onSelected(index);
                          if (scaffold?.isDrawerOpen ?? false) {
                            scaffold!.closeDrawer();
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: accent,
                    child: Text(
                      _initials(portal.displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portal.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          portal.isParent ? 'Ota-ona' : 'O‘quvchi',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chiqish',
                    onPressed: portal.logout,
                    color: colors.onSurfaceVariant,
                    icon: const Icon(Icons.logout_rounded, size: 19),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _destinationLabel(
  PortalLanguage language,
  PortalSection section,
  bool parent, {
  bool mobile = false,
}) {
  if (mobile) {
    return switch ((section, language)) {
      (PortalSection.home, PortalLanguage.ru) => parent ? 'Семья' : 'Сегодня',
      (PortalSection.home, PortalLanguage.en) => parent ? 'Family' : 'Today',
      (PortalSection.identity, PortalLanguage.ru) =>
        parent ? 'Ребёнок' : 'Профиль',
      (PortalSection.identity, PortalLanguage.en) =>
        parent ? 'Child' : 'Profile',
      (PortalSection.assignments, PortalLanguage.ru) => 'Задания',
      (PortalSection.assignments, PortalLanguage.en) => 'Tasks',
      (PortalSection.schedule, PortalLanguage.ru) => 'Расписание',
      (PortalSection.schedule, PortalLanguage.en) => 'Schedule',
      (PortalSection.messages, _) => 'Chat',
      (PortalSection.account, PortalLanguage.ru) => 'Профиль',
      (PortalSection.account, PortalLanguage.en) => 'Profile',
      (PortalSection.home, _) => parent ? 'Oila' : 'Bugun',
      (PortalSection.identity, _) => parent ? 'Farzand' : 'Profil',
      (PortalSection.assignments, _) => 'Vazifa',
      (PortalSection.schedule, _) => 'Jadval',
      (PortalSection.account, _) => 'Profil',
      _ => _destinationLabel(language, section, parent),
    };
  }
  return switch ((section, language)) {
    (PortalSection.home, PortalLanguage.ru) => parent ? 'Моя семья' : 'Сегодня',
    (PortalSection.home, PortalLanguage.en) => parent ? 'My family' : 'Today',
    (PortalSection.identity, PortalLanguage.ru) =>
      parent ? 'Мои дети' : 'Мой профиль',
    (PortalSection.identity, PortalLanguage.en) =>
      parent ? 'My children' : 'My profile',
    (PortalSection.assignments, PortalLanguage.ru) =>
      parent ? 'Задания ребёнка' : 'Задания',
    (PortalSection.assignments, PortalLanguage.en) =>
      parent ? 'Child assignments' : 'Assignments',
    (PortalSection.schedule, PortalLanguage.ru) =>
      parent ? 'Семейный календарь' : 'Расписание',
    (PortalSection.schedule, PortalLanguage.en) =>
      parent ? 'Family calendar' : 'Schedule',
    (PortalSection.attendance, PortalLanguage.ru) =>
      parent ? 'Контроль посещаемости' : 'Посещаемость',
    (PortalSection.attendance, PortalLanguage.en) =>
      parent ? 'Attendance tracking' : 'Attendance',
    (PortalSection.academics, PortalLanguage.ru) =>
      parent ? 'Успеваемость' : 'Мои результаты',
    (PortalSection.academics, PortalLanguage.en) =>
      parent ? 'Academic progress' : 'My results',
    (PortalSection.placement, PortalLanguage.ru) => 'Тест уровня',
    (PortalSection.placement, PortalLanguage.en) => 'Level test',
    (PortalSection.content, PortalLanguage.ru) =>
      parent ? 'Учебные материалы' : 'Библиотека',
    (PortalSection.content, PortalLanguage.en) =>
      parent ? 'Learning materials' : 'Library',
    (PortalSection.messages, PortalLanguage.ru) =>
      parent ? 'Чат со школой' : 'Чат',
    (PortalSection.messages, PortalLanguage.en) =>
      parent ? 'School chat' : 'Chat',
    (PortalSection.ai, PortalLanguage.ru) => 'ИИ-помощник',
    (PortalSection.ai, PortalLanguage.en) => 'AI assistant',
    (PortalSection.notifications, PortalLanguage.ru) =>
      parent ? 'Важные уведомления' : 'Уведомления',
    (PortalSection.notifications, PortalLanguage.en) =>
      parent ? 'Important updates' : 'Notifications',
    (PortalSection.forms, PortalLanguage.ru) =>
      parent ? 'Согласия и опросы' : 'Опросы',
    (PortalSection.forms, PortalLanguage.en) =>
      parent ? 'Consents and forms' : 'Forms',
    (PortalSection.achievements, PortalLanguage.ru) =>
      parent ? 'Достижения ребёнка' : 'Мои достижения',
    (PortalSection.achievements, PortalLanguage.en) =>
      parent ? 'Child achievements' : 'My achievements',
    (PortalSection.discipline, PortalLanguage.ru) =>
      parent ? 'Правила и события' : 'Правила',
    (PortalSection.discipline, PortalLanguage.en) =>
      parent ? 'Rules and events' : 'Rules',
    (PortalSection.finance, PortalLanguage.ru) => 'Платежи',
    (PortalSection.finance, PortalLanguage.en) => 'Payments',
    (PortalSection.cards, PortalLanguage.ru) => 'Карта и кошелёк',
    (PortalSection.cards, PortalLanguage.en) => 'Card and wallet',
    (PortalSection.account, PortalLanguage.ru) => 'Профиль и безопасность',
    (PortalSection.account, PortalLanguage.en) => 'Profile and security',
    (PortalSection.home, _) => parent ? 'Oilam' : 'Bugun',
    (PortalSection.identity, _) => parent ? 'Farzandlarim' : 'Mening profilim',
    (PortalSection.assignments, _) =>
      parent ? 'Farzand vazifalari' : 'Vazifalar',
    (PortalSection.schedule, _) => parent ? 'Oila taqvimi' : 'Dars jadvali',
    (PortalSection.attendance, _) => parent ? 'Davomat nazorati' : 'Davomatim',
    (PortalSection.academics, _) => parent ? 'O‘zlashtirish' : 'Natijalarim',
    (PortalSection.placement, _) => 'Daraja sinovi',
    (PortalSection.content, _) => parent ? 'O‘quv materiallari' : 'Kutubxona',
    (PortalSection.messages, _) => parent ? 'Maktab bilan chat' : 'Chat',
    (PortalSection.ai, _) => 'AI yordamchi',
    (PortalSection.notifications, _) =>
      parent ? 'Muhim xabarlar' : 'Bildirishnomalar',
    (PortalSection.forms, _) =>
      parent ? 'Rozilik va so‘rovlar' : 'So‘rovnomalar',
    (PortalSection.achievements, _) =>
      parent ? 'Farzand yutuqlari' : 'Yutuqlarim',
    (PortalSection.discipline, _) =>
      parent ? 'Qoidalar va holatlar' : 'Qoidalar',
    (PortalSection.finance, _) => 'To‘lovlar',
    (PortalSection.cards, _) => 'Karta va hamyon',
    (PortalSection.account, _) =>
      parent ? 'Profil va xavfsizlik' : 'Sozlamalar',
  };
}

String _navigationGroup(
  PortalSection section,
  bool parent,
  PortalLanguage language,
) {
  final group = switch (section) {
    PortalSection.home || PortalSection.identity => 0,
    PortalSection.assignments ||
    PortalSection.schedule ||
    PortalSection.attendance ||
    PortalSection.academics ||
    PortalSection.placement ||
    PortalSection.content => 1,
    PortalSection.messages || PortalSection.notifications => 2,
    PortalSection.ai => 3,
    PortalSection.forms ||
    PortalSection.achievements ||
    PortalSection.discipline ||
    PortalSection.finance ||
    PortalSection.cards => 4,
    PortalSection.account => 5,
  };
  return switch ((group, language)) {
    (0, PortalLanguage.ru) => 'ГЛАВНАЯ',
    (0, PortalLanguage.en) => 'HOME',
    (1, PortalLanguage.ru) => parent ? 'ОБУЧЕНИЕ РЕБЁНКА' : 'УЧЁБА',
    (1, PortalLanguage.en) => parent ? 'CHILD LEARNING' : 'LEARNING',
    (2, PortalLanguage.ru) => 'ОБЩЕНИЕ',
    (2, PortalLanguage.en) => 'COMMUNICATION',
    (3, PortalLanguage.ru) => parent ? 'ПОМОЩНИК СЕМЬИ' : 'ПОМОЩНИК В УЧЁБЕ',
    (3, PortalLanguage.en) => parent ? 'FAMILY ASSISTANT' : 'STUDY ASSISTANT',
    (4, PortalLanguage.ru) => parent ? 'СЕРВИСЫ СЕМЬИ' : 'СЕРВИСЫ',
    (4, PortalLanguage.en) => parent ? 'FAMILY SERVICES' : 'SERVICES',
    (5, PortalLanguage.ru) => 'СИСТЕМА',
    (5, PortalLanguage.en) => 'SYSTEM',
    (0, _) => 'BOSH SAHIFA',
    (1, _) => parent ? 'FARZAND TA’LIMI' : 'O‘QISH',
    (2, _) => 'ALOQA',
    (3, _) => parent ? 'OILA YORDAMCHISI' : 'O‘QISH YORDAMCHISI',
    (4, _) => parent ? 'OILA XIZMATLARI' : 'XIZMATLAR',
    _ => 'TIZIM',
  };
}

class _SectionHost extends StatefulWidget {
  const _SectionHost({super.key, required this.section});

  final PortalSection section;

  @override
  State<_SectionHost> createState() => _SectionHostState();
}

class _SectionHostState extends State<_SectionHost> {
  int? _observedStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PortalScope.read(context).loadSection(widget.section);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final portal = PortalScope.of(context);
    final next = portal.selectedStudentId;
    if (_observedStudentId != null &&
        next != null &&
        next != _observedStudentId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) portal.loadSection(widget.section, force: true);
      });
    }
    _observedStudentId = next;
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final error = portal.sectionError(widget.section);
    if (portal.isLoading(widget.section) && !portal.isLoaded(widget.section)) {
      return const _PortalSectionSkeleton();
    }
    if (error != null && !portal.isLoaded(widget.section)) {
      return _SectionError(
        message: error,
        onRetry: () => portal.refresh(widget.section),
      );
    }
    final content = switch (widget.section) {
      PortalSection.home => const _RebuiltHomePortalPage(),
      PortalSection.identity => const _IdentityPortalPage(),
      PortalSection.assignments => const _AssignmentsPortalPage(),
      PortalSection.schedule => const _SchedulePortalPage(),
      PortalSection.academics => const _AcademicsPortalPage(),
      PortalSection.placement => const _PlacementPortalPage(),
      PortalSection.content => const _ContentPortalPage(),
      PortalSection.attendance => const _AttendancePortalPage(),
      PortalSection.messages => const _RebuiltMessagesPortalPage(),
      PortalSection.ai => const _AiPortalPage(),
      PortalSection.notifications => const _EnhancedNotificationsPortalPage(),
      PortalSection.forms => const _FormsPortalPage(),
      PortalSection.achievements => const _AchievementsPortalPage(),
      PortalSection.discipline => const _DisciplinePortalPage(),
      PortalSection.finance => const _FinancePortalPage(),
      PortalSection.cards => const _CardsPortalPage(),
      PortalSection.account => const _AccountPortalPage(),
    };
    final page = error == null
        ? content
        : Column(
            children: [
              _StaleDataBanner(
                message: error,
                onRetry: () => portal.refresh(widget.section),
              ),
              Expanded(child: content),
            ],
          );
    final showMobileChild =
        portal.isParent &&
        portal.children.isNotEmpty &&
        MediaQuery.sizeOf(context).width < 840 &&
        widget.section != PortalSection.home &&
        widget.section != PortalSection.account &&
        widget.section != PortalSection.notifications &&
        widget.section != PortalSection.messages;
    if (!showMobileChild) return page;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ChildContextSelector(portal: portal),
            ),
          ),
        ),
        Expanded(child: page),
      ],
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Avvalgi ma’lumot ko‘rsatilmoqda: $message',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Yangilash')),
          ],
        ),
      ),
    ),
  );
}

class _PortalBrandMark extends StatelessWidget {
  const _PortalBrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.54,
        color: colors.onPrimary,
      ),
    );
  }
}

class _PortalPage extends StatelessWidget {
  const _PortalPage({
    required this.title,
    required this.subtitle,
    required this.section,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final PortalSection section;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final displayedTitle = _portalSectionPageTitle(portal, section, title);
    final displayedSubtitle = _portalSectionPageSubtitle(
      portal,
      section,
      subtitle,
    );
    final optionalFailures = portal.optionalApiFailures.entries
        .where((entry) => _optionalFailureBelongsTo(section, entry.key))
        .toList();
    final content = RefreshIndicator(
      onRefresh: () => portal.refresh(section),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width >= 840
              ? 20
              : mobile
              ? 12
              : 16,
          mobile ? 10 : 16,
          MediaQuery.sizeOf(context).width >= 840
              ? 20
              : mobile
              ? 12
              : 16,
          mobile ? 24 : 32,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 680;
                      final heading = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mobile) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 26,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Flexible(
                                  child: Text(
                                    portal.isParent
                                        ? 'OILA MARKAZI'
                                        : 'O‘QUV MAKONI',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Sf.eyebrow(color: colors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            displayedTitle,
                            maxLines: mobile ? 2 : null,
                            overflow: mobile ? TextOverflow.ellipsis : null,
                            style: mobile
                                ? Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  )
                                : Theme.of(context).textTheme.headlineMedium,
                          ),
                          SizedBox(height: mobile ? 3 : 5),
                          Text(
                            displayedSubtitle,
                            maxLines: mobile ? 2 : null,
                            overflow: mobile ? TextOverflow.ellipsis : null,
                            style:
                                (mobile
                                        ? Theme.of(context).textTheme.bodySmall
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium)
                                    ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      );
                      if (compact || trailing == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            heading,
                            if (trailing != null) ...[
                              SizedBox(height: mobile ? 8 : 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: trailing!,
                              ),
                            ],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 24),
                          trailing!,
                        ],
                      );
                    },
                  ),
                  if (portal.sectionError(section) case final warning?) ...[
                    const SizedBox(height: 14),
                    _InlineMessage(text: warning, error: true),
                  ],
                  for (final failure in optionalFailures) ...[
                    const SizedBox(height: 10),
                    _InlineMessage(
                      text:
                          '${failure.value.message} (${failure.key.replaceFirst('/api/v1/', '')})',
                      error: true,
                    ),
                  ],
                  SizedBox(height: mobile ? 10 : 16),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (portal.preferences.pattern == PortalPattern.none) return content;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PortalPatternPainter(
                pattern: portal.preferences.pattern,
                color: colors.primary.withValues(alpha: .055),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _PortalPatternPainter extends CustomPainter {
  const _PortalPatternPainter({required this.pattern, required this.color});

  final PortalPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 34.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        switch (pattern) {
          case PortalPattern.none:
            return;
          case PortalPattern.dots:
            canvas.drawCircle(Offset(x + 8, y + 8), 1.4, paint);
            break;
          case PortalPattern.grid:
            if (x == 0) {
              canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
            }
            if (y == 0) {
              canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
            }
            break;
          case PortalPattern.tile:
            canvas.drawRect(
              Rect.fromLTWH(x + 4, y + 4, 20, 20),
              paint..style = PaintingStyle.stroke,
            );
            paint.style = PaintingStyle.fill;
            break;
          case PortalPattern.topo:
            canvas.drawArc(
              Rect.fromCircle(center: Offset(x + 10, y + 10), radius: 9),
              .2,
              4.7,
              false,
              paint..style = PaintingStyle.stroke,
            );
            paint.style = PaintingStyle.fill;
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PortalPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.color != color;
}

String _portalSectionPageTitle(
  PortalController portal,
  PortalSection section,
  String fallback,
) {
  final language = portal.preferences.language;
  if (language == PortalLanguage.uz) return fallback;
  return switch ((section, language)) {
    (PortalSection.home, PortalLanguage.ru) =>
      portal.isParent
          ? 'Семейный центр'
          : 'Здравствуйте, ${portal.displayName.split(' ').first}',
    (PortalSection.home, _) =>
      portal.isParent
          ? 'Family center'
          : 'Hello, ${portal.displayName.split(' ').first}',
    (PortalSection.identity, PortalLanguage.ru) =>
      portal.isParent ? 'Мои дети' : 'Мой профиль',
    (PortalSection.identity, _) =>
      portal.isParent ? 'My children' : 'My profile',
    (PortalSection.assignments, PortalLanguage.ru) =>
      portal.isParent ? 'Задания ребёнка' : 'Задания',
    (PortalSection.assignments, _) =>
      portal.isParent ? 'Child assignments' : 'Assignments',
    (PortalSection.schedule, PortalLanguage.ru) =>
      portal.isParent ? 'Семейный календарь' : 'Расписание занятий',
    (PortalSection.schedule, _) =>
      portal.isParent ? 'Family calendar' : 'Class schedule',
    (PortalSection.academics, PortalLanguage.ru) =>
      portal.isParent ? 'Успеваемость ребёнка' : 'Мои результаты',
    (PortalSection.academics, _) =>
      portal.isParent ? 'Child academic progress' : 'My results',
    (PortalSection.placement, PortalLanguage.ru) => 'Тест уровня',
    (PortalSection.placement, _) => 'Level test',
    (PortalSection.content, PortalLanguage.ru) => 'Учебные материалы',
    (PortalSection.content, _) => 'Learning materials',
    (PortalSection.attendance, PortalLanguage.ru) =>
      portal.isParent ? 'Посещаемость ребёнка' : 'Моя посещаемость',
    (PortalSection.attendance, _) =>
      portal.isParent ? 'Child attendance' : 'My attendance',
    (PortalSection.messages, PortalLanguage.ru) =>
      portal.isParent ? 'Чат со школой' : 'Чат',
    (PortalSection.messages, _) => portal.isParent ? 'School chat' : 'Chat',
    (PortalSection.ai, PortalLanguage.ru) => 'ИИ-помощник',
    (PortalSection.ai, _) => 'AI assistant',
    (PortalSection.notifications, PortalLanguage.ru) =>
      portal.isParent ? 'Важные уведомления' : 'Уведомления',
    (PortalSection.notifications, _) =>
      portal.isParent ? 'Important updates' : 'Notifications',
    (PortalSection.forms, PortalLanguage.ru) => 'Опросы и формы',
    (PortalSection.forms, _) => 'Forms and surveys',
    (PortalSection.achievements, PortalLanguage.ru) =>
      portal.isParent ? 'Достижения ребёнка' : 'Мои достижения',
    (PortalSection.achievements, _) =>
      portal.isParent ? 'Child achievements' : 'My achievements',
    (PortalSection.discipline, PortalLanguage.ru) => 'Правила и дисциплина',
    (PortalSection.discipline, _) => 'Rules and discipline',
    (PortalSection.finance, PortalLanguage.ru) => 'Платежи и счета',
    (PortalSection.finance, _) => 'Payments and invoices',
    (PortalSection.cards, PortalLanguage.ru) => 'Карта и кошелёк',
    (PortalSection.cards, _) => 'Card and wallet',
    (PortalSection.account, PortalLanguage.ru) => 'Профиль и безопасность',
    (PortalSection.account, _) => 'Profile and security',
  };
}

String _portalSectionPageSubtitle(
  PortalController portal,
  PortalSection section,
  String fallback,
) {
  final language = portal.preferences.language;
  if (language == PortalLanguage.uz) return fallback;
  return switch ((section, language)) {
    (PortalSection.home, PortalLanguage.ru) =>
      portal.isParent
          ? 'Учёба, посещаемость и финансовое состояние ребёнка.'
          : 'Актуальная учебная информация с сервера центра.',
    (PortalSection.home, _) =>
      portal.isParent
          ? 'Learning, attendance and financial status for your child.'
          : 'Current learning information from the center server.',
    (PortalSection.identity, PortalLanguage.ru) =>
      portal.isParent
          ? 'Дети, представители и разрешённые лица.'
          : 'Личные и учебные данные вашего профиля.',
    (PortalSection.identity, _) =>
      portal.isParent
          ? 'Children, guardians and authorized people.'
          : 'Your personal and academic profile details.',
    (PortalSection.assignments, PortalLanguage.ru) =>
      'Задания, сроки, отправленные работы и оценки.',
    (PortalSection.assignments, _) =>
      'Assignments, deadlines, submissions and grades.',
    (PortalSection.schedule, PortalLanguage.ru) =>
      'Занятия, время, преподаватели и кабинеты.',
    (PortalSection.schedule, _) => 'Classes, times, teachers and rooms.',
    (PortalSection.academics, PortalLanguage.ru) =>
      'Экзамены, оценки и учебные результаты.',
    (PortalSection.academics, _) => 'Exams, grades and academic results.',
    (PortalSection.placement, PortalLanguage.ru) =>
      'Личный кабинет определения учебного уровня.',
    (PortalSection.placement, _) =>
      'Your personal learning-level assessment area.',
    (PortalSection.content, PortalLanguage.ru) =>
      'Курсы, уроки, файлы и библиотека центра.',
    (PortalSection.content, _) =>
      'Courses, lessons, files and the center library.',
    (PortalSection.attendance, PortalLanguage.ru) =>
      'Отметки посещаемости за текущий учебный период.',
    (PortalSection.attendance, _) =>
      'Attendance records for the current academic period.',
    (PortalSection.messages, PortalLanguage.ru) =>
      'Личные и групповые беседы с преподавателями.',
    (PortalSection.messages, _) =>
      'Private and group conversations with teachers.',
    (PortalSection.ai, PortalLanguage.ru) =>
      'Ответы на основе ваших учебных данных.',
    (PortalSection.ai, _) => 'Answers grounded in your learning data.',
    (PortalSection.notifications, PortalLanguage.ru) =>
      'События школы, сообщения и обновления безопасности.',
    (PortalSection.notifications, _) =>
      'School events, messages and security updates.',
    (PortalSection.forms, PortalLanguage.ru) =>
      'Открытые формы, согласия и опросы.',
    (PortalSection.forms, _) => 'Open forms, consents and surveys.',
    (PortalSection.achievements, PortalLanguage.ru) =>
      'Подтверждённые центром награды и достижения.',
    (PortalSection.achievements, _) =>
      'Awards and achievements confirmed by the center.',
    (PortalSection.discipline, PortalLanguage.ru) =>
      'Правила центра и связанные записи.',
    (PortalSection.discipline, _) => 'Center rules and related records.',
    (PortalSection.finance, PortalLanguage.ru) =>
      'Счета и остаток задолженности без списания денег.',
    (PortalSection.finance, _) =>
      'Invoices and outstanding balance without charging money.',
    (PortalSection.cards, PortalLanguage.ru) =>
      'Активные карты и история школьного кошелька.',
    (PortalSection.cards, _) => 'Active cards and school wallet history.',
    (PortalSection.account, PortalLanguage.ru) =>
      'Личные данные, устройства, язык и внешний вид.',
    (PortalSection.account, _) =>
      'Personal details, devices, language and appearance.',
  };
}

const Map<String, (String, String)> _portalUiTranslations = {
  'Darslar': ('Занятия', 'Classes'),
  'Yaqin darslar': ('Ближайшие занятия', 'Upcoming classes'),
  'Yaqin vazifalar': ('Ближайшие задания', 'Upcoming assignments'),
  'So‘nggi natijalar': ('Последние результаты', 'Recent results'),
  'Ochiq vazifalar': ('Открытые задания', 'Open assignments'),
  'Vazifalar': ('Задания', 'Assignments'),
  'Davomat': ('Посещаемость', 'Attendance'),
  'O‘z vaqtida': ('Вовремя', 'On time'),
  'Keldi': ('Присутствовал', 'Present'),
  'Kechikdi': ('Опоздал', 'Late'),
  'Kelmadi': ('Отсутствовал', 'Absent'),
  'Guruh': ('Группа', 'Group'),
  'Qarzdorlik': ('Задолженность', 'Outstanding'),
  'O‘qish pulsi': ('Учебный прогресс', 'Learning pulse'),
  'Farzand o‘qish pulsi': ('Учебный прогресс ребёнка', 'Child learning pulse'),
  'So‘nggi davomat': ('Последняя посещаемость', 'Recent attendance'),
  'Davomat taqsimoti': ('Распределение посещаемости', 'Attendance breakdown'),
  'Jami qarzdorlik': ('Общая задолженность', 'Total outstanding'),
  'Hisob-fakturalar': ('Счета', 'Invoices'),
  'Muddati o‘tgan': ('Просрочено', 'Overdue'),
  'Yakuniy baholar': ('Итоговые оценки', 'Final grades'),
  'Imtihonlar': ('Экзамены', 'Exams'),
  'Tabel so‘rovlari': ('Запросы табеля', 'Transcript requests'),
  'Fanlar bo‘yicha o‘zlashtirish': (
    'Успеваемость по предметам',
    'Progress by subject',
  ),
  'O‘quv materiallari': ('Учебные материалы', 'Learning materials'),
  'Yordamchi bilan suhbat': ('Диалог с помощником', 'Assistant conversation'),
  'Bildirishnoma sozlamalari': (
    'Настройки уведомлений',
    'Notification settings',
  ),
  'Yutuqlar devori': ('Стена достижений', 'Achievement wall'),
  'Yutuqlar katalogi': ('Каталог достижений', 'Achievement catalog'),
  'Menga tegishli qoidalar': ('Мои правила', 'Rules that apply to me'),
  'Intizom yozuvlari': ('Записи дисциплины', 'Discipline records'),
  'Sinovlar tarixi': ('История тестов', 'Test history'),
  'Mening kartalarim': ('Мои карты', 'My cards'),
  'Hamyon tarixi': ('История кошелька', 'Wallet history'),
  'Faol qurilmalar': ('Активные устройства', 'Active devices'),
  'Tezkor sozlamalar': ('Быстрые настройки', 'Quick settings'),
  'Ilova ko‘rinishi': ('Внешний вид', 'Appearance'),
  'Qulaylik': ('Доступность', 'Accessibility'),
  'Chat ko‘rinishi': ('Оформление чата', 'Chat appearance'),
  'Jadval bo‘sh': ('Расписание пусто', 'Schedule is empty'),
  'Hozircha ko‘rinadigan dars mavjud emas.': (
    'Пока нет доступных занятий.',
    'There are no visible classes yet.',
  ),
  'Vazifa yo‘q': ('Заданий нет', 'No assignments'),
  'Ochiq vazifa yo‘q': ('Открытых заданий нет', 'No open assignments'),
  'Yaqin dars yo‘q': ('Ближайших занятий нет', 'No upcoming classes'),
  'Davomat yozuvi yo‘q': ('Записей посещаемости нет', 'No attendance records'),
  'Baho yo‘q': ('Оценок нет', 'No grades'),
  'Imtihon e’lon qilinmagan': ('Экзамены не объявлены', 'No exams announced'),
  'Tabel so‘rovi yo‘q': ('Запросов табеля нет', 'No transcript requests'),
  'Material yo‘q': ('Материалов нет', 'No materials'),
  'Fayl yo‘q': ('Файлов нет', 'No files'),
  'Kutubxona yo‘q': ('Библиотека пуста', 'Library is empty'),
  'Modul yo‘q': ('Модулей нет', 'No modules'),
  'Bildirishnoma yo‘q': ('Уведомлений нет', 'No notifications'),
  'Ochiq so‘rovnoma yo‘q': ('Открытых опросов нет', 'No open forms'),
  'Yutuq hali yo‘q': ('Достижений пока нет', 'No achievements yet'),
  'Qoida yo‘q': ('Правил нет', 'No rules'),
  'Intizom yozuvi yo‘q': ('Записей дисциплины нет', 'No discipline records'),
  'Savollar topilmadi': ('Вопросы не найдены', 'No questions found'),
  'Hisob-faktura yo‘q': ('Счетов нет', 'No invoices'),
  'Karta berilmagan': ('Карта не выпущена', 'No card issued'),
  'Operatsiya yo‘q': ('Операций нет', 'No transactions'),
  'Qurilma ro‘yxati bo‘sh': ('Список устройств пуст', 'Device list is empty'),
  'Ma’lumotlar yuklanmoqda': ('Загружаем данные', 'Loading your information'),
  'Bir oz kuting — kerakli ma’lumotlarni xavfsiz tayyorlayapmiz.': (
    'Пожалуйста, подождите — мы безопасно подготавливаем нужные данные.',
    'Please wait while we securely prepare the information you need.',
  ),
  'Bo‘limni yuklab bo‘lmadi': (
    'Не удалось загрузить раздел',
    'We could not load this section',
  ),
  'Qayta urinish': ('Повторить', 'Try again'),
  'Yangi voqealar shu yerda ko‘rinadi.': (
    'Новые события появятся здесь.',
    'New events will appear here.',
  ),
  'Ustoz belgilagan yozuvlar shu yerda ko‘rinadi.': (
    'Отметки преподавателя появятся здесь.',
    'Teacher records will appear here.',
  ),
  'Yangi hisob chiqarilganda shu yerda ko‘rinadi.': (
    'Новые счета появятся здесь.',
    'New invoices will appear here.',
  ),
  'Hamyon harakatlari shu yerda ko‘rinadi.': (
    'Операции кошелька появятся здесь.',
    'Wallet activity will appear here.',
  ),
};

String _portalUiLiteral(BuildContext context, String value) {
  final language = PortalScope.of(context).preferences.language;
  if (language == PortalLanguage.uz) return value;
  final row = _portalUiTranslations[value];
  if (row == null) return value;
  return language == PortalLanguage.ru ? row.$1 : row.$2;
}

bool _optionalFailureBelongsTo(PortalSection section, String path) =>
    switch (section) {
      PortalSection.home =>
        path.contains('/notifications/') || path.contains('/finance/'),
      PortalSection.identity =>
        path.contains('/students/') || path.contains('/parents/'),
      PortalSection.assignments => path.contains('/assignments/'),
      PortalSection.schedule => path.contains('/schedule/'),
      PortalSection.academics => path.contains('/academics/'),
      PortalSection.placement => path.contains('/placement/'),
      PortalSection.content => path.contains('/content/'),
      PortalSection.attendance => path.contains('/attendance/'),
      PortalSection.messages => path.contains('/messaging/'),
      PortalSection.ai => path.contains('/ai/'),
      PortalSection.notifications => path.contains('/notifications/'),
      PortalSection.forms => path.contains('/forms/'),
      PortalSection.achievements => path.contains('/achievements/'),
      PortalSection.discipline => path.contains('/rulebook/'),
      PortalSection.finance => path.contains('/finance/'),
      PortalSection.cards => path.contains('/cards/'),
      PortalSection.account => path.contains('/users/'),
    };

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final effectivePadding = mobile && padding == const EdgeInsets.all(14)
        ? const EdgeInsets.all(12)
        : padding;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mobile ? 14 : 16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(padding: effectivePadding, child: child),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SectionCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: colors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Sf.monoStyle(
              size: 21,
              weight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _portalUiLiteral(context, label).toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Sf.eyebrow(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, this.minWidth = 220});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.isEmpty) return const SizedBox.shrink();
        final count = (constraints.maxWidth / minWidth).floor().clamp(1, 4);
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return _SectionCard(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 8 : 18,
          vertical: mobile ? 20 : 30,
        ),
        child: Column(
          children: [
            Container(
              width: mobile ? 52 : 60,
              height: mobile ? 52 : 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryContainer, colors.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(mobile ? 17 : 20),
              ),
              child: Icon(icon, size: mobile ? 24 : 28, color: colors.primary),
            ),
            SizedBox(height: mobile ? 13 : 16),
            Text(
              _portalUiLiteral(context, title),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Text(
                _portalUiLiteral(context, message),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = error ? colors.errorContainer : colors.primaryContainer;
    final foreground = error
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _SectionCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    size: 30,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _portalUiLiteral(context, 'Bo‘limni yuklab bo‘lmadi'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _portalUiLiteral(context, message),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_portalUiLiteral(context, 'Qayta urinish')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalSectionSkeleton extends StatelessWidget {
  const _PortalSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: _portalUiLiteral(context, 'Ma’lumotlar yuklanmoqda'),
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: _SectionCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        color: colors.primary,
                        backgroundColor: colors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _portalUiLiteral(context, 'Ma’lumotlar yuklanmoqda'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _portalUiLiteral(
                        context,
                        'Bir oz kuting — kerakli ma’lumotlarni xavfsiz tayyorlayapmiz.',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.text, {this.positive = false, this.warning = false});

  final String text;
  final bool positive;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = positive
        ? colors.primaryContainer
        : warning
        ? colors.tertiaryContainer
        : colors.surfaceContainerHighest;
    final foreground = positive
        ? colors.onPrimaryContainer
        : warning
        ? colors.onTertiaryContainer
        : colors.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _statusLabelFor(context, text),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

String _statusLabelFor(BuildContext context, String raw) {
  final language = PortalScope.of(context).preferences.language;
  if (language == PortalLanguage.uz) return _statusLabel(raw);
  final value = raw.toLowerCase();
  if (language == PortalLanguage.ru) {
    return switch (value) {
      'published' || 'e’lon qilingan' => 'Опубликовано',
      'submitted' || 'topshirilgan' => 'Отправлено',
      'graded' || 'baholangan' => 'Оценено',
      'returned' || 'qayta ishlash' => 'На доработке',
      'scheduled' || 'rejada' => 'Запланировано',
      'cancelled' || 'canceled' || 'bekor qilingan' => 'Отменено',
      'present' || 'keldi' => 'Присутствовал',
      'absent' || 'kelmadi' => 'Отсутствовал',
      'late' || 'kechikdi' => 'Опоздал',
      'excused' || 'sababli' => 'По уважительной причине',
      'active' || 'faol' => 'Активно',
      'issued' || 'chiqarilgan' => 'Выпущено',
      'partially_paid' || 'qisman to‘langan' => 'Оплачено частично',
      'paid' || 'to‘langan' => 'Оплачено',
      'overdue' || 'muddati o‘tgan' => 'Просрочено',
      'pending' || 'kutilmoqda' => 'Ожидается',
      'ready' || 'generated' || 'tayyor' => 'Готово',
      _ => raw,
    };
  }
  return switch (value) {
    'published' || 'e’lon qilingan' => 'Published',
    'submitted' || 'topshirilgan' => 'Submitted',
    'graded' || 'baholangan' => 'Graded',
    'returned' || 'qayta ishlash' => 'Needs revision',
    'scheduled' || 'rejada' => 'Scheduled',
    'cancelled' || 'canceled' || 'bekor qilingan' => 'Cancelled',
    'present' || 'keldi' => 'Present',
    'absent' || 'kelmadi' => 'Absent',
    'late' || 'kechikdi' => 'Late',
    'excused' || 'sababli' => 'Excused',
    'active' || 'faol' => 'Active',
    'issued' || 'chiqarilgan' => 'Issued',
    'partially_paid' || 'qisman to‘langan' => 'Partially paid',
    'paid' || 'to‘langan' => 'Paid',
    'overdue' || 'muddati o‘tgan' => 'Overdue',
    'pending' || 'kutilmoqda' => 'Pending',
    'ready' || 'generated' || 'tayyor' => 'Ready',
    _ => raw,
  };
}

String _statusLabel(String raw) => switch (raw.toLowerCase()) {
  'published' => 'E’lon qilingan',
  'submitted' => 'Topshirilgan',
  'graded' => 'Baholangan',
  'returned' => 'Qayta ishlash',
  'scheduled' => 'Rejada',
  'cancelled' => 'Bekor qilingan',
  'present' => 'Keldi',
  'absent' => 'Kelmadi',
  'late' => 'Kechikdi',
  'excused' => 'Sababli',
  'active' => 'Faol',
  'issued' => 'Chiqarilgan',
  'partially_paid' => 'Qisman to‘langan',
  'paid' => 'To‘langan',
  'overdue' => 'Muddati o‘tgan',
  'pending' => 'Kutilmoqda',
  'ready' || 'generated' => 'Tayyor',
  'waived' => 'Bekor qilingan',
  _ => raw.isEmpty ? 'Noma’lum' : raw,
};

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .take(2);
  return parts.map((item) => item.characters.first.toUpperCase()).join();
}

String _errorText(Object error) =>
    error is ApiException ? error.message : 'Amal bajarilmadi.';

String _dateLabel(Object? raw, {bool time = false}) {
  final date = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (date == null) return '—';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  if (!time) return '$day.$month.${date.year}';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month · $hour:$minute';
}

String _compactDateLabel(Object? raw) {
  final value = _dateLabel(raw);
  return value.length <= 5 ? value : value.substring(0, 5);
}

String _money(
  BuildContext context,
  Object? raw, {
  PortalCurrency sourceCurrency = PortalCurrency.uzs,
  double? sourceToPreferredRate,
}) {
  final preferences = PortalScope.of(context).preferences;
  if (preferences.hideAmounts) {
    final conversionAvailable =
        sourceToPreferredRate != null &&
        sourceToPreferredRate.isFinite &&
        sourceToPreferredRate > 0;
    final hiddenCurrency =
        preferences.currency == sourceCurrency || conversionAvailable
        ? preferences.currency
        : sourceCurrency;
    return '•••• ${hiddenCurrency.code}';
  }
  final result = PortalMoneyFormatter.format(
    raw,
    language: preferences.language,
    sourceCurrency: sourceCurrency,
    preferredCurrency: preferences.currency,
    sourceToPreferredRate: sourceToPreferredRate,
  );
  if (!result.conversionUnavailable) return result.text;
  final warning = switch (preferences.language) {
    PortalLanguage.uz => 'kurs yo‘q',
    PortalLanguage.ru => 'нет курса',
    PortalLanguage.en => 'rate unavailable',
  };
  return '${result.text} · $warning';
}

Future<void> _runAction(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success)));
  } on Object catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(_errorText(error)),
      ),
    );
  }
}
