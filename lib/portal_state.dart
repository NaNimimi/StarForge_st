import 'dart:async';

import 'package:flutter/foundation.dart';

import 'starforge_api.dart';

enum AuthPhase { restoring, signedOut, signedIn }

enum PortalSection {
  home,
  identity,
  assignments,
  schedule,
  academics,
  content,
  attendance,
  messages,
  notifications,
  forms,
  achievements,
  discipline,
  finance,
  cards,
  account,
}

final class PortalController extends ChangeNotifier {
  PortalController({
    SecureSessionStore sessionStore = const SecureSessionStore(),
    StarForgeApi? api,
    bool restoreSession = true,
  }) : _store = sessionStore,
       _api = api ?? StarForgeApi(baseUrl: defaultApiBaseUrl) {
    if (restoreSession) {
      unawaited(restore());
    } else {
      phase = AuthPhase.signedOut;
    }
  }

  final SecureSessionStore _store;
  final StarForgeApi _api;

  AuthPhase phase = AuthPhase.restoring;
  String role = '';
  String deviceId = '';
  bool mustChangePassword = false;
  bool authenticationBusy = false;
  String? authenticationError;
  Map<String, Object?> profile = const {};

  final Set<PortalSection> _loaded = {};
  final Set<PortalSection> _loading = {};
  final Map<PortalSection, String> _errors = {};

  Map<String, Object?> dashboard = const {};
  Map<String, Object?> report = const {};
  List<Map<String, Object?>> children = const [];
  int? selectedStudentId;
  int? selectingStudentId;
  int _childSelectionGeneration = 0;
  Map<String, Object?> studentProfile = const {};
  List<Map<String, Object?>> studentEvents = const [];
  Map<String, Object?> studentStats = const {};
  Map<String, Object?> studentComparison = const {};
  List<Map<String, Object?>> birthdays = const [];
  List<Map<String, Object?>> enrollmentReasons = const [];
  Map<String, Object?> parentProfile = const {};
  List<Map<String, Object?>> guardians = const [];
  List<Map<String, Object?>> pickups = const [];

  List<Map<String, Object?>> assignments = const [];
  List<Map<String, Object?>> submissions = const [];
  List<Map<String, Object?>> lessons = const [];
  List<Map<String, Object?>> terms = const [];
  List<Map<String, Object?>> timeSlots = const [];
  List<Map<String, Object?>> lessonTypes = const [];
  List<Map<String, Object?>> scheduleRules = const [];
  String calendarUrl = '';
  List<Map<String, Object?>> attendance = const [];
  Map<String, Object?> attendanceSummary = const {};
  List<Map<String, Object?>> subjects = const [];
  List<Map<String, Object?>> examTypes = const [];
  List<Map<String, Object?>> exams = const [];
  List<Map<String, Object?>> grades = const [];
  List<Map<String, Object?>> transcripts = const [];

  List<Map<String, Object?>> libraries = const [];
  List<Map<String, Object?>> courses = const [];
  List<Map<String, Object?>> modules = const [];
  List<Map<String, Object?>> contentLessons = const [];
  List<Map<String, Object?>> folders = const [];
  List<Map<String, Object?>> files = const [];
  List<Map<String, Object?>> materials = const [];

  List<Map<String, Object?>> notifications = const [];
  int unreadNotificationCount = 0;
  List<Map<String, Object?>> notificationPreferences = const [];
  List<Map<String, Object?>> contacts = const [];
  int? messagingSelfUserId;
  List<Map<String, Object?>> threads = const [];
  final Map<int, List<Map<String, Object?>>> messages = {};
  final Set<int> loadingMessageThreads = {};
  final Map<int, String> messageErrors = {};
  List<Map<String, Object?>> forms = const [];
  List<Map<String, Object?>> achievementGrants = const [];
  List<Map<String, Object?>> rules = const [];
  List<Map<String, Object?>> pendingRules = const [];
  List<Map<String, Object?>> penalties = const [];
  List<Map<String, Object?>> cards = const [];
  List<Map<String, Object?>> cardTypes = const [];
  List<Map<String, Object?>> cardScans = const [];
  Map<String, Object?> wallet = const {};
  Map<String, Object?> outstanding = const {};
  List<Map<String, Object?>> devices = const [];
  DateTime? lastSuccessfulSyncAt;
  bool connectionIssue = false;

  bool get isStudent => role == 'student';
  bool get isParent => role == 'parent';
  bool get isAuthenticated => phase == AuthPhase.signedIn;
  String get baseUrl => _api.baseUrl;
  String get displayName => _value(profile, const [
    'full_name',
    'username',
  ], fallback: isParent ? 'Ota-ona' : 'O‘quvchi');

  Set<String> get permissions {
    final raw = profile['permission_codes'];
    if (raw is! List) return const {};
    return {for (final value in raw) '$value'};
  }

  bool can(String permission) {
    final separator = permission.indexOf(':');
    final wildcard = separator < 0
        ? '$permission:*'
        : '${permission.substring(0, separator)}:*';
    return permissions.contains(permission) || permissions.contains(wildcard);
  }

  bool isLoading(PortalSection section) => _loading.contains(section);
  bool isLoaded(PortalSection section) => _loaded.contains(section);
  String? sectionError(PortalSection section) => _errors[section];

  Future<void> restore() async {
    phase = AuthPhase.restoring;
    notifyListeners();
    final record = await _store.read();
    if (record == null) {
      phase = AuthPhase.signedOut;
      notifyListeners();
      return;
    }
    _api
      ..baseUrl = record.baseUrl
      ..accessToken = record.accessToken;
    role = record.role;
    deviceId = record.deviceId;
    try {
      await _loadProfile();
      _assertFamilyRole();
      phase = AuthPhase.signedIn;
      notifyListeners();
      await loadSection(PortalSection.home);
    } on Object {
      await _store.clear();
      _api.accessToken = null;
      phase = AuthPhase.signedOut;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    if (authenticationBusy) return false;
    authenticationBusy = true;
    authenticationError = null;
    notifyListeners();
    try {
      _api.baseUrl = baseUrl;
      deviceId = deviceId.isEmpty
          ? 'family-${DateTime.now().microsecondsSinceEpoch}'
          : deviceId;
      final result = await _api.post(
        '/api/v1/auth/role-login/',
        body: {
          'username': username.trim(),
          'password': password,
          'device_id': deviceId,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        },
      );
      final data = result.object;
      final access = '${data['access'] ?? ''}'.trim();
      role = '${data['role'] ?? ''}'.trim().toLowerCase();
      if (access.isEmpty) {
        throw const ApiException(
          message: 'Server sessiya kalitini qaytarmadi.',
          code: 'invalid_login_response',
        );
      }
      _assertFamilyRole();
      _api.accessToken = access;
      mustChangePassword = data['must_change_password'] == true;
      await _loadProfile();
      await _store.save(
        SessionRecord(
          baseUrl: _api.baseUrl,
          accessToken: access,
          role: role,
          deviceId: deviceId,
        ),
      );
      phase = AuthPhase.signedIn;
      authenticationBusy = false;
      notifyListeners();
      await loadSection(PortalSection.home, force: true);
      return true;
    } on FormatException catch (error) {
      authenticationError = error.message;
    } on ApiException catch (error) {
      authenticationError = error.message;
    } on Object {
      authenticationError = 'Kirish vaqtida kutilmagan xatolik yuz berdi.';
    }
    authenticationBusy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    if (_api.accessToken != null) {
      try {
        await _api.post('/api/v1/auth/logout/', body: const {});
      } on Object {
        // Local credentials still have to be removed if the server is offline.
      }
    }
    await _expireSession();
  }

  Future<void> _expireSession() async {
    await _store.clear();
    _api.accessToken = null;
    role = '';
    profile = const {};
    mustChangePassword = false;
    _clearData();
    phase = AuthPhase.signedOut;
    notifyListeners();
  }

  void _assertFamilyRole() {
    if (role != 'student' && role != 'parent') {
      throw const ApiException(
        message: 'Bu ilova faqat o‘quvchi va ota-ona akkauntlari uchun.',
        code: 'unsupported_role',
      );
    }
  }

  Future<void> _loadProfile() async {
    profile = (await _api.get('/api/v1/users/me/')).object;
    final principal = '${profile['principal_kind'] ?? ''}'.toLowerCase();
    if (principal.isNotEmpty) role = principal;
    mustChangePassword = profile['must_change_password'] == true;
  }

  Future<void> loadSection(PortalSection section, {bool force = false}) async {
    if (!isAuthenticated || _loading.contains(section)) return;
    if (!force && _loaded.contains(section)) return;
    _loading.add(section);
    _errors.remove(section);
    notifyListeners();
    try {
      await switch (section) {
        PortalSection.home => _loadHome(),
        PortalSection.identity => _loadIdentity(),
        PortalSection.assignments => _loadAssignments(),
        PortalSection.schedule => _loadSchedule(),
        PortalSection.academics => _loadAcademics(),
        PortalSection.content => _loadContent(),
        PortalSection.attendance => _loadAttendance(),
        PortalSection.messages => _loadMessaging(),
        PortalSection.notifications => _loadNotifications(),
        PortalSection.forms => _loadForms(),
        PortalSection.achievements => _loadAchievements(),
        PortalSection.discipline => _loadDiscipline(),
        PortalSection.finance => _loadFinance(),
        PortalSection.cards => _loadCards(),
        PortalSection.account => _loadAccount(),
      };
      _loaded.add(section);
      lastSuccessfulSyncAt = DateTime.now();
      connectionIssue = false;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _expireSession();
        return;
      }
      _errors[section] = error.message;
      connectionIssue = true;
    } on Object {
      _errors[section] = 'Ma’lumotlarni yuklab bo‘lmadi.';
      connectionIssue = true;
    } finally {
      _loading.remove(section);
      notifyListeners();
    }
  }

  Future<void> refresh(PortalSection section) =>
      loadSection(section, force: true);

  Future<void> _loadHome() async {
    await _loadProfile();
    if (isStudent) {
      final values = await Future.wait([
        _api.get('/api/v1/students/me/dashboard/'),
        _api.get('/api/v1/students/me/report/'),
      ]);
      dashboard = values[0].object;
      report = values[1].object;
      selectedStudentId = _integer(profile['id']);
      await _refreshUnreadNotificationCount();
    } else {
      children = (await _api.get('/api/v1/parents/me/children/')).rows;
      if (children.isEmpty) {
        selectedStudentId = null;
        report = const {};
        outstanding = const {};
        return;
      }
      final ids = children.map((item) => _integer(item['id'])).whereType<int>();
      if (selectedStudentId == null || !ids.contains(selectedStudentId)) {
        selectedStudentId = ids.firstOrNull;
      }
      await _loadSelectedChild();
      await _refreshUnreadNotificationCount();
    }
  }

  Future<void> _refreshUnreadNotificationCount() async {
    try {
      unreadNotificationCount =
          _integer(
            (await _api.get(
              '/api/v1/notifications/unread-count/',
            )).object['count'],
          ) ??
          0;
    } on ApiException {
      unreadNotificationCount = notifications
          .where((item) => item['read_at'] == null)
          .length;
    }
  }

  Future<void> _loadIdentity() async {
    if (isStudent) {
      final studentRows = (await _api.get(
        '/api/v1/students/',
        query: const {'page_size': 25},
      )).rows;
      final studentId =
          selectedStudentId ??
          _integer(studentRows.firstOrNull?['id']) ??
          _integer(profile['id']);
      selectedStudentId = studentId;
      final values = await Future.wait([
        if (studentId != null) _api.get('/api/v1/students/$studentId/'),
        if (studentId != null) _api.get('/api/v1/students/$studentId/events/'),
        _api.get('/api/v1/students/stats/'),
        _api.get('/api/v1/students/birthdays/', query: const {'page_size': 25}),
        _api.get(
          '/api/v1/students/enrollment-reasons/',
          query: const {'page_size': 100},
        ),
      ]);
      var index = 0;
      if (studentId != null) {
        studentProfile = values[index++].object;
        studentEvents = values[index++].rows;
      } else {
        studentProfile = studentRows.firstOrNull ?? const {};
        studentEvents = const [];
      }
      studentStats = values[index++].object;
      studentComparison = const {};
      birthdays = values[index++].rows;
      enrollmentReasons = values[index].rows;
      return;
    }

    final values = await Future.wait([
      _api.get('/api/v1/parents/', query: const {'page_size': 25}),
      _api.get('/api/v1/parents/guardians/', query: const {'page_size': 100}),
      _api.get('/api/v1/parents/pickups/', query: const {'page_size': 100}),
      if (children.isEmpty) _api.get('/api/v1/parents/me/children/'),
    ]);
    parentProfile = values[0].rows.firstOrNull ?? const {};
    guardians = values[1].rows;
    pickups = values[2].rows;
    if (children.isEmpty && values.length > 3) children = values[3].rows;
    final studentId =
        selectedStudentId ?? _integer(children.firstOrNull?['id']);
    selectedStudentId = studentId;
    if (studentId != null) {
      final childValues = await Future.wait([
        _api.get('/api/v1/students/$studentId/'),
        _api.get('/api/v1/students/$studentId/events/'),
      ]);
      studentProfile = childValues[0].object;
      studentEvents = childValues[1].rows;
    } else {
      studentProfile = const {};
      studentEvents = const [];
    }
  }

  Future<void> selectChild(int studentId) async {
    if (!isParent ||
        selectedStudentId == studentId ||
        selectingStudentId != null) {
      return;
    }
    final generation = ++_childSelectionGeneration;
    selectingStudentId = studentId;
    _errors.remove(PortalSection.home);
    notifyListeners();
    try {
      final next = await _fetchSelectedChild(studentId);
      if (generation != _childSelectionGeneration) return;
      selectedStudentId = studentId;
      report = next.$1;
      outstanding = next.$2;
      _loaded.removeAll({
        PortalSection.identity,
        PortalSection.schedule,
        PortalSection.finance,
        PortalSection.attendance,
        PortalSection.academics,
        PortalSection.content,
        PortalSection.achievements,
        PortalSection.discipline,
      });
    } on ApiException catch (error) {
      if (generation == _childSelectionGeneration) {
        _errors[PortalSection.home] = error.message;
      }
    } finally {
      if (generation == _childSelectionGeneration) {
        selectingStudentId = null;
        notifyListeners();
      }
    }
  }

  Future<void> _loadSelectedChild() async {
    final studentId = selectedStudentId;
    if (studentId == null) return;
    final next = await _fetchSelectedChild(studentId);
    report = next.$1;
    outstanding = next.$2;
  }

  Future<(Map<String, Object?>, Map<String, Object?>)> _fetchSelectedChild(
    int studentId,
  ) async {
    final nextReport = (await _api.get(
      '/api/v1/parents/me/children/$studentId/report/',
    )).object;
    Map<String, Object?> nextOutstanding = const {};
    if (can('finance:read_own')) {
      try {
        nextOutstanding = (await _api.get(
          '/api/v1/finance/outstanding/',
          query: {'student': studentId},
        )).object;
        _errors.remove(PortalSection.finance);
      } on ApiException catch (error) {
        _errors[PortalSection.finance] = error.message;
      }
    }
    return (nextReport, nextOutstanding);
  }

  Future<void> _loadAssignments() async {
    if (!can('assignments:read')) {
      assignments = const [];
      submissions = const [];
      return;
    }
    final values = await Future.wait([
      _api.get('/api/v1/assignments/', query: const {'page_size': 100}),
      _api.get(
        '/api/v1/assignments/submissions/',
        query: const {'page_size': 100},
      ),
    ]);
    assignments = values[0].rows;
    submissions = values[1].rows;
  }

  Future<void> _loadSchedule() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 7)).toUtc();
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 120)).toUtc();
    final selectedChild = children
        .where((item) => _integer(item['id']) == selectedStudentId)
        .firstOrNull;
    final selectedCohortId = isParent
        ? _integer(selectedChild?['current_cohort'])
        : null;
    final values = await Future.wait([
      _api.get(
        '/api/v1/schedule/lessons/',
        query: {
          'page_size': 100,
          'ordering': 'starts_at',
          'date_from': start.toIso8601String(),
          'date_to': end.toIso8601String(),
          'cohort': ?selectedCohortId,
        },
      ),
      _api.get('/api/v1/schedule/terms/', query: const {'page_size': 100}),
      _api.get('/api/v1/schedule/timeslots/', query: const {'page_size': 100}),
      _api.get(
        '/api/v1/schedule/lesson-types/',
        query: const {'page_size': 100},
      ),
      _api.get('/api/v1/schedule/rules/', query: const {'page_size': 100}),
      _api.get('/api/v1/schedule/ical-url/'),
    ]);
    lessons = values[0].rows;
    terms = values[1].rows;
    timeSlots = values[2].rows;
    lessonTypes = values[3].rows;
    scheduleRules = values[4].rows;
    calendarUrl = valueText(values[5].object, const ['url'], fallback: '');
  }

  Future<void> _loadAttendance() async {
    final values = await Future.wait([
      _api.get(
        '/api/v1/attendance/records/',
        query: const {'page_size': 100, 'ordering': '-created_at'},
      ),
      if (terms.isEmpty)
        _api.get('/api/v1/schedule/terms/', query: const {'page_size': 100}),
    ]);
    attendance = values[0].rows;
    if (terms.isEmpty && values.length > 1) terms = values[1].rows;
    final studentId = selectedStudentId;
    final currentTerm = terms
        .where((item) => item['is_current'] == true)
        .firstOrNull;
    final termId = _integer(currentTerm?['id'] ?? terms.firstOrNull?['id']);
    if (studentId != null && termId != null) {
      attendanceSummary = (await _api.get(
        '/api/v1/attendance/summary/',
        query: {'student': studentId, 'term': termId},
      )).object;
    } else {
      attendanceSummary = const {};
    }
  }

  Future<void> _loadAcademics() async {
    final values = await Future.wait([
      _api.get('/api/v1/academics/subjects/', query: const {'page_size': 100}),
      _api.get(
        '/api/v1/academics/exam-types/',
        query: const {'page_size': 100},
      ),
      _api.get('/api/v1/academics/exams/', query: const {'page_size': 100}),
      _api.get('/api/v1/academics/grades/', query: const {'page_size': 100}),
      _api.get(
        '/api/v1/academics/transcripts/',
        query: const {'page_size': 100},
      ),
      if (terms.isEmpty)
        _api.get('/api/v1/schedule/terms/', query: const {'page_size': 100}),
    ]);
    subjects = values[0].rows;
    examTypes = values[1].rows;
    exams = values[2].rows;
    grades = values[3].rows;
    transcripts = values[4].rows;
    if (terms.isEmpty && values.length > 5) terms = values[5].rows;
  }

  Future<void> _loadContent() async {
    final values = await Future.wait([
      _api.get('/api/v1/content/libraries/', query: const {'page_size': 100}),
      _api.get('/api/v1/content/courses/', query: const {'page_size': 100}),
      _api.get('/api/v1/content/modules/', query: const {'page_size': 100}),
      _api.get('/api/v1/content/lessons/', query: const {'page_size': 100}),
      _api.get('/api/v1/content/folders/', query: const {'page_size': 100}),
      _api.get('/api/v1/content/files/', query: const {'page_size': 100}),
      _api.get('/api/v1/content/materials/', query: const {'page_size': 100}),
    ]);
    libraries = values[0].rows;
    courses = values[1].rows;
    modules = values[2].rows;
    contentLessons = values[3].rows;
    folders = values[4].rows;
    files = values[5].rows;
    materials = values[6].rows;
  }

  Future<void> _loadNotifications() async {
    final values = await Future.wait([
      _api.get('/api/v1/notifications/'),
      _api.get('/api/v1/notifications/unread-count/'),
    ]);
    notifications = values[0].rows;
    unreadNotificationCount =
        _integer(values[1].object['count']) ??
        notifications.where((item) => item['read_at'] == null).length;
    if (can('notifications:read')) {
      notificationPreferences = (await _api.get(
        '/api/v1/notifications/preferences/',
      )).rows;
    } else {
      notificationPreferences = const [];
    }
  }

  Future<void> _loadMessaging() async {
    final values = await Future.wait([
      _api.get('/api/v1/messaging/contacts/', query: const {'page_size': 100}),
      _api.get('/api/v1/messaging/threads/', query: const {'page_size': 100}),
    ]);
    contacts = values[0].rows;
    messagingSelfUserId = _integer(values[0].pagination['self_user_id']);
    threads = values[1].rows;
  }

  Future<void> loadMessages(int threadId, {bool force = false}) async {
    if (!force && messages.containsKey(threadId)) return;
    if (loadingMessageThreads.contains(threadId)) return;
    loadingMessageThreads.add(threadId);
    messageErrors.remove(threadId);
    notifyListeners();
    try {
      final result = await _api.get(
        '/api/v1/messaging/threads/$threadId/messages/',
        query: const {'page_size': 100},
      );
      messages[threadId] = result.rows;
      threads = [
        for (final thread in threads)
          if (_integer(thread['id']) == threadId)
            {...thread, 'unread_count': 0}
          else
            thread,
      ];
      lastSuccessfulSyncAt = DateTime.now();
      connectionIssue = false;
      notifyListeners();
      try {
        await _api.post(
          '/api/v1/messaging/threads/$threadId/read/',
          body: const {},
        );
      } on Object {
        // Reading the transcript succeeded. A failed best-effort read marker
        // must not hide already loaded messages or trap the UI in a spinner.
      }
    } on Object catch (error) {
      messageErrors[threadId] = error is ApiException
          ? error.message
          : 'Xabarlarni yuklab bo‘lmadi.';
      connectionIssue = true;
    } finally {
      loadingMessageThreads.remove(threadId);
      notifyListeners();
    }
  }

  Future<void> _loadForms() async {
    forms = (await _api.get(
      '/api/v1/forms/',
      query: const {'page_size': 100, 'status': 'published'},
    )).rows;
  }

  Future<void> _loadAchievements() async {
    achievementGrants = (await _api.get(
      '/api/v1/achievements/mine/',
      query: const {'page_size': 100},
    )).rows;
  }

  Future<void> _loadDiscipline() async {
    final values = await Future.wait([
      _api.get('/api/v1/rulebook/rules/mine/'),
      _api.get('/api/v1/rulebook/rules/pending/'),
      _api.get('/api/v1/rulebook/penalties/', query: const {'page_size': 100}),
    ]);
    rules = values[0].rows;
    pendingRules = values[1].rows;
    penalties = values[2].rows;
  }

  Future<void> _loadFinance() async {
    final studentId = selectedStudentId;
    if (studentId == null) {
      outstanding = const {};
      return;
    }
    outstanding = (await _api.get(
      '/api/v1/finance/outstanding/',
      query: {'student': studentId},
    )).object;
  }

  Future<void> _loadCards() async {
    if (!isStudent || !can('card:read')) return;
    final values = await Future.wait([
      _api.get('/api/v1/cards/', query: const {'page_size': 100}),
      _api.get('/api/v1/cards/types/', query: const {'page_size': 100}),
      _api.get('/api/v1/cards/wallets/me/'),
    ]);
    cards = values[0].rows;
    cardTypes = values[1].rows;
    // Scan history is intentionally staff-only even when a student owns the
    // card. Family clients only receive the card and their wallet projection.
    cardScans = const [];
    wallet = values[2].object;
  }

  Future<void> _loadAccount() async {
    await _loadProfile();
    devices = (await _api.get(
      '/api/v1/users/devices/',
      query: const {'page_size': 100},
    )).rows;
  }

  Future<void> submitAssignment({
    required int assignmentId,
    required String text,
    List<String> attachmentKeys = const [],
  }) async {
    await _api.post(
      '/api/v1/assignments/$assignmentId/submissions/',
      body: {'text': text.trim(), 'attachment_keys': attachmentKeys},
    );
    await refresh(PortalSection.assignments);
  }

  Future<String> uploadAssignmentFile({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final grant = (await _api.post(
      '/api/v1/assignments/upload-url/',
      body: {
        'filename': filename,
        'content_type': contentType,
        'size_bytes': bytes.length,
      },
    )).object;
    final url = '${grant['url'] ?? ''}';
    final key = '${grant['key'] ?? ''}';
    if (url.isEmpty || key.isEmpty) {
      throw const ApiException(
        message: 'Yuklash ruxsati noto‘g‘ri qaytdi.',
        code: 'invalid_upload_grant',
      );
    }
    await _api.uploadBytes(url, bytes, contentType: contentType);
    return key;
  }

  Future<void> requestTranscript({int? termId}) async {
    final studentId = selectedStudentId;
    if (studentId == null) {
      throw const ApiException(message: 'O‘quvchi tanlanmagan.');
    }
    final body = <String, Object?>{'student': studentId};
    if (termId != null) body['term'] = termId;
    await _api.post('/api/v1/academics/transcripts/', body: body);
    await refresh(PortalSection.academics);
  }

  Future<String> contentDownloadUrl(int fileId) async {
    final data = (await _api.get(
      '/api/v1/content/files/$fileId/download-url/',
    )).object;
    final url = '${data['url'] ?? data['download_url'] ?? ''}';
    if (url.isEmpty) {
      throw const ApiException(message: 'Yuklab olish havolasi topilmadi.');
    }
    return url;
  }

  Future<void> trackContentView(int fileId) => _api
      .post('/api/v1/content/files/$fileId/track-view/', body: const {})
      .then((_) {});

  Future<void> sendMessage(
    int threadId,
    String body, {
    List<String> attachments = const [],
  }) async {
    await _api.post(
      '/api/v1/messaging/threads/$threadId/messages/',
      body: {'body': body.trim(), 'attachments': attachments},
    );
    await loadMessages(threadId, force: true);
    await refresh(PortalSection.messages);
  }

  Future<String> uploadMessageFile({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final grant = (await _api.post(
      '/api/v1/messaging/attachments/upload-url/',
      body: {
        'filename': filename,
        'content_type': contentType,
        'size_bytes': bytes.length,
      },
    )).object;
    final url = valueText(grant, const ['url'], fallback: '');
    final key = valueText(grant, const ['key'], fallback: '');
    final rawFields = grant['fields'];
    final fields = rawFields is Map
        ? <String, String>{
            for (final entry in rawFields.entries)
              '${entry.key}': '${entry.value}',
          }
        : const <String, String>{};
    if (url.isEmpty || key.isEmpty || fields.isEmpty) {
      throw const ApiException(
        message: 'Fayl yuklash ruxsati noto‘g‘ri qaytdi.',
        code: 'invalid_upload_grant',
      );
    }
    await _api.uploadMultipartBytes(
      url,
      bytes,
      filename: filename,
      fields: fields,
    );
    return key;
  }

  Future<String> messageAttachmentDownloadUrl(int threadId, String key) async {
    final data = (await _api.get(
      '/api/v1/messaging/threads/$threadId/attachments/download/',
      query: {'key': key},
    )).object;
    final url = valueText(data, const ['url'], fallback: '');
    if (url.isEmpty) {
      throw const ApiException(message: 'Yuklab olish havolasi topilmadi.');
    }
    return url;
  }

  Future<int> createThread({
    required List<int> participantIds,
    required String subject,
    required String firstBody,
    List<String> attachments = const [],
  }) async {
    final data = (await _api.post(
      '/api/v1/messaging/threads/',
      body: {
        'participant_ids': participantIds,
        'subject': subject.trim(),
        'first_body': firstBody.trim(),
        'attachments': attachments,
      },
    )).object;
    await refresh(PortalSection.messages);
    return _integer(data['id']) ?? 0;
  }

  Future<void> setThreadMuted(int threadId, bool muted) async {
    await _api.patch(
      '/api/v1/messaging/threads/$threadId/preferences/',
      body: {'notifications_muted': muted},
    );
    await refresh(PortalSection.messages);
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _api.post(
      '/api/v1/notifications/$notificationId/read/',
      body: const {},
    );
    await refresh(PortalSection.notifications);
  }

  Future<void> markAllNotificationsRead() async {
    await _api.post('/api/v1/notifications/read-all/', body: const {});
    await refresh(PortalSection.notifications);
  }

  Future<void> saveNotificationPreferences(
    List<Map<String, Object?>> preferences,
  ) async {
    await _api.put(
      '/api/v1/notifications/preferences/',
      body: {'preferences': preferences},
    );
    await refresh(PortalSection.notifications);
  }

  Future<void> submitForm(
    int formId,
    List<Map<String, Object?>> answers,
  ) async {
    await _api.post(
      '/api/v1/forms/$formId/submit/',
      body: {'answers': answers},
    );
    await refresh(PortalSection.forms);
  }

  Future<void> acknowledgeRule(int ruleId) async {
    await _api.post(
      '/api/v1/rulebook/rules/$ruleId/acknowledge/',
      body: const {},
    );
    await refresh(PortalSection.discipline);
  }

  Future<Map<String, Object?>> updateProfile(
    Map<String, Object?> changes,
  ) async {
    profile = (await _api.patch('/api/v1/users/me/', body: changes)).object;
    notifyListeners();
    return profile;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final data = (await _api.post(
      '/api/v1/auth/password/change/',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    )).object;
    final access = '${data['access'] ?? ''}'.trim();
    if (access.isNotEmpty) _api.accessToken = access;
    mustChangePassword = false;
    await _store.save(
      SessionRecord(
        baseUrl: _api.baseUrl,
        accessToken: _api.accessToken ?? access,
        role: role,
        deviceId: deviceId,
      ),
    );
    await _loadProfile();
    notifyListeners();
  }

  Future<void> revokeDevice(int id) async {
    await _api.delete('/api/v1/users/devices/$id/');
    await refresh(PortalSection.account);
  }

  Future<void> requestPasswordReset({
    required String baseUrl,
    required String identifier,
    required String accountType,
  }) async {
    _api.baseUrl = baseUrl;
    await _api.post(
      '/api/v1/auth/password/reset/request/',
      body: {'identifier': identifier.trim(), 'account_type': accountType},
    );
  }

  Future<void> confirmPasswordReset({
    required String baseUrl,
    required String identifier,
    required String accountType,
    required String code,
    required String newPassword,
  }) async {
    _api.baseUrl = baseUrl;
    await _api.post(
      '/api/v1/auth/password/reset/confirm/',
      body: {
        'identifier': identifier.trim(),
        'account_type': accountType,
        'code': code.trim(),
        'new_password': newPassword,
      },
    );
  }

  String contactName(int userId) {
    final contact = contacts
        .where((item) => _integer(item['user_id'] ?? item['id']) == userId)
        .firstOrNull;
    return contact == null
        ? 'Maktab xodimi'
        : _value(contact, const [
            'display_name',
            'username',
          ], fallback: 'Kontakt');
  }

  String threadTitle(Map<String, Object?> thread) {
    final participants = thread['participants'];
    if (participants is List) {
      final otherIds = <int>[];
      for (final raw in participants) {
        if (raw is! Map) continue;
        final id = _integer(raw['user']);
        if (id != null && id != messagingSelfUserId) otherIds.add(id);
      }
      if (otherIds.length > 1) {
        return _value(thread, const ['subject'], fallback: 'Guruh suhbati');
      }
      if (otherIds case [final userId]) return contactName(userId);
    }
    return _value(thread, const ['subject'], fallback: 'Suhbat');
  }

  void _clearData() {
    _loaded.clear();
    _loading.clear();
    _errors.clear();
    dashboard = report = const {};
    studentProfile = studentStats = studentComparison = parentProfile =
        const {};
    children = studentEvents = birthdays = enrollmentReasons = guardians =
        pickups = assignments = submissions = lessons = terms = timeSlots =
            lessonTypes = scheduleRules = attendance = const [];
    calendarUrl = '';
    attendanceSummary = const {};
    subjects = examTypes = exams = grades = transcripts = const [];
    libraries = courses = modules = contentLessons = folders = files =
        materials = const [];
    notifications = notificationPreferences = contacts = threads = forms =
        const [];
    achievementGrants = rules = pendingRules = penalties = cards = cardTypes =
        cardScans = devices = const [];
    messages.clear();
    loadingMessageThreads.clear();
    messageErrors.clear();
    wallet = outstanding = const {};
    unreadNotificationCount = 0;
    selectedStudentId = null;
    selectingStudentId = null;
    _childSelectionGeneration++;
    messagingSelfUserId = null;
    lastSuccessfulSyncAt = null;
    connectionIssue = false;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }
}

String valueText(
  Map<String, Object?> map,
  List<String> keys, {
  String fallback = '—',
}) => _value(map, keys, fallback: fallback);

int? valueInt(Object? value) => _integer(value);

List<Map<String, Object?>> valueRows(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

Map<String, Object?> valueMap(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const <String, Object?>{};

String _value(
  Map<String, Object?> map,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = map[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

int? _integer(Object? value) =>
    value is int ? value : int.tryParse('${value ?? ''}');
