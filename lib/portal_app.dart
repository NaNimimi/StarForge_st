import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'portal_state.dart';
import 'starforge_api.dart';
import 'theme.dart';

part 'portal_pages.dart';
part 'portal_identity_pages.dart';
part 'portal_visuals.dart';

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
              'StarForge Oila',
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
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _PortalBrandMark(size: 48),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STARFORGE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Family workspace',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 44),
          Text(
            'Kabinetga kirish',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 9),
          Text(
            'O‘quv jarayoni, aloqa va oilaviy nazorat — bitta xavfsiz joyda.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 30),
          TextFormField(
            key: const ValueKey('portal-login-username'),
            controller: _username,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Login',
              hintText: 'Akkaunt logini',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Loginni kiriting' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('portal-login-password'),
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Parol',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Parolni ko‘rsatish' : 'Parolni yashirish',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value ?? '').isEmpty ? 'Parolni kiriting' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
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
              child: const Text('Parolni unutdingizmi?'),
            ),
          ),
          if (portal.authenticationError case final error?) ...[
            _InlineMessage(text: error, error: true),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('portal-login-submit'),
            onPressed: portal.authenticationBusy ? null : _submit,
            icon: portal.authenticationBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              portal.authenticationBusy ? 'Kirilmoqda…' : 'Davom etish',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'MARKAZ SOZLAMASI',
                  style: Sf.eyebrow(color: colors.onSurfaceVariant),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => setState(() => _showServer = !_showServer),
            icon: Icon(
              _showServer ? Icons.expand_less_rounded : Icons.dns_outlined,
            ),
            label: Text(_showServer ? 'Serverni yashirish' : 'Markaz serveri'),
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
                decoration: const InputDecoration(
                  labelText: 'Server manzili',
                  hintText: 'https://markaz.example.uz',
                  prefixIcon: Icon(Icons.language_rounded),
                ),
                validator: (value) {
                  try {
                    normalizeApiBaseUrl(value ?? '');
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
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final formPane = ColoredBox(
              color: colors.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 64 : 22,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: form,
                  ),
                ),
              ),
            );
            if (!wide) return formPane;
            return Row(
              children: [
                const Expanded(flex: 11, child: _LoginStoryPanel()),
                Expanded(flex: 9, child: formPane),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginStoryPanel extends StatelessWidget {
  const _LoginStoryPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101525),
      child: Stack(
        children: [
          const Positioned(
            right: -100,
            top: -80,
            child: _LoginOrbit(size: 440, color: Color(0xFF5968F2)),
          ),
          const Positioned(
            left: -130,
            bottom: -170,
            child: _LoginOrbit(size: 390, color: Color(0xFFFFC857)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 58, 56, 54),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LoginSignal(),
                const Spacer(),
                Text(
                  'Ta’lim jarayoni\nendi aniq ko‘rinadi.',
                  style: Sf.serif(
                    size: 54,
                    color: Colors.white,
                    height: 1.04,
                    italic: false,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 540,
                  child: Text(
                    'Darslar, natijalar, topshiriqlar va maktab bilan muloqot — o‘quvchi va oila uchun yagona raqamli makon.',
                    style: TextStyle(
                      color: Color(0xFFB8C0D6),
                      fontSize: 16,
                      height: 1.55,
                      fontFamily: Sf.ui,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _LoginFeature(
                      icon: Icons.bolt_rounded,
                      text: 'Tezkor holat',
                    ),
                    _LoginFeature(
                      icon: Icons.forum_outlined,
                      text: 'Himoyalangan chat',
                    ),
                    _LoginFeature(
                      icon: Icons.insights_rounded,
                      text: 'Aniq tahlil',
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'STARFORGE EDU  /  OILA PORTALI',
                  style: TextStyle(
                    color: Color(0xFF7F8AA7),
                    fontSize: 11,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w800,
                    fontFamily: Sf.mono,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSignal extends StatelessWidget {
  const _LoginSignal();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: 14, color: Color(0xFF65D6A6)),
        SizedBox(width: 8),
        Text(
          'XAVFSIZ KABINETGA KIRISH',
          style: TextStyle(
            color: Color(0xFFD7DCEE),
            fontSize: 10,
            letterSpacing: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _LoginFeature extends StatelessWidget {
  const _LoginFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFFAEB6FF)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LoginOrbit extends StatelessWidget {
  const _LoginOrbit({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.2), width: 42),
    ),
  );
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
        _message = 'Agar akkaunt mavjud bo‘lsa, tasdiqlash kodi yuborildi.';
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
        const SnackBar(content: Text('Parol yangilandi. Endi tizimga kiring.')),
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
      appBar: AppBar(title: const Text('Parolni tiklash')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'student', label: Text('O‘quvchi')),
              ButtonSegment(value: 'parent', label: Text('Ota-ona')),
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
            decoration: const InputDecoration(
              labelText: 'Login, telefon yoki email',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _server,
            enabled: !_codeSent,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Server manzili',
              prefixIcon: Icon(Icons.language_rounded),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tasdiqlash kodi',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yangi parol',
                helperText: 'Kamida 8 belgi',
                prefixIcon: Icon(Icons.password_rounded),
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
                  ? 'Kuting…'
                  : _codeSent
                  ? 'Parolni yangilash'
                  : 'Kod yuborish',
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
      setState(
        () => _error =
            'Yangi parol kamida 8 belgi bo‘lsin va ikkala maydon mos kelsin.',
      );
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
        title: const Text('Yangi parol'),
        actions: [
          TextButton(
            onPressed: _busy ? null : PortalScope.read(context).logout,
            child: const Text('Chiqish'),
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
                      'Vaqtinchalik parolni almashtiring',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _old,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Hozirgi parol',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _next,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Yangi parol',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Yangi parolni takrorlang',
                      ),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 14),
                      _InlineMessage(text: error, error: true),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? 'Saqlanmoqda…' : 'Parolni saqlash'),
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
        if (portal.can('content:read'))
          const _PortalDestination(
            PortalSection.content,
            'Kutubxona',
            Icons.local_library_outlined,
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
      const _PortalDestination(
        PortalSection.account,
        'Profil va xavfsizlik',
        Icons.manage_accounts_outlined,
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
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final drawer = _PortalNavigation(
      destinations: destinations,
      selectedIndex: selected,
      onSelected: (index) =>
          setState(() => _section = destinations[index].section),
    );
    final baseTheme = Theme.of(context);
    final accent = portal.isStudent
        ? const Color(0xFF5968F2)
        : const Color(0xFF235B62);
    final accentSoft = portal.isStudent
        ? const Color(0xFFE9EBFF)
        : const Color(0xFFE1F0F0);
    final accentInk = portal.isStudent
        ? const Color(0xFF273192)
        : const Color(0xFF174249);
    final roleScheme = baseTheme.colorScheme.copyWith(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accentSoft,
      onPrimaryContainer: accentInk,
      secondary: portal.isStudent
          ? const Color(0xFF25A978)
          : const Color(0xFFC86645),
      tertiary: portal.isStudent
          ? const Color(0xFF8B5CF6)
          : const Color(0xFF9A5AC7),
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
        builder: (roleContext) => Scaffold(
          drawer: wide
              ? null
              : Drawer(
                  width: 300,
                  backgroundColor: const Color(0xFF101525),
                  child: SafeArea(child: drawer),
                ),
          appBar: AppBar(
            automaticallyImplyLeading: !wide,
            toolbarHeight: 64,
            backgroundColor: roleScheme.surfaceContainerLowest,
            titleSpacing: wide ? 30 : 4,
            title: Row(
              children: [
                if (wide) ...[
                  Text(
                    portal.isParent ? 'OILA PORTALI' : 'O‘QUVCHI PORTALI',
                    style: Sf.eyebrow(color: roleScheme.onSurfaceVariant),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.chevron_right_rounded, size: 16),
                  ),
                ],
                Flexible(
                  child: Text(
                    destinations[selected].label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(roleContext).textTheme.titleMedium,
                  ),
                ),
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
              if (portal.unreadNotificationCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Badge(
                    label: Text('${portal.unreadNotificationCount}'),
                    child: IconButton(
                      tooltip: 'Bildirishnomalar',
                      onPressed: () => setState(
                        () => _section = PortalSection.notifications,
                      ),
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                ),
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
                tooltip: 'Profil',
                onPressed: () =>
                    setState(() => _section = PortalSection.account),
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: roleScheme.primary,
                  child: Text(
                    _initials(portal.displayName),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          body: Row(
            children: [
              if (wide) SizedBox(width: 268, child: drawer),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: roleScheme.surfaceContainerLowest,
                  ),
                  child: _PortalNavigationScope(
                    onNavigate: (section) => setState(() => _section = section),
                    child: _SectionHost(
                      key: ValueKey(
                        '${_section.name}-${portal.selectedStudentId ?? 0}',
                      ),
                      section: _section,
                    ),
                  ),
                ),
              ),
            ],
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
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: const Color(0xFF101525),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 18, 18),
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
                        style: const TextStyle(
                          color: Color(0xFF7F8AA7),
                          fontSize: 9,
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
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final group = _navigationGroup(item.section, portal.isParent);
                final previousGroup = index == 0
                    ? null
                    : _navigationGroup(
                        destinations[index - 1].section,
                        portal.isParent,
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
                          style: const TextStyle(
                            color: Color(0xFF66718D),
                            fontSize: 9,
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
                        selectedTileColor: accent,
                        tileColor: Colors.transparent,
                        hoverColor: selected
                            ? accent.withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.06),
                        focusColor: selected
                            ? accent.withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.09),
                        leading: Icon(
                          item.icon,
                          size: 20,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF9AA4BB),
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFFC8CEDD),
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
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  badge > 99 ? '99+' : '$badge',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected ? Colors.white : accent,
                                    fontSize: 9,
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
                          onSelected(index);
                          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                            Navigator.maybePop(context);
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
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          portal.isParent ? 'Ota-ona' : 'O‘quvchi',
                          style: const TextStyle(
                            color: Color(0xFF8993AA),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chiqish',
                    onPressed: portal.logout,
                    color: const Color(0xFF9AA4BB),
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

String _navigationGroup(PortalSection section, bool parent) =>
    switch (section) {
      PortalSection.home || PortalSection.identity => 'BOSH SAHIFA',
      PortalSection.assignments ||
      PortalSection.schedule ||
      PortalSection.attendance ||
      PortalSection.academics ||
      PortalSection.content => parent ? 'FARZAND TA’LIMI' : 'O‘QISH',
      PortalSection.messages || PortalSection.notifications => 'ALOQA',
      PortalSection.forms ||
      PortalSection.achievements ||
      PortalSection.discipline ||
      PortalSection.finance ||
      PortalSection.cards => parent ? 'OILA XIZMATLARI' : 'XIZMATLAR',
      PortalSection.account => 'TIZIM',
    };

class _SectionHost extends StatefulWidget {
  const _SectionHost({super.key, required this.section});

  final PortalSection section;

  @override
  State<_SectionHost> createState() => _SectionHostState();
}

class _SectionHostState extends State<_SectionHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PortalScope.read(context).loadSection(widget.section);
    });
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
      PortalSection.content => const _ContentPortalPage(),
      PortalSection.attendance => const _AttendancePortalPage(),
      PortalSection.messages => const _RebuiltMessagesPortalPage(),
      PortalSection.notifications => const _NotificationsPortalPage(),
      PortalSection.forms => const _FormsPortalPage(),
      PortalSection.achievements => const _AchievementsPortalPage(),
      PortalSection.discipline => const _DisciplinePortalPage(),
      PortalSection.finance => const _FinancePortalPage(),
      PortalSection.cards => const _CardsPortalPage(),
      PortalSection.account => const _AccountPortalPage(),
    };
    if (error == null) return content;
    return Column(
      children: [
        _StaleDataBanner(
          message: error,
          onRetry: () => portal.refresh(widget.section),
        ),
        Expanded(child: content),
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
    return RefreshIndicator(
      onRefresh: () => portal.refresh(section),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width >= 1024 ? 32 : 16,
          18,
          MediaQuery.sizeOf(context).width >= 1024 ? 32 : 16,
          40,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 680;
                      final heading = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
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
                              const SizedBox(height: 14),
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
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: colors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: Sf.ui,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
        final count = (constraints.maxWidth / minWidth).floor().clamp(1, 4);
        const gap = 16.0;
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
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(icon, size: 46, color: colors.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
                    Icons.cloud_off_rounded,
                    size: 30,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Bo‘limni yuklab bo‘lmadi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Qayta urinish'),
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
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    Widget block({required double height, double? width}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Semantics(
      label: 'Ma’lumotlar yuklanmoqda',
      liveRegion: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
                const SizedBox(height: 22),
                block(height: 12, width: 124),
                const SizedBox(height: 12),
                block(height: 32, width: 280),
                const SizedBox(height: 9),
                block(height: 14, width: 420),
                const SizedBox(height: 24),
                block(height: 152),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var index = 0; index < 4; index++)
                        block(
                          height: 82,
                          width: constraints.maxWidth >= 900
                              ? (constraints.maxWidth - 36) / 4
                              : constraints.maxWidth >= 520
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                block(height: 220),
              ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(text),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
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

String _money(Object? raw) {
  final value = double.tryParse('${raw ?? ''}');
  if (value == null) return '—';
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} so‘m';
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
