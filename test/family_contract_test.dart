import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/app_state.dart';
import 'package:starforge_student/family_data.dart';
import 'package:starforge_student/family_messaging.dart';

void main() {
  group('staff-shaped family projections', () {
    late AppState state;

    setUp(() {
      SfClock.now = () => DateTime(2026, 7, 28, 12);
      state = AppState();
    });

    tearDown(() {
      state.dispose();
      SfClock.now = DateTime.now;
    });

    test(
      'published assignments are visible and raw statuses are preserved',
      () {
        final accepted = state.receiveFamilyResource(
          FamilyResource.assignments,
          {
            'success': true,
            'data': [
              {
                'id': 8,
                'cohort': 42,
                'cohort_name': '9-B Algebra',
                'title': 'Quadratic equations',
                'description': 'Solve every exercise.',
                'due_at': '2026-07-30T18:00:00+05:00',
                'max_score': '100',
                'status': 'published',
                'published_at': '2026-07-20T10:00:00Z',
              },
              {
                'id': 9,
                'cohort': 42,
                'cohort_name': '9-B Algebra',
                'title': 'Teacher draft',
                'due_at': '2026-08-01T18:00:00+05:00',
                'status': 'quality_review',
                'published_at': null,
              },
            ],
          },
        );

        expect(accepted, isTrue);
        expect(state.familyData.origin, FamilyDataOrigin.server);
        expect(state.familyData.assignments.last.statusRaw, 'quality_review');
        expect(state.familyData.visibleAssignments.map((item) => item.id), [
          '8',
        ]);
      },
    );

    test('submission accepts numeric assignment id and exposes own grade', () {
      expect(
        state.receiveFamilyResource(FamilyResource.submissions, {
          'results': [
            {
              'id': 31,
              'assignment': 8,
              'assignment_title': 'Quadratic equations',
              'submitted_at': '2026-07-28T13:00:00Z',
              'is_late': false,
              'attempt_number': 1,
              'status': 'graded',
              'grade': {
                'score': '92',
                'feedback': 'Good work',
                'graded_by': 17,
                'graded_at': '2026-07-29T09:00:00Z',
              },
            },
          ],
          'next': null,
        }),
        isTrue,
      );

      final submission = state.familyData.submissions.single;
      expect(submission.assignmentId, '8');
      expect(submission.grade?.score, 92);
      expect(state.familyData.grades.single.percent, 92);
    });

    test('attendance and schedule retain unknown server status safely', () {
      expect(
        state.receiveFamilyResource(FamilyResource.attendance, {
          'data': [
            {
              'id': 99,
              'lesson': 700,
              'lesson_title': 'Linear equations',
              'lesson_starts_at': '2026-07-10T09:00:00Z',
              'status': 'remote_join',
            },
          ],
        }),
        isTrue,
      );
      expect(state.familyData.attendance.single.lessonId, '700');
      expect(state.familyData.attendance.single.statusRaw, 'remote_join');

      expect(
        state.receiveFamilyResource(FamilyResource.lessons, {
          'data': [
            {
              'id': 700,
              'teacher': 17,
              'teacher_name': 'Server Teacher',
              'room': 304,
              'room_name': '304',
              'title': 'Linear equations',
              'status': 'cancelled',
              'starts_at': '2026-07-30T09:00:00Z',
              'ends_at': '2026-07-30T10:00:00Z',
              'cancel_reason': 'Teacher is unavailable',
            },
          ],
        }),
        isTrue,
      );
      expect(state.familyData.lessons.single.isCancelled, isTrue);
      expect(
        state.familyData.lessons.single.cancelReason,
        'Teacher is unavailable',
      );
    });

    test('materials fail closed on visibility and publication', () {
      expect(
        state.receiveFamilyResource(FamilyResource.materials, {
          'data': [
            {
              'id': 1,
              'title': 'Visible book',
              'status': 'published',
              'visibility': 'family',
              'is_active': true,
              'is_downloadable': true,
            },
            {
              'id': 2,
              'title': 'Staff notes',
              'status': 'published',
              'visibility': 'staff',
              'is_active': true,
            },
            {
              'id': 3,
              'title': 'Unpublished',
              'status': 'draft',
              'visibility': 'family',
              'is_active': true,
            },
          ],
        }),
        isTrue,
      );
      expect(state.familyData.visibleMaterials.map((item) => item.title), [
        'Visible book',
      ]);
    });

    test(
      'materials fail closed when visibility or active state is missing or unknown',
      () {
        expect(
          state.receiveFamilyResource(FamilyResource.materials, {
            'data': [
              {
                'id': 10,
                'title': 'Missing policy',
                'status': 'published',
                'is_downloadable': true,
              },
              {
                'id': 11,
                'title': 'Unknown visibility',
                'status': 'published',
                'visibility': 'unknown',
                'is_active': true,
              },
              {
                'id': 12,
                'title': 'Missing active state',
                'status': 'published',
                'visibility': 'family',
              },
              {
                'id': 13,
                'title': 'Unknown active state',
                'status': 'published',
                'visibility': 'family',
                'is_active': 'unknown',
              },
            ],
          }),
          isTrue,
        );

        expect(state.familyData.visibleMaterials, isEmpty);
      },
    );

    test('draft assignment stays hidden even when published_at is present', () {
      expect(
        state.receiveFamilyResource(FamilyResource.assignments, {
          'data': [
            {
              'id': 20,
              'cohort': 42,
              'cohort_name': '9-B Algebra',
              'title': 'Withdrawn assignment',
              'due_at': '2026-08-01T18:00:00+05:00',
              'status': 'draft',
              'published_at': '2026-07-20T10:00:00Z',
            },
          ],
        }),
        isTrue,
      );

      expect(state.familyData.assignments.single.statusRaw, 'draft');
      expect(state.familyData.visibleAssignments, isEmpty);
    });

    test('ungraded or scoreless grade payloads stay hidden', () {
      expect(
        state.receiveFamilyResource(FamilyResource.submissions, {
          'data': [
            {
              'id': 41,
              'assignment': 8,
              'assignment_title': 'Not graded yet',
              'status': 'submitted',
              'grade': {
                'submission': 41,
                'graded': false,
                'score': '88',
                'graded_at': '2026-07-29T09:00:00Z',
              },
            },
            {
              'id': 42,
              'assignment': 9,
              'assignment_title': 'Missing score',
              'status': 'graded',
              'grade': {
                'submission': 42,
                'graded': true,
                'score': null,
                'graded_at': '2026-07-29T10:00:00Z',
              },
            },
          ],
        }),
        isTrue,
      );

      expect(state.familyData.submissions, hasLength(2));
      expect(
        state.familyData.submissions.every((item) => item.grade == null),
        isTrue,
      );
      expect(state.familyData.grades, isEmpty);
    });

    test('malformed resources do not replace the last good snapshot', () {
      final before = state.familyData.assignments;
      expect(
        state.receiveFamilyResource(FamilyResource.assignments, const {
          'data': 'not-a-list',
        }),
        isFalse,
      );
      expect(state.familyData.assignments, same(before));
    });

    test(
      'mixed malformed rows do not partially replace the last good snapshot',
      () {
        final before = state.familyData.assignments;

        expect(
          state.receiveFamilyResource(FamilyResource.assignments, {
            'data': [
              {
                'id': 30,
                'cohort': 42,
                'cohort_name': '9-B Algebra',
                'title': 'Otherwise valid assignment',
                'due_at': '2026-08-02T18:00:00+05:00',
                'status': 'published',
                'published_at': '2026-07-28T10:00:00Z',
              },
              'not-an-object-row',
            ],
          }),
          isFalse,
        );
        expect(state.familyData.assignments, same(before));
      },
    );
  });

  group('notification compatibility and privacy', () {
    test('canonical event targets the exact thread and reads read_at', () {
      final state = AppState();
      addTearDown(state.dispose);

      expect(
        state.receiveNoticePayload({
          'id': 41,
          'event_type': 'message.received',
          'title': 'New message',
          'body': 'A teacher replied.',
          'data': {'thread_id': 42},
          'read_at': '2026-07-19T15:35:00+05:00',
          'created_at': '2026-07-19T15:30:00+05:00',
        }, authenticatedRole: 'student'),
        isTrue,
      );
      final notice = state.notices.first;
      expect(notice.destination, NoticeDestination.messages);
      expect(notice.entityId, '42');
      expect(notice.eventType, 'message.received');
      expect(notice.isRead, isTrue);
      expect(notice.audience, NoticeAudience.student);
    });

    test('unknown audience fails closed and replay preserves read state', () {
      final state = AppState();
      addTearDown(state.dispose);
      expect(
        state.receiveNoticePayload({
          'id': 'private',
          'event_type': 'assignment.graded',
          'title': 'Result',
          'body': 'Ready',
        }),
        isFalse,
      );

      expect(
        state.receiveNoticePayload({
          'id': 'replay',
          'event_type': 'assignment.graded',
          'title': 'Result',
          'body': 'Ready',
          'recipient_role': 'student',
          'read_at': '2026-07-28T10:00:00Z',
        }),
        isTrue,
      );
      expect(
        state.receiveNoticePayload({
          'id': 'replay',
          'event_type': 'assignment.graded',
          'title': 'Result updated',
          'body': 'Ready',
        }),
        isTrue,
      );
      expect(state.notices.first.isRead, isTrue);
      expect(state.notices.first.audience, NoticeAudience.student);
    });

    test('shared preview notice read state stays isolated by role', () {
      final state = AppState();
      addTearDown(state.dispose);
      final shared = state.notices.firstWhere((item) => item.id == 'n1');

      state.markNoticeReadForRole(shared.id, 'student');
      expect(state.isNoticeReadForRole(shared, 'student'), isTrue);
      expect(state.isNoticeReadForRole(shared, 'parent'), isFalse);
    });
  });

  group('role-scoped messaging', () {
    test('student and parent drafts and transcripts are isolated', () async {
      final controller = FamilyMessagingController(now: DateTime(2026, 7, 28));
      addTearDown(controller.dispose);
      final student = FamilyMessagingController.scopeKey(
        tenant: 'preview-center',
        userId: 'student-101',
        role: 'student',
      );
      final parent = FamilyMessagingController.scopeKey(
        tenant: 'preview-center',
        userId: 'parent-101',
        role: 'parent',
      );
      final studentThread = controller.threads(student).first;
      final parentThread = controller.threads(parent).first;

      controller.setDraft(student, studentThread.id, 'Student draft');
      expect(controller.draft(parent, parentThread.id), isEmpty);

      final beforeParent = parentThread.messages.length;
      expect(
        await controller.sendText(
          scope: student,
          threadId: studentThread.id,
          senderId: 'student-101',
          text: 'Only student can see this',
        ),
        isTrue,
      );
      expect(
        controller.thread(student, studentThread.id)?.messages.last.body,
        'Only student can see this',
      );
      expect(
        controller.thread(parent, parentThread.id)?.messages.length,
        beforeParent,
      );
    });

    test('failed local send keeps text and can be retried', () async {
      final repository = _FlakyMessagingRepository();
      final controller = FamilyMessagingController(
        repository: repository,
        now: DateTime(2026, 7, 28),
      );
      addTearDown(controller.dispose);
      final scope = FamilyMessagingController.scopeKey(
        tenant: 'preview-center',
        userId: 'student-101',
        role: 'student',
      );
      final thread = controller.threads(scope).first;

      expect(
        await controller.sendText(
          scope: scope,
          threadId: thread.id,
          senderId: 'student-101',
          text: 'Keep this text',
        ),
        isFalse,
      );
      final failed = controller.thread(scope, thread.id)!.messages.last;
      expect(failed.body, 'Keep this text');
      expect(failed.status, FamilyMessageStatus.failed);

      expect(await controller.retry(scope, thread.id, failed.id), isTrue);
      expect(
        controller.thread(scope, thread.id)!.messages.last.status,
        FamilyMessageStatus.localOnly,
      );
    });
  });
}

final class _FlakyMessagingRepository implements FamilyMessagingRepository {
  var calls = 0;

  @override
  String get connectionLabel => 'Test';

  @override
  bool get isLocalPreview => true;

  @override
  Future<FamilyMessage> sendText({
    required String scopeKey,
    required String threadId,
    required String senderId,
    required String body,
    required String clientRequestId,
  }) async {
    calls++;
    if (calls == 1) throw StateError('offline');
    return FamilyMessage(
      id: 'saved-$clientRequestId',
      threadId: threadId,
      senderId: senderId,
      body: body,
      createdAt: DateTime(2026, 7, 28),
      status: FamilyMessageStatus.localOnly,
      clientRequestId: clientRequestId,
    );
  }
}
