part of 'portal_app.dart';

/// Cross-page routing and paged API helpers for the family communication area.
///
/// Keeping these helpers in the portal library lets chat and notification pages
/// use the authenticated API client without duplicating session/auth handling.
final class _PortalCommunicationRouter {
  _PortalCommunicationRouter._();

  static final ValueNotifier<int?> pendingThreadId = ValueNotifier<int?>(null);

  static void capture(Map<String, dynamic> payload) {
    final raw =
        payload['thread_id'] ??
        (payload['data'] is Map ? (payload['data'] as Map)['thread_id'] : null);
    final parsed = valueInt(raw);
    if (parsed != null) pendingThreadId.value = parsed;
  }

  static int? takeThread() {
    final value = pendingThreadId.value;
    pendingThreadId.value = null;
    return value;
  }
}

final class _MessageHistoryState {
  _MessageHistoryState({required this.oldestPage, required this.pages});

  int oldestPage;
  final int pages;
  bool busy = false;

  bool get hasOlder => oldestPage > 1;
}

final Expando<Map<int, _MessageHistoryState>> _messageHistory =
    Expando<Map<int, _MessageHistoryState>>('portal-message-history');

String _communicationsText(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (PortalScope.of(context).preferences.language) {
  PortalLanguage.uz => uz,
  PortalLanguage.ru => ru,
  PortalLanguage.en => en,
};

String _communicationsErrorText(BuildContext context, Object error) =>
    _communicationsErrorTextFor(
      PortalScope.of(context).preferences.language,
      error,
    );

String _communicationsErrorTextFor(PortalLanguage language, Object error) =>
    error is ApiException
    ? error.message
    : switch (language) {
        PortalLanguage.uz => 'Amal bajarilmadi.',
        PortalLanguage.ru => 'Не удалось выполнить действие.',
        PortalLanguage.en => 'The action could not be completed.',
      };

extension _PortalCommunicationApi on PortalController {
  Map<int, _MessageHistoryState> get _historyStates =>
      _messageHistory[this] ??= <int, _MessageHistoryState>{};

  Future<List<Map<String, Object?>>> searchMessagingContacts({
    String search = '',
    String category = '',
    int page = 1,
  }) async {
    final result = await getApi(
      '/api/v1/messaging/contacts/',
      query: {
        'page': page,
        'page_size': 100,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (category.isNotEmpty) 'category': category,
      },
    );
    if (page == 1 && search.trim().isEmpty && category.isEmpty) {
      contacts = result.rows;
      messagingSelfUserId = valueInt(result.pagination['self_user_id']);
      notifyDataChanged();
    }
    return result.rows;
  }

  Future<Map<String, Object?>> fetchThreadDetail(int threadId) async {
    final row = (await getApi('/api/v1/messaging/threads/$threadId/')).object;
    if (row.isNotEmpty) {
      threads = [
        for (final thread in threads)
          if (valueInt(thread['id']) == threadId) row else thread,
      ];
      if (!threads.any((thread) => valueInt(thread['id']) == threadId)) {
        threads = [row, ...threads];
      }
      notifyDataChanged();
    }
    return row;
  }

  /// Loads the newest message page. The backend orders messages oldest-first,
  /// so page 1 is not necessarily the latest page for long conversations.
  Future<void> ensureLatestMessagePage(int threadId) async {
    final first = await getApi(
      '/api/v1/messaging/threads/$threadId/messages/',
      query: const {'page': 1, 'page_size': 100},
    );
    final pages = valueInt(first.pagination['pages']) ?? 1;
    final latest = pages > 1
        ? await getApi(
            '/api/v1/messaging/threads/$threadId/messages/',
            query: {'page': pages, 'page_size': 100},
          )
        : first;
    final previousState = _historyStates[threadId];
    messages[threadId] = _mergeMessages(
      previousState == null ? const [] : messages[threadId] ?? const [],
      latest.rows,
    );
    _historyStates[threadId] = _MessageHistoryState(
      oldestPage: previousState?.oldestPage ?? pages,
      pages: pages,
    );
    notifyDataChanged();
  }

  bool hasOlderMessages(int threadId) =>
      _historyStates[threadId]?.hasOlder ?? false;

  bool loadingOlderMessages(int threadId) =>
      _historyStates[threadId]?.busy ?? false;

  Future<bool> loadOlderMessages(int threadId) async {
    final state = _historyStates[threadId];
    if (state == null || !state.hasOlder || state.busy) return false;
    state.busy = true;
    notifyDataChanged();
    try {
      final page = state.oldestPage - 1;
      final result = await getApi(
        '/api/v1/messaging/threads/$threadId/messages/',
        query: {'page': page, 'page_size': 100},
      );
      messages[threadId] = _mergeMessages(
        result.rows,
        messages[threadId] ?? const [],
      );
      state.oldestPage = page;
      return true;
    } finally {
      state.busy = false;
      notifyDataChanged();
    }
  }

  Future<({List<Map<String, Object?>> rows, String? next})>
  fetchNotificationPage({String? nextUrl, String eventType = ''}) async {
    var path = '/api/v1/notifications/';
    final query = <String, Object?>{};
    if (nextUrl != null && nextUrl.isNotEmpty) {
      final uri = Uri.parse(nextUrl);
      path = uri.path;
      query.addAll(uri.queryParameters);
    } else if (eventType.isNotEmpty) {
      query['event_type'] = eventType;
    }
    final result = await getApi(path, query: query);
    final envelope = result.object;
    return (
      rows: result.rows,
      next: valueText(envelope, const ['next'], fallback: '').trim().isEmpty
          ? null
          : valueText(envelope, const ['next']),
    );
  }
}

List<Map<String, Object?>> _mergeMessages(
  List<Map<String, Object?>> first,
  List<Map<String, Object?>> second,
) {
  final byId = <String, Map<String, Object?>>{};
  for (final row in [...first, ...second]) {
    byId['${row['id'] ?? '${row['sender']}:${row['created_at']}'}'] = row;
  }
  final rows = byId.values.toList()
    ..sort((a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'));
  return rows;
}

PortalSection? _completeNotificationDestination(
  Map<String, Object?> notification,
  PortalController portal,
) {
  final payload = <String, dynamic>{
    for (final entry in notification.entries) entry.key: entry.value,
  };
  final nested = notification['data'] ?? notification['payload'];
  if (nested is Map) {
    for (final entry in nested.entries) {
      payload['${entry.key}'] = entry.value;
    }
  }
  _PortalCommunicationRouter.capture(payload);
  final event = valueText(notification, const [
    'event_type',
    'type',
  ], fallback: '').toLowerCase();
  final route = notificationRouteFromPayload(payload);
  if ((route == 'messages' || event == 'message.received') &&
      portal.can('messaging:read')) {
    return PortalSection.messages;
  }
  if ((route == 'assignments' || event.startsWith('assignments.')) &&
      portal.can('assignments:read')) {
    return PortalSection.assignments;
  }
  if ((route == 'schedule' ||
          route == 'calendar' ||
          event.startsWith('schedule.') ||
          event == 'cohorts.announcement') &&
      portal.can('schedule:read')) {
    return PortalSection.schedule;
  }
  if ((route == 'attendance' || event.startsWith('attendance.')) &&
      portal.can('attendance:read')) {
    return PortalSection.attendance;
  }
  if ((route == 'academics' ||
          route == 'grades' ||
          route == 'exams' ||
          event.startsWith('academics.')) &&
      portal.can('academics:read')) {
    return PortalSection.academics;
  }
  if ((route == 'content' ||
          route == 'courses' ||
          route == 'materials' ||
          event == 'report.ready') &&
      portal.can('content:read')) {
    return PortalSection.content;
  }
  if ((route == 'forms') && portal.can('forms:read')) {
    return PortalSection.forms;
  }
  if ((route == 'achievements' || event.contains('achievement')) &&
      portal.can('achievements:read')) {
    return PortalSection.achievements;
  }
  if ((route == 'discipline' ||
          route == 'rules' ||
          route == 'penalties' ||
          event.startsWith('penalty.')) &&
      portal.can('penalty:read')) {
    return PortalSection.discipline;
  }
  if ((route == 'finance' ||
          route == 'payments' ||
          event.startsWith('finance.') ||
          event.startsWith('payments.') ||
          event.startsWith('billing.')) &&
      portal.can('finance:read_own')) {
    return PortalSection.finance;
  }
  if (route == 'cards' || route == 'wallet') {
    return portal.can('card:read') ? PortalSection.cards : null;
  }
  if (route == 'account' || event.startsWith('auth.')) {
    return PortalSection.account;
  }
  if (route == 'students' ||
      route == 'parents' ||
      route == 'identity' ||
      event.startsWith('students.')) {
    return PortalSection.identity;
  }
  return null;
}

String _notificationEventLabel(BuildContext context, String event) {
  final language = PortalScope.of(context).preferences.language;
  return switch ((event, language)) {
    ('attendance.absent', PortalLanguage.uz) => 'Davomat · kelmadi',
    ('attendance.absent', PortalLanguage.ru) => 'Посещаемость · отсутствовал',
    ('attendance.absent', PortalLanguage.en) => 'Attendance · absent',
    ('attendance.late', PortalLanguage.uz) => 'Davomat · kechikdi',
    ('attendance.late', PortalLanguage.ru) => 'Посещаемость · опоздал',
    ('attendance.late', PortalLanguage.en) => 'Attendance · late',
    ('academics.grades_published', PortalLanguage.uz) => 'Yangi baholar',
    ('academics.grades_published', PortalLanguage.ru) => 'Новые оценки',
    ('academics.grades_published', PortalLanguage.en) => 'New grades',
    ('assignments.created', PortalLanguage.uz) => 'Yangi vazifa',
    ('assignments.created', PortalLanguage.ru) => 'Новое задание',
    ('assignments.created', PortalLanguage.en) => 'New assignment',
    ('assignments.due_soon', PortalLanguage.uz) => 'Vazifa muddati',
    ('assignments.due_soon', PortalLanguage.ru) => 'Срок задания',
    ('assignments.due_soon', PortalLanguage.en) => 'Assignment deadline',
    ('assignments.graded', PortalLanguage.uz) => 'Vazifa baholandi',
    ('assignments.graded', PortalLanguage.ru) => 'Задание оценено',
    ('assignments.graded', PortalLanguage.en) => 'Assignment graded',
    ('schedule.lesson_reminder', PortalLanguage.uz) => 'Dars eslatmasi',
    ('schedule.lesson_reminder', PortalLanguage.ru) => 'Напоминание об уроке',
    ('schedule.lesson_reminder', PortalLanguage.en) => 'Lesson reminder',
    ('auth.new_device_login', PortalLanguage.uz) => 'Yangi qurilma',
    ('auth.new_device_login', PortalLanguage.ru) => 'Новое устройство',
    ('auth.new_device_login', PortalLanguage.en) => 'New device',
    ('students.enrollment_changed', PortalLanguage.uz) => 'Ta’lim holati',
    ('students.enrollment_changed', PortalLanguage.ru) => 'Статус обучения',
    ('students.enrollment_changed', PortalLanguage.en) => 'Enrollment status',
    ('finance.invoice_issued', PortalLanguage.uz) => 'Yangi hisob',
    ('finance.invoice_issued', PortalLanguage.ru) => 'Новый счёт',
    ('finance.invoice_issued', PortalLanguage.en) => 'New invoice',
    ('finance.payment_reminder', PortalLanguage.uz) => 'To‘lov eslatmasi',
    ('finance.payment_reminder', PortalLanguage.ru) => 'Напоминание об оплате',
    ('finance.payment_reminder', PortalLanguage.en) => 'Payment reminder',
    ('payments.payment_completed', PortalLanguage.uz) => 'To‘lov qabul qilindi',
    ('payments.payment_completed', PortalLanguage.ru) => 'Платёж принят',
    ('payments.payment_completed', PortalLanguage.en) => 'Payment received',
    ('payments.payment_failed', PortalLanguage.uz) => 'To‘lov amalga oshmadi',
    ('payments.payment_failed', PortalLanguage.ru) => 'Платёж не прошёл',
    ('payments.payment_failed', PortalLanguage.en) => 'Payment failed',
    ('cohorts.announcement', PortalLanguage.uz) => 'Guruh e’loni',
    ('cohorts.announcement', PortalLanguage.ru) => 'Объявление группы',
    ('cohorts.announcement', PortalLanguage.en) => 'Group announcement',
    ('penalty.escalated', PortalLanguage.uz) => 'Intizomiy ogohlantirish',
    ('penalty.escalated', PortalLanguage.ru) => 'Дисциплинарное предупреждение',
    ('penalty.escalated', PortalLanguage.en) => 'Disciplinary warning',
    ('message.received', PortalLanguage.uz) => 'Yangi xabar',
    ('message.received', PortalLanguage.ru) => 'Новое сообщение',
    ('message.received', PortalLanguage.en) => 'New message',
    ('report.ready', PortalLanguage.uz) => 'Hisobot tayyor',
    ('report.ready', PortalLanguage.ru) => 'Отчёт готов',
    ('report.ready', PortalLanguage.en) => 'Report ready',
    (_, PortalLanguage.uz) => event.isEmpty ? 'Noma’lum' : event,
    (_, PortalLanguage.ru) => event.isEmpty ? 'Неизвестно' : event,
    (_, PortalLanguage.en) => event.isEmpty ? 'Unknown' : event,
  };
}

class _ChatDirectoryNotice extends StatelessWidget {
  const _ChatDirectoryNotice({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final failed = error != null;
    final title = failed
        ? _communicationsText(
            context,
            uz: 'Maktab kontaktlari yuklanmadi',
            ru: 'Не удалось загрузить контакты школы',
            en: 'School contacts could not be loaded',
          )
        : _communicationsText(
            context,
            uz: 'Maktab kontaktlari hali mavjud emas',
            ru: 'Контакты школы пока недоступны',
            en: 'School contacts are not available yet',
          );
    return Material(
      key: const ValueKey('chat-directory-notice'),
      color: (failed ? colors.errorContainer : colors.secondaryContainer)
          .withValues(alpha: 0.64),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                failed ? Icons.cloud_off_rounded : Icons.contact_page_outlined,
                color: failed ? colors.error : colors.secondary,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    failed
                        ? error!
                        : _communicationsText(
                            context,
                            uz: 'O‘qituvchi yoki xodim markaz tomonidan faollashtirilgach yangi suhbat boshlash mumkin.',
                            ru: 'Новый диалог можно будет начать после того, как центр активирует учителя или сотрудника.',
                            en: 'You can start a new conversation after the center activates a teacher or staff member.',
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: _communicationsText(
                context,
                uz: 'Qayta tekshirish',
                ru: 'Проверить снова',
                en: 'Check again',
              ),
              onPressed: loading ? null : onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedNotificationsPortalPage extends StatefulWidget {
  const _EnhancedNotificationsPortalPage();

  @override
  State<_EnhancedNotificationsPortalPage> createState() =>
      _EnhancedNotificationsPortalPageState();
}

class _EnhancedNotificationsPortalPageState
    extends State<_EnhancedNotificationsPortalPage> {
  List<Map<String, Object?>> _rows = const [];
  String _readFilter = 'all';
  String _eventFilter = '';
  String? _next;
  String? _error;
  bool _loading = false;
  bool _loadingMore = false;
  Timer? _pollTimer;
  final Set<int> _autoMarkedIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rows = [...PortalScope.read(context).notifications];
      unawaited(_reload());
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_loading && !_loadingMore) {
          unawaited(_reload(quiet: true));
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload({bool quiet = false}) async {
    if (_loading) return;
    if (!quiet) setState(() => _loading = true);
    try {
      final page = await PortalScope.read(
        context,
      ).fetchNotificationPage(eventType: _eventFilter);
      if (!mounted) return;
      setState(() {
        _rows = page.rows;
        _next = page.next;
        _error = null;
      });
      final portal = PortalScope.read(context);
      portal.notifications = page.rows;
      portal.unreadNotificationCount = page.rows
          .where((row) => row['read_at'] == null)
          .length;
      portal.notifyDataChanged();
      unawaited(_markVisibleNotificationsRead(portal));
    } on Object catch (error) {
      if (mounted && !quiet) {
        setState(() => _error = _communicationsErrorText(context, error));
      }
    } finally {
      if (mounted && !quiet) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final next = _next;
    if (next == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await PortalScope.read(
        context,
      ).fetchNotificationPage(nextUrl: next);
      if (!mounted) return;
      final byId = <String, Map<String, Object?>>{
        for (final row in [..._rows, ...page.rows]) '${row['id']}': row,
      };
      setState(() {
        _rows = byId.values.toList();
        _next = page.next;
        _error = null;
      });
      unawaited(_markVisibleNotificationsRead(PortalScope.read(context)));
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _communicationsErrorText(context, error));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markVisibleNotificationsRead(PortalController portal) async {
    if (!mounted) return;
    final unreadRows = _rows
        .where((row) => row['read_at'] == null)
        .toList(growable: false);
    if (unreadRows.isEmpty) return;
    final newIds = unreadRows
        .map((row) => valueInt(row['id']))
        .whereType<int>()
        .where((id) => !_autoMarkedIds.contains(id))
        .toSet();
    final readAt = DateTime.now().toUtc().toIso8601String();
    setState(() {
      _rows = [
        for (final row in _rows)
          if (row['read_at'] == null) {...row, 'read_at': readAt} else row,
      ];
    });
    portal.notifications = [
      for (final row in portal.notifications)
        if (row['read_at'] == null) {...row, 'read_at': readAt} else row,
    ];
    portal.unreadNotificationCount = 0;
    portal.notifyDataChanged();
    if (newIds.isEmpty) return;
    _autoMarkedIds.addAll(newIds);
    try {
      await portal.markAllNotificationsRead(refreshAfter: false);
    } on Object catch (error) {
      _autoMarkedIds.removeAll(newIds);
      if (mounted) {
        setState(() => _error = _communicationsErrorText(context, error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final filtered = _rows.where((row) {
      final unread = row['read_at'] == null;
      if (_readFilter == 'unread' && !unread) return false;
      if (_readFilter == 'read' && unread) return false;
      return true;
    }).toList();
    final eventTypes =
        _rows
            .map((row) => valueText(row, const ['event_type']))
            .where((event) => event.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in filtered) {
      groups
          .putIfAbsent(_notificationDay(context, row['created_at']), () => [])
          .add(row);
    }

    return _PortalPage(
      title: portal.isParent
          ? _communicationsText(
              context,
              uz: 'Muhim xabarlar',
              ru: 'Важные сообщения',
              en: 'Important updates',
            )
          : _communicationsText(
              context,
              uz: 'Bildirishnomalar',
              ru: 'Уведомления',
              en: 'Notifications',
            ),
      subtitle: _communicationsText(
        context,
        uz: 'Maktab voqealari, xabarlar va xavfsizlik yangiliklari.',
        ru: 'События школы, сообщения и обновления безопасности.',
        en: 'School events, messages, and security updates.',
      ),
      section: PortalSection.notifications,
      trailing: IconButton.outlined(
        tooltip: _communicationsText(
          context,
          uz: 'Yangilash',
          ru: 'Обновить',
          en: 'Refresh',
        ),
        onPressed: _loading ? null : _reload,
        icon: _loading
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            key: const ValueKey('notification-filter-panel'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final filters = Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final entry in {
                        'all': _communicationsText(
                          context,
                          uz: 'Barchasi',
                          ru: 'Все',
                          en: 'All',
                        ),
                        'unread': _communicationsText(
                          context,
                          uz: 'Yangi',
                          ru: 'Новые',
                          en: 'New',
                        ),
                        'read': _communicationsText(
                          context,
                          uz: 'O‘qilgan',
                          ru: 'Прочитанные',
                          en: 'Read',
                        ),
                      }.entries)
                        FilterChip(
                          selected: _readFilter == entry.key,
                          label: Text(entry.value),
                          onSelected: (_) =>
                              setState(() => _readFilter = entry.key),
                        ),
                    ],
                  );
                  final typePicker = DropdownButton<String>(
                    value: eventTypes.contains(_eventFilter)
                        ? _eventFilter
                        : '',
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(
                          _communicationsText(
                            context,
                            uz: 'Barcha turlar',
                            ru: 'Все типы',
                            en: 'All types',
                          ),
                        ),
                      ),
                      for (final event in eventTypes)
                        DropdownMenuItem(
                          value: event,
                          child: Text(_notificationEventLabel(context, event)),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _eventFilter = value ?? '');
                      unawaited(_reload());
                    },
                  );
                  if (constraints.maxWidth < 620) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filters,
                        const SizedBox(height: 8),
                        typePicker,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: filters),
                      typePicker,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _CommunicationsSectionError(message: _error!, onRetry: _reload),
        ],
        const SizedBox(height: 14),
        if (!_loading && filtered.isEmpty)
          _EmptyState(
            icon: Icons.notifications_none_rounded,
            title: _rows.isEmpty
                ? _communicationsText(
                    context,
                    uz: 'Bildirishnoma yo‘q',
                    ru: 'Уведомлений нет',
                    en: 'No notifications',
                  )
                : _communicationsText(
                    context,
                    uz: 'Filtr bo‘yicha xabar yo‘q',
                    ru: 'По этому фильтру ничего нет',
                    en: 'No notifications match this filter',
                  ),
            message: _rows.isEmpty
                ? _communicationsText(
                    context,
                    uz: 'Yangi maktab voqealari shu yerda paydo bo‘ladi.',
                    ru: 'Новые события школы появятся здесь.',
                    en: 'New school events will appear here.',
                  )
                : _communicationsText(
                    context,
                    uz: 'Boshqa filtrni tanlang.',
                    ru: 'Выберите другой фильтр.',
                    en: 'Choose another filter.',
                  ),
          )
        else
          for (final group in groups.entries) ...[
            _PageSectionTitle(title: group.key),
            const SizedBox(height: 8),
            _NotificationDayCard(
              rows: group.value,
              onOpen: (row) => _openNotification(row, portal),
            ),
            const SizedBox(height: 14),
          ],
        if (_next != null)
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadingMore ? null : _loadMore,
              icon: _loadingMore
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(
                _communicationsText(
                  context,
                  uz: 'Oldingi bildirishnomalarni yuklash',
                  ru: 'Загрузить предыдущие уведомления',
                  en: 'Load earlier notifications',
                ),
              ),
            ),
          ),
        if (portal.notificationPreferences.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PageSectionTitle(
            title: _communicationsText(
              context,
              uz: 'Bildirishnoma sozlamalari',
              ru: 'Настройки уведомлений',
              en: 'Notification settings',
            ),
          ),
          const SizedBox(height: 8),
          _CommunicationsNotificationPreferences(
            rows: portal.notificationPreferences,
          ),
        ],
      ],
    );
  }

  Future<void> _openNotification(
    Map<String, Object?> row,
    PortalController portal,
  ) async {
    final id = valueInt(row['id']);
    if (id != null && row['read_at'] == null) {
      setState(() {
        _rows = [
          for (final item in _rows)
            if (valueInt(item['id']) == id)
              {...item, 'read_at': DateTime.now().toIso8601String()}
            else
              item,
        ];
      });
      try {
        await portal.markNotificationRead(id);
      } on Object {
        if (mounted) await _reload();
      }
    }
    if (!mounted) return;
    final destination = _completeNotificationDestination(row, portal);
    if (destination != null) {
      _PortalNavigationScope.go(context, destination);
      return;
    }
    _showJsonDetail(
      context,
      title: valueText(
        row,
        const ['title'],
        fallback: _communicationsText(
          context,
          uz: 'Bildirishnoma',
          ru: 'Уведомление',
          en: 'Notification',
        ),
      ),
      fields: {
        _communicationsText(
          context,
          uz: 'Xabar',
          ru: 'Сообщение',
          en: 'Message',
        ): valueText(row, const [
          'body',
        ]),
        _communicationsText(
          context,
          uz: 'Turi',
          ru: 'Тип',
          en: 'Type',
        ): _notificationEventLabel(
          context,
          valueText(row, const ['event_type']),
        ),
        _communicationsText(context, uz: 'Vaqt', ru: 'Время', en: 'Time'):
            _dateLabel(row['created_at'], time: true),
      },
    );
  }
}

String _notificationDay(BuildContext context, Object? raw) {
  final value = DateTime.tryParse('$raw')?.toLocal();
  if (value == null) {
    return _communicationsText(
      context,
      uz: 'Avvalgi xabarlar',
      ru: 'Предыдущие сообщения',
      en: 'Earlier notifications',
    );
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  final delta = today.difference(day).inDays;
  if (delta == 0) {
    return _communicationsText(
      context,
      uz: 'Bugun',
      ru: 'Сегодня',
      en: 'Today',
    );
  }
  if (delta == 1) {
    return _communicationsText(
      context,
      uz: 'Kecha',
      ru: 'Вчера',
      en: 'Yesterday',
    );
  }
  return _dateLabel(raw);
}

class _NotificationDayCard extends StatelessWidget {
  const _NotificationDayCard({required this.rows, required this.onOpen});

  final List<Map<String, Object?>> rows;
  final ValueChanged<Map<String, Object?>> onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _NotificationRow(row: rows[index], onTap: () => onOpen(rows[index])),
          if (index != rows.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.row, required this.onTap});

  final Map<String, Object?> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = row['read_at'] == null;
    final event = valueText(row, const ['event_type']);
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      tileColor: unread
          ? colors.primaryContainer.withValues(alpha: 0.22)
          : null,
      leading: CircleAvatar(
        backgroundColor: unread
            ? colors.primary
            : colors.surfaceContainerHighest,
        foregroundColor: unread ? colors.onPrimary : colors.onSurfaceVariant,
        child: Icon(_notificationIcon(event), size: 20),
      ),
      title: Text(
        valueText(row, const [
          'title',
        ], fallback: _notificationEventLabel(context, event)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${valueText(row, const ['body'])}\n${_notificationEventLabel(context, event)} · ${_dateLabel(row['created_at'], time: true)}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: unread
          ? Badge(
              backgroundColor: colors.primary,
              child: const SizedBox.square(dimension: 8),
            )
          : const Icon(Icons.done_all_rounded, size: 19),
    );
  }
}

IconData _notificationIcon(String event) {
  if (event.startsWith('attendance.')) return Icons.fact_check_outlined;
  if (event.startsWith('assignments.')) return Icons.assignment_outlined;
  if (event.startsWith('academics.')) return Icons.school_outlined;
  if (event.startsWith('schedule.')) return Icons.event_outlined;
  if (event.startsWith('finance.') || event.startsWith('payments.')) {
    return Icons.account_balance_wallet_outlined;
  }
  if (event == 'message.received') return Icons.forum_outlined;
  if (event.startsWith('penalty.')) return Icons.gavel_outlined;
  if (event.startsWith('auth.')) return Icons.security_outlined;
  return Icons.notifications_outlined;
}

class _CommunicationsSectionError extends StatelessWidget {
  const _CommunicationsSectionError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
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
                _communicationsText(
                  context,
                  uz: 'Bo‘limni yuklab bo‘lmadi',
                  ru: 'Не удалось загрузить раздел',
                  en: 'The section could not be loaded',
                ),
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
                label: Text(
                  _communicationsText(
                    context,
                    uz: 'Qayta urinish',
                    ru: 'Повторить',
                    en: 'Try again',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CommunicationsNotificationPreferences extends StatefulWidget {
  const _CommunicationsNotificationPreferences({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  State<_CommunicationsNotificationPreferences> createState() =>
      _CommunicationsNotificationPreferencesState();
}

class _CommunicationsNotificationPreferencesState
    extends State<_CommunicationsNotificationPreferences> {
  late List<Map<String, Object?>> _rows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final row in widget.rows) {...row},
    ];
  }

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var index = 0; index < _rows.length; index++)
          SwitchListTile(
            value: _rows[index]['enabled'] == true,
            title: Text(
              _notificationEventLabel(context, '${_rows[index]['event_type']}'),
            ),
            subtitle: Text(switch ('${_rows[index]['channel']}'.toLowerCase()) {
              'push' || 'in_app' => _communicationsText(
                context,
                uz: 'Ilova ichida',
                ru: 'В приложении',
                en: 'In app',
              ),
              'email' => _communicationsText(
                context,
                uz: 'Elektron pochta',
                ru: 'Электронная почта',
                en: 'Email',
              ),
              'sms' => 'SMS',
              _ => _communicationsText(
                context,
                uz: 'Bildirishnoma kanali',
                ru: 'Канал уведомлений',
                en: 'Notification channel',
              ),
            }),
            onChanged: _busy
                ? null
                : (value) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final language = PortalScope.of(
                      context,
                    ).preferences.language;
                    setState(() {
                      _rows[index]['enabled'] = value;
                      _busy = true;
                    });
                    try {
                      await PortalScope.read(
                        context,
                      ).saveNotificationPreferences(_rows);
                    } on Object catch (error) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              _communicationsErrorTextFor(language, error),
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
          ),
      ],
    ),
  );
}
