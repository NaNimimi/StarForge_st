import 'package:flutter/material.dart';

import 'family_data.dart';
import 'family_messaging.dart';

abstract final class SfClock {
  static DateTime Function() now = DateTime.now;
}

/// Family application state with strict staff-shaped read projections.
///
/// A parent/student authentication endpoint is not present in the supplied
/// staff project, so device actions remain explicit local preview state. Server
/// payloads enter only through typed notification and family-resource
/// boundaries; the UI never signs into the staff-only API.
class AppState extends ChangeNotifier {
  AppState({
    AiTutorTransport? aiTransport,
    FamilySnapshot? familySnapshot,
    FamilyMessagingRepository? messagingRepository,
  }) : _aiTransport = aiTransport ?? const LocalStudyTutorTransport(),
       _familyData =
           familySnapshot ?? FamilySnapshot.localPreview(now: SfClock.now()),
       messaging = FamilyMessagingController(
         repository: messagingRepository,
         now: SfClock.now(),
       ) {
    messaging.addListener(_relayMessaging);
  }

  static const announcementIds = {
    'announcement-olympiad',
    'announcement-meeting',
    'announcement-library',
    'announcement-welcome',
  };

  final ValueNotifier<int> resetSignal = ValueNotifier<int>(0);
  FamilySnapshot _familyData;
  final FamilyMessagingController messaging;
  bool largeText = false;
  bool reduceMotion = false;
  bool hideAmounts = false;
  bool darkMode = false;
  bool highContrast = false;
  bool paymentCompleted = false;
  String? receiptNumber;
  String? paymentMethod;
  final Map<String, String> profileNames = {
    'parent': 'Akbarova Dilnoza',
    'student': 'Akbarov Akmal',
  };

  final Map<String, bool> notificationPreferences = {
    'push': true,
    'att': true,
    'card': true,
    'pay': true,
    'homework': true,
    'messages': true,
  };

  final Set<String> favoriteMaterials = {'material-601'};
  final Set<String> downloadedMaterials = <String>{};
  final Set<String> completedTasks = {'english-words'};
  final Set<String> lessonReminders = <String>{};
  final Set<String> sentParentReminders = <String>{};
  final Set<String> readAnnouncements = {'announcement-welcome'};
  final Set<String> pinnedAnnouncements = <String>{};
  final Set<String> calendarReminders = <String>{};

  final List<AppNotice> notices = _initialNotices();
  final Map<String, Set<String>> _readNoticeRoles = {};
  final AiTutorTransport _aiTransport;
  final List<AiChatMessage> aiMessages = <AiChatMessage>[];
  bool aiGenerating = false;
  String? aiError;
  String? lastAiPrompt;
  int _aiRequestGeneration = 0;

  final List<StudyTask> personalTasks = <StudyTask>[];
  final List<PersonalCalendarEvent> personalEvents = <PersonalCalendarEvent>[];
  final List<SupportTicket> supportTickets = <SupportTicket>[];
  final List<String> attendanceExplanations = <String>[];

  final List<StudyGoal> goals = _initialGoals();
  final Map<String, bool> toolkitToggles = <String, bool>{};
  final Map<String, String> toolkitValues = <String, String>{};
  final Map<String, int> toolkitCounters = <String, int>{};
  final List<ToolkitActivity> toolkitActivity = <ToolkitActivity>[];

  int get unreadNoticeCount => notices.where((notice) => !notice.isRead).length;
  List<AppNotice> noticesForRole(String role) => notices
      .where((notice) => notice.audience.allows(role))
      .toList(growable: false);
  int unreadNoticeCountForRole(String role) => notices
      .where(
        (notice) =>
            notice.audience.allows(role) && !isNoticeReadForRole(notice, role),
      )
      .length;
  int get unreadAnnouncementCount =>
      announcementIds.difference(readAnnouncements).length;
  String get aiConnectionLabel => _aiTransport.connectionLabel;
  bool get aiUsesLocalDemo => _aiTransport.isLocalDemo;
  FamilySnapshot get familyData => _familyData;
  bool get familyUsesLocalPreview => _familyData.isPreview;

  String messagingScopeForRole(String role) =>
      FamilyMessagingController.scopeKey(
        tenant: 'preview-center',
        userId: role == 'parent' ? 'parent-101' : 'student-101',
        role: role,
      );

  String messagingUserIdForRole(String role) =>
      role == 'parent' ? 'parent-101' : 'student-101';

  bool receiveFamilyResource(FamilyResource resource, Object? payload) {
    try {
      _familyData = _familyData.replaceResource(
        resource,
        payload,
        receivedAt: SfClock.now(),
      );
      notifyListeners();
      return true;
    } on FormatException {
      return false;
    }
  }

  void setFamilyLoadState(FamilyLoadState value, {String? errorMessage}) {
    _familyData = _familyData.copyWith(
      loadState: value,
      errorMessage: errorMessage,
      clearError: errorMessage == null,
    );
    notifyListeners();
  }

  void _relayMessaging() => notifyListeners();

  @override
  void dispose() {
    messaging.removeListener(_relayMessaging);
    messaging.dispose();
    resetSignal.dispose();
    super.dispose();
  }

  void setLargeText(bool value) {
    if (largeText == value) return;
    largeText = value;
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    if (reduceMotion == value) return;
    reduceMotion = value;
    notifyListeners();
  }

  void setHideAmounts(bool value) {
    if (hideAmounts == value) return;
    hideAmounts = value;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (darkMode == value) return;
    darkMode = value;
    notifyListeners();
  }

  void setHighContrast(bool value) {
    if (highContrast == value) return;
    highContrast = value;
    notifyListeners();
  }

  void setProfileName(String role, String value) {
    final normalized = value.trim();
    if (normalized.length < 3 || profileNames[role] == normalized) return;
    profileNames[role] = normalized;
    notifyListeners();
  }

  void setNotificationPreference(String key, bool value) {
    if (notificationPreferences[key] == value) return;
    notificationPreferences[key] = value;
    notifyListeners();
  }

  void markNoticeRead(String id) {
    final index = notices.indexWhere((notice) => notice.id == id);
    if (index < 0 || notices[index].isRead) return;
    notices[index] = notices[index].copyWith(isRead: true);
    notifyListeners();
  }

  bool isNoticeReadForRole(AppNotice notice, String role) {
    if (notice.isRead) return true;
    return _readNoticeRoles[notice.id]?.contains(role.toLowerCase()) ?? false;
  }

  void markNoticeReadForRole(String id, String role) {
    final index = notices.indexWhere((notice) => notice.id == id);
    if (index < 0) return;
    final notice = notices[index];
    if (notice.audience != NoticeAudience.all) {
      markNoticeRead(id);
      return;
    }
    final normalized = role.toLowerCase();
    final roles = _readNoticeRoles.putIfAbsent(id, () => {});
    if (roles.add(normalized)) notifyListeners();
  }

  void markAllNoticesRead() {
    var changed = false;
    for (var index = 0; index < notices.length; index++) {
      if (!notices[index].isRead) {
        notices[index] = notices[index].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void markAllNoticesReadForRole(String role) {
    var changed = false;
    for (var index = 0; index < notices.length; index++) {
      final notice = notices[index];
      if (notice.audience.allows(role) && !notice.isRead) {
        if (notice.audience == NoticeAudience.all) {
          changed =
              _readNoticeRoles
                  .putIfAbsent(notice.id, () => {})
                  .add(role.toLowerCase()) ||
              changed;
        } else {
          notices[index] = notice.copyWith(isRead: true);
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  void addNotice(AppNotice notice) {
    final index = notices.indexWhere((item) => item.id == notice.id);
    if (index >= 0) {
      final previous = notices[index];
      notices[index] = notice.copyWith(
        isRead: previous.isRead || notice.isRead,
        audience: notice.audience == NoticeAudience.unknown
            ? previous.audience
            : notice.audience,
      );
      if (index > 0) {
        final updated = notices[index];
        notices
          ..removeAt(index)
          ..insert(0, updated);
      }
    } else {
      notices.insert(0, notice);
    }
    notifyListeners();
  }

  /// Accepts the backend/push shape at one boundary and keeps malformed data
  /// out of the UI. Duplicate event ids update the existing row rather than
  /// inflating the unread badge.
  bool receiveNoticePayload(
    Map<String, dynamic> payload, {
    String? authenticatedRole,
  }) {
    try {
      final framePayload = payload['type'] == 'notification'
          ? payload['payload']
          : null;
      final normalized = framePayload is Map
          ? Map<String, dynamic>.from(framePayload)
          : Map<String, dynamic>.from(payload);
      if (authenticatedRole != null &&
          !normalized.containsKey('recipient_role') &&
          !normalized.containsKey('audience') &&
          !normalized.containsKey('role')) {
        normalized['recipient_role'] = authenticatedRole;
      }
      final notice = AppNotice.fromPayload(normalized);
      final duplicate = notices.any((item) => item.id == notice.id);
      if (!duplicate && notice.audience == NoticeAudience.unknown) return false;
      addNotice(notice);
      return true;
    } on FormatException {
      return false;
    }
  }

  Future<bool> askAi(String prompt) => _sendAi(prompt, addUserMessage: true);

  Future<bool> _sendAi(String prompt, {required bool addUserMessage}) async {
    final value = prompt.trim();
    if (value.length < 3 || aiGenerating) return false;

    final requestGeneration = ++_aiRequestGeneration;
    lastAiPrompt = value;
    aiError = null;
    aiGenerating = true;
    if (addUserMessage) {
      aiMessages.add(
        AiChatMessage(
          id: 'ai-user-${DateTime.now().microsecondsSinceEpoch}',
          text: value,
          role: AiMessageRole.user,
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();

    try {
      final raw = await _aiTransport.send(value);
      if (requestGeneration != _aiRequestGeneration) return false;
      final response = AiTutorResponse.fromPayload(raw);
      aiMessages.add(
        AiChatMessage(
          id: response.requestId,
          text: response.answer,
          role: AiMessageRole.assistant,
          createdAt: DateTime.now(),
          sources: response.sources,
          isLocalDemo: response.isLocalDemo || _aiTransport.isLocalDemo,
        ),
      );
      aiGenerating = false;
      notifyListeners();
      return true;
    } catch (_) {
      if (requestGeneration != _aiRequestGeneration) return false;
      aiGenerating = false;
      aiError =
          'Javob olinmadi. Ulanishni tekshiring yoki so‘rovni qayta yuboring.';
      notifyListeners();
      return false;
    }
  }

  void cancelAiRequest() {
    if (!aiGenerating) return;
    _aiRequestGeneration++;
    aiGenerating = false;
    aiError = null;
    notifyListeners();
  }

  Future<bool> retryLastAiPrompt() {
    final prompt = lastAiPrompt;
    if (prompt == null || aiGenerating) return Future<bool>.value(false);
    return _sendAi(prompt, addUserMessage: false);
  }

  void clearAiChat() {
    _aiRequestGeneration++;
    aiMessages.clear();
    aiGenerating = false;
    aiError = null;
    lastAiPrompt = null;
    notifyListeners();
  }

  void toggleFavoriteMaterial(String id) {
    favoriteMaterials.contains(id)
        ? favoriteMaterials.remove(id)
        : favoriteMaterials.add(id);
    notifyListeners();
  }

  void markMaterialDownloaded(String id) {
    if (downloadedMaterials.add(id)) notifyListeners();
  }

  void removeMaterialDownload(String id) {
    if (downloadedMaterials.remove(id)) notifyListeners();
  }

  void toggleTask(String id) {
    completedTasks.contains(id)
        ? completedTasks.remove(id)
        : completedTasks.add(id);
    notifyListeners();
  }

  void addPersonalTask(StudyTask task) {
    personalTasks.add(task);
    notifyListeners();
  }

  void removePersonalTask(String id) {
    personalTasks.removeWhere((task) => task.id == id);
    completedTasks.remove(id);
    notifyListeners();
  }

  void toggleLessonReminder(String id) {
    lessonReminders.contains(id)
        ? lessonReminders.remove(id)
        : lessonReminders.add(id);
    notifyListeners();
  }

  bool markParentReminderSent(String id) {
    final added = sentParentReminders.add(id);
    if (added) notifyListeners();
    return added;
  }

  void addAttendanceExplanation(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    attendanceExplanations.insert(0, normalized);
    notifyListeners();
  }

  void markAnnouncementRead(String id) {
    if (readAnnouncements.add(id)) notifyListeners();
  }

  void markAllAnnouncementsRead(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      changed = readAnnouncements.add(id) || changed;
    }
    if (changed) notifyListeners();
  }

  void togglePinnedAnnouncement(String id) {
    pinnedAnnouncements.contains(id)
        ? pinnedAnnouncements.remove(id)
        : pinnedAnnouncements.add(id);
    notifyListeners();
  }

  void addPersonalEvent(PersonalCalendarEvent event) {
    personalEvents.add(event);
    notifyListeners();
  }

  void removePersonalEvent(String id) {
    personalEvents.removeWhere((event) => event.id == id);
    calendarReminders.remove(id);
    notifyListeners();
  }

  void toggleCalendarReminder(String id) {
    calendarReminders.contains(id)
        ? calendarReminders.remove(id)
        : calendarReminders.add(id);
    notifyListeners();
  }

  void createSupportTicket(SupportTicket ticket) {
    supportTickets.insert(0, ticket);
    notifyListeners();
  }

  void completePayment(String method) {
    if (paymentCompleted) return;
    paymentCompleted = true;
    paymentMethod = method;
    receiptNumber =
        'SF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    notices.insert(
      0,
      AppNotice(
        id: 'payment-${DateTime.now().millisecondsSinceEpoch}',
        title: 'To‘lov muvaffaqiyatli',
        body: '600 000 so‘m $method orqali qabul qilindi.',
        time: 'Hozir',
        type: NoticeType.success,
        destination: NoticeDestination.payments,
        audience: NoticeAudience.parent,
      ),
    );
    notifyListeners();
  }

  void addGoal(StudyGoal goal) {
    goals.add(goal);
    notifyListeners();
  }

  void updateGoal(String id, int current) {
    final index = goals.indexWhere((goal) => goal.id == id);
    if (index < 0) return;
    goals[index] = goals[index].copyWith(current: current);
    notifyListeners();
  }

  void setToolkitToggle(String id, String title, bool value) {
    if (toolkitToggles[id] == value) return;
    toolkitToggles[id] = value;
    _recordToolkitActivity(
      featureId: id,
      title: title,
      value: value ? 'Yoqildi' : 'O‘chirildi',
    );
    notifyListeners();
  }

  void setToolkitValue(String id, String title, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || toolkitValues[id] == normalized) return;
    toolkitValues[id] = normalized;
    _recordToolkitActivity(featureId: id, title: title, value: normalized);
    notifyListeners();
  }

  void incrementToolkitCounter(String id, String title, {int amount = 1}) {
    final next = (toolkitCounters[id] ?? 0) + amount;
    toolkitCounters[id] = next.clamp(0, 9999);
    _recordToolkitActivity(
      featureId: id,
      title: title,
      value: toolkitCounters[id].toString(),
    );
    notifyListeners();
  }

  void recordToolkitAction(String id, String title, String result) {
    toolkitValues[id] = result;
    _recordToolkitActivity(featureId: id, title: title, value: result);
    notifyListeners();
  }

  void clearToolkitWorkspace() {
    if (toolkitToggles.isEmpty &&
        toolkitValues.isEmpty &&
        toolkitCounters.isEmpty &&
        toolkitActivity.isEmpty) {
      return;
    }
    toolkitToggles.clear();
    toolkitValues.clear();
    toolkitCounters.clear();
    toolkitActivity.clear();
    notifyListeners();
  }

  void _recordToolkitActivity({
    required String featureId,
    required String title,
    required String value,
  }) {
    toolkitActivity.insert(
      0,
      ToolkitActivity(
        id: 'tool-${DateTime.now().microsecondsSinceEpoch}',
        featureId: featureId,
        title: title,
        value: value,
        createdAt: DateTime.now(),
      ),
    );
    if (toolkitActivity.length > 50) {
      toolkitActivity.removeRange(50, toolkitActivity.length);
    }
  }

  void resetDemoSession() {
    _aiRequestGeneration++;
    aiMessages.clear();
    aiGenerating = false;
    aiError = null;
    lastAiPrompt = null;
    personalTasks.clear();
    completedTasks
      ..clear()
      ..add('english-words');
    favoriteMaterials
      ..clear()
      ..add('material-601');
    downloadedMaterials.clear();
    lessonReminders.clear();
    sentParentReminders.clear();
    readAnnouncements
      ..clear()
      ..add('announcement-welcome');
    pinnedAnnouncements.clear();
    calendarReminders.clear();
    personalEvents.clear();
    supportTickets.clear();
    attendanceExplanations.clear();
    _familyData = FamilySnapshot.localPreview(now: SfClock.now());
    messaging.resetPreview(SfClock.now());
    paymentCompleted = false;
    receiptNumber = null;
    paymentMethod = null;
    largeText = false;
    reduceMotion = false;
    hideAmounts = false;
    darkMode = false;
    highContrast = false;
    profileNames
      ..clear()
      ..addAll({'parent': 'Akbarova Dilnoza', 'student': 'Akbarov Akmal'});
    notificationPreferences.updateAll((_, _) => true);
    notices
      ..clear()
      ..addAll(_initialNotices());
    _readNoticeRoles.clear();
    goals
      ..clear()
      ..addAll(_initialGoals());
    toolkitToggles.clear();
    toolkitValues.clear();
    toolkitCounters.clear();
    toolkitActivity.clear();
    resetSignal.value++;
    notifyListeners();
  }
}

List<AppNotice> _initialNotices() => [
  AppNotice(
    id: 'n1',
    title: 'Yangi Up karta',
    body: 'Akmal mustaqil yechim uchun yulduz oldi.',
    time: '5 daqiqa oldin',
    type: NoticeType.success,
    destination: NoticeDestination.achievements,
  ),
  AppNotice(
    id: 'n2',
    title: 'To‘lov eslatmasi',
    body: 'Avgust oyi to‘lovi uchun 4 kun qoldi.',
    time: '1 soat oldin',
    type: NoticeType.warning,
    destination: NoticeDestination.payments,
    audience: NoticeAudience.parent,
  ),
  AppNotice(
    id: 'n3',
    title: 'Ustozdan xabar',
    body: 'Uy vazifasi ertaga tekshiriladi.',
    time: 'Kecha',
    type: NoticeType.message,
    destination: NoticeDestination.messages,
  ),
];

List<StudyGoal> _initialGoals() => [
  StudyGoal(
    id: 'goal-algebra',
    title: 'Algebra testidan 90% olish',
    subject: 'Algebra',
    current: 78,
    target: 90,
  ),
  StudyGoal(
    id: 'goal-reading',
    title: 'Haftasiga 120 daqiqa o‘qish',
    subject: 'Mustaqil o‘qish',
    current: 85,
    target: 120,
  ),
];

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
            as AppScope?;
    assert(element != null, 'AppScope is missing above this context');
    return element!.notifier!;
  }
}

enum NoticeType { success, warning, message, info }

enum NoticeAudience {
  all,
  student,
  parent,
  unknown;

  bool allows(String role) =>
      this == NoticeAudience.all || name == role.toLowerCase();

  static NoticeAudience parse(Object? value) {
    final role = '$value'.trim().toLowerCase();
    return switch (role) {
      'student' || 'learner' => NoticeAudience.student,
      'parent' || 'guardian' => NoticeAudience.parent,
      'all' || 'family' => NoticeAudience.all,
      _ => NoticeAudience.unknown,
    };
  }
}

enum NoticeDestination {
  home,
  study,
  calendar,
  messages,
  payments,
  achievements,
  announcements,
  noticeDetails;

  String get wireName => switch (this) {
    NoticeDestination.home => 'home',
    NoticeDestination.study => 'homework',
    NoticeDestination.calendar => 'calendar',
    NoticeDestination.messages => 'messages',
    NoticeDestination.payments => 'payments',
    NoticeDestination.achievements => 'cards',
    NoticeDestination.announcements => 'announcements',
    NoticeDestination.noticeDetails => 'notification',
  };

  String get label => switch (this) {
    NoticeDestination.home => 'Bosh sahifa',
    NoticeDestination.study => 'Vazifalar',
    NoticeDestination.calendar => 'Jadval',
    NoticeDestination.messages => 'Xabarlar',
    NoticeDestination.payments => 'To‘lovlar',
    NoticeDestination.achievements => 'Natijalar',
    NoticeDestination.announcements => 'E’lonlar',
    NoticeDestination.noticeDetails => 'Bildirishnoma',
  };

  static NoticeDestination parse(Object? value) {
    final route = '$value'.trim().toLowerCase();
    return switch (route) {
      'task' || 'tasks' || 'homework' || 'study' => NoticeDestination.study,
      'calendar' || 'schedule' || 'event' => NoticeDestination.calendar,
      'chat' || 'message' || 'messages' => NoticeDestination.messages,
      'payment' || 'payments' || 'invoice' => NoticeDestination.payments,
      'card' ||
      'cards' ||
      'achievement' ||
      'achievements' => NoticeDestination.achievements,
      'announcement' ||
      'announcements' ||
      'news' => NoticeDestination.announcements,
      _ => NoticeDestination.noticeDetails,
    };
  }

  static NoticeDestination fromEventType(Object? value) {
    final event = '$value'.trim().toLowerCase();
    if (event.isEmpty) return NoticeDestination.noticeDetails;
    final domain = event.split('.').first;
    return switch (domain) {
      'assignment' ||
      'assignments' ||
      'submission' ||
      'grade' => NoticeDestination.study,
      'message' ||
      'messages' ||
      'messaging' ||
      'thread' => NoticeDestination.messages,
      'schedule' || 'lesson' || 'attendance' => NoticeDestination.calendar,
      'payment' || 'payments' || 'invoice' => NoticeDestination.payments,
      'achievement' ||
      'achievements' ||
      'card' => NoticeDestination.achievements,
      'announcement' ||
      'announcements' ||
      'news' => NoticeDestination.announcements,
      _ => NoticeDestination.noticeDetails,
    };
  }
}

class AppNotice {
  final String id;
  final String title;
  final String body;
  final String time;
  final NoticeType type;
  final NoticeDestination destination;
  final NoticeAudience audience;
  final bool isRead;
  final DateTime? createdAt;
  final String? entityId;
  final String? eventType;

  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.destination = NoticeDestination.home,
    this.audience = NoticeAudience.all,
    this.isRead = false,
    this.createdAt,
    this.entityId,
    this.eventType,
  });

  String get route => destination.wireName;

  factory AppNotice.fromPayload(Map<String, dynamic> payload) {
    Object? pick(Iterable<String> keys) {
      for (final key in keys) {
        final direct = payload[key];
        if (direct != null) return direct;
      }
      return null;
    }

    final nestedRaw = payload['data'];
    final nested = nestedRaw is Map
        ? Map<String, dynamic>.from(nestedRaw)
        : const <String, dynamic>{};
    Object? pickNested(Iterable<String> keys) {
      final direct = pick(keys);
      if (direct != null) return direct;
      for (final key in keys) {
        final value = nested[key];
        if (value != null) return value;
      }
      return null;
    }

    final id =
        '${pickNested(const ['id', 'notification_id', 'event_id']) ?? ''}'
            .trim();
    final title = '${pickNested(const ['title', 'subject', 'heading']) ?? ''}'
        .trim();
    final body =
        '${pickNested(const ['body', 'message', 'description', 'text']) ?? ''}'
            .trim();
    if (id.isEmpty || title.isEmpty || body.isEmpty) {
      throw const FormatException(
        'Notification payload requires id, title and body.',
      );
    }

    final createdRaw = pickNested(const [
      'created_at',
      'sent_at',
      'timestamp',
      'date',
    ]);
    final createdAt = _parsePayloadDate(createdRaw);
    final explicitTime =
        '${pickNested(const ['time_label', 'relative_time', 'time']) ?? ''}'
            .trim();
    final eventType = '${pickNested(const ['event_type', 'eventType']) ?? ''}'
        .trim()
        .toLowerCase();
    final rawType =
        '${pickNested(const ['category', 'severity', 'type']) ?? eventType}'
            .trim()
            .toLowerCase();
    final type = switch (rawType.split('.').first) {
      'success' || 'payment' || 'achievement' => NoticeType.success,
      'warning' || 'attendance' || 'urgent' => NoticeType.warning,
      'message' || 'messages' || 'messaging' || 'chat' => NoticeType.message,
      _ => NoticeType.info,
    };
    final routeRaw = pickNested(const [
      'route',
      'destination',
      'screen',
      'action',
    ]);
    final readRaw = pickNested(const ['is_read', 'read', 'seen']);
    final readAtRaw = pickNested(const ['read_at', 'readAt']);
    final destination = eventType.isNotEmpty
        ? NoticeDestination.fromEventType(eventType)
        : NoticeDestination.parse(routeRaw);
    final entity = pickNested(switch (destination) {
      NoticeDestination.messages => const [
        'thread_id',
        'conversation_id',
        'entity_id',
        'target_id',
        'object_id',
      ],
      NoticeDestination.study => const [
        'assignment_id',
        'submission_id',
        'entity_id',
        'target_id',
        'object_id',
      ],
      NoticeDestination.calendar => const [
        'lesson_id',
        'attendance_id',
        'entity_id',
        'target_id',
        'object_id',
      ],
      NoticeDestination.payments => const [
        'payment_id',
        'invoice_id',
        'entity_id',
        'target_id',
        'object_id',
      ],
      _ => const ['entity_id', 'target_id', 'object_id'],
    });
    final entityText = '$entity'.trim();

    return AppNotice(
      id: id,
      title: title,
      body: body,
      time: explicitTime.isNotEmpty
          ? explicitTime
          : createdAt == null
          ? 'Hozir'
          : _relativePayloadTime(createdAt),
      type: type,
      destination: destination,
      audience: NoticeAudience.parse(
        pickNested(const ['recipient_role', 'audience', 'role']),
      ),
      isRead:
          readRaw == true ||
          '$readRaw'.toLowerCase() == 'true' ||
          '$readRaw' == '1' ||
          (readAtRaw != null &&
              '$readAtRaw'.trim().isNotEmpty &&
              '$readAtRaw'.toLowerCase() != 'null'),
      createdAt: createdAt,
      entityId: entityText.isEmpty || entityText == 'null' ? null : entityText,
      eventType: eventType.isEmpty ? null : eventType,
    );
  }

  AppNotice copyWith({bool? isRead, NoticeAudience? audience}) => AppNotice(
    id: id,
    title: title,
    body: body,
    time: time,
    type: type,
    destination: destination,
    audience: audience ?? this.audience,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    entityId: entityId,
    eventType: eventType,
  );
}

DateTime? _parsePayloadDate(Object? value) {
  if (value is DateTime) return value;
  if (value is num) {
    final milliseconds = value.abs() < 100000000000
        ? value.toInt() * 1000
        : value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  final text = '$value'.trim();
  if (text.isEmpty || text == 'null') return null;
  return DateTime.tryParse(text);
}

String _relativePayloadTime(DateTime value) {
  final difference = SfClock.now().difference(value.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return 'Hozir';
  if (difference.inMinutes < 60) return '${difference.inMinutes} daqiqa oldin';
  if (difference.inHours < 24) return '${difference.inHours} soat oldin';
  if (difference.inDays == 1) return 'Kecha';
  return '${difference.inDays} kun oldin';
}

enum AiMessageRole { user, assistant }

class AiSource {
  final String title;
  final String? detail;

  const AiSource({required this.title, this.detail});

  factory AiSource.fromPayload(Object? value) {
    if (value is String) {
      final title = value.trim();
      if (title.isEmpty) throw const FormatException('Empty AI source.');
      return AiSource(title: title);
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final title =
          '${map['title'] ?? map['name'] ?? map['label'] ?? map['url'] ?? ''}'
              .trim();
      if (title.isEmpty) throw const FormatException('Empty AI source.');
      final detail = '${map['detail'] ?? map['url'] ?? map['section'] ?? ''}'
          .trim();
      return AiSource(title: title, detail: detail.isEmpty ? null : detail);
    }
    throw const FormatException('Unsupported AI source.');
  }
}

class AiTutorResponse {
  final String answer;
  final String requestId;
  final List<AiSource> sources;
  final bool isLocalDemo;

  const AiTutorResponse({
    required this.answer,
    required this.requestId,
    this.sources = const <AiSource>[],
    this.isLocalDemo = false,
  });

  factory AiTutorResponse.fromPayload(Object? raw) {
    if (raw is String) {
      final answer = raw.trim();
      if (answer.isEmpty) {
        throw const FormatException('AI response is empty.');
      }
      return AiTutorResponse(
        answer: answer,
        requestId: 'ai-${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    if (raw is! Map) {
      throw const FormatException('Unsupported AI response.');
    }
    final payload = Map<String, dynamic>.from(raw);
    final nestedRaw = payload['data'] ?? payload['result'];
    final nested = nestedRaw is Map
        ? Map<String, dynamic>.from(nestedRaw)
        : const <String, dynamic>{};
    Object? pick(Iterable<String> keys) {
      for (final key in keys) {
        if (payload[key] != null) return payload[key];
        if (nested[key] != null) return nested[key];
      }
      return null;
    }

    final answer =
        '${pick(const ['answer', 'response', 'content', 'message', 'output', 'text']) ?? ''}'
            .trim();
    if (answer.isEmpty) {
      throw const FormatException('AI response does not contain an answer.');
    }
    final sourceRaw = pick(const ['sources', 'references', 'citations']);
    final sources = <AiSource>[];
    if (sourceRaw is Iterable) {
      for (final item in sourceRaw) {
        try {
          sources.add(AiSource.fromPayload(item));
        } on FormatException {
          // A malformed optional source must not hide a valid answer.
        }
      }
    }
    final requestId = '${pick(const ['request_id', 'requestId', 'id']) ?? ''}'
        .trim();
    final mode = '${pick(const ['mode', 'provider', 'source']) ?? ''}'
        .toLowerCase();
    return AiTutorResponse(
      answer: answer,
      requestId: requestId.isEmpty
          ? 'ai-${DateTime.now().microsecondsSinceEpoch}'
          : requestId,
      sources: List<AiSource>.unmodifiable(sources),
      isLocalDemo: mode.contains('local') || mode.contains('demo'),
    );
  }
}

class AiChatMessage {
  final String id;
  final String text;
  final AiMessageRole role;
  final DateTime createdAt;
  final List<AiSource> sources;
  final bool isLocalDemo;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.createdAt,
    this.sources = const <AiSource>[],
    this.isLocalDemo = false,
  });
}

abstract interface class AiTutorTransport {
  String get connectionLabel;
  bool get isLocalDemo;
  Future<Object?> send(String prompt);
}

/// A deliberately labelled offline tutor used until a real endpoint is
/// configured. It never pretends that a server answered.
class LocalStudyTutorTransport implements AiTutorTransport {
  const LocalStudyTutorTransport();

  @override
  String get connectionLabel => 'Lokal o‘quv rejimi';

  @override
  bool get isLocalDemo => true;

  @override
  Future<Object?> send(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final value = prompt.toLowerCase();
    final (
      answer,
      sources,
    ) = value.contains('diskriminant') || value.contains('kvadrat')
        ? (
            'Kvadrat tenglama ax² + bx + c = 0 ko‘rinishida bo‘ladi. '
                'Avval a, b va c ni ajrating, keyin D = b² − 4ac ni hisoblang. '
                'D musbat bo‘lsa 2 ta, nol bo‘lsa 1 ta, manfiy bo‘lsa haqiqiy ildiz yo‘q.',
            const [
              {'title': 'Algebra · Kvadrat tenglamalar', 'section': '9-sinf'},
            ],
          )
        : value.contains('english') ||
              value.contains('ingliz') ||
              value.contains('word')
        ? (
            'Mavzuni 3 qismga bo‘ling: yangi so‘zlarni ma’no bilan yozing, '
                'har biri bilan gap tuzing va 10 daqiqadan keyin o‘zingizni tekshiring.',
            const [
              {'title': 'Ingliz tili · Unit 8', 'section': 'O‘quv reja'},
            ],
          )
        : (
            'Savolni kichik qadamlarga ajrating: ma’lumlarni yozing, kerakli '
                'qoidani tanlang, yechimni bajaring va oxirida natijani tekshiring. '
                'Mavzuni aniqroq yozsangiz, lokal yordamchi batafsilroq yo‘l ko‘rsatadi.',
            const [
              {'title': 'StarForge o‘quv yo‘riqnomasi'},
            ],
          );
    return {
      'data': {
        'answer': answer,
        'sources': sources,
        'request_id': 'local-${DateTime.now().microsecondsSinceEpoch}',
        'mode': 'local_demo',
      },
    };
  }
}

class StudyTask {
  final String id;
  final String title;
  final String subject;
  final String dueLabel;
  final DateTime dueAt;
  final int minutes;
  final bool isPersonal;

  const StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueLabel,
    required this.dueAt,
    required this.minutes,
    this.isPersonal = false,
  });
}

class StudyGoal {
  final String id;
  final String title;
  final String subject;
  final int current;
  final int target;

  const StudyGoal({
    required this.id,
    required this.title,
    required this.subject,
    required this.current,
    required this.target,
  });

  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);

  StudyGoal copyWith({int? current}) => StudyGoal(
    id: id,
    title: title,
    subject: subject,
    current: current ?? this.current,
    target: target,
  );
}

class PersonalCalendarEvent {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String time;
  final String notes;

  const PersonalCalendarEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.notes,
  });
}

class SupportTicket {
  final String id;
  final String topic;
  final String message;
  final String priority;
  final DateTime createdAt;
  final String status;

  const SupportTicket({
    required this.id,
    required this.topic,
    required this.message,
    required this.priority,
    required this.createdAt,
    this.status = 'Qabul qilindi',
  });
}

class ToolkitActivity {
  final String id;
  final String featureId;
  final String title;
  final String value;
  final DateTime createdAt;

  const ToolkitActivity({
    required this.id,
    required this.featureId,
    required this.title,
    required this.value,
    required this.createdAt,
  });
}
