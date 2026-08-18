import 'dart:async';

import 'package:flutter/foundation.dart';

import 'portal_i18n.dart';
import 'portal_preferences.dart';
import 'push_notification_service.dart';
import 'starforge_api.dart';

enum AuthPhase { restoring, signedOut, signedIn }

enum PortalSection {
  home,
  identity,
  assignments,
  schedule,
  academics,
  placement,
  content,
  attendance,
  messages,
  ai,
  notifications,
  forms,
  achievements,
  discipline,
  finance,
  cards,
  account,
}

/// Reads the capability shape used by the current API while retaining support
/// for older tenants that only publish `permission_codes`.
Set<String> effectivePermissionCodes(Map<String, Object?> profile) {
  final effective = profile['effective_permissions'];
  final raw = _hasPermissionShape(effective)
      ? effective
      : profile['permission_codes'];
  return _permissionValues(raw, revoked: false);
}

bool _hasPermissionShape(Object? raw) {
  if (raw is Iterable || raw is String) return true;
  if (raw is! Map) return false;
  return const {
    'permissions',
    'granted',
    'permission_codes',
    'effective',
  }.any(raw.containsKey);
}

Set<String> revokedPermissionCodes(Map<String, Object?> profile) {
  final revoked = <String>{
    ..._permissionValues(profile['revoked_permission_codes'], revoked: false),
  };
  // The live API publishes `effective_permissions` as a flat list of grants.
  // Only the structured legacy shape can carry embedded revocations. Treating
  // the list as both granted and revoked hides every permitted destination.
  if (profile['effective_permissions'] is Map) {
    revoked.addAll(
      _permissionValues(profile['effective_permissions'], revoked: true),
    );
  }
  return revoked;
}

final class PortalController extends ChangeNotifier {
  PortalController({
    SecureSessionStore sessionStore = const SecureSessionStore(),
    StarForgeApi? api,
    PortalPreferences? preferences,
    bool restoreSession = true,
  }) : _store = sessionStore,
       _api = api ?? StarForgeApi(baseUrl: defaultApiBaseUrl),
       _preferences = preferences ?? PortalPreferences.memory() {
    _syncPreferences();
    _preferences.addListener(_syncPreferences);
    if (restoreSession) {
      unawaited(restore());
    } else {
      phase = AuthPhase.signedOut;
    }
  }

  final SecureSessionStore _store;
  final StarForgeApi _api;
  final PortalPreferences _preferences;

  PortalPreferences get preferences => _preferences;

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
  final Map<String, ApiException> _optionalApiFailures = {};

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
  List<Map<String, Object?>> placementAttempts = const [];
  List<Map<String, Object?>> placementTests = const [];

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
  final Map<int, Map<String, Object?>> messagingContactProfiles = {};
  final Set<int> _loadingMessagingContactProfiles = {};
  int? messagingSelfUserId;
  List<Map<String, Object?>> threads = const [];
  final Map<int, List<Map<String, Object?>>> messages = {};
  final Set<int> loadingMessageThreads = {};
  final Map<int, String> messageErrors = {};
  List<Map<String, Object?>> aiRequests = const [];
  Map<String, Object?> aiBudget = const {};
  Map<String, Object?> aiUsage = const {};
  List<Map<String, Object?>> aiConversation = const [];
  List<Map<String, Object?>> aiSources = const [];
  List<String> aiSuggestions = const [];
  bool aiReplyBusy = false;
  String? aiReplyError;
  bool aiFallbackMode = false;
  bool aiServiceAvailable = false;
  List<Map<String, Object?>> forms = const [];
  List<Map<String, Object?>> achievementGrants = const [];
  List<Map<String, Object?>> achievementCatalog = const [];
  List<Map<String, Object?>> rules = const [];
  List<Map<String, Object?>> pendingRules = const [];
  List<Map<String, Object?>> penalties = const [];
  List<Map<String, Object?>> cards = const [];
  List<Map<String, Object?>> cardTypes = const [];
  List<Map<String, Object?>> cardScans = const [];
  Map<String, Object?> wallet = const {};
  Map<String, Object?> outstanding = const {};
  List<Map<String, Object?>> devices = const [];
  final Map<int, Map<String, Object?>> assignmentDetails = {};
  final Map<int, Map<String, Object?>> submissionDetails = {};
  final Map<int, Map<String, Object?>> attendanceRecordDetails = {};
  final Map<int, Map<String, Object?>> scheduleLessonDetails = {};
  final Map<int, Map<String, Object?>> examDetails = {};
  final Map<int, Map<String, Object?>> gradeDetails = {};
  final Map<int, Map<String, Object?>> transcriptDetails = {};
  final Map<int, Map<String, Object?>> placementAttemptDetails = {};
  final Map<int, List<Map<String, Object?>>> placementSuggestions = {};
  final Map<int, Map<String, Object?>> achievementDetails = {};
  final Map<int, Map<String, Object?>> cardDetails = {};
  final Map<String, Map<int, Map<String, Object?>>> contentDetails = {};
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

  Set<String> get permissions => effectivePermissionCodes(profile);
  Set<String> get revokedPermissions => revokedPermissionCodes(profile);

  Map<String, ApiException> get optionalApiFailures =>
      Map<String, ApiException>.unmodifiable(_optionalApiFailures);

  ApiException? optionalApiFailure(String path) => _optionalApiFailures[path];

  bool can(String permission) {
    if (_permissionSetAllows(revokedPermissions, permission)) return false;
    return _permissionSetAllows(permissions, permission);
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
      unawaited(_bindPushSession());
      await loadSection(PortalSection.home);
    } on Object {
      await _store.clear();
      _api.accessToken = null;
      PushNotificationService.instance.unbindAuthenticatedSession();
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
      final body = <String, Object?>{
        'username': username.trim(),
        'password': password,
      };
      if (!kIsWeb) {
        final platform = pushPlatformName(defaultTargetPlatform);
        if (platform != 'unsupported') {
          body
            ..['device_id'] = deviceId
            ..['platform'] = platform;
        }
      }
      ApiResult result;
      try {
        // This is the canonical login contract. The deployed tenant currently
        // exposes the same session flow through role-login, so only a missing
        // route (404/405) is allowed to use the compatibility endpoint.
        result = await _api.post('/api/v1/auth/login/', body: body);
      } on ApiException catch (error) {
        if (error.statusCode != 404 && error.statusCode != 405) rethrow;
        result = await _api.post('/api/v1/auth/role-login/', body: body);
      }
      final data = result.object;
      final access = _sessionAccess(result.data);
      if (access.isEmpty) {
        throw ApiException(
          message: portalText(
            _preferences.language,
            'error.invalidLoginResponse',
          ),
          code: 'invalid_login_response',
        );
      }
      _api.accessToken = access;
      role = '${data['role'] ?? ''}'.trim().toLowerCase();
      mustChangePassword = data['must_change_password'] == true;
      await _loadProfile();
      _assertFamilyRole();
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
      unawaited(_bindPushSession());
      await loadSection(PortalSection.home, force: true);
      return true;
    } on FormatException catch (error) {
      authenticationError = error.message;
    } on ApiException catch (error) {
      authenticationError = error.message;
    } on Object {
      authenticationError = portalText(
        _preferences.language,
        'error.unexpectedLogin',
      );
    }
    _api.accessToken = null;
    role = '';
    authenticationBusy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    // Stop token-refresh callbacks before remote teardown. Otherwise a refresh
    // racing logout could recreate the device registration.
    PushNotificationService.instance.unbindAuthenticatedSession();
    if (_api.accessToken != null) {
      await _revokePushRegistrations();
      try {
        await _api.post('/api/v1/auth/logout/', body: const {});
      } on Object {
        // Local credentials still have to be removed if the server is offline.
      }
    }
    await _expireSession();
  }

  Future<void> _revokePushRegistrations() async {
    try {
      var ownedDevices = devices;
      try {
        ownedDevices = (await _getAllPages(
          '/api/v1/users/devices/',
          query: const {'page_size': 100},
        )).rows;
      } on Object {
        // Fall back to the already loaded account-device list when the listing
        // endpoint is temporarily unavailable.
      }
      final ids = ownedDevices
          .map((item) => _integer(item['id']))
          .whereType<int>()
          .toSet();
      for (final id in ids) {
        try {
          await _api.delete('/api/v1/users/devices/$id/');
        } on Object {
          // Best-effort cleanup must never trap the user inside the app.
        }
      }
    } on Object {
      // Local/offline logout must remain available. When reachable, the backend
      // logout endpoint also invalidates every token belonging to this account.
    }
  }

  Future<void> _expireSession() async {
    PushNotificationService.instance.unbindAuthenticatedSession();
    await _store.clear();
    _api.accessToken = null;
    role = '';
    profile = const {};
    mustChangePassword = false;
    _clearData();
    phase = AuthPhase.signedOut;
    notifyListeners();
  }

  Future<void> _bindPushSession() async {
    if (!isAuthenticated || deviceId.isEmpty) return;
    await PushNotificationService.instance.bindAuthenticatedSession(
      deviceId: deviceId,
      registrar: (body) async =>
          (await _api.post('/api/v1/users/devices/', body: body)).data,
    );
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

  Future<ApiResult> _optionalGet(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    try {
      final result = await _api.get(path, query: query);
      _optionalApiFailures.remove(path);
      return result;
    } on ApiException catch (error) {
      if (error.isUnauthorized) rethrow;
      _optionalApiFailures[path] = error;
      return ApiResult.failed(error);
    }
  }

  /// Drains a page-number endpoint using only the server's finite page/count
  /// metadata. Cursor feeds (notably notifications and messaging) deliberately
  /// do not use this helper, so a `next` URL can never trigger an accidental
  /// unbounded crawl.
  Future<ApiResult> _getAllPages(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final first = await _api.get(path, query: query);
    final firstRows = first.rows;
    final info = first.pageInfo;
    final requestedPageSize = _integer(query['page_size']);
    final pageSize = info.pageSize ?? requestedPageSize;
    final currentPage = info.page ?? _integer(query['page']) ?? 1;
    final totalPages =
        info.totalPages ??
        (info.total != null && pageSize != null && pageSize > 0
            ? (info.total! / pageSize).ceil()
            : null);
    if (firstRows.isEmpty ||
        totalPages == null ||
        totalPages <= currentPage ||
        currentPage < 1) {
      return first;
    }

    final rows = <Map<String, Object?>>[...firstRows];
    for (var page = currentPage + 1; page <= totalPages; page++) {
      final result = await _api.get(path, query: {...query, 'page': page});
      rows.addAll(result.rows);
    }
    return ApiResult(data: rows, pagination: first.pagination);
  }

  Future<ApiResult> _optionalGetAllPages(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    try {
      final result = await _getAllPages(path, query: query);
      _optionalApiFailures.remove(path);
      return result;
    } on ApiException catch (error) {
      if (error.isUnauthorized) rethrow;
      _optionalApiFailures[path] = error;
      return ApiResult.failed(error);
    }
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
        PortalSection.placement => _loadPlacement(),
        PortalSection.content => _loadContent(),
        PortalSection.attendance => _loadAttendance(),
        PortalSection.messages => _loadMessaging(),
        PortalSection.ai => _loadAi(),
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

  /// Read-only escape hatch for paged/detail family endpoints. Mutating API
  /// operations remain explicit controller methods so callers cannot bypass
  /// refresh and permission handling accidentally.
  Future<ApiResult> getApi(
    String path, {
    Map<String, Object?> query = const {},
  }) {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError.value(path, 'path', 'Expected an /api/v1/ path.');
    }
    return _api.get(path, query: query);
  }

  /// Notifies widgets after a caller appends a page to one of the controller's
  /// observable lists using [getApi].
  void notifyDataChanged() => notifyListeners();

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
    if (can('messaging:read')) {
      final result = await _optionalGet(
        '/api/v1/messaging/threads/',
        query: const {'page_size': 20},
      );
      if (result.isSuccessful) threads = result.rows;
    }
  }

  Future<void> _refreshUnreadNotificationCount() async {
    final result = await _optionalGet('/api/v1/notifications/unread-count/');
    if (result.isFailed) {
      unreadNotificationCount = notifications
          .where((item) => item['read_at'] == null)
          .length;
      return;
    }
    unreadNotificationCount = _integer(result.object['count']) ?? 0;
  }

  Future<void> _loadIdentity() async {
    if (isStudent) {
      final studentRows = (await _getAllPages(
        '/api/v1/students/',
        query: const {'page_size': 25},
      )).rows;
      final selectedExists = studentRows.any(
        (item) => _integer(item['id']) == selectedStudentId,
      );
      final studentId =
          (selectedExists ? selectedStudentId : null) ??
          _integer(studentRows.firstOrNull?['id']) ??
          _integer(profile['id']);
      selectedStudentId = studentId;
      final values = await Future.wait([
        if (studentId != null) _api.get('/api/v1/students/$studentId/'),
        if (studentId != null)
          _optionalGet('/api/v1/students/$studentId/events/'),
        _optionalGet('/api/v1/students/stats/'),
        _optionalGet(
          '/api/v1/students/comparison/',
          query: const {'metric': 'joined', 'unit': 'month'},
        ),
        _optionalGetAllPages(
          '/api/v1/students/birthdays/',
          query: const {'page_size': 25},
        ),
        _optionalGetAllPages(
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
      studentComparison = values[index++].object;
      birthdays = values[index++].rows;
      enrollmentReasons = values[index].rows;
      return;
    }

    if (children.isEmpty) {
      children = (await _api.get('/api/v1/parents/me/children/')).rows;
    }
    final childIds = children
        .map((item) => _integer(item['id']))
        .whereType<int>()
        .toSet();
    final studentId = childIds.contains(selectedStudentId)
        ? selectedStudentId
        : childIds.firstOrNull;
    selectedStudentId = studentId;

    final principalId = _integer(profile['id']);
    final roleNativeProfile =
        '${profile['principal_kind'] ?? ''}'.toLowerCase() == 'parent';
    if (roleNativeProfile && principalId != null) {
      parentProfile = (await _api.get('/api/v1/parents/$principalId/')).object;
    } else {
      final parentRows = (await _getAllPages(
        '/api/v1/parents/',
        query: const {'page_size': 100},
      )).rows;
      final username = '${profile['username'] ?? ''}'.trim();
      parentProfile =
          parentRows
              .where(
                (item) =>
                    (principalId != null &&
                        _integer(item['id']) == principalId) ||
                    (username.isNotEmpty && '${item['username']}' == username),
              )
              .firstOrNull ??
          (parentRows.length == 1 ? parentRows.first : const {});
    }

    final parentId = _integer(parentProfile['id']) ?? principalId;
    final familyValues = await Future.wait([
      _optionalGetAllPages(
        '/api/v1/parents/guardians/',
        query: {'page_size': 100, 'parent': ?parentId, 'student': ?studentId},
      ),
      _optionalGetAllPages(
        '/api/v1/parents/pickups/',
        query: {'page_size': 100, 'student': ?studentId},
      ),
    ]);
    guardians = familyValues[0].rows;
    pickups = familyValues[1].rows;

    if (studentId != null) {
      final childValues = await Future.wait([
        _api.get('/api/v1/students/$studentId/'),
        _optionalGet('/api/v1/students/$studentId/events/'),
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
        PortalSection.assignments,
        PortalSection.schedule,
        PortalSection.finance,
        PortalSection.attendance,
        PortalSection.academics,
        PortalSection.placement,
        PortalSection.content,
        PortalSection.ai,
        PortalSection.achievements,
        PortalSection.discipline,
        PortalSection.cards,
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
    final cohortId = _selectedCohortId;
    final values = await Future.wait([
      _getAllPages(
        '/api/v1/assignments/',
        query: {'page_size': 100, if (isParent) 'cohort': ?cohortId},
      ),
      _getAllPages(
        '/api/v1/assignments/submissions/',
        query: const {'page_size': 100},
      ),
    ]);
    assignments = values[0].rows;
    submissions = _selectedStudentRows(values[1].rows);
  }

  Future<void> _loadPlacement() async {
    // The deployed API currently scopes attempts to staff or the student who
    // owns them. Parents cannot read a linked child's attempts yet, so avoid a
    // misleading request/empty state until the backend adds guardian scoping.
    if (isParent) {
      placementAttempts = const [];
      placementTests = const [];
      return;
    }

    // Attempt list/detail are authenticated SELF actions. The backend applies
    // row-level scoping, so a student can never read somebody else's attempt.
    placementAttempts = _selectedStudentRows(
      (await _getAllPages(
        '/api/v1/placement/attempts/',
        query: {
          'page_size': 100,
          if (isParent && selectedStudentId != null)
            'student': selectedStudentId,
        },
      )).rows,
    );

    // Full test definitions contain answer keys and are staff-protected. Family
    // accounts only request them when the backend explicitly grants capability.
    if (can('placement:read') || can('placement:write')) {
      final tests = await _optionalGetAllPages(
        '/api/v1/placement/tests/',
        query: const {'page_size': 100},
      );
      placementTests = tests.isSuccessful ? tests.rows : const [];
    } else {
      placementTests = const [];
    }
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
      _getAllPages(
        '/api/v1/schedule/lessons/',
        query: {
          'page_size': 100,
          'ordering': 'starts_at',
          'date_from': start.toIso8601String(),
          'date_to': end.toIso8601String(),
          'cohort': ?selectedCohortId,
        },
      ),
      _optionalGetAllPages(
        '/api/v1/schedule/terms/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/schedule/timeslots/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/schedule/lesson-types/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/schedule/rules/',
        query: const {'page_size': 100},
      ),
      _optionalGet('/api/v1/schedule/ical-url/'),
    ]);
    lessons = values[0].rows;
    terms = values[1].rows;
    timeSlots = values[2].rows;
    lessonTypes = values[3].rows;
    scheduleRules = values[4].rows;
    calendarUrl = valueText(values[5].object, const ['url'], fallback: '');
  }

  Future<void> _loadAttendance() async {
    final studentId = selectedStudentId;
    final values = await Future.wait([
      _getAllPages(
        '/api/v1/attendance/records/',
        query: {
          'page_size': 100,
          'ordering': '-created_at',
          if (isParent) 'student': ?studentId,
        },
      ),
      if (terms.isEmpty)
        _optionalGetAllPages(
          '/api/v1/schedule/terms/',
          query: const {'page_size': 100},
        ),
    ]);
    attendance = values[0].rows;
    if (terms.isEmpty && values.length > 1) terms = values[1].rows;
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
    final studentId = selectedStudentId;
    final cohortId = _selectedCohortId;
    final values = await Future.wait([
      _optionalGetAllPages(
        '/api/v1/academics/subjects/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/academics/exam-types/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/academics/exams/',
        query: {'page_size': 100, if (isParent) 'cohort': ?cohortId},
      ),
      _getAllPages(
        '/api/v1/academics/grades/',
        query: {'page_size': 100, if (isParent) 'student': ?studentId},
      ),
      _optionalGetAllPages(
        '/api/v1/academics/transcripts/',
        query: const {'page_size': 100},
      ),
      if (terms.isEmpty)
        _optionalGetAllPages(
          '/api/v1/schedule/terms/',
          query: const {'page_size': 100},
        ),
    ]);
    subjects = values[0].rows;
    examTypes = values[1].rows;
    exams = values[2].rows;
    grades = _selectedStudentRows(values[3].rows);
    transcripts = _selectedStudentRows(values[4].rows);
    if (terms.isEmpty && values.length > 5) terms = values[5].rows;
  }

  Future<void> _loadContent() async {
    final values = await Future.wait([
      _optionalGetAllPages(
        '/api/v1/content/libraries/',
        query: const {'page_size': 100},
      ),
      _getAllPages('/api/v1/content/courses/', query: const {'page_size': 100}),
      _optionalGetAllPages(
        '/api/v1/content/modules/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/content/lessons/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/content/folders/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/content/files/',
        query: const {'page_size': 100},
      ),
      _optionalGetAllPages(
        '/api/v1/content/materials/',
        query: const {'page_size': 100},
      ),
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
      _optionalGet(
        '/api/v1/messaging/contacts/',
        query: const {'page_size': 100},
      ),
      _api.get('/api/v1/messaging/threads/', query: const {'page_size': 100}),
    ]);
    contacts = values[0].rows;
    messagingSelfUserId = _integer(values[0].pagination['self_user_id']);
    threads = values[1].rows;
  }

  Future<void> _loadAi() async {
    final result = await _optionalGet(
      '/api/v1/ai/family-assistant/',
      query: {
        if (isParent && selectedStudentId != null) 'student': selectedStudentId,
      },
    );
    if (result.isSuccessful) {
      final data = result.object;
      aiServiceAvailable = true;
      aiConversation = valueRows(data['history']);
      aiSources = valueRows(data['sources']);
      aiSuggestions = _stringRows(data['suggestions']);
      aiFallbackMode = data['fallback_used'] == true;
      if (aiConversation.isEmpty) {
        aiConversation = [_familyAssistantWelcome()];
      }
      if (aiSuggestions.isEmpty) {
        aiSuggestions = _familyAssistantSuggestions();
      }
      aiReplyError = null;
      return;
    }

    final failure = result.failure;
    if (_familyAssistantFallbackEligible(failure)) {
      // The AI page renders its own clear unavailable state. Avoid duplicating
      // that state in the global optional-endpoint warning banner.
      _optionalApiFailures.remove('/api/v1/ai/family-assistant/');
    }

    aiServiceAvailable = false;
    aiFallbackMode = false;
    aiConversation = const [];
    aiSources = const [];
    aiSuggestions = const [];
    aiReplyError =
        'AI yordamchi hali markaz tomonidan ulanmagan. Hozircha bu funksiya ishlamaydi.';
  }

  Future<void> askFamilyAssistant(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || aiReplyBusy) return;
    if (!aiServiceAvailable) {
      aiReplyError =
          'AI yordamchi hali markaz tomonidan ulanmagan. Hozircha bu funksiya ishlamaydi.';
      notifyListeners();
      return;
    }
    final optimisticId = 'local-user-${DateTime.now().microsecondsSinceEpoch}';
    aiConversation = [
      ...aiConversation,
      {
        'id': optimisticId,
        'role': 'user',
        'content': message,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
    aiReplyBusy = true;
    aiReplyError = null;
    notifyListeners();
    try {
      final result = await _api.post(
        '/api/v1/ai/family-assistant/',
        body: {
          'message': message,
          if (isParent && selectedStudentId != null)
            'student': selectedStudentId,
        },
      );
      final data = result.object;
      final serverHistory = valueRows(data['history']);
      final answer = '${data['answer'] ?? ''}'.trim();
      if (serverHistory.isNotEmpty) {
        aiConversation = serverHistory;
      } else if (answer.isNotEmpty) {
        aiConversation = [
          ...aiConversation,
          {
            'id':
                data['assistant_message_id'] ??
                'server-${DateTime.now().microsecondsSinceEpoch}',
            'role': 'assistant',
            'content': answer,
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
      }
      aiSources = valueRows(data['sources']);
      aiSuggestions = _stringRows(data['suggestions']);
      aiFallbackMode = data['fallback_used'] == true;
      aiServiceAvailable = true;
    } on ApiException catch (error) {
      if (_familyAssistantFallbackEligible(error)) {
        aiServiceAvailable = false;
        aiFallbackMode = false;
        aiConversation = aiConversation
            .where((item) => item['id'] != optimisticId)
            .toList(growable: false);
        aiReplyError =
            'AI yordamchi hali markaz tomonidan ulanmagan. Hozircha bu funksiya ishlamaydi.';
      } else {
        aiReplyError = error.message;
      }
    } on Object {
      aiReplyError = 'AI yordamchi hozir javob bera olmadi.';
    } finally {
      aiReplyBusy = false;
      notifyListeners();
    }
  }

  Map<String, Object?> _familyAssistantWelcome() => {
    'id': 'family-welcome',
    'role': 'assistant',
    'content': isParent
        ? 'Farzandingizning o‘qishi bo‘yicha savol bering. Men kabinetdagi davomat, baholar va vazifalarni bir joyda tushuntiraman.'
        : 'Salom! Vazifalar, baholar, davomat yoki bugungi o‘qish rejangiz haqida savol bering.',
    'created_at': DateTime.now().toIso8601String(),
  };

  List<String> _familyAssistantSuggestions() => isParent
      ? const [
          'Qaysi fan ko‘proq e’tibor talab qiladi?',
          'Davomat holatini tushuntir',
          'Yaqin vazifalarni ko‘rsat',
        ]
      : const [
          'Bugun nimadan boshlay?',
          'Baholarimni tahlil qil',
          'Vazifalarim uchun reja tuz',
        ];

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
    forms = (await _getAllPages(
      '/api/v1/forms/',
      query: const {'page_size': 100, 'status': 'published'},
    )).rows;
  }

  Future<void> _loadAchievements() async {
    final values = await Future.wait([
      _getAllPages(
        '/api/v1/achievements/',
        query: const {'page_size': 100, 'status': 'active'},
      ),
      _getAllPages(
        '/api/v1/achievements/mine/',
        query: const {'page_size': 100},
      ),
    ]);
    achievementCatalog = values[0].rows;
    achievementGrants = _selectedStudentRows(values[1].rows);
  }

  Future<void> _loadDiscipline() async {
    final studentId = selectedStudentId;
    final values = await Future.wait([
      _api.get('/api/v1/rulebook/rules/mine/'),
      _api.get('/api/v1/rulebook/rules/pending/'),
      _getAllPages(
        '/api/v1/rulebook/penalties/',
        query: {'page_size': 100, if (isParent) 'student': ?studentId},
      ),
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
    if (!can('card:read')) return;
    final studentId = selectedStudentId;
    if (studentId == null) return;
    final values = await Future.wait([
      _getAllPages(
        '/api/v1/cards/',
        query: {'page_size': 100, if (isParent) 'student': studentId},
      ),
      _getAllPages('/api/v1/cards/types/', query: const {'page_size': 100}),
      _api.get(
        isParent
            ? '/api/v1/cards/wallets/$studentId/'
            : '/api/v1/cards/wallets/me/',
      ),
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
    devices = (await _getAllPages(
      '/api/v1/users/devices/',
      query: const {'page_size': 100},
    )).rows;
  }

  Future<Map<String, Object?>> loadAssignmentDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/assignments/$id/',
    id: id,
    target: assignmentDetails,
    force: force,
  );

  Future<Map<String, Object?>> loadSubmissionDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/assignments/submissions/$id/',
    id: id,
    target: submissionDetails,
    force: force,
  );

  Future<Map<String, Object?>> loadAttendanceRecordDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/attendance/records/$id/',
    id: id,
    target: attendanceRecordDetails,
    force: force,
  );

  Future<Map<String, Object?>> loadScheduleLessonDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/schedule/lessons/$id/',
    id: id,
    target: scheduleLessonDetails,
    force: force,
  );

  Future<Map<String, Object?>> loadExamDetail(int id, {bool force = false}) =>
      _loadDetail(
        path: '/api/v1/academics/exams/$id/',
        id: id,
        target: examDetails,
        force: force,
      );

  Future<Map<String, Object?>> loadGradeDetail(int id, {bool force = false}) =>
      _loadDetail(
        path: '/api/v1/academics/grades/$id/',
        id: id,
        target: gradeDetails,
        force: force,
      );

  Future<Map<String, Object?>> loadTranscriptDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/academics/transcripts/$id/',
    id: id,
    target: transcriptDetails,
    force: force,
  );

  Future<Map<String, Object?>> loadPlacementAttemptDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/placement/attempts/$id/',
    id: id,
    target: placementAttemptDetails,
    force: force,
  );

  Future<List<Map<String, Object?>>> loadPlacementSuggestions(
    int attemptId, {
    bool force = false,
  }) async {
    if (!can('placement:write')) {
      throw const ApiException(
        message: 'Guruh tavsiyalari faqat vakolatli xodimlar uchun.',
        code: 'forbidden',
        statusCode: 403,
      );
    }
    final cached = placementSuggestions[attemptId];
    if (!force && cached != null) return cached;
    final rows = (await _api.get(
      '/api/v1/placement/attempts/$attemptId/suggestions/',
    )).rows;
    placementSuggestions[attemptId] = rows;
    lastSuccessfulSyncAt = DateTime.now();
    connectionIssue = false;
    notifyListeners();
    return rows;
  }

  Future<Map<String, Object?>> submitPlacementAttempt(
    int attemptId,
    List<Map<String, Object?>> answers,
  ) async {
    if (!isStudent) {
      throw const ApiException(
        message: 'Daraja sinovini faqat o‘quvchi topshirishi mumkin.',
        code: 'forbidden',
        statusCode: 403,
      );
    }
    final result = (await _api.post(
      '/api/v1/placement/attempts/$attemptId/submit/',
      body: {'answers': answers},
    )).object;
    placementAttemptDetails[attemptId] = result;
    placementAttempts = [
      for (final attempt in placementAttempts)
        if (_integer(attempt['id']) == attemptId)
          {...attempt, ...result}
        else
          attempt,
    ];
    lastSuccessfulSyncAt = DateTime.now();
    connectionIssue = false;
    notifyListeners();
    await refresh(PortalSection.placement);
    return placementAttemptDetails[attemptId] ?? result;
  }

  Future<Map<String, Object?>> loadAchievementDetail(
    int id, {
    bool force = false,
  }) => _loadDetail(
    path: '/api/v1/achievements/$id/',
    id: id,
    target: achievementDetails,
    force: force,
  );

  Future<Map<String, Object?>> loadCardDetail(int id, {bool force = false}) =>
      _loadDetail(
        path: '/api/v1/cards/$id/',
        id: id,
        target: cardDetails,
        force: force,
      );

  Future<Map<String, Object?>> loadContentDetail(
    String resource,
    int id, {
    bool force = false,
  }) {
    const resources = {
      'libraries',
      'courses',
      'modules',
      'lessons',
      'folders',
      'files',
      'materials',
    };
    if (!resources.contains(resource)) {
      throw ArgumentError.value(resource, 'resource');
    }
    final target = contentDetails.putIfAbsent(resource, () => {});
    final path = switch (resource) {
      'libraries' => '/api/v1/content/libraries/$id/',
      'courses' => '/api/v1/content/courses/$id/',
      'modules' => '/api/v1/content/modules/$id/',
      'lessons' => '/api/v1/content/lessons/$id/',
      'folders' => '/api/v1/content/folders/$id/',
      'files' => '/api/v1/content/files/$id/',
      'materials' => '/api/v1/content/materials/$id/',
      _ => throw StateError('Unreachable content resource.'),
    };
    return _loadDetail(path: path, id: id, target: target, force: force);
  }

  Future<Map<String, Object?>> _loadDetail({
    required String path,
    required int id,
    required Map<int, Map<String, Object?>> target,
    required bool force,
  }) async {
    final cached = target[id];
    if (!force && cached != null) return cached;
    final value = (await _api.get(path)).object;
    target[id] = value;
    lastSuccessfulSyncAt = DateTime.now();
    connectionIssue = false;
    notifyListeners();
    return value;
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
    final rawFields = grant['fields'];
    final fields = rawFields is Map
        ? <String, String>{
            for (final entry in rawFields.entries)
              '${entry.key}': '${entry.value}',
          }
        : const <String, String>{};
    final method = '${grant['method'] ?? (fields.isEmpty ? 'PUT' : 'POST')}'
        .trim()
        .toUpperCase();
    if (url.isEmpty ||
        key.isEmpty ||
        (method == 'POST' && fields.isEmpty) ||
        (method != 'POST' && method != 'PUT')) {
      throw const ApiException(
        message: 'Yuklash ruxsati noto‘g‘ri qaytdi.',
        code: 'invalid_upload_grant',
      );
    }
    if (method == 'POST') {
      await _api.uploadMultipartBytes(
        url,
        bytes,
        filename: filename,
        contentType: contentType,
        fields: fields,
      );
    } else {
      await _api.uploadBytes(url, bytes, contentType: contentType);
    }
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
    // The POST is the transactional boundary. A later refresh failure must not
    // make the composer retry a message whose one-time attachment grant was
    // already consumed by the server.
    try {
      await loadMessages(threadId, force: true);
      await refresh(PortalSection.messages);
    } on ApiException {
      // Polling will reconcile the successfully-created message shortly.
    }
  }

  Future<void> editMessage({
    required int threadId,
    required int messageId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) {
      throw const ApiException(
        message: 'Xabar matni bo‘sh bo‘lishi mumkin emas.',
        code: 'validation_error',
      );
    }
    await _api.patch(
      '/api/v1/messaging/messages/$messageId/',
      body: {'body': text},
    );
    await loadMessages(threadId, force: true);
  }

  Future<void> deleteMessage({
    required int threadId,
    required int messageId,
  }) async {
    await _api.delete('/api/v1/messaging/messages/$messageId/');
    final cached = messages[threadId];
    if (cached != null) {
      messages[threadId] = [
        for (final message in cached)
          if (_integer(message['id']) != messageId) message,
      ];
      notifyListeners();
    }
    await loadMessages(threadId, force: true);
  }

  Future<void> setMessageReaction({
    required int threadId,
    required int messageId,
    required String emoji,
    required bool remove,
  }) async {
    final normalized = emoji.trim();
    if (normalized.isEmpty) return;
    if (remove) {
      final encoded = Uri.encodeComponent(normalized);
      await _api.delete(
        '/api/v1/messaging/messages/$messageId/reactions/$encoded/',
      );
    } else {
      await _api.post(
        '/api/v1/messaging/messages/$messageId/reactions/',
        body: {'emoji': normalized},
      );
    }
    await loadMessages(threadId, force: true);
  }

  Map<String, Object?> messagingContactByUserId(int? userId) {
    if (userId == null) return const {};
    final contact = contacts
        .where((item) => _integer(item['user_id'] ?? item['id']) == userId)
        .firstOrNull;
    final detail = messagingContactProfiles[userId];
    if (contact == null) return detail ?? const {};
    if (detail == null) return contact;
    final merged = <String, Object?>{
      ...contact,
      ...detail,
      'id': contact['id'],
      'user_id': userId,
    };
    // Directory rows are refreshed more often than full profiles. Prefer their
    // fresh signed avatar URL over a cached URL that may have expired.
    for (final key in const ['avatar_url', 'photo_url', 'profile_photo_url']) {
      final value = '${contact[key] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') merged[key] = contact[key];
    }
    return merged;
  }

  Future<Map<String, Object?>> loadMessagingContactProfile(
    Map<String, Object?> contact, {
    bool force = false,
  }) async {
    final userId = _integer(contact['user_id'] ?? contact['id']);
    if (userId == null) return contact;
    final directory = contacts
        .where((item) => _integer(item['user_id'] ?? item['id']) == userId)
        .firstOrNull;
    final base = <String, Object?>{
      ...contact,
      ...?directory,
      'user_id': userId,
    };
    final cached = messagingContactProfiles[userId];
    if (!force && cached?['_profile_detail_loaded'] == true) {
      return messagingContactByUserId(userId);
    }
    if (!force && cached?['_profile_detail_attempted'] == true) {
      return messagingContactByUserId(userId);
    }
    if (!force && _loadingMessagingContactProfiles.contains(userId)) {
      return messagingContactByUserId(userId);
    }
    final profileId = _integer(base['profile_id']);
    final kind = _value(base, const ['principal_kind'], fallback: '');
    final rolePath = switch ((kind, profileId)) {
      ('student', final int id) => '/api/v1/students/$id/',
      ('teacher', final int id) => '/api/v1/teachers/$id/',
      ('staff', final int id) => '/api/v1/org/staff/$id/',
      ('parent', final int id) => '/api/v1/parents/$id/',
      _ => '',
    };
    // The live API exposes role detail and student leadership endpoints, but
    // intentionally has no messaging contact-detail route.
    // openapi-operation: GET /api/v1/students/{}/leadership-profile/
    final paths = <String>[
      if (rolePath.isNotEmpty) rolePath,
      if (kind == 'student' && profileId != null)
        '/api/v1/students/$profileId/leadership-profile/',
    ];
    _loadingMessagingContactProfiles.add(userId);
    try {
      var merged = <String, Object?>{...base};
      var loaded = false;
      for (final path in paths) {
        try {
          final detail = (await _api.get(path)).object;
          merged = {...merged, ..._normalizedContactDetail(detail)};
          loaded = true;
        } on ApiException catch (error) {
          // Family accounts may not read another role's private directory
          // record. Keep the permitted contact/thread data in that case.
          if (error.statusCode != 403 &&
              error.statusCode != 404 &&
              error.statusCode != 405) {
            rethrow;
          }
        }
      }
      messagingContactProfiles[userId] = {
        ...merged,
        'id': base['id'],
        'user_id': userId,
        'profile_id': profileId,
        '_profile_detail_attempted': true,
        '_profile_detail_loaded': loaded,
      };
    } finally {
      _loadingMessagingContactProfiles.remove(userId);
    }
    notifyListeners();
    return messagingContactByUserId(userId);
  }

  Map<String, Object?> _normalizedContactDetail(Map<String, Object?> detail) {
    final identity = detail['identity'] is Map
        ? Map<String, Object?>.from(detail['identity'] as Map)
        : const <String, Object?>{};
    final branch = identity['branch'] is Map
        ? Map<String, Object?>.from(identity['branch'] as Map)
        : const <String, Object?>{};
    final group = identity['current_group'] is Map
        ? Map<String, Object?>.from(identity['current_group'] as Map)
        : const <String, Object?>{};
    final department = group['department'] is Map
        ? Map<String, Object?>.from(group['department'] as Map)
        : const <String, Object?>{};
    final photo = identity['photo'] is Map
        ? Map<String, Object?>.from(identity['photo'] as Map)
        : const <String, Object?>{};
    final learning = detail['learning'] is Map
        ? Map<String, Object?>.from(detail['learning'] as Map)
        : const <String, Object?>{};
    final metadata = detail['record_metadata'] is Map
        ? Map<String, Object?>.from(detail['record_metadata'] as Map)
        : const <String, Object?>{};
    final memberships = detail['role_memberships'] is List
        ? detail['role_memberships'] as List
        : detail['account_type_assignments'] is List
        ? detail['account_type_assignments'] as List
        : const [];
    final membership = memberships.whereType<Map>().firstOrNull;
    return <String, Object?>{
      ...detail,
      ...identity,
      if (identity['public_student_id'] != null)
        'student_id': identity['public_student_id'],
      if (branch['name'] != null) 'branch_name': branch['name'],
      if (group['name'] != null) 'current_cohort_name': group['name'],
      if ('${identity['academic_level'] ?? ''}'.trim().isEmpty &&
          group['level'] != null)
        'academic_level': group['level'],
      if (department['name'] != null) 'department_name': department['name'],
      if (photo['download_url'] != null) 'avatar_url': photo['download_url'],
      if (learning['subjects'] != null) 'subjects': learning['subjects'],
      if (metadata['created_at'] != null) 'created_at': metadata['created_at'],
      if (membership?['branch_name'] != null)
        'branch_name': membership?['branch_name'],
      if (membership?['department_name'] != null)
        'department_name': membership?['department_name'],
    };
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
    final method = valueText(grant, const [
      'method',
    ], fallback: fields.isEmpty ? 'PUT' : 'POST').toUpperCase();
    if (url.isEmpty ||
        key.isEmpty ||
        (method == 'POST' && fields.isEmpty) ||
        (method != 'POST' && method != 'PUT')) {
      throw const ApiException(
        message: 'Fayl yuklash ruxsati noto‘g‘ri qaytdi.',
        code: 'invalid_upload_grant',
      );
    }
    if (method == 'POST') {
      await _api.uploadMultipartBytes(
        url,
        bytes,
        filename: filename,
        contentType: contentType,
        fields: fields,
      );
    } else {
      await _api.uploadBytes(url, bytes, contentType: contentType);
    }
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

  Future<void> forwardMessage({
    required int sourceThreadId,
    required int targetThreadId,
    required Map<String, Object?> message,
  }) async {
    final forwardedAttachments = <String>[];
    final rawAttachments = message['attachments'];
    if (rawAttachments is List) {
      for (final raw in rawAttachments.take(10)) {
        final key = _messageStorageKey(raw);
        if (key.isEmpty) continue;
        final url = await messageAttachmentDownloadUrl(sourceThreadId, key);
        final bytes = await _api.downloadBytes(url);
        final filename = _messageStorageFilename(key);
        forwardedAttachments.add(
          await uploadMessageFile(
            filename: filename,
            contentType: _messageForwardContentType(filename),
            bytes: bytes,
          ),
        );
      }
    }
    final body = valueText(message, const ['body'], fallback: '');
    final forwardedBody = body.isEmpty ? '' : '↪ Forwarded message\n$body';
    await sendMessage(
      targetThreadId,
      forwardedBody,
      attachments: forwardedAttachments,
    );
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

  Future<void> markAllNotificationsRead({bool refreshAfter = true}) async {
    await _api.post('/api/v1/notifications/read-all/', body: const {});
    final readAt = DateTime.now().toUtc().toIso8601String();
    notifications = [
      for (final row in notifications)
        if (row['read_at'] == null) {...row, 'read_at': readAt} else row,
    ];
    unreadNotificationCount = 0;
    notifyDataChanged();
    if (refreshAfter) await refresh(PortalSection.notifications);
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
    if (isStudent) {
      studentProfile = {...studentProfile, ...profile};
    } else if (isParent) {
      parentProfile = {...parentProfile, ...profile};
    }
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

  int? get _selectedCohortId {
    if (isStudent) return _integer(profile['current_cohort']);
    final child = children
        .where((item) => _integer(item['id']) == selectedStudentId)
        .firstOrNull;
    return _integer(child?['current_cohort']);
  }

  List<Map<String, Object?>> _selectedStudentRows(
    List<Map<String, Object?>> rows,
  ) {
    if (!isParent || selectedStudentId == null) return rows;
    return [
      for (final row in rows)
        if (_rowStudentId(row) case final id? when id == selectedStudentId)
          row
        else if (_rowStudentId(row) == null)
          row,
    ];
  }

  int? _rowStudentId(Map<String, Object?> row) {
    final raw = row['student'] ?? row['student_id'];
    if (raw is Map) return _integer(raw['id']);
    return _integer(raw);
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
    _optionalApiFailures.clear();
    dashboard = report = const {};
    studentProfile = studentStats = studentComparison = parentProfile =
        const {};
    children = studentEvents = birthdays = enrollmentReasons = guardians =
        pickups = assignments = submissions = lessons = terms = timeSlots =
            lessonTypes = scheduleRules = attendance = const [];
    calendarUrl = '';
    attendanceSummary = const {};
    subjects = examTypes = exams = grades = transcripts = const [];
    placementAttempts = placementTests = const [];
    libraries = courses = modules = contentLessons = folders = files =
        materials = const [];
    notifications = notificationPreferences = contacts = threads = forms =
        const [];
    messagingContactProfiles.clear();
    _loadingMessagingContactProfiles.clear();
    aiRequests = const [];
    aiBudget = aiUsage = const {};
    aiConversation = aiSources = const [];
    aiSuggestions = const [];
    aiReplyBusy = false;
    aiReplyError = null;
    aiFallbackMode = false;
    aiServiceAvailable = false;
    achievementCatalog = achievementGrants = rules = pendingRules = penalties =
        cards = cardTypes = cardScans = devices = const [];
    messages.clear();
    loadingMessageThreads.clear();
    messageErrors.clear();
    assignmentDetails.clear();
    submissionDetails.clear();
    attendanceRecordDetails.clear();
    scheduleLessonDetails.clear();
    examDetails.clear();
    gradeDetails.clear();
    transcriptDetails.clear();
    placementAttemptDetails.clear();
    placementSuggestions.clear();
    achievementDetails.clear();
    cardDetails.clear();
    contentDetails.clear();
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
    PushNotificationService.instance.unbindAuthenticatedSession();
    _preferences.removeListener(_syncPreferences);
    _api.close();
    super.dispose();
  }

  void _syncPreferences() {
    _api.acceptLanguage = _preferences.language.code;
    notifyListeners();
  }
}

bool _familyAssistantFallbackEligible(ApiException? error) {
  if (error == null) return false;
  return const {404, 405, 502, 503, 504}.contains(error.statusCode) ||
      error.code == 'service_unavailable';
}

Set<String> _permissionValues(Object? raw, {required bool revoked}) {
  if (raw is Map) {
    final keys = revoked
        ? const ['revoked', 'revoked_permissions', 'revoked_permission_codes']
        : const ['permissions', 'granted', 'permission_codes', 'effective'];
    return {
      for (final key in keys) ..._permissionValues(raw[key], revoked: false),
    };
  }
  if (raw is String) {
    final value = raw.trim();
    return value.isEmpty || value == 'null' ? const {} : {value};
  }
  if (raw is! Iterable) return const {};
  return {
    for (final value in raw)
      if ('$value'.trim().isNotEmpty && '$value'.trim() != 'null')
        '$value'.trim(),
  };
}

bool _permissionSetAllows(Set<String> codes, String permission) {
  if (codes.contains('*:*') || codes.contains(permission)) return true;
  final separator = permission.indexOf(':');
  final resource = separator < 0
      ? permission
      : permission.substring(0, separator);
  return codes.contains('$resource:*');
}

Map<int, Map<String, Object?>> latestAssignmentSubmissions(
  Iterable<Map<String, Object?>> rows,
) {
  final latest = <int, Map<String, Object?>>{};
  for (final row in rows) {
    final assignmentId = _integer(row['assignment']);
    if (assignmentId == null) continue;
    final current = latest[assignmentId];
    if (current == null || _isLaterSubmission(row, current)) {
      latest[assignmentId] = row;
    }
  }
  return latest;
}

bool assignmentAcceptsAnotherSubmission(
  Map<String, Object?> assignment,
  Map<String, Object?>? latestSubmission,
) {
  if ('${assignment['status']}'.trim().toLowerCase() != 'published') {
    return false;
  }
  if (latestSubmission == null) return true;

  final maxResubmits = _integer(assignment['max_resubmits']);
  if (maxResubmits == null) {
    // The API falls back to the center-wide limit when this field is null. Keep
    // the server authoritative instead of incorrectly locking the student out.
    return true;
  }
  final attempt = _integer(latestSubmission['attempt_number']) ?? 1;
  return attempt < maxResubmits + 1;
}

bool _isLaterSubmission(
  Map<String, Object?> candidate,
  Map<String, Object?> current,
) {
  final candidateAttempt = _integer(candidate['attempt_number']) ?? 0;
  final currentAttempt = _integer(current['attempt_number']) ?? 0;
  if (candidateAttempt != currentAttempt) {
    return candidateAttempt > currentAttempt;
  }

  final candidateTime = DateTime.tryParse('${candidate['submitted_at'] ?? ''}');
  final currentTime = DateTime.tryParse('${current['submitted_at'] ?? ''}');
  if (candidateTime != null && currentTime != null) {
    final comparison = candidateTime.compareTo(currentTime);
    if (comparison != 0) return comparison > 0;
  } else if (candidateTime != null) {
    return true;
  }

  return (_integer(candidate['id']) ?? 0) > (_integer(current['id']) ?? 0);
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

List<String> _stringRows(Object? value) => value is Iterable
    ? [
        for (final item in value)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ]
    : const [];

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

String _sessionAccess(Object? value) {
  const keys = {'access', 'access_token', 'token', 'session_key', 'key'};
  if (value is Map) {
    for (final key in keys) {
      final text = value[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    for (final nestedKey in const ['session', 'data', 'credentials']) {
      final nested = _sessionAccess(value[nestedKey]);
      if (nested.isNotEmpty) return nested;
    }
  }
  return '';
}

String _messageStorageKey(Object? value) {
  if (value is Map) {
    for (final field in const [
      'key',
      'attachment_key',
      'file_key',
      'storage_key',
      'path',
    ]) {
      final text = '${value[field] ?? ''}'.trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }
  final text = '${value ?? ''}'.trim();
  return text == 'null' ? '' : text;
}

String _messageStorageFilename(String key) {
  final name = Uri.decodeComponent(key.split('?').first.split('/').last);
  final normalized = name.replaceFirst(
    RegExp(r'^[0-9a-f]{8,}-', caseSensitive: false),
    '',
  );
  return normalized.isEmpty ? 'forwarded-file' : normalized;
}

String _messageForwardContentType(String filename) {
  final extension = filename.toLowerCase().split('.').last;
  return switch (extension) {
    'pdf' => 'application/pdf',
    'mp3' => 'audio/mpeg',
    'm4a' || 'aac' => 'audio/mp4',
    'ogg' => 'audio/ogg',
    'opus' => 'audio/opus',
    'wav' => 'audio/wav',
    'webm' =>
      filename.toLowerCase().contains('voice-') ? 'audio/webm' : 'video/webm',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'mp4' || 'm4v' => 'video/mp4',
    'mov' => 'video/quicktime',
    '3gp' => 'video/3gpp',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt' => 'text/plain',
    _ => 'application/octet-stream',
  };
}
