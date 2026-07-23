import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const StarForgeApp());
}

class StarForgeApp extends StatelessWidget {
  const StarForgeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StarForge EDU · Ota-ona / O‘quvchi',
      debugShowCheckedModeBanner: false,
      theme: Sf.theme(),
      home: const FamilyShell(),
    );
  }
}

class NavItem {
  final String id, label;
  final IconData icon;
  final int badge;
  const NavItem(this.id, this.label, this.icon, {this.badge = 0});
}

class RoleCfg {
  final AppRole role;
  final String who, firstName, roleLabel, sub;
  final Color accent, accentInk;
  final List<NavItem> nav;
  const RoleCfg({
    required this.role,
    required this.who,
    required this.firstName,
    required this.roleLabel,
    required this.sub,
    required this.accent,
    required this.accentInk,
    required this.nav,
  });
}

const _parentCfg = RoleCfg(
  role: AppRole.parent,
  who: 'Akbarova Dilnoza',
  firstName: 'Akbarova',
  roleLabel: 'Ota-ona',
  sub: 'Akmal · 9-B ona',
  accent: Sf.primary,
  accentInk: Sf.primaryInk,
  nav: [
    NavItem('home', 'Bosh sahifa', Icons.home_rounded),
    NavItem('child', 'Farzandim', Icons.person_rounded),
    NavItem('attendance', 'Davomat', Icons.check_circle_rounded),
    NavItem('cards', 'Kartalar', Icons.star_rounded),
    NavItem('schedule', 'Jadval', Icons.calendar_today_rounded),
    NavItem('payments', 'To‘lovlar', Icons.trending_up_rounded, badge: 1),
    NavItem('messages', 'Xabarlar', Icons.chat_bubble_rounded, badge: 2),
    NavItem('settings', 'Sozlamalar', Icons.settings_rounded),
  ],
);

const _studentCfg = RoleCfg(
  role: AppRole.student,
  who: 'Akbarov Akmal',
  firstName: 'Akbarov',
  roleLabel: 'O‘quvchi',
  sub: '9-B · 14 yosh',
  accent: Sf.accent,
  accentInk: Sf.accentInk,
  nav: [
    NavItem('home', 'Bugun', Icons.home_rounded),
    NavItem('groups', 'Guruhlarim', Icons.groups_rounded, badge: 3),
    NavItem('attendance', 'Davomatim', Icons.check_circle_rounded),
    NavItem('cards', 'Kartalarim', Icons.star_rounded),
    NavItem('materials', 'Materiallar', Icons.folder_rounded),
    NavItem('schedule', 'Jadval', Icons.calendar_today_rounded),
    NavItem('messages', 'Xabarlar', Icons.chat_bubble_rounded, badge: 1),
    NavItem('ai', 'AI repetitor', Icons.auto_awesome_rounded),
    NavItem('settings', 'Sozlamalar', Icons.settings_rounded),
  ],
);

RoleCfg cfgOf(AppRole r) => r == AppRole.parent ? _parentCfg : _studentCfg;

const double kWideBreakpoint = 980;

class FamilyShell extends StatefulWidget {
  const FamilyShell({super.key});
  @override
  State<FamilyShell> createState() => _FamilyShellState();
}

class _FamilyShellState extends State<FamilyShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AppRole _role = AppRole.parent;
  String _active = 'home';

  RoleCfg get _cfg => cfgOf(_role);
  NavItem get _current => _cfg.nav.firstWhere((n) => n.id == _active, orElse: () => _cfg.nav.first);

  void _nav(String id) {
    setState(() => _active = id);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _switchRole(AppRole r) {
    if (r == _role) return;
    setState(() {
      _role = r;
      _active = cfgOf(r).nav.first.id;
    });
    sfToast(context, '${cfgOf(r).roleLabel} sifatida kirildi', sub: cfgOf(r).who, tone: cfgOf(r).accent);
  }

  Widget _page(String id) {
    switch (id) {
      case 'home':
        return _role == AppRole.parent ? ParentHomeScreen(onNav: _nav) : HomeScreen(onNav: _nav);
      case 'child':
        return ChildScreen(onNav: _nav);
      case 'groups':
        return const GroupsScreen();
      case 'attendance':
        return AttendanceScreen(role: _role);
      case 'cards':
        return CardsScreen(role: _role);
      case 'materials':
        return const MaterialsScreen();
      case 'schedule':
        return const ScheduleScreen();
      case 'payments':
        return const PaymentsScreen();
      case 'messages':
        return MessagesScreen(role: _role);
      case 'ai':
        return const AiScreen();
      case 'settings':
        return SettingsScreen(role: _role);
      default:
        return _role == AppRole.parent ? ParentHomeScreen(onNav: _nav) : HomeScreen(onNav: _nav);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Sf.bg,
      drawerEdgeDragWidth: 32,
      drawer: Drawer(
        backgroundColor: Sf.surface,
        width: 260,
        child: _SideNav(
          cfg: _cfg,
          active: _active,
          onNav: _nav,
          onClose: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth >= kWideBreakpoint;
          final column = Column(children: [
            _TopBar(
              cfg: _cfg,
              current: _current,
              showBurger: !wide,
              onBurger: () => _scaffoldKey.currentState?.openDrawer(),
              onSwitchRole: _switchRole,
            ),
            Expanded(
              child: DotPattern(
                child: SingleChildScrollView(
                  key: ValueKey('${_role.name}-$_active'),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1560),
                      child: Padding(
                        padding: wide
                            ? const EdgeInsets.fromLTRB(28, 24, 28, 90)
                            : const EdgeInsets.fromLTRB(14, 16, 14, 90),
                        child: _page(_active),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]);
          if (wide) {
            return Row(children: [
              SizedBox(
                width: 244,
                child: _SideNav(cfg: _cfg, active: _active, onNav: _nav),
              ),
              Expanded(child: column),
            ]);
          }
          return column;
        }),
      ),
    );
  }
}

// ─────────────────────────── SIDEBAR ───────────────────────────
class _SideNav extends StatelessWidget {
  final RoleCfg cfg;
  final String active;
  final NavCb onNav;
  final VoidCallback? onClose;
  const _SideNav({required this.cfg, required this.active, required this.onNav, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Sf.surface,
        border: Border(right: BorderSide(color: Sf.border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 12),
          child: Row(children: [
            SfStar(size: 26, color: cfg.accent),
            const SizedBox(width: 9),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                RichText(
                  text: TextSpan(style: Sf.t(size: 14.5, weight: FontWeight.w700, color: Sf.ink, letterSpacing: -0.3), children: [
                    const TextSpan(text: 'StarForge'),
                    TextSpan(text: ' · EDU', style: Sf.t(size: 14.5, weight: FontWeight.w500, color: Sf.muted)),
                  ]),
                ),
                const SizedBox(height: 1),
                Text(cfg.roleLabel, style: Sf.t(size: 10.5, weight: FontWeight.w700, color: cfg.accent)),
              ]),
            ),
            if (onClose != null)
              _MiniIcon(icon: Icons.close_rounded, onTap: onClose!),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            children: [
              for (final n in cfg.nav)
                _NavBtn(
                  item: n,
                  accent: cfg.accent,
                  active: n.id == active,
                  onTap: () => onNav(n.id),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final NavItem item;
  final Color accent;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({required this.item, required this.accent, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: active ? accent : Sf.surface2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(children: [
              Icon(item.icon, size: 18, color: active ? const Color(0xFFFFFCF5) : Sf.muted),
              const SizedBox(width: 11),
              Expanded(
                child: Text(item.label,
                    style: Sf.t(
                        size: 13,
                        weight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? const Color(0xFFFFFCF5) : Sf.ink2)),
              ),
              if (item.badge > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0x40FFFCF5) : Sf.surface3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${item.badge}',
                      style: Sf.monoStyle(
                          size: 10,
                          weight: FontWeight.w700,
                          color: active ? const Color(0xFFFFFCF5) : Sf.ink2)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── TOP BAR ───────────────────────────
class _TopBar extends StatelessWidget {
  final RoleCfg cfg;
  final NavItem current;
  final bool showBurger;
  final VoidCallback onBurger;
  final ValueChanged<AppRole> onSwitchRole;
  const _TopBar({
    required this.cfg,
    required this.current,
    required this.showBurger,
    required this.onBurger,
    required this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Sf.surface,
        border: Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(children: [
        if (showBurger) ...[
          _MiniIcon(icon: Icons.menu_rounded, onTap: onBurger),
          const SizedBox(width: 12),
        ],
        Icon(current.icon, size: 16, color: cfg.accent),
        const SizedBox(width: 8),
        Text(current.label, style: Sf.t(size: 14, weight: FontWeight.w700)),
        const Spacer(),
        if (!showBurger) ...[
          const _SearchBox(),
          const SizedBox(width: 12),
        ],
        const _BellButton(),
        const SizedBox(width: 8),
        _RoleSwitcher(cfg: cfg, onSwitchRole: onSwitchRole),
      ]),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Material(
        color: Sf.bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => sfToast(context, 'Qidiruv ochildi', tone: Sf.primary),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Sf.border),
            ),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 15, color: Sf.muted),
              const SizedBox(width: 8),
              Text('Izlash...', style: Sf.t(size: 13, color: Sf.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface2,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 18, color: Sf.ink2)),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => sfToast(context, '3 ta yangi bildirishnoma', tone: Sf.primary),
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_rounded, size: 18, color: Sf.ink2),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Sf.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Sf.surface, width: 2),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final RoleCfg cfg;
  final ValueChanged<AppRole> onSwitchRole;
  const _RoleSwitcher({required this.cfg, required this.onSwitchRole});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppRole>(
      tooltip: 'Rolni almashtirish',
      offset: const Offset(0, 46),
      color: Sf.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Sf.border),
      ),
      onSelected: onSwitchRole,
      itemBuilder: (ctx) => [
        PopupMenuItem<AppRole>(
          enabled: false,
          height: 30,
          child: Text('ROLNI ALMASHTIRISH · DEMO',
              style: Sf.t(size: 10, weight: FontWeight.w700, color: Sf.muted, letterSpacing: 0.6)),
        ),
        for (final r in const [AppRole.parent, AppRole.student])
          PopupMenuItem<AppRole>(
            value: r,
            child: _RoleOptionRow(cfg: cfgOf(r), selected: r == cfg.role),
          ),
        PopupMenuItem<AppRole>(
          enabled: false,
          height: 34,
          child: Container(
            width: 232,
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Sf.border))),
            child: Text('Har rol turli sahifa va ruxsatlarni ko‘radi',
                style: Sf.t(size: 10, color: Sf.muted)),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 9, 5),
        decoration: BoxDecoration(
          color: Sf.surface2,
          border: Border.all(color: Sf.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Avatar(cfg.who, size: 30, color: cfg.accent),
          const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(cfg.who, style: Sf.t(size: 12.5, weight: FontWeight.w700, height: 1.1)),
            Text(cfg.roleLabel, style: Sf.t(size: 10, weight: FontWeight.w700, color: cfg.accent)),
          ]),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more_rounded, size: 14, color: Sf.muted),
        ]),
      ),
    );
  }
}

class _RoleOptionRow extends StatelessWidget {
  final RoleCfg cfg;
  final bool selected;
  const _RoleOptionRow({required this.cfg, required this.selected});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      child: Row(children: [
        Avatar(cfg.who, size: 28, color: cfg.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(cfg.who, style: Sf.t(size: 12.5, weight: FontWeight.w700)),
            Text('${cfg.roleLabel} · ${cfg.nav.length - 1} sahifa',
                style: Sf.t(size: 10.5, color: Sf.muted)),
          ]),
        ),
        if (selected) Icon(Icons.check_rounded, size: 15, color: cfg.accent),
      ]),
    );
  }
}
