import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'family_data.dart';
import 'family_messaging.dart';
import 'theme.dart';
import 'toolkit.dart';

enum FamilyRole { parent, student }

enum MainDestination { home, study, calendar, messages, more }

class FamilyExperience extends StatefulWidget {
  const FamilyExperience({super.key});

  @override
  State<FamilyExperience> createState() => _FamilyExperienceState();
}

class _FamilyExperienceState extends State<FamilyExperience> {
  final _shellKey = GlobalKey<ScaffoldState>();
  FamilyRole _role = FamilyRole.student;
  MainDestination _destination = MainDestination.home;
  _StudyMode _studyMode = _StudyMode.tasks;
  String _activeThreadId = 'student-thread-algebra';
  bool _openMessageThreadOnPhone = false;

  AppState get _state => AppScope.read(context);
  String get _messagingScope => _state.messagingScopeForRole(_role.name);

  String get _profileName =>
      _state.profileNames[_role.name] ??
      (_role == FamilyRole.parent ? 'Akbarova Dilnoza' : 'Akbarov Akmal');

  void _select(MainDestination value) {
    if (_destination == value) return;
    setState(() {
      _destination = value;
      if (value == MainDestination.messages) {
        _openMessageThreadOnPhone = false;
      }
    });
  }

  void _selectPrimaryIndex(int index) {
    final destination = MainDestination.values[index];
    if (destination == MainDestination.study) {
      _openStudy(_StudyMode.tasks);
    } else {
      _select(destination);
    }
  }

  void _openStudy([_StudyMode mode = _StudyMode.tasks]) {
    setState(() {
      _studyMode = mode;
      _destination = MainDestination.study;
    });
  }

  void _switchRole(FamilyRole role) {
    if (_role == role) return;
    setState(() {
      _role = role;
      _destination = MainDestination.home;
      _studyMode = _StudyMode.tasks;
      _activeThreadId = '${role.name}-thread-algebra';
      _openMessageThreadOnPhone = false;
    });
    _announce(
      role == FamilyRole.parent
          ? 'Ota-ona profili ochildi'
          : 'O‘quvchi profili ochildi',
    );
  }

  void _openMessages([String? draft]) {
    final defaultThread = '${_role.name}-thread-algebra';
    setState(() {
      if (_state.messaging.thread(_messagingScope, _activeThreadId) == null) {
        _activeThreadId = defaultThread;
      }
      if (draft != null) {
        _activeThreadId = defaultThread;
        _state.messaging.setDraft(_messagingScope, _activeThreadId, draft);
      }
      _openMessageThreadOnPhone = draft != null;
      _destination = MainDestination.messages;
    });
  }

  void _openPaymentsFromNotice() {
    if (_role != FamilyRole.parent) {
      setState(() => _role = FamilyRole.parent);
    }
    _push(_PaymentsDetail(announce: _announce));
  }

  void _openSearch() {
    _showGlobalSearch(
      context,
      _role,
      onStudy: _openStudy,
      onGrades: () => _openStudy(_StudyMode.grades),
      onCalendar: () => _select(MainDestination.calendar),
      onMessages: () => _openMessages(),
      onFeature: _openFeature,
    );
  }

  void _openNotifications() {
    _showNotifications(context, role: _role, onOpen: _openNotice);
  }

  void _openNotice(AppNotice notice) {
    _state.markNoticeReadForRole(notice.id, _role.name);
    switch (notice.destination) {
      case NoticeDestination.home:
        _select(MainDestination.home);
      case NoticeDestination.study:
        final event = notice.eventType ?? '';
        _openStudy(
          event.contains('grade') ? _StudyMode.grades : _StudyMode.tasks,
        );
      case NoticeDestination.calendar:
        if ((notice.eventType ?? '').startsWith('attendance')) {
          _openFeature(FeatureRoute.attendance);
        } else {
          _select(MainDestination.calendar);
        }
      case NoticeDestination.messages:
        final target = notice.entityId;
        if (target != null &&
            _state.messaging.thread(_messagingScope, target) != null) {
          setState(() {
            _activeThreadId = target;
            _openMessageThreadOnPhone = true;
            _destination = MainDestination.messages;
          });
        } else if (target == null) {
          _openMessages();
        } else {
          _showSimpleDetail(context, notice.title, notice.body);
        }
      case NoticeDestination.payments:
        if (_role == FamilyRole.parent) _openPaymentsFromNotice();
      case NoticeDestination.achievements:
        _openFeature(FeatureRoute.achievements);
      case NoticeDestination.announcements:
        _openFeature(FeatureRoute.announcements);
      case NoticeDestination.noticeDetails:
        _showSimpleDetail(context, notice.title, notice.body);
    }
  }

  Future<void> _sendMessage(String threadId, String text) async {
    final sent = await _state.messaging.sendText(
      scope: _messagingScope,
      threadId: threadId,
      senderId: _state.messagingUserIdForRole(_role.name),
      text: text,
    );
    if (!mounted) return;
    _announce(
      sent ? 'Xabar qurilmada saqlandi' : 'Xabar saqlanmadi',
      detail: sent
          ? 'Family server ulanmaguncha bu lokal yozishma.'
          : 'Matn saqlandi, qayta yuborish mumkin.',
    );
  }

  void _selectThread(String threadId) {
    if (_activeThreadId == threadId) return;
    _state.messaging.markRead(_messagingScope, threadId);
    setState(() => _activeThreadId = threadId);
  }

  void _saveMessageDraft(String threadId, String value) =>
      _state.messaging.setDraft(_messagingScope, threadId, value);

  void _toggleThreadMute(String threadId) =>
      _state.messaging.toggleMuted(_messagingScope, threadId);

  void _announce(String text, {String? detail}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              if (detail != null)
                Text(
                  detail,
                  style: TextStyle(
                    color: Theme.of(context)
                        .snackBarTheme
                        .contentTextStyle
                        ?.color
                        ?.withValues(alpha: 0.74),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final phone = size.shortestSide < 600;
    final expanded = !phone && size.width >= 840;
    final medium = !phone && !expanded;
    final destinations = _navigationItems(_role);
    final selectedIndex = MainDestination.values.indexOf(_destination);
    final richItems = _richNavigationItems();
    final activeRichId = _activeRichNavigationId;
    final showSectionTopBar = _destination != MainDestination.messages;
    final page = switch (_destination) {
      MainDestination.home => _HomePage(
        role: _role,
        name: _profileName,
        onStudy: _openStudy,
        onGrades: () => _openStudy(_StudyMode.grades),
        onMaterials: () => _openStudy(_StudyMode.materials),
        onCalendar: () => _select(MainDestination.calendar),
        onMessages: _openMessages,
        onNotifications: _openNotifications,
        onNotice: _openNotice,
        onFeature: _openFeature,
      ),
      MainDestination.study => _StudyPage(
        role: _role,
        initialMode: _studyMode,
        onModeChanged: _openStudy,
        onMessage: _openMessages,
        announce: _announce,
      ),
      MainDestination.calendar => _CalendarPage(announce: _announce),
      MainDestination.messages => _MessagesPage(
        role: _role,
        scope: _messagingScope,
        threadId: _activeThreadId,
        initiallyOpenThread: _openMessageThreadOnPhone,
        onThread: _selectThread,
        onDraftChanged: _saveMessageDraft,
        onMute: _toggleThreadMute,
        onSend: _sendMessage,
        announce: _announce,
      ),
      MainDestination.more => _MorePage(
        role: _role,
        name: _profileName,
        onRole: _switchRole,
        onFeature: _openFeature,
        onStudy: _openStudy,
        onCalendar: () => _select(MainDestination.calendar),
        onMessages: () => _openMessages(),
      ),
    };

    final content = KeyedSubtree(
      key: ValueKey('${_role.name}-${_destination.name}'),
      child: page,
    );

    final topBar = _ShellTopBar(
      title: _currentSectionTitle,
      name: _profileName,
      role: _role,
      unread: _state.unreadNoticeCountForRole(_role.name),
      onMenu: () => _shellKey.currentState?.openDrawer(),
      onSearch: _openSearch,
      onNotifications: _openNotifications,
      onProfile: () => _openFeature(FeatureRoute.profile),
      showMenu: phone,
    );

    return Scaffold(
      key: _shellKey,
      drawer: expanded
          ? null
          : Drawer(
              width: 292,
              child: Builder(
                builder: (drawerContext) => _RichNavigation(
                  items: richItems,
                  activeId: activeRichId,
                  role: _role,
                  name: _profileName,
                  onProfile: () {
                    Navigator.pop(drawerContext);
                    Future<void>.delayed(
                      Duration.zero,
                      () => _openFeature(FeatureRoute.profile),
                    );
                  },
                  onRole: (role) {
                    Navigator.pop(drawerContext);
                    Future<void>.delayed(
                      Duration.zero,
                      () => _switchRole(role),
                    );
                  },
                  onSelected: (item) {
                    Navigator.pop(drawerContext);
                    Future<void>.delayed(Duration.zero, item.onTap);
                  },
                ),
              ),
            ),
      body: SafeArea(
        bottom: !phone,
        child: expanded
            ? Row(
                children: [
                  SizedBox(
                    width: 264,
                    child: _RichNavigation(
                      items: richItems,
                      activeId: activeRichId,
                      role: _role,
                      name: _profileName,
                      onProfile: () => _openFeature(FeatureRoute.profile),
                      onRole: _switchRole,
                      onSelected: (item) => item.onTap(),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (showSectionTopBar) topBar,
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              )
            : medium
            ? Row(
                children: [
                  _CompactNavigationRail(
                    items: destinations,
                    selectedIndex: selectedIndex,
                    role: _role,
                    onSelected: _selectPrimaryIndex,
                    onMenu: () => _shellKey.currentState?.openDrawer(),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (showSectionTopBar) topBar,
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  if (showSectionTopBar) topBar,
                  Expanded(child: content),
                ],
              ),
      ),
      bottomNavigationBar: phone
          ? MediaQuery.textScalerOf(context).scale(1) > 1.6
                ? _AccessibleBottomNavigation(
                    items: destinations,
                    selectedIndex: selectedIndex,
                    onSelected: _selectPrimaryIndex,
                  )
                : NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: _selectPrimaryIndex,
                    destinations: [
                      for (final item in destinations)
                        NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                          tooltip: item.label,
                        ),
                    ],
                  )
          : null,
    );
  }

  String get _activeRichNavigationId => switch (_destination) {
    MainDestination.home => 'home',
    MainDestination.study => _studyMode.name,
    MainDestination.calendar => 'calendar',
    MainDestination.messages => 'messages',
    MainDestination.more => 'more',
  };

  String get _currentSectionTitle => switch (_destination) {
    MainDestination.home => 'Bosh sahifa',
    MainDestination.study => 'O‘qish',
    MainDestination.calendar => 'Jadval',
    MainDestination.messages => 'Xabarlar',
    MainDestination.more => 'Xizmatlar',
  };

  List<_RichNavigationItem> _richNavigationItems() {
    return [
      _RichNavigationItem(
        id: 'home',
        section: 'Asosiy',
        label: 'Bosh sahifa',
        icon: Icons.home_outlined,
        onTap: () => _select(MainDestination.home),
      ),
      _RichNavigationItem(
        id: 'tasks',
        section: 'Asosiy',
        label: 'Vazifalar',
        icon: Icons.assignment_outlined,
        onTap: () => _openStudy(_StudyMode.tasks),
      ),
      _RichNavigationItem(
        id: 'grades',
        section: 'Asosiy',
        label: 'Baholar',
        icon: Icons.school_outlined,
        onTap: () => _openStudy(_StudyMode.grades),
      ),
      _RichNavigationItem(
        id: 'materials',
        section: 'Asosiy',
        label: 'Materiallar',
        icon: Icons.library_books_outlined,
        onTap: () => _openStudy(_StudyMode.materials),
      ),
      _RichNavigationItem(
        id: 'calendar',
        section: 'Asosiy',
        label: 'Jadval',
        icon: Icons.calendar_month_outlined,
        onTap: () => _select(MainDestination.calendar),
      ),
      _RichNavigationItem(
        id: 'messages',
        section: 'Asosiy',
        label: 'Xabarlar',
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () => _openMessages(),
      ),
      _RichNavigationItem(
        id: 'attendance',
        section: 'Natijalar',
        label: 'Davomat',
        icon: Icons.fact_check_outlined,
        onTap: () => _openFeature(FeatureRoute.attendance),
      ),
      _RichNavigationItem(
        id: 'achievements',
        section: 'Natijalar',
        label: _role == FamilyRole.parent ? 'Natijalar' : 'Yutuqlar',
        icon: Icons.emoji_events_outlined,
        onTap: () => _openFeature(FeatureRoute.achievements),
      ),
      _RichNavigationItem(
        id: 'announcements',
        section: 'Maktab',
        label: 'E’lonlar',
        icon: Icons.campaign_outlined,
        onTap: () => _openFeature(FeatureRoute.announcements),
      ),
      if (_role == FamilyRole.parent)
        _RichNavigationItem(
          id: 'payments',
          section: 'Maktab',
          label: 'To‘lovlar',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => _openFeature(FeatureRoute.payments),
        ),
      if (_role == FamilyRole.student)
        _RichNavigationItem(
          id: 'ai',
          section: 'Maktab',
          label: 'AI repetitor',
          icon: Icons.auto_awesome_outlined,
          onTap: () => _openFeature(FeatureRoute.aiTutor),
        ),
      _RichNavigationItem(
        id: 'toolkit',
        section: 'Maktab',
        label: 'Aqlli asboblar · 40+',
        icon: Icons.widgets_outlined,
        onTap: () => _openFeature(FeatureRoute.toolkit),
      ),
      _RichNavigationItem(
        id: 'more',
        section: 'Maktab',
        label: 'Barcha xizmatlar',
        icon: Icons.grid_view_outlined,
        onTap: () => _select(MainDestination.more),
      ),
      _RichNavigationItem(
        id: 'profile',
        section: 'Hisob',
        label: 'Mening profilim',
        icon: Icons.account_circle_outlined,
        onTap: () => _openFeature(FeatureRoute.profile),
      ),
      _RichNavigationItem(
        id: 'settings',
        section: 'Hisob',
        label: 'Sozlamalar',
        icon: Icons.settings_outlined,
        onTap: () => _openFeature(FeatureRoute.settings),
      ),
      _RichNavigationItem(
        id: 'support',
        section: 'Hisob',
        label: 'Yordam',
        icon: Icons.support_agent_outlined,
        onTap: () => _openFeature(FeatureRoute.support),
      ),
    ];
  }

  void _openFeature(FeatureRoute route) {
    switch (route) {
      case FeatureRoute.attendance:
        _push(
          _AttendanceDetail(
            role: _role,
            onMessage: _openMessages,
            announce: _announce,
          ),
        );
      case FeatureRoute.achievements:
        _push(
          _AchievementsDetail(onMessage: _openMessages, announce: _announce),
        );
      case FeatureRoute.announcements:
        _push(const _AnnouncementsDetail());
      case FeatureRoute.payments:
        if (_role == FamilyRole.parent) {
          _push(_PaymentsDetail(announce: _announce));
        }
      case FeatureRoute.aiTutor:
        if (_role == FamilyRole.student) {
          _push(_AiTutorDetail(announce: _announce));
        }
      case FeatureRoute.support:
        _push(_SupportDetail(role: _role, announce: _announce));
      case FeatureRoute.settings:
        _push(
          _SettingsDetail(
            role: _role,
            onReset: () {
              setState(() {
                _role = FamilyRole.student;
                _destination = MainDestination.home;
                _studyMode = _StudyMode.tasks;
                _activeThreadId = 'student-thread-algebra';
                _openMessageThreadOnPhone = false;
              });
            },
          ),
        );
      case FeatureRoute.profile:
        _push(
          _FamilyProfileDetail(
            role: _role,
            onRole: _switchRole,
            onStudy: _openStudy,
            onCalendar: () => _select(MainDestination.calendar),
            onMessages: _openMessages,
            onFeature: _openFeature,
          ),
        );
      case FeatureRoute.toolkit:
        _push(
          ToolkitPage(
            isParent: _role == FamilyRole.parent,
            announce: _announce,
          ),
        );
    }
  }

  Future<void> _push(Widget page) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationItem(this.label, this.icon, this.selectedIcon);
}

class _AccessibleBottomNavigation extends StatelessWidget {
  final List<_NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _AccessibleBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('accessible-bottom-navigation'),
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: Semantics(
                    selected: index == selectedIndex,
                    button: true,
                    label: items[index].label,
                    child: IconButton(
                      tooltip: items[index].label,
                      onPressed: () => onSelected(index),
                      style: IconButton.styleFrom(
                        backgroundColor: index == selectedIndex
                            ? colors.secondaryContainer
                            : Colors.transparent,
                        foregroundColor: index == selectedIndex
                            ? colors.onSecondaryContainer
                            : colors.onSurfaceVariant,
                      ),
                      icon: Icon(
                        index == selectedIndex
                            ? items[index].selectedIcon
                            : items[index].icon,
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

class _RichNavigationItem {
  final String id;
  final String section;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RichNavigationItem({
    required this.id,
    required this.section,
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

List<_NavigationItem> _navigationItems(FamilyRole role) => [
  const _NavigationItem('Bosh sahifa', Icons.home_outlined, Icons.home_rounded),
  const _NavigationItem(
    'O‘qish',
    Icons.menu_book_outlined,
    Icons.menu_book_rounded,
  ),
  const _NavigationItem(
    'Jadval',
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
  ),
  const _NavigationItem(
    'Xabarlar',
    Icons.chat_bubble_outline_rounded,
    Icons.chat_bubble_rounded,
  ),
  const _NavigationItem(
    'Xizmatlar',
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
  ),
];

class _CompactNavigationRail extends StatelessWidget {
  final List<_NavigationItem> items;
  final int selectedIndex;
  final FamilyRole role;
  final ValueChanged<int> onSelected;
  final VoidCallback onMenu;

  const _CompactNavigationRail({
    required this.items,
    required this.selectedIndex,
    required this.role,
    required this.onSelected,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: NavigationRail(
        minWidth: 84,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelType: NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BrandMark(color: Theme.of(context).colorScheme.primary),
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton.filledTonal(
            tooltip: 'Barcha bo‘limlar',
            onPressed: onMenu,
            icon: const Icon(Icons.menu_open_rounded),
          ),
        ),
        destinations: [
          for (final item in items)
            NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _RichNavigation extends StatelessWidget {
  final List<_RichNavigationItem> items;
  final String activeId;
  final FamilyRole role;
  final String name;
  final VoidCallback onProfile;
  final ValueChanged<FamilyRole> onRole;
  final ValueChanged<_RichNavigationItem> onSelected;

  const _RichNavigation({
    required this.items,
    required this.activeId,
    required this.role,
    required this.name,
    required this.onProfile,
    required this.onRole,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  _BrandMark(color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StarForge · EDU',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          role == FamilyRole.parent
                              ? 'Ota-ona kabineti'
                              : 'O‘quvchi kabineti',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _IdentityButton(
                key: const ValueKey('open-family-profile-sidebar'),
                name: name,
                subtitle: role == FamilyRole.parent
                    ? 'Ota-ona profili'
                    : 'O‘quvchi · 9-B',
                onTap: onProfile,
                switchKey: const ValueKey('switch-family-cabinet-sidebar'),
                onSwitchRole: () => _showRolePicker(context, role, onRole),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  for (var index = 0; index < items.length; index++)
                    Builder(
                      builder: (context) {
                        final item = items[index];
                        final showSection =
                            index == 0 ||
                            items[index - 1].section != item.section;
                        final selected = item.id == activeId;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showSection)
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  10,
                                  index == 0 ? 8 : 18,
                                  10,
                                  7,
                                ),
                                child: Text(
                                  item.section.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Material(
                                color: selected
                                    ? colors.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: Semantics(
                                  button: true,
                                  selected: selected,
                                  child: InkWell(
                                    key: ValueKey('rich-nav-${item.id}'),
                                    onTap: () => onSelected(item),
                                    borderRadius: BorderRadius.circular(14),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 48,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.icon,
                                              size: 20,
                                              color: selected
                                                  ? colors.primary
                                                  : colors.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: selected
                                                          ? colors
                                                                .onPrimaryContainer
                                                          : colors.onSurface,
                                                      fontWeight: selected
                                                          ? FontWeight.w900
                                                          : FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellTopBar extends StatelessWidget {
  final String title;
  final String name;
  final FamilyRole role;
  final int unread;
  final bool showMenu;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _ShellTopBar({
    required this.title,
    required this.name,
    required this.role,
    required this.unread,
    required this.showMenu,
    required this.onMenu,
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final roomy = constraints.maxWidth >= 680;
            final accessibilityCompact =
                constraints.maxWidth < 360 &&
                MediaQuery.textScalerOf(context).scale(1) > 1.6;
            return Row(
              children: [
                if (showMenu)
                  IconButton(
                    key: const ValueKey('open-rich-navigation'),
                    tooltip: 'Bo‘limlar menyusi',
                    onPressed: onMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                if (showMenu) const SizedBox(width: 2),
                Expanded(
                  child: Row(
                    children: [
                      if (roomy) ...[
                        _BrandMark(color: colors.primary),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (roomy)
                  OutlinedButton.icon(
                    key: const ValueKey('global-search'),
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Izlash'),
                  )
                else
                  IconButton(
                    key: const ValueKey('global-search'),
                    tooltip: 'Izlash',
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Bildirishnomalar',
                  onPressed: onNotifications,
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                if (!accessibilityCompact) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('open-family-profile-topbar'),
                    tooltip: 'Profilni ochish',
                    onPressed: onProfile,
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text(
                        _initials(name),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final Color color;

  const _BrandMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ),
    );
  }
}

class _IdentityButton extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final Key? switchKey;
  final VoidCallback onSwitchRole;

  const _IdentityButton({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
    required this.onSwitchRole,
    this.switchKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Profilni ochish',
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Sf.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Sf.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text(_initials(name)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: switchKey,
                  tooltip: 'Kabinetni almashtirish',
                  onPressed: onSwitchRole,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final double maxWidth;

  const _Page({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = width < 360
            ? 16.0
            : width < 600
            ? 20.0
            : width < 840
            ? 28.0
            : 40.0;
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 0),
                    child: _LargeHeader(
                      eyebrow: eyebrow,
                      title: title,
                      subtitle: subtitle,
                      actions: actions,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 64),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LargeHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const _LargeHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actions.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.headlineLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(subtitle!, style: theme.textTheme.bodyLarge),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const _SectionHeader(this.title, {this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            action != null &&
            (constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.5);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: heading),
                    ?action,
                  ],
                ),
        );
      },
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: color ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sf.radiusLarge),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _GroupedRows extends StatelessWidget {
  final List<Widget> children;

  const _GroupedRows({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sf.radiusLarge),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(height: 1, indent: 62, color: colors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth * 0.35).clamp(48, 180),
                    ),
                    child: trailing ?? const Icon(Icons.chevron_right_rounded),
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

class _StatePill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;

  const _StatePill(this.text, {this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = color ?? colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tone,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceStrip extends StatelessWidget {
  final FamilySnapshot snapshot;

  const _DataSourceStrip({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final preview = snapshot.isPreview;
    final label = switch (snapshot.loadState) {
      FamilyLoadState.loading => 'Yangilanmoqda',
      FamilyLoadState.offline => 'Offline ma’lumot',
      FamilyLoadState.error => 'Yangilashda xato',
      FamilyLoadState.empty => 'Ma’lumot yo‘q',
      FamilyLoadState.ready =>
        preview
            ? 'Namuna rejimi'
            : 'Yangilandi · ${_messageTime(snapshot.updatedAt)}',
    };
    final icon = switch (snapshot.loadState) {
      FamilyLoadState.loading => Icons.sync_rounded,
      FamilyLoadState.offline => Icons.cloud_off_outlined,
      FamilyLoadState.error => Icons.error_outline_rounded,
      FamilyLoadState.empty => Icons.inbox_outlined,
      FamilyLoadState.ready =>
        preview ? Icons.science_outlined : Icons.cloud_done_outlined,
    };
    final detail = snapshot.errorMessage;
    return Semantics(
      label: preview ? 'Namuna ma’lumotlari' : 'Tasdiqlangan ma’lumotlar',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: detail ?? label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: preview
                  ? colors.tertiaryContainer.withValues(alpha: 0.54)
                  : colors.primaryContainer.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: largeText ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 7),
                if (largeText)
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  )
                else
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  final FamilyRole role;
  final String name;
  final VoidCallback onStudy;
  final VoidCallback onGrades;
  final VoidCallback onMaterials;
  final VoidCallback onCalendar;
  final ValueChanged<String?> onMessages;
  final VoidCallback onNotifications;
  final ValueChanged<AppNotice> onNotice;
  final ValueChanged<FeatureRoute> onFeature;

  const _HomePage({
    required this.role,
    required this.name,
    required this.onStudy,
    required this.onGrades,
    required this.onMaterials,
    required this.onCalendar,
    required this.onMessages,
    required this.onNotifications,
    required this.onNotice,
    required this.onFeature,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final firstName = name.split(' ').last;
    final colors = Theme.of(context).colorScheme;
    final schoolTasks = state.familyData.visibleAssignments;
    final submittedIds = {
      for (final item in state.familyData.submissions)
        if (const {
          'submitted',
          'graded',
          'returned',
        }.contains(item.statusRaw.toLowerCase()))
          item.assignmentId,
    };
    final totalTasks = schoolTasks.length + state.personalTasks.length;
    final completedTasks =
        submittedIds
            .where((id) => schoolTasks.any((item) => item.id == id))
            .length +
        state.personalTasks
            .where((item) => state.completedTasks.contains(item.id))
            .length;
    final openTasks = totalTasks - completedTasks;
    final now = SfClock.now();
    final scheduled =
        state.familyData.lessons
            .where((item) => !item.isCancelled && item.endsAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final nextLesson = scheduled.isEmpty ? null : scheduled.first;
    final pendingAssignments =
        schoolTasks.where((item) => !submittedIds.contains(item.id)).toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final nextAssignment = pendingAssignments.isEmpty
        ? null
        : pendingAssignments.first;
    final attendance = state.familyData.attendance;
    final attended = attendance
        .where(
          (item) => const {
            'present',
            'late',
            'excused',
          }.contains(item.statusRaw.toLowerCase()),
        )
        .length;
    final attendancePercent = attendance.isEmpty
        ? 0
        : (attended / attendance.length * 100).round();
    final grades = state.familyData.grades;
    final gradeAverage = grades.isEmpty
        ? 0
        : (grades.map((item) => item.percent).reduce((a, b) => a + b) /
                  grades.length)
              .round();
    final recentGrades = [...grades]
      ..sort((a, b) => b.gradedAt.compareTo(a.gradedAt));
    final recentGrade = recentGrades.isEmpty ? null : recentGrades.first;
    final unreadMessages = state.messaging
        .threads(state.messagingScopeForRole(role.name))
        .fold<int>(0, (total, thread) => total + thread.unreadCount);
    final agendaCount =
        (nextLesson == null ? 0 : 1) + (nextAssignment == null ? 0 : 1);
    return _Page(
      eyebrow: _friendlyDate(SfClock.now()),
      title: role == FamilyRole.student ? 'Salom, $firstName' : 'Oila nazorati',
      subtitle: role == FamilyRole.student
          ? 'Bugun asosiy vazifalar va darslar bir joyda.'
          : 'Akmalning bugungi o‘qishi bo‘yicha qisqa va aniq ko‘rinish.',
      maxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DataSourceStrip(snapshot: state.familyData),
          const SizedBox(height: 14),
          _SurfaceCard(
            color: colors.primaryContainer,
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatePill(
                      role == FamilyRole.student
                          ? nextLesson == null
                                ? 'Keyingi dars kutilmoqda'
                                : 'Keyingi dars · ${_clockTime(nextLesson.startsAt)}'
                          : 'Bugungi holat',
                      icon: Icons.schedule_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      role == FamilyRole.student
                          ? nextLesson?.title ?? 'Bugungi darslar yakunlangan'
                          : '$totalTasks vazifadan $completedTasks tasi bajarildi',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role == FamilyRole.student
                          ? nextLesson == null
                                ? 'Yangi jadval serverdan kelganda ko‘rinadi'
                                : '${nextLesson.roomName} · ${nextLesson.teacherName}'
                          : nextAssignment == null
                          ? 'Faol maktab vazifasi yo‘q'
                          : 'Keyingi muddat — ${_deadlineLabel(nextAssignment.dueAt)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: role == FamilyRole.student
                          ? nextLesson != null
                                ? onCalendar
                                : onStudy
                          : onGrades,
                      icon: Icon(
                        role == FamilyRole.student
                            ? nextLesson != null
                                  ? Icons.calendar_month_rounded
                                  : Icons.assignment_turned_in_outlined
                            : Icons.insights_rounded,
                      ),
                      label: Text(
                        role == FamilyRole.student
                            ? nextLesson != null
                                  ? 'Jadvalni ochish'
                                  : 'Vazifalarni ko‘rish'
                            : 'Natijalarni ochish',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.onPrimaryContainer,
                        foregroundColor: colors.primaryContainer,
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 560) return content;
                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 24),
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 112,
                      color: colors.onPrimaryContainer.withValues(alpha: 0.18),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          _HomeQuickGrid(
            items: [
              _HomeQuickItem(
                id: 'tasks',
                icon: Icons.assignment_outlined,
                label: 'Vazifalar',
                detail: openTasks == 0
                    ? 'Hammasi tayyor'
                    : '$openTasks ta bajarilmagan',
                onTap: onStudy,
              ),
              _HomeQuickItem(
                id: 'lesson',
                icon: Icons.calendar_month_outlined,
                label: 'Keyingi dars',
                detail: nextLesson == null
                    ? 'Bugun dars qolmadi'
                    : '${_clockTime(nextLesson.startsAt)} · ${nextLesson.title}',
                onTap: onCalendar,
              ),
              _HomeQuickItem(
                id: 'grade',
                icon: Icons.school_outlined,
                label: 'So‘nggi baho',
                detail: recentGrade == null
                    ? 'Hozircha baho yo‘q'
                    : '${recentGrade.percent}% · ${recentGrade.subject}',
                onTap: onGrades,
              ),
              _HomeQuickItem(
                id: 'messages',
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Xabarlar',
                detail: unreadMessages == 0
                    ? 'Yangi xabar yo‘q'
                    : '$unreadMessages ta o‘qilmagan',
                onTap: () => onMessages(null),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final agenda = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    'Bugungi reja',
                    subtitle:
                        '${SfClock.now().day} ${_monthName(SfClock.now().month)} · $agendaCount ta band',
                    action: TextButton(
                      onPressed: onCalendar,
                      child: const Text('Jadval'),
                    ),
                  ),
                  _GroupedRows(
                    children: [
                      if (nextLesson != null)
                        _ActionRow(
                          icon: Icons.school_outlined,
                          title: nextLesson.title,
                          subtitle:
                              '${_clockTime(nextLesson.startsAt)}–${_clockTime(nextLesson.endsAt)} · ${nextLesson.roomName}',
                          trailing: _StatePill(
                            '${nextLesson.endsAt.difference(nextLesson.startsAt).inMinutes} daqiqa',
                          ),
                          onTap: onCalendar,
                        ),
                      if (nextAssignment != null)
                        _ActionRow(
                          icon: Icons.assignment_outlined,
                          title: nextAssignment.title,
                          subtitle:
                              '${_deadlineLabel(nextAssignment.dueAt)} gacha',
                          trailing: _StatePill(
                            'Muhim',
                            icon: Icons.priority_high_rounded,
                            color: colors.error,
                          ),
                          onTap: onStudy,
                        ),
                      if (agendaCount == 0)
                        const _EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'Bugungi reja bajarildi',
                          message:
                              'Yangi dars yoki vazifa kelganda shu yerda ko‘rinadi.',
                        ),
                    ],
                  ),
                ],
              );
              final overview = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    role == FamilyRole.parent
                        ? 'Farzand holati'
                        : 'Haftalik holat',
                  ),
                  _WeeklySummaryCard(
                    items: role == FamilyRole.parent
                        ? [
                            _Metric(
                              'Davomat',
                              '$attendancePercent%',
                              '$attended/${attendance.length} dars',
                            ),
                            _Metric(
                              'O‘rtacha',
                              '$gradeAverage%',
                              '${grades.length} ta baho',
                            ),
                            _Metric(
                              'Vazifalar',
                              '$completedTasks/$totalTasks',
                              '$openTasks ta qolgan',
                            ),
                          ]
                        : [
                            _Metric(
                              'Davomat',
                              '$attendancePercent%',
                              '$attended/${attendance.length} dars',
                            ),
                            _Metric(
                              'Natija',
                              '$gradeAverage%',
                              '${grades.length} ta baho',
                            ),
                            _Metric(
                              'Vazifalar',
                              '$completedTasks/$totalTasks',
                              '$openTasks ta qolgan',
                            ),
                          ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader('O‘quv maqsadlari'),
                  for (final goal in state.goals) ...[
                    _GoalProgressCard(
                      goal: goal,
                      onTap: () =>
                          _showGoalProgressDialog(context, state, goal),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
              if (constraints.maxWidth < 780) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [agenda, const SizedBox(height: 24), overview],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: agenda),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: overview),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            'Diqqat va tavsiyalar',
            subtitle: role == FamilyRole.parent
                ? 'Akmal uchun muhim bo‘lgan holatlar'
                : 'Bugun foydali bo‘ladigan keyingi qadamlar',
          ),
          _GroupedRows(
            children: [
              if (nextAssignment != null)
                _ActionRow(
                  icon: Icons.assignment_late_outlined,
                  title: nextAssignment.title,
                  subtitle:
                      '${nextAssignment.subject} · ${_deadlineLabel(nextAssignment.dueAt)} gacha',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onStudy,
                ),
              if (recentGrade != null)
                _ActionRow(
                  icon: Icons.rate_review_outlined,
                  title:
                      '${recentGrade.subject}: ${recentGrade.percent}% natija',
                  subtitle: recentGrade.feedback.isEmpty
                      ? 'Batafsil natijani ko‘ring'
                      : recentGrade.feedback,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onGrades,
                ),
              if (unreadMessages > 0)
                _ActionRow(
                  icon: Icons.mark_chat_unread_outlined,
                  title: '$unreadMessages ta o‘qilmagan xabar',
                  subtitle: 'Ustoz yozishmalarini tekshiring',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onMessages(null),
                ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final materials = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    'Tavsiya etilgan materiallar',
                    subtitle:
                        '${state.familyData.visibleMaterials.length} ta mavjud',
                    action: TextButton(
                      onPressed: onMaterials,
                      child: const Text('Barchasi'),
                    ),
                  ),
                  _GroupedRows(
                    children: [
                      for (final material
                          in state.familyData.visibleMaterials.take(3))
                        _ActionRow(
                          icon: material.contentType.toLowerCase() == 'audio'
                              ? Icons.headphones_outlined
                              : Icons.description_outlined,
                          title: material.title,
                          subtitle:
                              '${material.topic} · ${material.contentType} · ${material.detail}',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: onMaterials,
                        ),
                    ],
                  ),
                ],
              );
              final service = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    role == FamilyRole.parent
                        ? 'Oila xizmati'
                        : 'Shaxsiy yordamchi',
                  ),
                  _SurfaceCard(
                    color: colors.secondaryContainer.withValues(alpha: 0.7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          role == FamilyRole.parent
                              ? Icons.account_balance_wallet_outlined
                              : Icons.auto_awesome_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          role == FamilyRole.parent
                              ? (state.paymentCompleted
                                    ? 'To‘lov tasdiqlangan'
                                    : 'To‘lov holatini tekshiring')
                              : 'AI repetitor bilan mavzuni mustahkamlang',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role == FamilyRole.parent
                              ? 'Kvitansiya va to‘lov tarixini xavfsiz ko‘ring.'
                              : 'Savol bering, reja yoki sodda tushuntirish oling.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: ValueKey(
                            role == FamilyRole.parent
                                ? 'home-open-payments'
                                : 'home-open-ai',
                          ),
                          onPressed: () => onFeature(
                            role == FamilyRole.parent
                                ? FeatureRoute.payments
                                : FeatureRoute.aiTutor,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            role == FamilyRole.parent
                                ? 'To‘lovlarni ochish'
                                : 'AI repetitorni ochish',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth < 780) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [materials, const SizedBox(height: 24), service],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: materials),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: service),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            'So‘nggi yangiliklar',
            subtitle:
                '${state.unreadNoticeCountForRole(role.name)} ta o‘qilmagan',
            action: TextButton(
              onPressed: onNotifications,
              child: const Text('Barchasi'),
            ),
          ),
          _GroupedRows(
            children: [
              for (final notice in state.noticesForRole(role.name).take(2))
                _ActionRow(
                  icon: notice.type == NoticeType.success
                      ? Icons.verified_outlined
                      : notice.type == NoticeType.warning
                      ? Icons.schedule_outlined
                      : Icons.notifications_outlined,
                  title: notice.title,
                  subtitle: '${notice.body} · ${notice.time}',
                  trailing: state.isNoticeReadForRole(notice, role.name)
                      ? const _StatePill('O‘qildi')
                      : const _StatePill('Yangi'),
                  onTap: () => onNotice(notice),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeQuickItem {
  final String id;
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  const _HomeQuickItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });
}

class _HomeQuickGrid extends StatelessWidget {
  final List<_HomeQuickItem> items;

  const _HomeQuickGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final itemHeight = (112 + (textScale - 1) * 36).clamp(112, 168).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: width,
                height: itemHeight,
                child: Material(
                  key: ValueKey('home-quick-${items[index].id}'),
                  color: index.isEven
                      ? colors.secondaryContainer.withValues(alpha: 0.62)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: items[index].onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 112),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  items[index].icon,
                                  color: colors.primary,
                                  size: 24,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_outward_rounded,
                                  size: 18,
                                  color: colors.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              items[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items[index].detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final List<_Metric> items;

  const _WeeklySummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 34,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? colors.primary
                          : index == 1
                          ? colors.tertiary
                          : colors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[index].label,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[index].context,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    items[index].value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: Sf.mono,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              Divider(height: 1, color: colors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final StudyGoal goal;
  final VoidCallback onTap;

  const _GoalProgressCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('goal-${goal.id}'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(goal.subject, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '${(goal.progress * 100).round()}%',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                  Text(
                    '${goal.current} / ${goal.target}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(fontFamily: Sf.mono),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showGoalProgressDialog(
  BuildContext context,
  AppState state,
  StudyGoal goal,
) async {
  var value = goal.current.clamp(0, goal.target).toDouble();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Maqsadni yangilash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(goal.title),
            const SizedBox(height: 18),
            Text(
              '${value.round()} / ${goal.target}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontFamily: Sf.mono),
            ),
            Slider(
              key: const ValueKey('goal-progress-slider'),
              value: value,
              max: goal.target.toDouble(),
              divisions: goal.target,
              label: value.round().toString(),
              onChanged: (next) => setDialogState(() => value = next),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              state.updateGoal(goal.id, value.round());
              Navigator.pop(dialogContext);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    ),
  );
}

class _Metric {
  final String label;
  final String value;
  final String context;

  const _Metric(this.label, this.value, this.context);
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> items;

  const _MetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? items.length
            : constraints.maxWidth >= 440
            ? 2
            : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _SurfaceCard(
                  child: Semantics(
                    label: '${item.label}: ${item.value}. ${item.context}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontFamily: Sf.mono,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.context,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _StudyMode { tasks, grades, materials }

class _StudyPage extends StatefulWidget {
  final FamilyRole role;
  final _StudyMode initialMode;
  final ValueChanged<_StudyMode> onModeChanged;
  final ValueChanged<String?> onMessage;
  final void Function(String, {String? detail}) announce;

  const _StudyPage({
    required this.role,
    required this.initialMode,
    required this.onModeChanged,
    required this.onMessage,
    required this.announce,
  });

  @override
  State<_StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<_StudyPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _Page(
      eyebrow: widget.role == FamilyRole.parent ? 'Akmal · 9-B' : 'O‘qish',
      title: 'O‘qish',
      subtitle: switch (widget.initialMode) {
        _StudyMode.tasks => 'Yaqin muddatlar va bajariladigan vazifalar.',
        _StudyMode.grades => 'Baholar, izohlar va fanlar bo‘yicha natija.',
        _StudyMode.materials => 'Ustozlar ulashgan o‘quv materiallari.',
      },
      maxWidth: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudySelector(
            value: widget.initialMode,
            onChanged: widget.onModeChanged,
          ),
          const SizedBox(height: 14),
          _DataSourceStrip(snapshot: state.familyData),
          const SizedBox(height: 24),
          if (widget.initialMode == _StudyMode.tasks) ...[
            _TaskCollection(
              role: widget.role,
              query: _query,
              onQuery: (value) => setState(() => _query = value),
              onAdd: () => _addTask(context),
              onReminder: () => _prepareReminder(context),
              onMessage: widget.onMessage,
              announce: widget.announce,
            ),
          ] else if (widget.initialMode == _StudyMode.grades)
            _GradesCollection(onMessage: widget.onMessage)
          else
            _MaterialsCollection(announce: widget.announce),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    final state = AppScope.read(context);
    final title = await _textEntryDialog(
      context,
      title: 'Shaxsiy vazifa',
      label: 'Vazifa nomi',
      hint: 'Masalan: 20 daqiqa kitob o‘qish',
      action: 'Vazifa qo‘shish',
      minLength: 3,
    );
    if (title == null || !mounted) return;
    state.addPersonalTask(
      StudyTask(
        id: 'personal-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subject: 'Shaxsiy reja',
        dueLabel: 'Bugun · 21:00',
        dueAt: DateTime.now().copyWith(hour: 21, minute: 0),
        minutes: 20,
        isPersonal: true,
      ),
    );
    widget.announce('Vazifa qo‘shildi', detail: title);
  }

  void _prepareReminder(BuildContext context) {
    widget.onMessage(
      'Assalomu alaykum, kvadrat tenglamalar vazifasi bo‘yicha savolim bor.',
    );
    widget.announce('Xabar qoralamasi tayyor');
  }
}

class _StudySelector extends StatelessWidget {
  final _StudyMode value;
  final ValueChanged<_StudyMode> onChanged;

  const _StudySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const items = [
      (_StudyMode.tasks, Icons.assignment_outlined, 'Vazifalar'),
      (_StudyMode.grades, Icons.school_outlined, 'Baholar'),
      (_StudyMode.materials, Icons.folder_outlined, 'Materiallar'),
    ];
    return Semantics(
      label: 'O‘qish bo‘limlari',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            ChoiceChip(
              key: ValueKey('study-tab-${item.$1.name}'),
              selected: value == item.$1,
              avatar: Icon(
                item.$2,
                size: 18,
                color: value == item.$1
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              label: Text(item.$3),
              onSelected: (_) => onChanged(item.$1),
            ),
        ],
      ),
    );
  }
}

class _TaskCollection extends StatelessWidget {
  final FamilyRole role;
  final String query;
  final ValueChanged<String> onQuery;
  final VoidCallback onAdd;
  final VoidCallback? onReminder;
  final ValueChanged<String?> onMessage;
  final void Function(String, {String? detail}) announce;

  const _TaskCollection({
    required this.role,
    required this.query,
    required this.onQuery,
    required this.onAdd,
    required this.onReminder,
    required this.onMessage,
    required this.announce,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final submissions = {
      for (final item in state.familyData.submissions)
        item.assignmentId: item.statusRaw,
    };
    final allTasks = <_TaskView>[
      for (final item in state.familyData.visibleAssignments)
        _TaskView(
          item.id,
          item.title,
          item.subject,
          _deadlineLabel(item.dueAt),
          item.estimatedMinutes,
          description: item.description,
          teacherName: item.teacherName,
          serverStatus: submissions[item.id] ?? 'assigned',
        ),
      for (final item in state.personalTasks)
        _TaskView(
          item.id,
          item.title,
          item.subject,
          item.dueLabel,
          item.minutes,
          personal: true,
        ),
    ];
    final tasks = allTasks.where((item) {
      final normalized = query.trim().toLowerCase();
      return normalized.isEmpty ||
          '${item.title} ${item.subject}'.toLowerCase().contains(normalized);
    }).toList();
    final completed = allTasks
        .where((task) => _taskCompleted(task, state))
        .length;
    final minutes = allTasks
        .where((task) => !_taskCompleted(task, state))
        .fold<int>(0, (sum, task) => sum + task.minutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          items: [
            _Metric(
              role == FamilyRole.parent ? 'Tekshirildi' : 'Bajarildi',
              '$completed/${allTasks.length}',
              role == FamilyRole.parent ? 'Nazorat holati' : 'Bugungi reja',
            ),
            _Metric(
              'Qolgan vaqt',
              '$minutes min',
              '${allTasks.length - completed} ta faol',
            ),
            _Metric(
              'Maktabdan',
              '${allTasks.where((task) => !task.personal).length} ta',
              'Tasdiqlangan topshiriq',
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('task-search'),
          onChanged: onQuery,
          decoration: const InputDecoration(
            labelText: 'Vazifalarni izlash',
            hintText: 'Fan yoki vazifa nomi',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          'Faol vazifalar',
          subtitle: '${tasks.length} ta natija',
          action: role == FamilyRole.student
              ? FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Shaxsiy vazifa'),
                )
              : FilledButton.tonalIcon(
                  onPressed: onReminder,
                  icon: Icon(
                    onReminder == null
                        ? Icons.check_rounded
                        : Icons.notifications_active_outlined,
                  ),
                  label: Text(
                    onReminder == null ? 'Mavjud emas' : 'Ustozga yozish',
                  ),
                ),
        ),
        if (tasks.isEmpty)
          _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Mos vazifa topilmadi',
            message: 'Izlash so‘zini o‘zgartiring.',
          )
        else
          _GroupedRows(
            children: [
              for (final task in tasks)
                _TaskRow(
                  task: task,
                  completed: _taskCompleted(task, state),
                  reminder: state.lessonReminders.contains(task.id),
                  role: role,
                  onToggle: () {
                    state.toggleTask(task.id);
                    announce(
                      state.completedTasks.contains(task.id)
                          ? 'Vazifa bajarildi'
                          : 'Vazifa qayta ochildi',
                      detail: task.title,
                    );
                  },
                  onOpen: () => _showTaskDetail(
                    context,
                    task,
                    state,
                    role,
                    onMessage,
                    announce,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _TaskView {
  final String id;
  final String title;
  final String subject;
  final String due;
  final int minutes;
  final bool personal;
  final String description;
  final String teacherName;
  final String serverStatus;

  const _TaskView(
    this.id,
    this.title,
    this.subject,
    this.due,
    this.minutes, {
    this.personal = false,
    this.description = '',
    this.teacherName = '',
    this.serverStatus = 'personal',
  });
}

bool _taskCompleted(_TaskView task, AppState state) {
  if (task.personal) return state.completedTasks.contains(task.id);
  return const {
    'submitted',
    'graded',
    'returned',
  }.contains(task.serverStatus.toLowerCase());
}

class _TaskRow extends StatelessWidget {
  final _TaskView task;
  final bool completed;
  final bool reminder;
  final FamilyRole role;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _TaskRow({
    required this.task,
    required this.completed,
    required this.reminder,
    required this.role,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionRow(
      icon: task.personal
          ? Icons.person_outline_rounded
          : Icons.assignment_outlined,
      title: task.title,
      subtitle:
          '${task.subject} · ${task.due} · ${task.minutes} daqiqa${reminder ? ' · Eslatma yoqilgan' : ''}',
      onTap: onOpen,
      trailing: role == FamilyRole.parent
          ? _StatePill(
              completed ? 'Bajarildi' : 'Kutilmoqda',
              icon: completed ? Icons.check_rounded : Icons.schedule_rounded,
            )
          : task.personal
          ? Checkbox(
              value: completed,
              semanticLabel: completed
                  ? '${task.title} bajarilgan'
                  : '${task.title} bajarilmagan',
              onChanged: (_) => onToggle(),
            )
          : _StatePill(
              _assignmentStatusLabel(task.serverStatus),
              icon: completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.schedule_rounded,
            ),
    );
  }
}

class _GradesCollection extends StatefulWidget {
  final ValueChanged<String?> onMessage;

  const _GradesCollection({required this.onMessage});

  @override
  State<_GradesCollection> createState() => _GradesCollectionState();
}

class _GradesCollectionState extends State<_GradesCollection> {
  String _period = 'Oy';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = SfClock.now();
    final windowDays = switch (_period) {
      'Hafta' => 7,
      'Oy' => 31,
      _ => 93,
    };
    final data = state.familyData.grades
        .where(
          (item) =>
              now.difference(item.gradedAt).inDays <= windowDays ||
              item.gradedAt.isAfter(now),
        )
        .toList(growable: false);
    final average = data.isEmpty
        ? 0
        : data.map((item) => item.percent).reduce((a, b) => a + b) /
              data.length;
    final bySubject = <String, List<FamilyGrade>>{};
    for (final item in data) {
      bySubject.putIfAbsent(item.subject, () => []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in const ['Hafta', 'Oy', 'Chorak'])
              ChoiceChip(
                label: Text(period),
                selected: _period == period,
                onSelected: (_) => setState(() => _period = period),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_period o‘rtachasi',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${average.round()}%',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(fontFamily: Sf.mono),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.trending_up_rounded, size: 42),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          'Fanlar kesimida',
          subtitle: _period == 'Hafta'
              ? 'Joriy haftadagi faollik'
              : 'Kuchli va e’tiborli yo‘nalishlar',
        ),
        _GroupedRows(
          children: [
            for (final entry in bySubject.entries)
              _ActionRow(
                icon: Icons.analytics_outlined,
                title: entry.key,
                subtitle: '${entry.value.length} ta baholangan ish',
                trailing: _StatePill(
                  '${(entry.value.map((item) => item.percent).reduce((a, b) => a + b) / entry.value.length).round()}%',
                ),
                onTap: () => _showSimpleDetail(
                  context,
                  '${entry.key} natijalari',
                  entry.value
                      .map(
                        (item) => '${item.assignmentTitle}: ${item.percent}%',
                      )
                      .join('\n'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionHeader('Baholangan ishlar', subtitle: '${data.length} ta'),
        _GroupedRows(
          children: [
            for (final grade in data)
              _ActionRow(
                icon: Icons.school_outlined,
                title: grade.assignmentTitle,
                subtitle:
                    '${_shortDate(grade.gradedAt)} · ${grade.teacherName}',
                trailing: _StatePill('${grade.percent}%'),
                onTap: () => _showGradeDetail(context, grade, widget.onMessage),
              ),
          ],
        ),
      ],
    );
  }
}

class _MaterialsCollection extends StatelessWidget {
  final void Function(String, {String? detail}) announce;

  const _MaterialsCollection({required this.announce});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final materials = state.familyData.visibleMaterials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          items: [
            _Metric('Kutubxona', '${materials.length}', 'Nashr qilingan'),
            _Metric(
              'Tanlangan',
              '${state.favoriteMaterials.length}',
              'Tezkor kirish',
            ),
            _Metric(
              'Yuklab olish',
              '${materials.where((item) => item.isDownloadable).length}',
              'Server ruxsat bergan',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugun uchun tavsiya',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      materials.isEmpty
                          ? 'Hozircha tavsiya yo‘q'
                          : '${materials.first.title}${materials.first.detail.isEmpty ? '' : ' · ${materials.first.detail}'}',
                    ),
                  ],
                ),
              ),
              if (materials.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      _showMaterialViewer(context, materials.first),
                  child: const Text('Ochish'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          'O‘quv materiallari',
          subtitle: 'Ko‘rish va tanlanganlar ro‘yxatiga qo‘shish',
        ),
        if (materials.isEmpty)
          const _EmptyState(
            icon: Icons.folder_off_outlined,
            title: 'Materiallar yo‘q',
            message: 'Nashr qilingan materiallar shu yerda paydo bo‘ladi.',
          )
        else
          _GroupedRows(
            children: [
              for (final material in materials)
                _ActionRow(
                  icon: material.contentType.toLowerCase().contains('audio')
                      ? Icons.headphones_outlined
                      : Icons.description_outlined,
                  title: material.title,
                  subtitle:
                      '${material.contentType} · ${material.topic}'
                      '${material.detail.isEmpty ? '' : ' · ${material.detail}'}',
                  trailing: IconButton(
                    tooltip: state.favoriteMaterials.contains(material.id)
                        ? 'Tanlanganlardan olib tashlash'
                        : 'Tanlanganlarga qo‘shish',
                    onPressed: () {
                      state.toggleFavoriteMaterial(material.id);
                      announce(
                        state.favoriteMaterials.contains(material.id)
                            ? 'Material tanlanganlarga qo‘shildi'
                            : 'Material tanlanganlardan olib tashlandi',
                      );
                    },
                    icon: Icon(
                      state.favoriteMaterials.contains(material.id)
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                  ),
                  onTap: () => _showMaterialViewer(context, material),
                ),
            ],
          ),
      ],
    );
  }
}

enum _CalendarFilter { all, school, personal }

class _CalendarPage extends StatefulWidget {
  final void Function(String, {String? detail}) announce;

  const _CalendarPage({required this.announce});

  @override
  State<_CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<_CalendarPage> {
  DateTime _selected = DateUtils.dateOnly(SfClock.now());
  _CalendarFilter _filter = _CalendarFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final today = DateUtils.dateOnly(SfClock.now());
    final schoolEvents = [
      for (final lesson in state.familyData.lessons)
        _CalendarView(
          id: lesson.id,
          title: lesson.title,
          subtitle:
              '${_clockTime(lesson.startsAt)} · ${lesson.roomName.isEmpty ? lesson.teacherName : lesson.roomName}'
              '${lesson.isCancelled ? ' · Bekor qilingan' : ''}',
          date: DateUtils.dateOnly(lesson.startsAt),
          sortAt: lesson.startsAt,
          icon: lesson.isCancelled
              ? Icons.event_busy_outlined
              : Icons.school_outlined,
          notes: [
            if (lesson.teacherName.isNotEmpty) 'Ustoz: ${lesson.teacherName}',
            if (lesson.cancelReason case final reason?)
              'Bekor qilish sababi: $reason',
          ].join('\n'),
        ),
    ];
    final all = [
      if (_filter != _CalendarFilter.personal) ...schoolEvents,
      if (_filter != _CalendarFilter.school)
        for (final event in state.personalEvents)
          _CalendarView(
            id: event.id,
            title: event.title,
            subtitle: '${event.time} · ${event.category}',
            date: DateUtils.dateOnly(event.date),
            sortAt: _calendarSortTime(event.date, event.time),
            icon: Icons.person_outline_rounded,
            personal: true,
            notes: event.notes,
          ),
    ]..sort((a, b) => a.sortAt.compareTo(b.sortAt));
    final selectedEvents = all
        .where((event) => DateUtils.isSameDay(event.date, _selected))
        .toList();
    final upcomingEvents = all
        .where((event) => event.date.isAfter(_selected))
        .take(4)
        .toList();

    return _Page(
      eyebrow: 'Reja va voqealar',
      title: 'Jadval',
      subtitle: 'Darslar, nazorat ishlari va shaxsiy reja bir joyda.',
      actions: [
        _HeaderAction(
          icon: Icons.add_rounded,
          label: 'Shaxsiy reja qo‘shish',
          onPressed: () => _addEvent(context),
        ),
      ],
      maxWidth: 920,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricGrid(
            items: [
              _Metric(
                'Bugun',
                '${schoolEvents.where((event) => DateUtils.isSameDay(event.date, today)).length}',
                'ta dars va voqea',
              ),
              _Metric(
                'Bu hafta',
                '${all.where((event) => !event.date.isBefore(today) && event.date.difference(today).inDays <= 7).length}',
                'ta rejalashtirilgan',
              ),
              _Metric(
                'Eslatmalar',
                '${state.calendarReminders.length}',
                'ta yoqilgan',
              ),
            ],
          ),
          const SizedBox(height: 22),
          _DateStrip(
            selected: _selected,
            onSelected: (date) => setState(() => _selected = date),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                (_CalendarFilter.all, 'Barchasi', Icons.view_agenda_outlined),
                (_CalendarFilter.school, 'Darslar', Icons.school_outlined),
                (
                  _CalendarFilter.personal,
                  'Shaxsiy',
                  Icons.person_outline_rounded,
                ),
              ])
                ChoiceChip(
                  selected: _filter == item.$1,
                  label: Text(item.$2),
                  avatar: Icon(item.$3, size: 18),
                  onSelected: (_) => setState(() => _filter = item.$1),
                ),
              ActionChip(
                avatar: const Icon(Icons.today_rounded, size: 18),
                label: const Text('Bugun'),
                onPressed: () => setState(() => _selected = today),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            '${_selected.day} ${_monthName(_selected.month)}',
            subtitle: '${selectedEvents.length} ta voqea',
          ),
          if (selectedEvents.isEmpty)
            _EmptyState(
              icon: Icons.event_available_outlined,
              title: switch (_filter) {
                _CalendarFilter.personal => 'Bu kunda shaxsiy reja yo‘q',
                _CalendarFilter.school => 'Bu kunda dars yo‘q',
                _CalendarFilter.all => 'Bu kun bo‘sh',
              },
              message: 'Shaxsiy reja qo‘shishingiz mumkin.',
              action: FilledButton.icon(
                onPressed: () => _addEvent(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Shaxsiy reja qo‘shish'),
              ),
            )
          else
            _GroupedRows(
              children: [
                for (final event in selectedEvents)
                  _ActionRow(
                    icon: event.icon,
                    title: event.title,
                    subtitle: event.subtitle,
                    trailing: state.calendarReminders.contains(event.id)
                        ? const _StatePill(
                            'Eslatma',
                            icon: Icons.notifications_active_rounded,
                          )
                        : null,
                    onTap: () => _showCalendarEvent(
                      context,
                      event,
                      state,
                      widget.announce,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 32),
          const _SectionHeader('Kelgusi voqealar'),
          if (upcomingEvents.isEmpty)
            const _EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Keyingi reja yo‘q',
              message: 'Yangi voqea qo‘shib haftani rejalashtiring.',
            )
          else
            _GroupedRows(
              children: [
                for (final event in upcomingEvents)
                  _ActionRow(
                    icon: event.icon,
                    title: event.title,
                    subtitle:
                        '${event.date.day} ${_monthName(event.date.month)} · ${event.subtitle}',
                    onTap: () => setState(() => _selected = event.date),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _addEvent(BuildContext context) async {
    final state = AppScope.read(context);
    final result = await Navigator.of(context).push<_EventDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EventForm(initialDate: _selected),
      ),
    );
    if (result == null || !context.mounted) return;
    final personalConflict = state.personalEvents.any(
      (event) =>
          DateUtils.isSameDay(event.date, result.date) &&
          event.time == result.time,
    );
    final schoolConflict = state.familyData.lessons.any(
      (lesson) =>
          DateUtils.isSameDay(lesson.startsAt, result.date) &&
          _clockTime(lesson.startsAt) == result.time &&
          !lesson.isCancelled,
    );
    if (personalConflict || schoolConflict) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Vaqt band'),
          content: const Text(
            'Bu vaqtda boshqa dars yoki shaxsiy voqea bor. '
            'Boshqa vaqt tanlang.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tushundim'),
            ),
          ],
        ),
      );
      return;
    }
    state.addPersonalEvent(
      PersonalCalendarEvent(
        id: 'event-${DateTime.now().millisecondsSinceEpoch}',
        title: result.title,
        category: result.category,
        date: result.date,
        time: result.time,
        notes: result.notes,
      ),
    );
    setState(() => _selected = DateUtils.dateOnly(result.date));
    widget.announce('Voqea qo‘shildi', detail: result.title);
  }
}

class _CalendarView {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final DateTime sortAt;
  final IconData icon;
  final bool personal;
  final String notes;

  const _CalendarView({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    DateTime? sortAt,
    required this.icon,
    this.personal = false,
    this.notes = '',
  }) : sortAt = sortAt ?? date;
}

DateTime _calendarSortTime(DateTime date, String time) {
  final parts = time.split(':');
  final hour = parts.isEmpty ? 0 : int.tryParse(parts.first) ?? 0;
  final minute = parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

class _DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  const _DateStrip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(SfClock.now());
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return SizedBox(
      height: largeText ? 96 : 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index - 2));
          final active = DateUtils.isSameDay(date, selected);
          final colors = Theme.of(context).colorScheme;
          return Material(
            color: active ? colors.primary : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: active ? colors.primary : colors.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(date),
              child: SizedBox(
                width: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdayShort(date.weekday),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: active ? colors.onPrimary : colors.onSurface,
                        fontFamily: Sf.mono,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventDraft {
  final String title;
  final String category;
  final DateTime date;
  final String time;
  final String notes;

  const _EventDraft({
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.notes,
  });
}

class _EventForm extends StatefulWidget {
  final DateTime initialDate;

  const _EventForm({required this.initialDate});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _date;
  String _category = 'Shaxsiy';
  String _time = '17:00';

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Yopish',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Yangi voqea'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Voqea ma’lumotlari',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nom va vaqtni kiriting. Xatolar shu yerning o‘zida ko‘rsatiladi.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _title,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Voqea nomi',
                          hintText: 'Masalan: Algebra takrorlash',
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 3
                            ? 'Kamida 3 ta belgi kiriting'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Tur'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Shaxsiy',
                            child: Text('Shaxsiy'),
                          ),
                          DropdownMenuItem(
                            value: 'Tayyorgarlik',
                            child: Text('Tayyorgarlik'),
                          ),
                          DropdownMenuItem(
                            value: 'Uchrashuv',
                            child: Text('Uchrashuv'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _category = value ?? _category),
                      ),
                      const SizedBox(height: 16),
                      _ActionRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Sana',
                        subtitle:
                            '${_date.day} ${_monthName(_date.month)} ${_date.year}',
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _time,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Vaqt'),
                        items: const [
                          DropdownMenuItem(
                            value: '09:00',
                            child: Text('09:00'),
                          ),
                          DropdownMenuItem(
                            value: '14:00',
                            child: Text('14:00'),
                          ),
                          DropdownMenuItem(
                            value: '17:00',
                            child: Text('17:00'),
                          ),
                          DropdownMenuItem(
                            value: '19:00',
                            child: Text('19:00'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _time = value ?? _time),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notes,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Izoh',
                          hintText: 'Ixtiyoriy qo‘shimcha ma’lumot',
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Voqeani saqlash'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EventDraft(
        title: _title.text.trim(),
        category: _category,
        date: _date,
        time: _time,
        notes: _notes.text.trim(),
      ),
    );
  }
}

enum _ThreadFilter { all, unread, muted }

class _MessagesPage extends StatefulWidget {
  final FamilyRole role;
  final String scope;
  final String threadId;
  final bool initiallyOpenThread;
  final ValueChanged<String> onThread;
  final void Function(String, String) onDraftChanged;
  final ValueChanged<String> onMute;
  final Future<void> Function(String, String) onSend;
  final void Function(String, {String? detail}) announce;

  const _MessagesPage({
    required this.role,
    required this.scope,
    required this.threadId,
    required this.initiallyOpenThread,
    required this.onThread,
    required this.onDraftChanged,
    required this.onMute,
    required this.onSend,
    required this.announce,
  });

  @override
  State<_MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<_MessagesPage> {
  late final TextEditingController _controller;
  final TextEditingController _threadSearch = TextEditingController();
  final TextEditingController _messageSearch = TextEditingController();
  late String _threadId;
  late bool _showThreadOnPhone;
  _ThreadFilter _filter = _ThreadFilter.all;
  bool _searchMessages = false;
  String? _readThreadId;

  @override
  void initState() {
    super.initState();
    _threadId = widget.threadId;
    _showThreadOnPhone = widget.initiallyOpenThread;
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.threadId != oldWidget.threadId && widget.threadId != _threadId) {
      _threadId = widget.threadId;
      _showThreadOnPhone = true;
      _readThreadId = null;
      _controller.text = AppScope.read(
        context,
      ).messaging.draft(widget.scope, _threadId);
    }
    if (widget.initiallyOpenThread && !oldWidget.initiallyOpenThread) {
      _showThreadOnPhone = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _threadSearch.dispose();
    _messageSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final threads = state.messaging.threads(widget.scope);
    if (threads.isNotEmpty &&
        !threads.any((thread) => thread.id == _threadId)) {
      _threadId = threads.first.id;
    }
    if (_controller.text.isEmpty && _threadId.isNotEmpty) {
      final saved = state.messaging.draft(widget.scope, _threadId);
      if (saved.isNotEmpty) {
        _controller
          ..text = saved
          ..selection = TextSelection.collapsed(offset: saved.length);
      }
    }
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= 840;
    final query = _threadSearch.text.trim().toLowerCase();
    final visibleThreads = threads.where((thread) {
      final matchesQuery =
          query.isEmpty ||
          '${thread.title} ${thread.subject} ${thread.messages.isEmpty ? '' : thread.messages.last.body}'
              .toLowerCase()
              .contains(query);
      final matchesFilter = switch (_filter) {
        _ThreadFilter.all => true,
        _ThreadFilter.unread => thread.unreadCount > 0,
        _ThreadFilter.muted => thread.isMuted,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    return PopScope<void>(
      canPop: split || !_showThreadOnPhone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showThreadOnPhone) {
          setState(() => _showThreadOnPhone = false);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: split
                ? Row(
                    children: [
                      SizedBox(
                        width: 360,
                        child: _ConversationList(
                          threads: visibleThreads,
                          selected: _threadId,
                          search: _threadSearch,
                          filter: _filter,
                          connectionLabel: state.messaging.connectionLabel,
                          onSearch: (_) => setState(() {}),
                          onFilter: (value) => setState(() => _filter = value),
                          onSelected: _changeContact,
                          onNew: () => _newConversation(context),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(child: _conversation(showBack: false)),
                    ],
                  )
                : _showThreadOnPhone
                ? _conversation(showBack: true)
                : _ConversationList(
                    threads: visibleThreads,
                    selected: _threadId,
                    search: _threadSearch,
                    filter: _filter,
                    connectionLabel: state.messaging.connectionLabel,
                    onSearch: (_) => setState(() {}),
                    onFilter: (value) => setState(() => _filter = value),
                    onSelected: (threadId) {
                      _changeContact(threadId);
                      setState(() => _showThreadOnPhone = true);
                    },
                    onNew: () => _newConversation(context),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _conversation({required bool showBack}) {
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final thread = state.messaging.thread(widget.scope, _threadId);
    if (thread == null) {
      return const _EmptyState(
        icon: Icons.forum_outlined,
        title: 'Suhbat topilmadi',
        message: 'Ruxsat berilgan suhbatlar ro‘yxatini yangilang.',
      );
    }
    if (thread.unreadCount > 0 && _readThreadId != thread.id) {
      _readThreadId = thread.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _threadId != thread.id) return;
        AppScope.read(context).messaging.markRead(widget.scope, thread.id);
      });
    }
    final selfId = state.messagingUserIdForRole(widget.role.name);
    final query = _messageSearch.text.trim().toLowerCase();
    final messages = query.isEmpty
        ? thread.messages
        : thread.messages
              .where((message) => message.body.toLowerCase().contains(query))
              .toList();
    return SafeArea(
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _searchMessages
                ? _ChatSearchHeader(
                    controller: _messageSearch,
                    onChanged: (_) => setState(() {}),
                    onClose: () => setState(() {
                      _searchMessages = false;
                      _messageSearch.clear();
                    }),
                  )
                : _FamilyChatHeader(
                    thread: thread,
                    connectionLabel: state.messaging.connectionLabel,
                    showBack: showBack,
                    onBack: () => setState(() => _showThreadOnPhone = false),
                    onSearch: () => setState(() => _searchMessages = true),
                    onMute: () {
                      widget.onMute(_threadId);
                      setState(() {});
                    },
                  ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _FamilyChatBackdrop()),
                Positioned.fill(
                  child: messages.isEmpty
                      ? _EmptyState(
                          icon: query.isEmpty
                              ? Icons.forum_outlined
                              : Icons.search_off_rounded,
                          title: query.isEmpty
                              ? 'Suhbatni boshlang'
                              : 'Xabar topilmadi',
                          message: query.isEmpty
                              ? 'Birinchi xabarni yozing — qoralama avtomatik saqlanadi.'
                              : 'Boshqa so‘z bilan qidiring.',
                        )
                      : ListView.builder(
                          key: const ValueKey('family-chat-timeline'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final previous = index == 0
                                ? null
                                : messages[index - 1];
                            final showDay =
                                previous == null ||
                                !_sameCalendarDay(
                                  previous.createdAt,
                                  message.createdAt,
                                );
                            return Column(
                              children: [
                                if (showDay)
                                  _MessageDayDivider(date: message.createdAt),
                                _MessageBubble(
                                  message: message,
                                  mine: message.senderId == selfId,
                                  senderName: thread.title,
                                  onRetry:
                                      message.status ==
                                          FamilyMessageStatus.failed
                                      ? () async {
                                          final sent = await state.messaging
                                              .retry(
                                                widget.scope,
                                                _threadId,
                                                message.id,
                                              );
                                          if (!mounted) return;
                                          widget.announce(
                                            sent
                                                ? 'Xabar qayta saqlandi'
                                                : 'Qayta yuborib bo‘lmadi',
                                          );
                                        }
                                      : null,
                                ),
                                const SizedBox(height: 9),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          _MessageComposer(
            controller: _controller,
            canSend: _controller.text.trim().isNotEmpty,
            onChanged: (value) {
              widget.onDraftChanged(_threadId, value);
              setState(() {});
            },
            onSend: () {
              final text = _controller.text;
              if (text.trim().isEmpty) return;
              widget.onSend(_threadId, text);
              _controller.clear();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void _changeContact(String value, {bool greeting = false}) {
    widget.onDraftChanged(_threadId, _controller.text);
    widget.onThread(value);
    setState(() {
      _threadId = value;
      _readThreadId = null;
      final saved = AppScope.read(context).messaging.draft(widget.scope, value);
      _controller.text = saved.isNotEmpty
          ? saved
          : (greeting ? 'Assalomu alaykum, ' : '');
    });
  }

  Future<void> _newConversation(BuildContext context) async {
    final threads = AppScope.read(context).messaging.threads(widget.scope);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Suhbatni tanlash',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                for (final thread in threads)
                  _ActionRow(
                    icon: Icons.person_outline_rounded,
                    title: thread.title,
                    subtitle: thread.subject,
                    onTap: () => Navigator.pop(sheetContext, thread.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      _changeContact(selected, greeting: true);
      setState(() => _showThreadOnPhone = true);
    }
  }
}

class _ConversationList extends StatelessWidget {
  final List<FamilyThread> threads;
  final String selected;
  final TextEditingController search;
  final _ThreadFilter filter;
  final String connectionLabel;
  final ValueChanged<String> onSearch;
  final ValueChanged<_ThreadFilter> onFilter;
  final ValueChanged<String> onSelected;
  final VoidCallback onNew;

  const _ConversationList({
    required this.threads,
    required this.selected,
    required this.search,
    required this.filter,
    required this.connectionLabel,
    required this.onSearch,
    required this.onFilter,
    required this.onSelected,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = threads.fold<int>(
      0,
      (total, thread) => total + thread.unreadCount,
    );
    return SafeArea(
      child: ColoredBox(
        color: colors.surface.withValues(alpha: 0.58),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xabarlar',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unread == 0
                              ? 'Barcha suhbatlar o‘qilgan'
                              : '$unread ta o‘qilmagan xabar',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Suhbatni tanlash',
                    onPressed: onNew,
                    icon: const Icon(Icons.edit_square),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const ValueKey('message-thread-search'),
                controller: search,
                onChanged: onSearch,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Ustoz yoki xabarni qidiring',
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Suhbatlarni izlash',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ThreadFilterChip(
                    label: 'Barchasi',
                    selected: filter == _ThreadFilter.all,
                    onTap: () => onFilter(_ThreadFilter.all),
                  ),
                  _ThreadFilterChip(
                    label: 'O‘qilmagan',
                    selected: filter == _ThreadFilter.unread,
                    onTap: () => onFilter(_ThreadFilter.unread),
                  ),
                  _ThreadFilterChip(
                    label: 'Ovozsiz',
                    selected: filter == _ThreadFilter.muted,
                    onTap: () => onFilter(_ThreadFilter.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$connectionLabel · faqat ruxsat berilgan suhbatlar',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Expanded(
              child: threads.isEmpty
                  ? _EmptyState(
                      icon: search.text.trim().isEmpty
                          ? Icons.forum_outlined
                          : Icons.search_off_rounded,
                      title: search.text.trim().isEmpty
                          ? 'Bu bo‘limda suhbat yo‘q'
                          : 'Suhbat topilmadi',
                      message: search.text.trim().isEmpty
                          ? 'Boshqa filtrni tanlang yoki yangi suhbatni oching.'
                          : 'Ism yoki xabar matnini o‘zgartirib ko‘ring.',
                    )
                  : ListView.builder(
                      key: const ValueKey('message-thread-list'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
                      itemCount: threads.length,
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        final last = thread.messages.isEmpty
                            ? null
                            : thread.messages.last;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            key: ValueKey('message-thread-${thread.id}'),
                            color: selected == thread.id
                                ? colors.primaryContainer
                                : thread.unreadCount > 0
                                ? colors.surface
                                : colors.surface.withValues(alpha: 0.72),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: selected == thread.id
                                    ? colors.primary
                                    : colors.outlineVariant,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => onSelected(thread.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          colors.secondaryContainer,
                                      foregroundColor:
                                          colors.onSecondaryContainer,
                                      child: Text(_initials(thread.title)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  thread.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            thread.unreadCount >
                                                                0
                                                            ? FontWeight.w900
                                                            : FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              if (last != null) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  _relativeThreadTime(
                                                    last.createdAt,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontFamily: Sf.mono,
                                                        color:
                                                            thread.unreadCount >
                                                                0
                                                            ? colors.primary
                                                            : colors
                                                                  .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            thread.subject,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  last?.body ??
                                                      'Suhbatni boshlash',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ),
                                              if (thread.isMuted)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 6,
                                                      ),
                                                  child: Icon(
                                                    Icons
                                                        .notifications_off_rounded,
                                                    size: 16,
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                                ),
                                              if (thread.unreadCount > 0)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 7,
                                                      ),
                                                  child: Badge(
                                                    label: Text(
                                                      '${thread.unreadCount}',
                                                    ),
                                                    backgroundColor:
                                                        colors.primary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThreadFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _FamilyChatHeader extends StatelessWidget {
  final FamilyThread thread;
  final String connectionLabel;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onMute;

  const _FamilyChatHeader({
    required this.thread,
    required this.connectionLabel,
    required this.showBack,
    required this.onBack,
    required this.onSearch,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = (66 + (textScale - 1) * 24).clamp(66, 96).toDouble();
    return SizedBox(
      key: const ValueKey('family-chat-header'),
      height: height,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Suhbatlarga qaytish',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            child: Text(_initials(thread.title)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  thread.isMuted
                      ? '${thread.subject} · ovozsiz'
                      : '${thread.subject} · $connectionLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Suhbat ichida qidirish',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: thread.isMuted
                ? 'Bildirishnomalarni yoqish'
                : 'Bildirishnomalarni o‘chirish',
            onPressed: onMute,
            icon: Icon(
              thread.isMuted
                  ? Icons.notifications_off_rounded
                  : Icons.notifications_outlined,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ChatSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _ChatSearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = (66 + (textScale - 1) * 24).clamp(66, 96).toDouble();
    return SizedBox(
      key: const ValueKey('family-chat-search-header'),
      height: height,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Qidiruvni yopish',
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: TextField(
              key: const ValueKey('family-chat-message-search'),
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Suhbat ichida qidiring',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

bool _sameCalendarDay(DateTime a, DateTime b) {
  final first = a.toLocal();
  final second = b.toLocal();
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _FamilyChatBackdrop extends StatelessWidget {
  const _FamilyChatBackdrop();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: 62,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 150,
              color: colors.primary.withValues(alpha: 0.045),
            ),
          ),
          Positioned(
            left: -34,
            bottom: 54,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 190,
              color: colors.secondary.withValues(alpha: 0.04),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageDayDivider extends StatelessWidget {
  final DateTime date;

  const _MessageDayDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = date.toLocal();
    final now = SfClock.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final label = day == today
        ? 'Bugun'
        : day == today.subtract(const Duration(days: 1))
        ? 'Kecha'
        : '${local.day} ${_monthName(local.month)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 2),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.94),
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
      ),
    );
  }
}

String _relativeThreadTime(DateTime date) {
  final local = date.toLocal();
  final now = SfClock.now().toLocal();
  if (_sameCalendarDay(local, now)) return _messageTime(local);
  final yesterday = now.subtract(const Duration(days: 1));
  if (_sameCalendarDay(local, yesterday)) return 'Kecha';
  return '${local.day}.${local.month.toString().padLeft(2, '0')}';
}

class _MessageBubble extends StatelessWidget {
  final FamilyMessage message;
  final bool mine;
  final String senderName;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.senderName,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.76).clamp(
      220.0,
      390.0,
    );
    final foreground = mine ? colors.onPrimary : colors.onSurface;
    final metadata = mine
        ? colors.onPrimary.withValues(alpha: 0.76)
        : colors.onSurfaceVariant;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(13, 11, 12, 8),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surface,
          border: Border.all(
            color: mine ? colors.primary : colors.outlineVariant,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 5),
            bottomRight: Radius.circular(mine ? 5 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!mine) ...[
              Text(
                senderName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
            ],
            Text(
              message.body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground, height: 1.42),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _messageTime(message.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: metadata,
                    fontFamily: Sf.mono,
                    fontSize: 9,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  _FamilyDeliveryIcon(status: message.status, color: metadata),
                ],
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: onRetry,
                      child: Text(
                        'Qayta urinish',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: mine ? colors.onPrimary : colors.error,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyDeliveryIcon extends StatelessWidget {
  final FamilyMessageStatus status;
  final Color color;

  const _FamilyDeliveryIcon({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _messageStatusLabel(status),
      child: Icon(
        switch (status) {
          FamilyMessageStatus.sending => Icons.schedule_rounded,
          FamilyMessageStatus.failed => Icons.error_outline_rounded,
          FamilyMessageStatus.localOnly => Icons.check_rounded,
          FamilyMessageStatus.delivered => Icons.done_all_rounded,
        },
        size: 14,
        color: status == FamilyMessageStatus.failed
            ? Theme.of(context).colorScheme.error
            : color,
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;
  final bool canSend;

  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.canSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 4,
      shadowColor: colors.shadow.withValues(alpha: 0.10),
      shape: Border(top: BorderSide(color: colors.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(hintText: 'Xabar yozing…'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Xabar yuborish',
                onPressed: canSend ? onSend : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum FeatureRoute {
  attendance,
  achievements,
  announcements,
  payments,
  aiTutor,
  support,
  settings,
  profile,
  toolkit,
}

class _FamilyProfileDetail extends StatelessWidget {
  final FamilyRole role;
  final ValueChanged<FamilyRole> onRole;
  final ValueChanged<_StudyMode> onStudy;
  final VoidCallback onCalendar;
  final ValueChanged<String?> onMessages;
  final ValueChanged<FeatureRoute> onFeature;

  const _FamilyProfileDetail({
    required this.role,
    required this.onRole,
    required this.onStudy,
    required this.onCalendar,
    required this.onMessages,
    required this.onFeature,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final name =
        state.profileNames[role.name] ??
        (role == FamilyRole.parent ? 'Akbarova Dilnoza' : 'Akbarov Akmal');
    final studentName =
        state.profileNames[FamilyRole.student.name] ?? 'Akbarov Akmal';
    final assignments = state.familyData.visibleAssignments;
    final submittedIds = {
      for (final item in state.familyData.submissions)
        if (const {
          'submitted',
          'graded',
          'returned',
        }.contains(item.statusRaw.toLowerCase()))
          item.assignmentId,
    };
    final totalTasks = assignments.length + state.personalTasks.length;
    final completedTasks =
        submittedIds
            .where((id) => assignments.any((item) => item.id == id))
            .length +
        state.personalTasks
            .where((item) => state.completedTasks.contains(item.id))
            .length;
    final attendance = state.familyData.attendance;
    final attended = attendance
        .where(
          (item) => const {
            'present',
            'late',
            'excused',
          }.contains(item.statusRaw.toLowerCase()),
        )
        .length;
    final attendancePercent = attendance.isEmpty
        ? 0
        : (attended / attendance.length * 100).round();
    final grades = state.familyData.grades;
    final gradeAverage = grades.isEmpty
        ? 0
        : (grades.map((item) => item.percent).reduce((a, b) => a + b) /
                  grades.length)
              .round();
    final now = SfClock.now();
    final lessons =
        state.familyData.lessons
            .where((item) => !item.isCancelled && item.endsAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final nextLesson = lessons.isEmpty ? null : lessons.first;
    final pending =
        assignments.where((item) => !submittedIds.contains(item.id)).toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final nextAssignment = pending.isEmpty ? null : pending.first;
    final unreadMessages = state.messaging
        .threads(state.messagingScopeForRole(role.name))
        .fold<int>(0, (total, thread) => total + thread.unreadCount);

    return KeyedSubtree(
      key: const ValueKey('family-profile-screen'),
      child: _DetailScaffold(
        title: 'Mening profilim',
        subtitle: role == FamilyRole.parent
            ? 'Shaxsiy kabinetingiz va bog‘langan farzandning o‘qish holati.'
            : 'Hisob ma’lumotlari, o‘qish holati va tezkor amallar.',
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: const ValueKey('family-profile-hero'),
              child: _SurfaceCard(
                color: colors.primaryContainer.withValues(alpha: 0.7),
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final avatar = CircleAvatar(
                      radius: 38,
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: Text(
                        _initials(name),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    );
                    final identity = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role == FamilyRole.parent
                              ? 'Ota-ona kabineti'
                              : 'O‘quvchi · 9-B',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 10),
                        _StatePill(
                          state.familyUsesLocalPreview
                              ? 'Namuna ma’lumotlari'
                              : 'Maktab ma’lumotlari',
                          icon: state.familyUsesLocalPreview
                              ? Icons.science_outlined
                              : Icons.verified_user_outlined,
                          color: colors.primary,
                        ),
                      ],
                    );
                    final edit = IconButton.filledTonal(
                      key: const ValueKey('family-profile-edit'),
                      tooltip: 'Ismni tahrirlash',
                      onPressed: () => _editName(context, state),
                      icon: const Icon(Icons.edit_outlined),
                    );
                    if (constraints.maxWidth < 430) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [avatar, const Spacer(), edit]),
                          const SizedBox(height: 16),
                          identity,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        avatar,
                        const SizedBox(width: 16),
                        Expanded(child: identity),
                        edit,
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            _MetricGrid(
              items: [
                _Metric(
                  'Davomat',
                  '$attendancePercent%',
                  '$attended/${attendance.length} dars',
                ),
                _Metric(
                  'O‘rtacha natija',
                  '$gradeAverage%',
                  '${grades.length} ta baho',
                ),
                _Metric(
                  'Vazifalar',
                  '$completedTasks/$totalTasks',
                  '${totalTasks - completedTasks} ta qolgan',
                ),
                _Metric(
                  'Yangi xabar',
                  '$unreadMessages',
                  unreadMessages == 0 ? 'Hammasi o‘qilgan' : 'Javob kutilmoqda',
                ),
              ],
            ),
            if (role == FamilyRole.parent) ...[
              const SizedBox(height: 24),
              const _SectionHeader(
                'Bog‘langan farzand',
                subtitle: 'Faqat oilangizga biriktirilgan profil ko‘rsatiladi',
              ),
              KeyedSubtree(
                key: const ValueKey('family-profile-student-summary'),
                child: _SurfaceCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: colors.secondaryContainer,
                        foregroundColor: colors.onSecondaryContainer,
                        child: Text(_initials(studentName)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            const Text('O‘quvchi · 9-B'),
                          ],
                        ),
                      ),
                      const _StatePill('Bog‘langan', icon: Icons.link_rounded),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _SectionHeader(
              'Tezkor amallar',
              subtitle: 'Har bir tugma tegishli bo‘limni ochadi',
            ),
            _HomeQuickGrid(
              items: [
                _HomeQuickItem(
                  id: 'profile-schedule',
                  icon: Icons.calendar_month_outlined,
                  label: 'Jadval',
                  detail: nextLesson == null
                      ? 'Yangi dars kutilmoqda'
                      : '${_clockTime(nextLesson.startsAt)} · ${nextLesson.title}',
                  onTap: () => _leaveAndRun(context, onCalendar),
                ),
                _HomeQuickItem(
                  id: 'profile-results',
                  icon: Icons.insights_outlined,
                  label: role == FamilyRole.parent
                      ? 'Farzand natijalari'
                      : 'Natijalarim',
                  detail: '$gradeAverage% o‘rtacha',
                  onTap: () =>
                      _leaveAndRun(context, () => onStudy(_StudyMode.grades)),
                ),
                _HomeQuickItem(
                  id: 'profile-message',
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Ustozga yozish',
                  detail: 'Tayyor suhbatni ochish',
                  onTap: () => _leaveAndRun(
                    context,
                    () => onMessages(
                      role == FamilyRole.parent
                          ? 'Assalomu alaykum. Farzandimning o‘qishi bo‘yicha savolim bor.'
                          : 'Assalomu alaykum. Mavzu bo‘yicha savolim bor.',
                    ),
                  ),
                ),
                _HomeQuickItem(
                  id: role == FamilyRole.parent
                      ? 'profile-payments'
                      : 'profile-ai',
                  icon: role == FamilyRole.parent
                      ? Icons.account_balance_wallet_outlined
                      : Icons.auto_awesome_outlined,
                  label: role == FamilyRole.parent
                      ? 'To‘lovlar'
                      : 'AI repetitor',
                  detail: role == FamilyRole.parent
                      ? (state.paymentCompleted
                            ? 'To‘langan'
                            : 'Holatni ko‘rish')
                      : 'Tushuntirish va reja',
                  onTap: () => _leaveAndRun(
                    context,
                    () => onFeature(
                      role == FamilyRole.parent
                          ? FeatureRoute.payments
                          : FeatureRoute.aiTutor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader('O‘qish hozir'),
            _GroupedRows(
              children: [
                if (nextLesson != null)
                  _ActionRow(
                    icon: Icons.school_outlined,
                    title: nextLesson.title,
                    subtitle:
                        '${_friendlyDate(nextLesson.startsAt)} · ${_clockTime(nextLesson.startsAt)} · ${nextLesson.roomName} · ${nextLesson.teacherName}',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _leaveAndRun(context, onCalendar),
                  ),
                if (nextAssignment != null)
                  _ActionRow(
                    icon: Icons.assignment_outlined,
                    title: nextAssignment.title,
                    subtitle:
                        '${nextAssignment.subject} · ${_deadlineLabel(nextAssignment.dueAt)} gacha',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        _leaveAndRun(context, () => onStudy(_StudyMode.tasks)),
                  ),
                if (nextLesson == null && nextAssignment == null)
                  const _EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'Faol ish topilmadi',
                    message:
                        'Yangi dars yoki vazifa kelganda shu yerda ko‘rinadi.',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              'So‘nggi natijalar',
              subtitle: '${grades.length} ta baholangan ish',
              action: TextButton(
                onPressed: () =>
                    _leaveAndRun(context, () => onStudy(_StudyMode.grades)),
                child: const Text('Barchasi'),
              ),
            ),
            _GroupedRows(
              children: grades.isEmpty
                  ? const [
                      _EmptyState(
                        icon: Icons.school_outlined,
                        title: 'Baho hali yo‘q',
                        message: 'Baholangan ishlar shu yerda ko‘rinadi.',
                      ),
                    ]
                  : [
                      for (final grade in grades.take(3))
                        _ActionRow(
                          icon: Icons.workspace_premium_outlined,
                          title: '${grade.subject} · ${grade.percent}%',
                          subtitle: grade.feedback.isEmpty
                              ? '${grade.assignmentTitle} · ${grade.teacherName}'
                              : grade.feedback,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _leaveAndRun(
                            context,
                            () => onStudy(_StudyMode.grades),
                          ),
                        ),
                    ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              'Davomat tarixi',
              subtitle: '${attendance.length} ta dars',
              action: TextButton(
                onPressed: () => _leaveAndRun(
                  context,
                  () => onFeature(FeatureRoute.attendance),
                ),
                child: const Text('Barchasi'),
              ),
            ),
            _GroupedRows(
              children: attendance.isEmpty
                  ? const [
                      _EmptyState(
                        icon: Icons.fact_check_outlined,
                        title: 'Davomat ma’lumoti yo‘q',
                        message:
                            'Maktab ma’lumoti kelganda shu yerda ko‘rinadi.',
                      ),
                    ]
                  : [
                      for (final item in attendance.take(4))
                        _ActionRow(
                          icon: item.statusRaw.toLowerCase() == 'present'
                              ? Icons.check_circle_outline_rounded
                              : item.statusRaw.toLowerCase() == 'late'
                              ? Icons.schedule_outlined
                              : Icons.info_outline_rounded,
                          title: item.lessonTitle,
                          subtitle: _friendlyDate(item.startsAt),
                          trailing: _StatePill(
                            _attendanceStatusLabel(item.statusRaw),
                          ),
                          onTap: () => _leaveAndRun(
                            context,
                            () => onFeature(FeatureRoute.attendance),
                          ),
                        ),
                    ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader('O‘quv maqsadlari'),
            for (final goal in state.goals) ...[
              _GoalProgressCard(
                goal: goal,
                onTap: () => _showGoalProgressDialog(context, state, goal),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            const _SectionHeader('Hisob va maxfiylik'),
            _GroupedRows(
              children: [
                _ActionRow(
                  icon: Icons.edit_outlined,
                  title: 'Ism va familiyani tahrirlash',
                  subtitle: name,
                  onTap: () => _editName(context, state),
                ),
                _ActionRow(
                  icon: Icons.notifications_outlined,
                  title: 'Bildirishnomalar',
                  subtitle:
                      '${state.notificationPreferences.values.where((value) => value).length} ta tur yoqilgan',
                  onTap: () => _leaveAndRun(
                    context,
                    () => onFeature(FeatureRoute.settings),
                  ),
                ),
                _ActionRow(
                  icon: Icons.settings_outlined,
                  title: 'Ilova sozlamalari',
                  subtitle: 'Ko‘rinish, matn va maxfiylik',
                  onTap: () => _leaveAndRun(
                    context,
                    () => onFeature(FeatureRoute.settings),
                  ),
                ),
                _ActionRow(
                  key: const ValueKey('switch-family-cabinet'),
                  icon: Icons.swap_horiz_rounded,
                  title: 'Kabinetni almashtirish',
                  subtitle: role == FamilyRole.parent
                      ? 'Hozir ota-ona kabineti'
                      : 'Hozir o‘quvchi kabineti',
                  onTap: () => _switchCabinet(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              state.familyUsesLocalPreview
                  ? 'Bu profil namuna rejimida. Serverga yuborilmagan o‘zgarishlar faqat shu sessiyada saqlanadi.'
                  : 'Maktabdan olingan ma’lumotlar faqat joriy oila profili doirasida ko‘rsatiladi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _leaveAndRun(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    Future<void>.delayed(Duration.zero, action);
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final value = await _textEntryDialog(
      context,
      title: 'Profil nomi',
      label: 'Ism va familiya',
      hint: 'Masalan: Akbarov Akmal',
      action: 'Saqlash',
      minLength: 3,
      initialValue: state.profileNames[role.name],
    );
    if (value != null && context.mounted) {
      state.setProfileName(role.name, value);
    }
  }

  Future<void> _switchCabinet(BuildContext context) {
    return _showRolePicker(context, role, (next) {
      Navigator.pop(context);
      Future<void>.delayed(Duration.zero, () => onRole(next));
    });
  }
}

class _MorePage extends StatelessWidget {
  final FamilyRole role;
  final String name;
  final ValueChanged<FamilyRole> onRole;
  final ValueChanged<FeatureRoute> onFeature;
  final ValueChanged<_StudyMode> onStudy;
  final VoidCallback onCalendar;
  final VoidCallback onMessages;

  const _MorePage({
    required this.role,
    required this.name,
    required this.onRole,
    required this.onFeature,
    required this.onStudy,
    required this.onCalendar,
    required this.onMessages,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _Page(
      eyebrow: 'Profil',
      title: 'Xizmatlar',
      subtitle: 'Kerakli maktab xizmatlari — bitta sodda katalogda.',
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityButton(
            key: const ValueKey('open-family-profile-more'),
            name: name,
            subtitle: role == FamilyRole.parent
                ? 'Ota-ona profili'
                : 'O‘quvchi · 9-B',
            onTap: () => onFeature(FeatureRoute.profile),
            switchKey: const ValueKey('switch-family-cabinet-more'),
            onSwitchRole: () => _showRolePicker(context, role, onRole),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(
            'Maktab xizmatlari',
            subtitle: 'Kerakli bo‘limni tanlang',
          ),
          const SizedBox(height: 10),
          _HomeQuickGrid(
            items: [
              _HomeQuickItem(
                id: 'attendance',
                icon: Icons.fact_check_outlined,
                label: role == FamilyRole.parent ? 'Davomat' : 'Davomatim',
                detail: 'Darslar bo‘yicha holat',
                onTap: () => onFeature(FeatureRoute.attendance),
              ),
              _HomeQuickItem(
                id: 'achievements',
                icon: Icons.emoji_events_outlined,
                label: role == FamilyRole.parent ? 'Natijalar' : 'Yutuqlarim',
                detail: 'Baholar va o‘sish',
                onTap: () => onFeature(FeatureRoute.achievements),
              ),
              _HomeQuickItem(
                id: 'announcements',
                icon: Icons.campaign_outlined,
                label: 'E’lonlar',
                detail: state.unreadAnnouncementCount == 0
                    ? 'Hammasi o‘qilgan'
                    : '${state.unreadAnnouncementCount} ta yangi',
                onTap: () => onFeature(FeatureRoute.announcements),
              ),
              _HomeQuickItem(
                id: role == FamilyRole.parent ? 'payments' : 'ai',
                icon: role == FamilyRole.parent
                    ? Icons.account_balance_wallet_outlined
                    : Icons.auto_awesome_outlined,
                label: role == FamilyRole.parent ? 'To‘lovlar' : 'AI repetitor',
                detail: role == FamilyRole.parent
                    ? (state.paymentCompleted ? 'To‘langan' : 'Kutilmoqda')
                    : 'Savol va tushuntirish',
                onTap: () => onFeature(
                  role == FamilyRole.parent
                      ? FeatureRoute.payments
                      : FeatureRoute.aiTutor,
                ),
              ),
              _HomeQuickItem(
                id: 'profile',
                icon: Icons.account_circle_outlined,
                label: 'Mening profilim',
                detail: 'Hisob va o‘qish holati',
                onTap: () => onFeature(FeatureRoute.profile),
              ),
              _HomeQuickItem(
                id: 'toolkit',
                icon: Icons.widgets_outlined,
                label: 'Aqlli asboblar',
                detail: '40+ foydali funksiya',
                onTap: () => onFeature(FeatureRoute.toolkit),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            'O‘qish va aloqa',
            subtitle: 'Eng ko‘p ishlatiladigan bo‘limlar',
          ),
          _GroupedRows(
            children: [
              _ActionRow(
                icon: Icons.assignment_outlined,
                title: 'Vazifalar',
                subtitle: 'Faol va bajarilgan ishlar',
                onTap: () => onStudy(_StudyMode.tasks),
              ),
              _ActionRow(
                icon: Icons.school_outlined,
                title: 'Baholar',
                subtitle: 'Natijalar va ustoz fikri',
                onTap: () => onStudy(_StudyMode.grades),
              ),
              _ActionRow(
                icon: Icons.library_books_outlined,
                title: 'Materiallar',
                subtitle: 'PDF, audio va konspektlar',
                onTap: () => onStudy(_StudyMode.materials),
              ),
              _ActionRow(
                icon: Icons.calendar_month_outlined,
                title: 'Jadval',
                subtitle: 'Darslar va shaxsiy voqealar',
                onTap: onCalendar,
              ),
              _ActionRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Ustozlar bilan xabarlar',
                subtitle: 'Suhbatlar va saqlangan qoralamalar',
                onTap: onMessages,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Yordam va sozlash'),
          _GroupedRows(
            children: [
              _ActionRow(
                icon: Icons.support_agent_outlined,
                title: 'Yordam markazi',
                subtitle: 'Savollar va yordam',
                onTap: () => onFeature(FeatureRoute.support),
              ),
              _ActionRow(
                icon: Icons.settings_outlined,
                title: 'Sozlamalar',
                subtitle: 'Ko‘rinish, qulaylik va maxfiylik',
                onTap: () => onFeature(FeatureRoute.settings),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            state.familyUsesLocalPreview
                ? 'Namuna rejimi · o‘zgarishlar shu qurilmada saqlanadi'
                : 'Maktab akkauntingiz bilan himoyalangan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  const _DetailScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subtitle != null) ...[
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    child,
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

class _AttendanceDetail extends StatefulWidget {
  final FamilyRole role;
  final ValueChanged<String?> onMessage;
  final void Function(String, {String? detail}) announce;

  const _AttendanceDetail({
    required this.role,
    required this.onMessage,
    required this.announce,
  });

  @override
  State<_AttendanceDetail> createState() => _AttendanceDetailState();
}

class _AttendanceDetailState extends State<_AttendanceDetail> {
  String _filter = 'Barchasi';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.familyData.attendance;
    final visible = _filter == 'Barchasi'
        ? all
        : all
              .where(
                (item) => _attendanceStatusLabel(item.statusRaw) == _filter,
              )
              .toList();
    final attended = all
        .where(
          (item) => const {
            'present',
            'late',
            'excused',
          }.contains(item.statusRaw.toLowerCase()),
        )
        .length;
    final known = all
        .where(
          (item) => const {
            'present',
            'late',
            'excused',
            'absent',
          }.contains(item.statusRaw.toLowerCase()),
        )
        .length;
    final percent = known == 0 ? 0 : (attended / known * 100).round();
    return _DetailScaffold(
      title: widget.role == FamilyRole.parent ? 'Davomat' : 'Davomatim',
      subtitle: state.familyUsesLocalPreview
          ? 'Namuna yozuvlari · maktabga yuborilmaydi.'
          : 'Tasdiqlangan dars yozuvlari.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in const [
                'Barchasi',
                'Ishtirok etdi',
                'Kechikdi',
                'Sababli',
                'Qatnashmadi',
              ])
                ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _MetricGrid(
            items: [
              _Metric('Davomat', '$percent%', '$attended/$known dars'),
              _Metric(
                'Kechikish',
                '${all.where((item) => item.statusRaw.toLowerCase() == 'late').length}',
                'Ko‘rsatilgan davr',
              ),
              _Metric(
                'Sababli',
                '${all.where((item) => item.statusRaw.toLowerCase() == 'excused').length}',
                'Server yozuvi',
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionHeader('Darslar', subtitle: '${visible.length} ta'),
          _GroupedRows(
            children: [
              for (final item in visible)
                _ActionRow(
                  icon: item.statusRaw.toLowerCase() == 'present'
                      ? Icons.check_circle_outline_rounded
                      : item.statusRaw.toLowerCase() == 'late'
                      ? Icons.schedule_rounded
                      : Icons.info_outline_rounded,
                  title: item.lessonTitle,
                  subtitle: _shortDate(item.startsAt),
                  trailing: _StatePill(_attendanceStatusLabel(item.statusRaw)),
                  onTap: () => _showAttendanceRecord(context, item),
                ),
            ],
          ),
          if (widget.role == FamilyRole.parent) ...[
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onMessage(
                  'Assalomu alaykum, davomat yozuvi bo‘yicha aniqlik '
                  'kiritmoqchi edim.',
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Davomat haqida ustozga yozish'),
            ),
          ],
          if (widget.role == FamilyRole.student) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onMessage(
                  'Assalomu alaykum, davomat yozuvi bo‘yicha savolim bor.',
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ustozga yozish'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementsDetail extends StatelessWidget {
  final ValueChanged<String?> onMessage;
  final void Function(String, {String? detail}) announce;

  const _AchievementsDetail({required this.onMessage, required this.announce});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final grades = state.familyData.grades;
    final average = grades.isEmpty
        ? 0
        : (grades.map((grade) => grade.percent).reduce((a, b) => a + b) /
                  grades.length)
              .round();
    final best = grades.isEmpty
        ? null
        : ([...grades]..sort((a, b) => b.percent.compareTo(a.percent))).first;
    final submissions = state.familyData.submissions;
    final completed = submissions
        .where(
          (item) => const {
            'submitted',
            'graded',
            'returned',
          }.contains(item.statusRaw.toLowerCase()),
        )
        .length;
    final late = submissions.where((item) => item.isLate).toList();
    return _DetailScaffold(
      title: 'Natijalar va yutuqlar',
      subtitle: 'Tasdiqlangan baholar va topshiriqlar bo‘yicha aniq ko‘rinish.',
      actions: [
        IconButton(
          tooltip: 'Hisobotni nusxalash',
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(
                text:
                    'StarForge Family\nO‘rtacha: $average%\nEng yaxshi: ${best?.percent ?? 0}%\nTopshiriqlar: $completed/${submissions.length}',
              ),
            );
            announce('Hisobot nusxalandi');
          },
          icon: const Icon(Icons.copy_all_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricGrid(
            items: [
              _Metric('O‘rtacha', '$average%', '${grades.length} ta baho'),
              _Metric(
                'Eng yaxshi',
                '${best?.percent ?? 0}%',
                best?.subject ?? 'Baho yo‘q',
              ),
              _Metric(
                'Topshiriqlar',
                '$completed/${submissions.length}',
                'Tasdiqlangan holat',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader('Baholangan ishlar'),
          if (grades.isEmpty)
            const _EmptyState(
              icon: Icons.school_outlined,
              title: 'Hozircha baho yo‘q',
              message: 'Ustoz baholagan ishlar shu yerda ko‘rinadi.',
            )
          else
            _GroupedRows(
              children: [
                for (final grade in grades.take(5))
                  _ActionRow(
                    icon: Icons.verified_outlined,
                    title: grade.assignmentTitle,
                    subtitle:
                        '${grade.subject} · ${_shortDate(grade.gradedAt)}',
                    trailing: _StatePill('${grade.percent}%'),
                    onTap: () => _showSimpleDetail(
                      context,
                      grade.assignmentTitle,
                      grade.feedback.isEmpty
                          ? '${grade.teacherName} izoh qoldirmagan.'
                          : '${grade.teacherName}\n\n${grade.feedback}',
                    ),
                  ),
              ],
            ),
          if (late.isNotEmpty) ...[
            const SizedBox(height: 22),
            _ActionRow(
              icon: Icons.schedule_outlined,
              title: 'Kech topshirilgan ish',
              subtitle: late.first.assignmentTitle,
              trailing: _StatePill(
                'Aniqlashtirish',
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () {
                Navigator.pop(context);
                onMessage(
                  'Assalomu alaykum, ${late.first.assignmentTitle} kech topshirilgani bo‘yicha aniqlik kiritmoqchiman.',
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AnnouncementsDetail extends StatefulWidget {
  const _AnnouncementsDetail();

  @override
  State<_AnnouncementsDetail> createState() => _AnnouncementsDetailState();
}

class _AnnouncementsDetailState extends State<_AnnouncementsDetail> {
  bool _pinnedOnly = false;

  static const _items = [
    (
      'announcement-olympiad',
      'Matematika olimpiadasi',
      '30 Iyul · Ro‘yxatdan o‘tish 29 Iyulgacha',
      'Maktab bosqichi 30 Iyul soat 14:00 da bo‘lib o‘tadi.',
    ),
    (
      'announcement-meeting',
      'Ota-onalar uchrashuvi',
      '31 Iyul · Online',
      'Uchrashuv havolasi tadbirdan oldin yuboriladi.',
    ),
    (
      'announcement-library',
      'Yangi elektron materiallar',
      '23 Iyul · 12 ta material',
      'Algebra va ingliz tili bo‘yicha yangi materiallar qo‘shildi.',
    ),
    (
      'announcement-welcome',
      'Yozgi jadval',
      '20 Iyul · Jadval',
      'Iyul–Avgust oylarida yangilangan jadval amal qiladi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = _pinnedOnly
        ? _items
              .where((item) => state.pinnedAnnouncements.contains(item.$1))
              .toList()
        : _items;
    return _DetailScaffold(
      title: 'E’lonlar',
      subtitle: 'Lokal namuna · ${state.unreadAnnouncementCount} ta o‘qilmagan',
      actions: [
        IconButton(
          tooltip: 'Barchasini o‘qish',
          onPressed: state.unreadAnnouncementCount == 0
              ? null
              : () => state.markAllAnnouncementsRead(
                  _items.map((item) => item.$1),
                ),
          icon: const Icon(Icons.done_all_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterChip(
            selected: _pinnedOnly,
            label: const Text('Faqat mahkamlangan'),
            avatar: const Icon(Icons.push_pin_outlined, size: 18),
            onSelected: (value) => setState(() => _pinnedOnly = value),
          ),
          const SizedBox(height: 20),
          if (visible.isEmpty)
            _EmptyState(
              icon: Icons.push_pin_outlined,
              title: 'Mahkamlangan e’lon yo‘q',
              message: 'Muhim e’lon yonidagi pin tugmasini bosing.',
            )
          else
            _GroupedRows(
              children: [
                for (final item in visible)
                  _ActionRow(
                    icon: state.readAnnouncements.contains(item.$1)
                        ? Icons.campaign_outlined
                        : Icons.mark_email_unread_outlined,
                    title: item.$2,
                    subtitle: item.$3,
                    trailing: IconButton(
                      tooltip: state.pinnedAnnouncements.contains(item.$1)
                          ? 'Mahkamlashni bekor qilish'
                          : 'Mahkamlash',
                      onPressed: () => state.togglePinnedAnnouncement(item.$1),
                      icon: Icon(
                        state.pinnedAnnouncements.contains(item.$1)
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                      ),
                    ),
                    onTap: () => _openAnnouncement(context, state, item),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentsDetail extends StatefulWidget {
  final void Function(String, {String? detail}) announce;

  const _PaymentsDetail({required this.announce});

  @override
  State<_PaymentsDetail> createState() => _PaymentsDetailState();
}

class _PaymentsDetailState extends State<_PaymentsDetail> {
  String _method = 'Click';
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final amount = state.hideAmounts ? '••• ••• so‘m' : '600 000 so‘m';
    return _DetailScaffold(
      title: 'To‘lovlar',
      subtitle: state.paymentCompleted
          ? 'Avgust to‘lovi qabul qilindi'
          : 'Keyingi to‘lov · 30 Iyulgacha',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurfaceCard(
            color: state.paymentCompleted
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatePill(
                  state.paymentCompleted ? 'To‘langan' : 'Kutilmoqda',
                  icon: state.paymentCompleted
                      ? Icons.verified_rounded
                      : Icons.schedule_rounded,
                ),
                const SizedBox(height: 16),
                Text(
                  amount,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(fontFamily: Sf.mono),
                ),
                const SizedBox(height: 6),
                Text(
                  state.paymentCompleted
                      ? '${state.receiptNumber} · ${state.paymentMethod}'
                      : 'Avgust · 9-B',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!state.paymentCompleted) ...[
            const _SectionHeader('To‘lov usuli'),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 520 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4) {
                  return DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'To‘lov usuli',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Click', child: Text('Click')),
                      DropdownMenuItem(value: 'Payme', child: Text('Payme')),
                      DropdownMenuItem(value: 'Uzcard', child: Text('Uzcard')),
                    ],
                    onChanged: _processing
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _method = value);
                            }
                          },
                  );
                }
                return SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Click', label: Text('Click')),
                    ButtonSegment(value: 'Payme', label: Text('Payme')),
                    ButtonSegment(value: 'Uzcard', label: Text('Uzcard')),
                  ],
                  selected: {_method},
                  onSelectionChanged: _processing
                      ? null
                      : (values) => setState(() => _method = values.first),
                  showSelectedIcon: false,
                );
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _processing ? null : () => _pay(context, state),
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(_processing ? 'Qabul qilinmoqda…' : 'Demo to‘lov'),
            ),
          ] else
            FilledButton.tonalIcon(
              onPressed: () => _receipt(context, state),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Kvitansiyani ochish'),
            ),
          const SizedBox(height: 32),
          const _SectionHeader('Tarix'),
          _GroupedRows(
            children: [
              _ActionRow(
                icon: Icons.receipt_outlined,
                title: state.hideAmounts
                    ? 'Iyul · ••• ••• so‘m'
                    : 'Iyul · 600 000 so‘m',
                subtitle: 'Click · SF-240701',
                trailing: const _StatePill('To‘langan'),
                onTap: () => _historyReceipt(
                  context,
                  state,
                  month: 'Iyul 2026',
                  method: 'Click',
                  number: 'SF-240701',
                ),
              ),
              _ActionRow(
                icon: Icons.receipt_outlined,
                title: state.hideAmounts
                    ? 'Iyun · ••• ••• so‘m'
                    : 'Iyun · 600 000 so‘m',
                subtitle: 'Payme · SF-240604',
                trailing: const _StatePill('To‘langan'),
                onTap: () => _historyReceipt(
                  context,
                  state,
                  month: 'Iyun 2026',
                  method: 'Payme',
                  number: 'SF-240604',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo to‘lovni tasdiqlash'),
        content: Text('600 000 so‘m · $_method\nHaqiqiy mablag‘ yechilmaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('To‘lovni tasdiqlash'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    state.completePayment(_method);
    setState(() => _processing = false);
    widget.announce('To‘lov muvaffaqiyatli', detail: state.receiptNumber);
  }

  Future<void> _receipt(BuildContext context, AppState state) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kvitansiya'),
        content: SelectableText(
          '${state.receiptNumber}\n${state.hideAmounts ? '••• ••• so‘m' : '600 000 so‘m'}\n${state.paymentMethod}\nAvgust 2026',
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: state.receiptNumber ?? 'SF-DEMO'),
              );
              if (context.mounted) widget.announce('Raqam nusxalandi');
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Nusxalash'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Future<void> _historyReceipt(
    BuildContext context,
    AppState state, {
    required String month,
    required String method,
    required String number,
  }) {
    final amount = state.hideAmounts ? '••• ••• so‘m' : '600 000 so‘m';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$month kvitansiyasi'),
        content: SelectableText(
          'Holat: To‘langan\nMiqdor: $amount\nUsul: $method\nRaqam: $number',
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: number));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Raqamni nusxalash'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }
}

class _AiTutorDetail extends StatefulWidget {
  final void Function(String, {String? detail}) announce;

  const _AiTutorDetail({required this.announce});

  @override
  State<_AiTutorDetail> createState() => _AiTutorDetailState();
}

class _AiTutorDetailState extends State<_AiTutorDetail> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'Diskriminantni sodda tushuntir',
    'Inglizcha so‘zlarni qanday yodlayman?',
    'Menga mini-test rejasini tuz',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refreshComposer);
  }

  @override
  void dispose() {
    _controller.removeListener(_refreshComposer);
    _controller.dispose();
    super.dispose();
  }

  void _refreshComposer() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final canSend = _controller.text.trim().length >= 3 && !state.aiGenerating;
    return _DetailScaffold(
      title: 'AI repetitor',
      subtitle:
          'Bir mavzuni tushuntirish, mashq rejasini tuzish va savol-javob uchun.',
      maxWidth: 760,
      actions: [
        IconButton(
          tooltip: 'Tarixni tozalash',
          onPressed: state.aiMessages.isEmpty || state.aiGenerating
              ? null
              : () => _confirmClear(state),
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurfaceCard(
            color: state.aiUsesLocalDemo
                ? colors.secondaryContainer
                : colors.primaryContainer,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  state.aiUsesLocalDemo
                      ? Icons.offline_bolt_outlined
                      : Icons.cloud_done_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.aiConnectionLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.aiUsesLocalDemo
                            ? 'Bu javob serverdan kelmaydi va lokal demo sifatida aniq belgilangan.'
                            : 'Javoblar ulangan xizmatdan keladi.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (state.aiMessages.isEmpty) ...[
            Text(
              'Savolni tanlang yoki o‘zingiz yozing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in _suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                    onPressed: state.aiGenerating
                        ? null
                        : () => _ask(state, suggestion),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          for (final message in state.aiMessages)
            _AiMessageBubble(message: message),
          if (state.aiGenerating)
            _SurfaceCard(
              color: colors.surfaceContainer,
              child: Row(
                children: [
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Javob tayyorlanmoqda…')),
                  TextButton.icon(
                    onPressed: state.cancelAiRequest,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('To‘xtatish'),
                  ),
                ],
              ),
            ),
          if (state.aiError != null)
            _SurfaceCard(
              color: colors.errorContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Javob olinmadi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.aiError!,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.aiGenerating
                        ? null
                        : state.retryLastAiPrompt,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Qayta urinish'),
                  ),
                ],
              ),
            ),
          if (state.aiMessages.isNotEmpty && !state.aiGenerating) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in const [
                  'Yana misol',
                  'Boshqacha tushuntir',
                  'Mini-test ber',
                ])
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _ask(state, suggestion),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 5,
            enabled: !state.aiGenerating,
            textInputAction: TextInputAction.send,
            onSubmitted: canSend ? (_) => _ask(state) : null,
            decoration: const InputDecoration(
              labelText: 'Savol',
              hintText: 'Masalan: diskriminantni sodda tushuntir',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('ai-send'),
            onPressed: canSend ? () => _ask(state) : null,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Savolni yuborish'),
          ),
          const SizedBox(height: 10),
          Text(
            'Muhim javobni ustoz yoki ishonchli manba bilan tekshiring.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _ask(AppState state, [String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.length < 3) return;
    _controller.clear();
    await state.askAi(question);
  }

  Future<void> _confirmClear(AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suhbatni tozalash?'),
        content: const Text(
          'Savollar va javoblar joriy seans tarixidan o‘chiriladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            key: const ValueKey('ai-clear-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) state.clearAiChat();
  }
}

class _AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;

  const _AiMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.role == AiMessageRole.user;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: mine ? colors.primaryContainer : colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text),
            if (!mine &&
                (message.isLocalDemo || message.sources.isNotEmpty)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (message.isLocalDemo)
                    const _StatePill(
                      'Lokal demo',
                      icon: Icons.offline_bolt_outlined,
                    ),
                  for (final source in message.sources)
                    _StatePill(source.title, icon: Icons.menu_book_outlined),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SupportDetail extends StatefulWidget {
  final FamilyRole role;
  final void Function(String, {String? detail}) announce;

  const _SupportDetail({required this.role, required this.announce});

  @override
  State<_SupportDetail> createState() => _SupportDetailState();
}

class _SupportDetailState extends State<_SupportDetail> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _DetailScaffold(
      title: 'Yordam markazi',
      subtitle:
          'FAQ va lokal murojaatlar. Demo murojaat tashqi serverga yuborilmaydi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('Ko‘p so‘raladigan savollar'),
          _GroupedRows(
            children: const [
              _FaqRow(
                question: 'Vazifani qanday bajarilgan deb belgilayman?',
                answer:
                    'Vazifalar bo‘limidagi checkboxni bosing. Holat darhol saqlanadi.',
              ),
              _FaqRow(
                question: 'To‘lov haqiqiymi?',
                answer: 'Yo‘q. Bu demo oqim va haqiqiy mablag‘ yechilmaydi.',
              ),
              _FaqRow(
                question: 'AI javobi ishonchlimi?',
                answer:
                    'AI yordamchi vosita. Muhim javobni ustoz bilan tekshiring.',
              ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _createTicket(context),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Lokal murojaat yaratish'),
          ),
          if (state.supportTickets.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionHeader('Lokal murojaatlar'),
            _GroupedRows(
              children: [
                for (final ticket in state.supportTickets)
                  _ActionRow(
                    icon: Icons.drafts_outlined,
                    title: ticket.topic,
                    subtitle: ticket.message,
                    trailing: const _StatePill('Lokal draft'),
                    onTap: () => _showSimpleDetail(
                      context,
                      ticket.id,
                      '${ticket.message}\n\nStatus: Lokal draft',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createTicket(BuildContext context) async {
    final message = await _textEntryDialog(
      context,
      title: 'Lokal murojaat',
      label: 'Muammo yoki taklif',
      hint: 'Nima bo‘ldi va qaysi ekranda?',
      action: 'Draftni saqlash',
      minLength: 10,
      multiline: true,
    );
    if (message == null || !context.mounted) return;
    AppScope.read(context).createSupportTicket(
      SupportTicket(
        id: 'SF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        topic: 'Yordam murojaati',
        message: message,
        priority: 'Oddiy',
        createdAt: DateTime.now(),
        status: 'Lokal draft',
      ),
    );
    widget.announce('Lokal draft saqlandi');
  }
}

class _FaqRow extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqRow({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      minTileHeight: 64,
      leading: const Icon(Icons.help_outline_rounded),
      title: Text(question),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(answer)],
    );
  }
}

class _SettingsDetail extends StatelessWidget {
  final FamilyRole role;
  final VoidCallback onReset;

  const _SettingsDetail({required this.role, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final name = state.profileNames[role.name] ?? '';
    return _DetailScaffold(
      title: 'Sozlamalar',
      subtitle: 'Ko‘rinish va qulaylik sozlamalari darhol qo‘llanadi.',
      maxWidth: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('Profil'),
          _GroupedRows(
            children: [
              _ActionRow(
                icon: Icons.person_outline_rounded,
                title: name,
                subtitle: 'Ism va familiyani tahrirlash',
                onTap: () => _editName(context, state),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader('Bildirishnomalar'),
          _GroupedRows(
            children: [
              _SwitchRow(
                icon: Icons.notifications_active_outlined,
                title: 'Push bildirishnomalar',
                subtitle: 'Muhim yangiliklarni qurilmada ko‘rsatish',
                value: state.notificationPreferences['push'] ?? true,
                onChanged: (value) =>
                    state.setNotificationPreference('push', value),
              ),
              _SwitchRow(
                icon: Icons.fact_check_outlined,
                title: 'Davomat o‘zgarishlari',
                subtitle: 'Kechikish, qatnashmaslik va sababli holatlar',
                value: state.notificationPreferences['att'] ?? true,
                onChanged: (value) =>
                    state.setNotificationPreference('att', value),
              ),
              _SwitchRow(
                icon: Icons.assignment_outlined,
                title: 'Vazifalar va muddatlar',
                subtitle: 'Yangi topshiriq va yaqinlashayotgan muddat',
                value: state.notificationPreferences['homework'] ?? true,
                onChanged: (value) =>
                    state.setNotificationPreference('homework', value),
              ),
              _SwitchRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Ustoz xabarlari',
                subtitle: 'Yangi suhbat va javoblar',
                value: state.notificationPreferences['messages'] ?? true,
                onChanged: (value) =>
                    state.setNotificationPreference('messages', value),
              ),
              _SwitchRow(
                icon: Icons.emoji_events_outlined,
                title: 'Natijalar va yutuqlar',
                subtitle: 'Yangi baho yoki e’tirof',
                value: state.notificationPreferences['card'] ?? true,
                onChanged: (value) =>
                    state.setNotificationPreference('card', value),
              ),
              if (role == FamilyRole.parent)
                _SwitchRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'To‘lovlar',
                  subtitle: 'To‘lov muddati va tasdiq holati',
                  value: state.notificationPreferences['pay'] ?? true,
                  onChanged: (value) =>
                      state.setNotificationPreference('pay', value),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader('Ko‘rinish va accessibility'),
          _GroupedRows(
            children: [
              _SwitchRow(
                icon: Icons.dark_mode_outlined,
                title: 'Qorong‘i rejim',
                subtitle: 'Kam yorug‘lik uchun sokin palitra',
                value: state.darkMode,
                onChanged: state.setDarkMode,
              ),
              _SwitchRow(
                icon: Icons.contrast_rounded,
                title: 'Yuqori kontrast',
                subtitle: 'Chegaralar va fokusni kuchaytiradi',
                value: state.highContrast,
                onChanged: state.setHighContrast,
              ),
              _SwitchRow(
                icon: Icons.text_increase_rounded,
                title: 'Katta matn',
                subtitle: 'Tizim masshtabiga qo‘shimcha 15%',
                value: state.largeText,
                onChanged: state.setLargeText,
              ),
              _SwitchRow(
                icon: Icons.motion_photos_off_outlined,
                title: 'Harakatni kamaytirish',
                subtitle: 'Keraksiz animatsiyalarni o‘chiradi',
                value: state.reduceMotion,
                onChanged: state.setReduceMotion,
              ),
              if (role == FamilyRole.parent)
                _SwitchRow(
                  icon: Icons.visibility_off_outlined,
                  title: 'Summalarni yashirish',
                  subtitle: 'To‘lov miqdorlari niqoblanadi',
                  value: state.hideAmounts,
                  onChanged: state.setHideAmounts,
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader('Demo ma’lumotlari'),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, state),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Boshlang‘ich holatni tiklash'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final value = await _textEntryDialog(
      context,
      title: 'Profil nomi',
      label: 'Ism va familiya',
      hint: 'Masalan: Akbarov Akmal',
      action: 'Saqlash',
      minLength: 3,
      initialValue: state.profileNames[role.name],
    );
    if (value != null && context.mounted) {
      state.setProfileName(role.name, value);
    }
  }

  Future<void> _confirmReset(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo holatini tiklash'),
        content: const Text(
          'Shaxsiy vazifalar, voqealar, murojaatlar va sozlamalar o‘chiriladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Holatni tiklash'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      state.resetDemoSession();
      onReset();
    }
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

Future<void> _showTaskDetail(
  BuildContext context,
  _TaskView task,
  AppState state,
  FamilyRole role,
  ValueChanged<String?> onMessage,
  void Function(String, {String? detail}) announce,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${task.subject} · ${task.due} · ${task.minutes} daqiqa',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _SurfaceCard(
                child: Text(
                  task.description.isNotEmpty
                      ? task.description
                      : task.personal
                      ? 'Bu shaxsiy reja faqat ushbu qurilmada saqlanadi.'
                      : 'Ustoz ko‘rsatmasi berilmagan.',
                ),
              ),
              const SizedBox(height: 20),
              if (!task.personal)
                _SurfaceCard(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    'Server holati: ${_assignmentStatusLabel(task.serverStatus)}'
                    '${task.teacherName.isEmpty ? '' : '\nUstoz: ${task.teacherName}'}',
                  ),
                ),
              if (!task.personal) const SizedBox(height: 20),
              if (role == FamilyRole.student && task.personal)
                FilledButton.icon(
                  onPressed: () {
                    state.toggleTask(task.id);
                    Navigator.pop(sheetContext);
                    announce(
                      state.completedTasks.contains(task.id)
                          ? 'Vazifa bajarildi'
                          : 'Vazifa qayta ochildi',
                    );
                  },
                  icon: Icon(
                    state.completedTasks.contains(task.id)
                        ? Icons.undo_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    state.completedTasks.contains(task.id)
                        ? 'Qayta ochish'
                        : 'Bajarildi deb belgilash',
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () {
                  state.toggleLessonReminder(task.id);
                  Navigator.pop(sheetContext);
                  announce(
                    state.lessonReminders.contains(task.id)
                        ? 'Vazifa eslatmasi yoqildi'
                        : 'Vazifa eslatmasi o‘chirildi',
                  );
                },
                icon: Icon(
                  state.lessonReminders.contains(task.id)
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                ),
                label: Text(
                  state.lessonReminders.contains(task.id)
                      ? 'Eslatmani o‘chirish'
                      : 'Eslatma yoqish',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onMessage('${task.title} vazifasi bo‘yicha savolim bor.');
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Ustozga savol berish'),
              ),
              if (task.personal) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    state.removePersonalTask(task.id);
                    Navigator.pop(sheetContext);
                    announce('Shaxsiy vazifa o‘chirildi', detail: task.title);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Shaxsiy vazifani o‘chirish'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showGradeDetail(
  BuildContext context,
  FamilyGrade grade,
  ValueChanged<String?> onMessage,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              grade.assignmentTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${grade.percent}% · ${_shortDate(grade.gradedAt)} · ${grade.teacherName}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _SurfaceCard(
              child: Text(
                grade.feedback.isEmpty
                    ? 'Ustoz izoh qoldirmagan.'
                    : 'Ustoz izohi\n\n${grade.feedback}',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onMessage(
                  '${grade.assignmentTitle} (${grade.percent}%) natijasi bo‘yicha savolim bor.',
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ustozga savol berish'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showMaterialViewer(
  BuildContext context,
  FamilyMaterial material,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _DetailScaffold(
        title: material.title,
        subtitle:
            '${material.contentType}${material.detail.isEmpty ? '' : ' · ${material.detail}'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SurfaceCard(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Icon(
                    material.contentType.toLowerCase().contains('audio')
                        ? Icons.headphones_rounded
                        : Icons.description_rounded,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    material.contentType.toLowerCase().contains('audio')
                        ? 'Audio ma’lumoti'
                        : 'Material ma’lumoti',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mavzu: ${material.topic}\n'
              'Versiya: ${material.version}\n'
              'Holat: ${material.statusRaw}\n'
              'Yuklab olish: ${material.isDownloadable ? 'ruxsat berilgan' : 'ruxsat berilmagan'}\n\n'
              'Family server fayl URL manzilini tasdiqlagandan keyin material '
              'mazmuni shu oynada ochiladi.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showCalendarEvent(
  BuildContext context,
  _CalendarView event,
  AppState state,
  void Function(String, {String? detail}) announce,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${event.date.day} ${_monthName(event.date.month)} · ${event.subtitle}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (event.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SurfaceCard(child: Text('Izoh\n\n${event.notes}')),
            ],
            if (event.personal) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  state.removePersonalEvent(event.id);
                  Navigator.pop(sheetContext);
                  announce('Shaxsiy voqea o‘chirildi');
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Shaxsiy voqeani o‘chirish'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> _openAnnouncement(
  BuildContext context,
  AppState state,
  (String, String, String, String) item,
) {
  state.markAnnouncementRead(item.$1);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(item.$2),
      content: Text('${item.$4}\n\n${item.$3}'),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: '${item.$2}\n${item.$4}'),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(const SnackBar(content: Text('E’lon nusxalandi')));
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Nusxalash'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tushundim'),
        ),
      ],
    ),
  );
}

Future<void> _showRolePicker(
  BuildContext context,
  FamilyRole current,
  ValueChanged<FamilyRole> onRole,
) async {
  final state = AppScope.read(context);
  final result = await showModalBottomSheet<FamilyRole>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profilni almashtirish',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.family_restroom_rounded,
              title: state.profileNames['parent'] ?? 'Akbarova Dilnoza',
              subtitle: 'Ota-ona profili',
              trailing: current == FamilyRole.parent
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(sheetContext, FamilyRole.parent),
            ),
            _ActionRow(
              icon: Icons.school_outlined,
              title: state.profileNames['student'] ?? 'Akbarov Akmal',
              subtitle: 'O‘quvchi · 9-B',
              trailing: current == FamilyRole.student
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(sheetContext, FamilyRole.student),
            ),
          ],
        ),
      ),
    ),
  );
  if (result != null && context.mounted) onRole(result);
}

Future<void> _showNotifications(
  BuildContext context, {
  required FamilyRole role,
  required ValueChanged<AppNotice> onOpen,
}) {
  final state = AppScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _NotificationsPanel(
      state: state,
      role: role,
      onOpen: (notice) {
        Navigator.pop(sheetContext);
        Future<void>.delayed(Duration.zero, () => onOpen(notice));
      },
    ),
  );
}

class _NotificationsPanel extends StatefulWidget {
  final AppState state;
  final FamilyRole role;
  final ValueChanged<AppNotice> onOpen;

  const _NotificationsPanel({
    required this.state,
    required this.role,
    required this.onOpen,
  });

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  bool _unreadOnly = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final all = widget.state.noticesForRole(widget.role.name);
        final visible = _unreadOnly
            ? all
                  .where(
                    (notice) => !widget.state.isNoticeReadForRole(
                      notice,
                      widget.role.name,
                    ),
                  )
                  .toList()
            : all;
        final unread = widget.state.unreadNoticeCountForRole(widget.role.name);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bildirishnomalar',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              unread == 0
                                  ? 'Yangi xabar yo‘q'
                                  : '$unread ta o‘qilmagan',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: unread == 0
                            ? null
                            : () => widget.state.markAllNoticesReadForRole(
                                widget.role.name,
                              ),
                        child: const Text('Barchasini o‘qish'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.mark_email_unread_outlined),
                        label: Text('Yangi'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.history_rounded),
                        label: Text('Tarix'),
                      ),
                    ],
                    selected: {_unreadOnly},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _unreadOnly = value.first),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: visible.isEmpty
                      ? _NotificationEmpty(
                          unreadOnly: _unreadOnly,
                          onHistory: () => setState(() => _unreadOnly = false),
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            final notice = visible[index];
                            return ListTile(
                              key: ValueKey('notice-${notice.id}'),
                              minTileHeight: 82,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              leading: _NoticeIcon(notice: notice),
                              title: Row(
                                children: [
                                  if (!widget.state.isNoticeReadForRole(
                                    notice,
                                    widget.role.name,
                                  )) ...[
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                  ],
                                  Expanded(child: Text(notice.title)),
                                ],
                              ),
                              subtitle: Text(
                                '${notice.body}\n${notice.time} · ${notice.destination.label}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                              ),
                              onTap: () => widget.onOpen(notice),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoticeIcon extends StatelessWidget {
  final AppNotice notice;

  const _NoticeIcon({required this.notice});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (notice.type) {
      NoticeType.success => (
        Icons.check_circle_outline_rounded,
        colors.primary,
      ),
      NoticeType.warning => (Icons.warning_amber_rounded, colors.error),
      NoticeType.message => (
        Icons.chat_bubble_outline_rounded,
        colors.tertiary,
      ),
      NoticeType.info => (Icons.notifications_outlined, colors.secondary),
    };
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  final bool unreadOnly;
  final VoidCallback onHistory;

  const _NotificationEmpty({required this.unreadOnly, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.done_all_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              unreadOnly
                  ? 'Barcha yangi xabarlar o‘qildi'
                  : 'Bildirishnomalar hali yo‘q',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (unreadOnly) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Tarixni ochish'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showGlobalSearch(
  BuildContext context,
  FamilyRole role, {
  required VoidCallback onStudy,
  required VoidCallback onGrades,
  required VoidCallback onCalendar,
  required VoidCallback onMessages,
  required ValueChanged<FeatureRoute> onFeature,
}) async {
  final controller = TextEditingController();
  final actions = <(String, String, IconData, VoidCallback)>[
    (
      'Vazifalar',
      'Topshiriq va shaxsiy reja',
      Icons.assignment_outlined,
      onStudy,
    ),
    ('Baholar', 'Natijalar va ustoz izohlari', Icons.school_outlined, onGrades),
    (
      'Jadval',
      'Darslar va voqealar',
      Icons.calendar_month_outlined,
      onCalendar,
    ),
    (
      'Xabarlar',
      'Ustozlar bilan suhbat',
      Icons.chat_bubble_outline_rounded,
      onMessages,
    ),
    (
      'Davomat',
      'Davomat tarixi va sabablar',
      Icons.fact_check_outlined,
      () => onFeature(FeatureRoute.attendance),
    ),
    (
      'E’lonlar',
      'Maktab yangiliklari',
      Icons.campaign_outlined,
      () => onFeature(FeatureRoute.announcements),
    ),
    if (role == FamilyRole.parent)
      (
        'To‘lovlar',
        'Tarix va demo to‘lov',
        Icons.account_balance_wallet_outlined,
        () => onFeature(FeatureRoute.payments),
      )
    else
      (
        'AI repetitor',
        'Savol va tushuntirish',
        Icons.auto_awesome_outlined,
        () => onFeature(FeatureRoute.aiTutor),
      ),
  ];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final query = controller.text.trim().toLowerCase();
        final visible = actions
            .where(
              (item) => '${item.$1} ${item.$2}'.toLowerCase().contains(query),
            )
            .toList();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ilova bo‘ylab izlash',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Izlash',
                      hintText: 'Bo‘lim yoki amal',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: visible.isEmpty
                        ? const _EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Natija topilmadi',
                            message: 'Boshqa so‘z bilan urinib ko‘ring.',
                          )
                        : ListView(
                            children: [
                              for (final item in visible)
                                _ActionRow(
                                  icon: item.$3,
                                  title: item.$1,
                                  subtitle: item.$2,
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    item.$4();
                                  },
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<String?> _textEntryDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String action,
  required int minLength,
  String? initialValue,
  bool multiline = false,
}) async {
  final controller = TextEditingController(text: initialValue);
  final key = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 6 : 1,
            decoration: InputDecoration(labelText: label, hintText: hint),
            validator: (value) => (value?.trim().length ?? 0) < minLength
                ? 'Kamida $minLength ta belgi kiriting'
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () {
            if (!key.currentState!.validate()) return;
            Navigator.pop(dialogContext, controller.text.trim());
          },
          child: Text(action),
        ),
      ],
    ),
  );
  return result;
}

Future<void> _showAttendanceRecord(
  BuildContext context,
  FamilyAttendanceRecord item,
) {
  return _showSimpleDetail(
    context,
    '${item.lessonTitle} · ${_shortDate(item.startsAt)}',
    'Holat: ${_attendanceStatusLabel(item.statusRaw)}'
        '${item.arrivedAt == null ? '' : '\nKelgan vaqt: ${_clockTime(item.arrivedAt!)}'}'
        '\n\nServer status kodi: ${item.statusRaw}.',
  );
}

Future<void> _showSimpleDetail(
  BuildContext context,
  String title,
  String body,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Yopish'),
        ),
      ],
    ),
  );
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0])
    .join()
    .toUpperCase();

String _messageTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _messageStatusLabel(FamilyMessageStatus value) => switch (value) {
  FamilyMessageStatus.delivered => 'Serverdan',
  FamilyMessageStatus.localOnly => 'Lokal',
  FamilyMessageStatus.sending => 'Saqlanmoqda',
  FamilyMessageStatus.failed => 'Xato',
};

String _clockTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _shortDate(DateTime value) => '${value.day} ${_monthName(value.month)}';

String _deadlineLabel(DateTime value) {
  final today = DateUtils.dateOnly(SfClock.now());
  final date = DateUtils.dateOnly(value);
  final day = date.difference(today).inDays;
  final prefix = switch (day) {
    0 => 'Bugun',
    1 => 'Ertaga',
    -1 => 'Kecha',
    _ => _shortDate(value),
  };
  return '$prefix · ${_clockTime(value)}';
}

String _assignmentStatusLabel(String raw) => switch (raw.toLowerCase()) {
  'assigned' || 'published' => 'Topshirilmagan',
  'submitted' => 'Topshirilgan',
  'graded' => 'Baholangan',
  'returned' => 'Qaytarilgan',
  'closed' => 'Yopilgan',
  final value => value.isEmpty ? 'Noma’lum' : value,
};

String _attendanceStatusLabel(String raw) => switch (raw.toLowerCase()) {
  'present' => 'Ishtirok etdi',
  'absent' => 'Qatnashmadi',
  'late' => 'Kechikdi',
  'excused' => 'Sababli',
  final value => value.isEmpty ? 'Noma’lum' : value,
};

String _friendlyDate(DateTime value) =>
    '${_weekday(value.weekday)} · ${value.day} ${_monthName(value.month)}';

String _weekday(int value) => const [
  'Dushanba',
  'Seshanba',
  'Chorshanba',
  'Payshanba',
  'Juma',
  'Shanba',
  'Yakshanba',
][value - 1];

String _weekdayShort(int value) =>
    const ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][value - 1];

String _monthName(int value) => const [
  'Yanvar',
  'Fevral',
  'Mart',
  'Aprel',
  'May',
  'Iyun',
  'Iyul',
  'Avgust',
  'Sentabr',
  'Oktabr',
  'Noyabr',
  'Dekabr',
][value - 1];
