import 'dart:async';

import 'package:flutter/foundation.dart';

enum FamilyMessageStatus { delivered, localOnly, sending, failed }

final class FamilyMessage {
  const FamilyMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.status,
    this.clientRequestId,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final FamilyMessageStatus status;
  final String? clientRequestId;

  FamilyMessage copyWith({String? id, FamilyMessageStatus? status}) =>
      FamilyMessage(
        id: id ?? this.id,
        threadId: threadId,
        senderId: senderId,
        body: body,
        createdAt: createdAt,
        status: status ?? this.status,
        clientRequestId: clientRequestId,
      );

  factory FamilyMessage.fromJson(
    Map<String, Object?> json, {
    required String threadId,
  }) => FamilyMessage(
    id: _required(json['id'], 'message.id'),
    threadId: '${json['thread_id'] ?? json['thread'] ?? threadId}',
    senderId: _required(
      json['sender_id'] ?? json['sender'],
      'message.sender_id',
    ),
    body: _required(json['body'], 'message.body'),
    createdAt:
        DateTime.tryParse('${json['created_at']}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    status: FamilyMessageStatus.delivered,
  );
}

final class FamilyThread {
  const FamilyThread({
    required this.id,
    required this.title,
    required this.subject,
    required this.participantIds,
    required this.messages,
    required this.unreadCount,
    required this.isMuted,
  });

  final String id;
  final String title;
  final String subject;
  final List<String> participantIds;
  final List<FamilyMessage> messages;
  final int unreadCount;
  final bool isMuted;

  FamilyThread copyWith({
    List<FamilyMessage>? messages,
    int? unreadCount,
    bool? isMuted,
  }) => FamilyThread(
    id: id,
    title: title,
    subject: subject,
    participantIds: participantIds,
    messages: messages ?? this.messages,
    unreadCount: unreadCount ?? this.unreadCount,
    isMuted: isMuted ?? this.isMuted,
  );
}

abstract interface class FamilyMessagingRepository {
  bool get isLocalPreview;
  String get connectionLabel;

  Future<FamilyMessage> sendText({
    required String scopeKey,
    required String threadId,
    required String senderId,
    required String body,
    required String clientRequestId,
  });
}

final class LocalFamilyMessagingRepository
    implements FamilyMessagingRepository {
  const LocalFamilyMessagingRepository();

  @override
  bool get isLocalPreview => true;

  @override
  String get connectionLabel => 'Lokal yozishma';

  @override
  Future<FamilyMessage> sendText({
    required String scopeKey,
    required String threadId,
    required String senderId,
    required String body,
    required String clientRequestId,
  }) async => FamilyMessage(
    id: 'local-$clientRequestId',
    threadId: threadId,
    senderId: senderId,
    body: body,
    createdAt: DateTime.now(),
    status: FamilyMessageStatus.localOnly,
    clientRequestId: clientRequestId,
  );
}

/// Role-scoped chat state. Names are display-only; all mutations use thread ids.
final class FamilyMessagingController extends ChangeNotifier {
  FamilyMessagingController({
    FamilyMessagingRepository? repository,
    required DateTime now,
  }) : _repository = repository ?? const LocalFamilyMessagingRepository() {
    _seedPreview(now);
  }

  final FamilyMessagingRepository _repository;
  final Map<String, List<FamilyThread>> _threadsByScope = {};
  final Map<String, Map<String, String>> _draftsByScope = {};
  final Map<String, int> _scopeGeneration = {};

  bool get isLocalPreview => _repository.isLocalPreview;
  String get connectionLabel => _repository.connectionLabel;

  static String scopeKey({
    required String tenant,
    required String userId,
    required String role,
  }) => '$tenant:$userId:$role';

  List<FamilyThread> threads(String scope) =>
      List.unmodifiable(_threadsByScope[scope] ?? const <FamilyThread>[]);

  FamilyThread? thread(String scope, String id) {
    for (final item in _threadsByScope[scope] ?? const <FamilyThread>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  String draft(String scope, String threadId) =>
      _draftsByScope[scope]?[threadId] ?? '';

  void setDraft(String scope, String threadId, String value) {
    final drafts = _draftsByScope.putIfAbsent(scope, () => {});
    final normalized = value.trimRight();
    if (normalized.isEmpty) {
      drafts.remove(threadId);
    } else {
      drafts[threadId] = value;
    }
  }

  void toggleMuted(String scope, String threadId) {
    _updateThread(
      scope,
      threadId,
      (thread) => thread.copyWith(isMuted: !thread.isMuted),
    );
  }

  void markRead(String scope, String threadId) {
    _updateThread(
      scope,
      threadId,
      (thread) =>
          thread.unreadCount == 0 ? thread : thread.copyWith(unreadCount: 0),
    );
  }

  Future<bool> sendText({
    required String scope,
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty || thread(scope, threadId) == null) return false;
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final generation = _scopeGeneration[scope] ?? 0;
    final pending = FamilyMessage(
      id: 'pending-$requestId',
      threadId: threadId,
      senderId: senderId,
      body: body,
      createdAt: DateTime.now(),
      status: FamilyMessageStatus.sending,
      clientRequestId: requestId,
    );
    _append(scope, threadId, pending);
    setDraft(scope, threadId, '');
    try {
      final resolved = await _repository.sendText(
        scopeKey: scope,
        threadId: threadId,
        senderId: senderId,
        body: body,
        clientRequestId: requestId,
      );
      if ((_scopeGeneration[scope] ?? 0) != generation) return false;
      _replaceMessage(scope, threadId, requestId, resolved);
      return true;
    } on Object {
      if ((_scopeGeneration[scope] ?? 0) != generation) return false;
      _replaceMessage(
        scope,
        threadId,
        requestId,
        pending.copyWith(status: FamilyMessageStatus.failed),
      );
      return false;
    }
  }

  Future<bool> retry(String scope, String threadId, String messageId) async {
    final item = thread(
      scope,
      threadId,
    )?.messages.where((message) => message.id == messageId);
    if (item == null || item.isEmpty) return false;
    final message = item.first;
    if (message.status != FamilyMessageStatus.failed) return false;
    _removeMessage(scope, threadId, messageId);
    return sendText(
      scope: scope,
      threadId: threadId,
      senderId: message.senderId,
      text: message.body,
    );
  }

  void clearScope(String scope) {
    _scopeGeneration[scope] = (_scopeGeneration[scope] ?? 0) + 1;
    _threadsByScope.remove(scope);
    _draftsByScope.remove(scope);
    notifyListeners();
  }

  void resetPreview(DateTime now) {
    for (final scope in _threadsByScope.keys.toList()) {
      _scopeGeneration[scope] = (_scopeGeneration[scope] ?? 0) + 1;
    }
    _threadsByScope.clear();
    _draftsByScope.clear();
    _seedPreview(now);
    notifyListeners();
  }

  void _seedPreview(DateTime now) {
    for (final role in const ['student', 'parent']) {
      final userId = role == 'student' ? 'student-101' : 'parent-101';
      final scope = scopeKey(
        tenant: 'preview-center',
        userId: userId,
        role: role,
      );
      _scopeGeneration[scope] = 0;
      _threadsByScope[scope] = [
        _previewThread(
          id: '$role-thread-algebra',
          title: 'Nigora Karimova',
          subject: 'Algebra',
          selfId: userId,
          now: now,
          incoming: role == 'student'
              ? 'Akmal, 8-misol yechimini tekshirib chiqdim.'
              : 'Akmalning algebra bo‘yicha haftalik natijasi tayyor.',
          outgoing: role == 'student'
              ? 'Rahmat, ustoz. Xatoni tushundim.'
              : 'Rahmat, natijani ko‘rib chiqaman.',
        ),
        _previewThread(
          id: '$role-thread-geometry',
          title: 'Bobur Aliyev',
          subject: 'Geometriya',
          selfId: userId,
          now: now.subtract(const Duration(days: 1)),
          incoming: 'Ertaga uchburchaklar mavzusini davom ettiramiz.',
        ),
        _previewThread(
          id: '$role-thread-english',
          title: 'Aziz Tursunov',
          subject: 'Ingliz tili',
          selfId: userId,
          now: now.subtract(const Duration(days: 3)),
          incoming: 'Unit 8 audio materiali ochiq.',
        ),
      ];
    }
  }

  FamilyThread _previewThread({
    required String id,
    required String title,
    required String subject,
    required String selfId,
    required DateTime now,
    required String incoming,
    String? outgoing,
  }) => FamilyThread(
    id: id,
    title: title,
    subject: subject,
    participantIds: [selfId, 'teacher-${id.split('-').last}'],
    unreadCount: 0,
    isMuted: false,
    messages: [
      FamilyMessage(
        id: '$id-incoming',
        threadId: id,
        senderId: 'teacher-${id.split('-').last}',
        body: incoming,
        createdAt: now.subtract(const Duration(minutes: 4)),
        status: FamilyMessageStatus.delivered,
      ),
      if (outgoing != null)
        FamilyMessage(
          id: '$id-outgoing',
          threadId: id,
          senderId: selfId,
          body: outgoing,
          createdAt: now,
          status: FamilyMessageStatus.localOnly,
        ),
    ],
  );

  void _append(String scope, String threadId, FamilyMessage message) {
    _updateThread(
      scope,
      threadId,
      (thread) => thread.copyWith(messages: [...thread.messages, message]),
    );
  }

  void _replaceMessage(
    String scope,
    String threadId,
    String clientRequestId,
    FamilyMessage replacement,
  ) {
    _updateThread(
      scope,
      threadId,
      (thread) => thread.copyWith(
        messages: [
          for (final item in thread.messages)
            if (item.clientRequestId == clientRequestId) replacement else item,
        ],
      ),
    );
  }

  void _removeMessage(String scope, String threadId, String messageId) {
    _updateThread(
      scope,
      threadId,
      (thread) => thread.copyWith(
        messages: [
          for (final item in thread.messages)
            if (item.id != messageId) item,
        ],
      ),
    );
  }

  void _updateThread(
    String scope,
    String threadId,
    FamilyThread Function(FamilyThread) update,
  ) {
    final threads = _threadsByScope[scope];
    if (threads == null) return;
    final index = threads.indexWhere((item) => item.id == threadId);
    if (index < 0) return;
    final next = update(threads[index]);
    if (identical(next, threads[index])) return;
    threads[index] = next;
    notifyListeners();
  }
}

String _required(Object? value, String field) {
  final result = value?.toString().trim() ?? '';
  if (result.isEmpty || result == 'null') {
    throw FormatException('$field is required.');
  }
  return result;
}
