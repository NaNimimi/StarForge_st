/// Read-only projections of the data produced by the staff application.
///
/// The staff client is not a family API: its authentication intentionally
/// rejects student and parent principals. These models therefore copy only the
/// shared JSON vocabulary. A future FamilyRepository can populate the same
/// snapshot after applying child ownership and visibility rules server-side.
enum FamilyDataOrigin { localPreview, server }

enum FamilyLoadState { ready, loading, empty, offline, error }

enum FamilyResource { assignments, submissions, lessons, attendance, materials }

final class FamilySnapshot {
  const FamilySnapshot({
    required this.assignments,
    required this.submissions,
    required this.lessons,
    required this.attendance,
    required this.materials,
    required this.origin,
    required this.updatedAt,
    this.loadState = FamilyLoadState.ready,
    this.errorMessage,
  });

  final List<FamilyAssignment> assignments;
  final List<FamilySubmission> submissions;
  final List<FamilyLesson> lessons;
  final List<FamilyAttendanceRecord> attendance;
  final List<FamilyMaterial> materials;
  final FamilyDataOrigin origin;
  final FamilyLoadState loadState;
  final DateTime updatedAt;
  final String? errorMessage;

  bool get isPreview => origin == FamilyDataOrigin.localPreview;

  List<FamilyAssignment> get visibleAssignments =>
      assignments.where((item) => item.isPublished).toList(growable: false);

  List<FamilyMaterial> get visibleMaterials => materials
      .where((item) => item.isPublished && item.isActive && item.familyVisible)
      .toList(growable: false);

  List<FamilyGrade> get grades {
    final assignmentById = {
      for (final assignment in assignments) assignment.id: assignment,
    };
    return [
      for (final submission in submissions)
        if (submission.grade case final grade?)
          FamilyGrade(
            submissionId: submission.id,
            assignmentId: submission.assignmentId,
            assignmentTitle:
                assignmentById[submission.assignmentId]?.title ??
                submission.assignmentTitle,
            subject:
                assignmentById[submission.assignmentId]?.subject ??
                submission.subject,
            score: grade.score,
            maxScore: assignmentById[submission.assignmentId]?.maxScore ?? 100,
            feedback: grade.feedback,
            teacherName: grade.teacherName,
            gradedAt: grade.gradedAt,
          ),
    ]..sort((a, b) => b.gradedAt.compareTo(a.gradedAt));
  }

  FamilySnapshot replaceResource(
    FamilyResource resource,
    Object? payload, {
    DateTime? receivedAt,
  }) {
    final rows = _rows(payload);
    return switch (resource) {
      FamilyResource.assignments => copyWith(
        assignments: [for (final row in rows) FamilyAssignment.fromJson(row)],
        origin: FamilyDataOrigin.server,
        updatedAt: receivedAt ?? DateTime.now(),
      ),
      FamilyResource.submissions => copyWith(
        submissions: [for (final row in rows) FamilySubmission.fromJson(row)],
        origin: FamilyDataOrigin.server,
        updatedAt: receivedAt ?? DateTime.now(),
      ),
      FamilyResource.lessons => copyWith(
        lessons: [for (final row in rows) FamilyLesson.fromJson(row)],
        origin: FamilyDataOrigin.server,
        updatedAt: receivedAt ?? DateTime.now(),
      ),
      FamilyResource.attendance => copyWith(
        attendance: [
          for (final row in rows) FamilyAttendanceRecord.fromJson(row),
        ],
        origin: FamilyDataOrigin.server,
        updatedAt: receivedAt ?? DateTime.now(),
      ),
      FamilyResource.materials => copyWith(
        materials: [for (final row in rows) FamilyMaterial.fromJson(row)],
        origin: FamilyDataOrigin.server,
        updatedAt: receivedAt ?? DateTime.now(),
      ),
    };
  }

  FamilySnapshot copyWith({
    List<FamilyAssignment>? assignments,
    List<FamilySubmission>? submissions,
    List<FamilyLesson>? lessons,
    List<FamilyAttendanceRecord>? attendance,
    List<FamilyMaterial>? materials,
    FamilyDataOrigin? origin,
    FamilyLoadState? loadState,
    DateTime? updatedAt,
    String? errorMessage,
    bool clearError = false,
  }) => FamilySnapshot(
    assignments: assignments ?? this.assignments,
    submissions: submissions ?? this.submissions,
    lessons: lessons ?? this.lessons,
    attendance: attendance ?? this.attendance,
    materials: materials ?? this.materials,
    origin: origin ?? this.origin,
    loadState: loadState ?? this.loadState,
    updatedAt: updatedAt ?? this.updatedAt,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  factory FamilySnapshot.localPreview({required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final algebraDue = today.add(const Duration(days: 1, hours: 18));
    final englishDue = today
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 20));
    return FamilySnapshot(
      origin: FamilyDataOrigin.localPreview,
      loadState: FamilyLoadState.ready,
      updatedAt: now,
      assignments: [
        FamilyAssignment(
          id: 'assignment-201',
          title: 'Kvadrat tenglamalar · 1–12',
          subject: 'Algebra',
          description:
              '1–12-misollarni yeching va yechim bosqichlarini ko‘rsating.',
          dueAt: algebraDue,
          statusRaw: 'published',
          publishedAt: today.subtract(const Duration(days: 2)),
          maxScore: 100,
          estimatedMinutes: 35,
          teacherName: 'Nigora Karimova',
        ),
        FamilyAssignment(
          id: 'assignment-202',
          title: 'Unit 8 · yangi so‘zlar',
          subject: 'Ingliz tili',
          description: 'Yangi so‘zlar bilan 10 ta gap tuzing.',
          dueAt: englishDue,
          statusRaw: 'published',
          publishedAt: today.subtract(const Duration(days: 4)),
          maxScore: 100,
          estimatedMinutes: 20,
          teacherName: 'Aziz Tursunov',
        ),
      ],
      submissions: [
        FamilySubmission(
          id: 'submission-302',
          assignmentId: 'assignment-202',
          assignmentTitle: 'Unit 8 · yangi so‘zlar',
          subject: 'Ingliz tili',
          statusRaw: 'graded',
          submittedAt: englishDue.subtract(const Duration(hours: 3)),
          attemptNumber: 1,
          isLate: false,
          grade: FamilySubmissionGrade(
            score: 88,
            feedback: 'Gaplar to‘g‘ri. Imlo belgilariga e’tibor bering.',
            teacherName: 'Aziz Tursunov',
            gradedAt: today.subtract(const Duration(days: 1, hours: 8)),
          ),
        ),
        FamilySubmission(
          id: 'submission-303',
          assignmentId: 'assignment-203',
          assignmentTitle: 'Algebra testi',
          subject: 'Algebra',
          statusRaw: 'graded',
          submittedAt: today.subtract(const Duration(days: 4, hours: 2)),
          attemptNumber: 1,
          isLate: false,
          grade: FamilySubmissionGrade(
            score: 94,
            feedback: 'Yechim aniq. 7-misolda tekshirish qadamini qo‘shing.',
            teacherName: 'Nigora Karimova',
            gradedAt: today.subtract(const Duration(days: 4)),
          ),
        ),
        FamilySubmission(
          id: 'submission-304',
          assignmentId: 'assignment-204',
          assignmentTitle: 'Geometriya nazorati',
          subject: 'Geometriya',
          statusRaw: 'graded',
          submittedAt: today.subtract(const Duration(days: 7, hours: 2)),
          attemptNumber: 1,
          isLate: false,
          grade: FamilySubmissionGrade(
            score: 82,
            feedback: 'Isbot yozilish tartibini takrorlang.',
            teacherName: 'Bobur Aliyev',
            gradedAt: today.subtract(const Duration(days: 7)),
          ),
        ),
      ],
      lessons: [
        FamilyLesson(
          id: 'lesson-401',
          title: 'Algebra darsi',
          teacherName: 'Nigora Karimova',
          roomName: '304-xona',
          startsAt: today.add(const Duration(hours: 9)),
          endsAt: today.add(const Duration(hours: 10, minutes: 20)),
          statusRaw: 'scheduled',
        ),
        FamilyLesson(
          id: 'lesson-402',
          title: 'Geometriya',
          teacherName: 'Bobur Aliyev',
          roomName: '201-xona',
          startsAt: today.add(const Duration(days: 1, hours: 11)),
          endsAt: today.add(const Duration(days: 1, hours: 12, minutes: 20)),
          statusRaw: 'scheduled',
        ),
        FamilyLesson(
          id: 'lesson-403',
          title: 'Algebra nazorat ishi',
          teacherName: 'Nigora Karimova',
          roomName: '304-xona',
          startsAt: today.add(const Duration(days: 2, hours: 9)),
          endsAt: today.add(const Duration(days: 2, hours: 10, minutes: 20)),
          statusRaw: 'scheduled',
        ),
      ],
      attendance: [
        for (var index = 0; index < 4; index++)
          FamilyAttendanceRecord(
            id: 'attendance-${501 + index}',
            lessonId: 'history-${501 + index}',
            lessonTitle: const [
              'Algebra',
              'Geometriya',
              'Ingliz tili',
              'Algebra',
            ][index],
            startsAt: today
                .subtract(Duration(days: index + 1))
                .add(const Duration(hours: 9)),
            statusRaw: const ['present', 'present', 'late', 'excused'][index],
            arrivedAt: index == 2
                ? today
                      .subtract(Duration(days: index + 1))
                      .add(const Duration(hours: 9, minutes: 9))
                : null,
          ),
      ],
      materials: const [
        FamilyMaterial(
          id: 'material-601',
          title: 'Kvadrat tenglamalar',
          topic: 'Algebra',
          contentType: 'PDF',
          detail: '12 sahifa',
          statusRaw: 'published',
          isActive: true,
          familyVisible: true,
          isDownloadable: false,
          version: 2,
        ),
        FamilyMaterial(
          id: 'material-602',
          title: 'Unit 8 listening',
          topic: 'Ingliz tili',
          contentType: 'Audio',
          detail: '08:24',
          statusRaw: 'published',
          isActive: true,
          familyVisible: true,
          isDownloadable: false,
          version: 1,
        ),
        FamilyMaterial(
          id: 'material-603',
          title: 'Uchburchaklar konspekti',
          topic: 'Geometriya',
          contentType: 'Matn',
          detail: '6 bo‘lim',
          statusRaw: 'published',
          isActive: true,
          familyVisible: true,
          isDownloadable: false,
          version: 3,
        ),
      ],
    );
  }
}

final class FamilyAssignment {
  const FamilyAssignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.dueAt,
    required this.statusRaw,
    required this.publishedAt,
    required this.maxScore,
    required this.estimatedMinutes,
    required this.teacherName,
  });

  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime dueAt;
  final String statusRaw;
  final DateTime? publishedAt;
  final double maxScore;
  final int estimatedMinutes;
  final String teacherName;

  bool get isPublished => statusRaw.toLowerCase() == 'published';

  factory FamilyAssignment.fromJson(Map<String, Object?> json) {
    final cohort = _map(json['cohort']);
    final teacher = _map(json['teacher']);
    return FamilyAssignment(
      id: _requiredId(json['id'], 'assignment'),
      title: _requiredText(json['title'], 'assignment.title'),
      subject: _text(
        json['subject_name'] ??
            json['subject'] ??
            json['cohort_name'] ??
            cohort['name'],
        fallback: 'Vazifa',
      ),
      description: _text(json['description']),
      dueAt: _requiredDate(json['due_at'], 'assignment.due_at'),
      statusRaw: _text(json['status'], fallback: 'unknown'),
      publishedAt: _date(json['published_at']),
      maxScore: _number(json['max_score'], fallback: 100),
      estimatedMinutes: _integer(json['estimated_minutes'], fallback: 30),
      teacherName: _text(
        json['teacher_name'] ?? teacher['name'],
        fallback: 'Ustoz',
      ),
    );
  }
}

final class FamilySubmission {
  const FamilySubmission({
    required this.id,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.subject,
    required this.statusRaw,
    required this.submittedAt,
    required this.attemptNumber,
    required this.isLate,
    this.grade,
  });

  final String id;
  final String assignmentId;
  final String assignmentTitle;
  final String subject;
  final String statusRaw;
  final DateTime submittedAt;
  final int attemptNumber;
  final bool isLate;
  final FamilySubmissionGrade? grade;

  factory FamilySubmission.fromJson(Map<String, Object?> json) {
    final assignment = _map(json['assignment']);
    final grade = _map(json['grade']);
    return FamilySubmission(
      id: _requiredId(json['id'], 'submission'),
      assignmentId: _requiredId(
        json['assignment_id'] ??
            (json['assignment'] is Map ? assignment['id'] : json['assignment']),
        'submission.assignment',
      ),
      assignmentTitle: _text(
        json['assignment_title'] ?? assignment['title'],
        fallback: 'Baholangan ish',
      ),
      subject: _text(json['subject_name'], fallback: 'Fan'),
      statusRaw: _text(json['status'], fallback: 'unknown'),
      submittedAt:
          _date(json['submitted_at']) ??
          _date(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      attemptNumber: _integer(json['attempt_number'], fallback: 1),
      isLate: _boolean(json['is_late']),
      grade:
          grade.isEmpty ||
              grade['score'] == null ||
              (grade.containsKey('graded') && !_boolean(grade['graded']))
          ? null
          : FamilySubmissionGrade.fromJson(grade),
    );
  }
}

final class FamilySubmissionGrade {
  const FamilySubmissionGrade({
    required this.score,
    required this.feedback,
    required this.teacherName,
    required this.gradedAt,
  });

  final double score;
  final String feedback;
  final String teacherName;
  final DateTime gradedAt;

  factory FamilySubmissionGrade.fromJson(Map<String, Object?> json) {
    final grader = _map(json['graded_by']);
    return FamilySubmissionGrade(
      score: _number(json['score']),
      feedback: _text(json['feedback']),
      teacherName: _text(
        json['teacher_name'] ?? grader['name'],
        fallback: 'Ustoz',
      ),
      gradedAt:
          _date(json['graded_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

final class FamilyGrade {
  const FamilyGrade({
    required this.submissionId,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.subject,
    required this.score,
    required this.maxScore,
    required this.feedback,
    required this.teacherName,
    required this.gradedAt,
  });

  final String submissionId;
  final String assignmentId;
  final String assignmentTitle;
  final String subject;
  final double score;
  final double maxScore;
  final String feedback;
  final String teacherName;
  final DateTime gradedAt;

  int get percent => maxScore <= 0 ? 0 : (score / maxScore * 100).round();
}

final class FamilyLesson {
  const FamilyLesson({
    required this.id,
    required this.title,
    required this.teacherName,
    required this.roomName,
    required this.startsAt,
    required this.endsAt,
    required this.statusRaw,
    this.cancelReason,
  });

  final String id;
  final String title;
  final String teacherName;
  final String roomName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String statusRaw;
  final String? cancelReason;

  bool get isCancelled => statusRaw.toLowerCase() == 'cancelled';

  factory FamilyLesson.fromJson(Map<String, Object?> json) {
    final teacher = _map(json['teacher']);
    final room = _map(json['room']);
    return FamilyLesson(
      id: _requiredId(json['id'], 'lesson'),
      title: _requiredText(
        json['title'] ?? json['lesson_type_name'],
        'lesson.title',
      ),
      teacherName: _text(
        json['teacher_name'] ?? teacher['name'],
        fallback: 'Ustoz',
      ),
      roomName: _text(json['room_name'] ?? room['name']),
      startsAt: _requiredDate(json['starts_at'], 'lesson.starts_at'),
      endsAt: _requiredDate(json['ends_at'], 'lesson.ends_at'),
      statusRaw: _text(json['status'], fallback: 'unknown'),
      cancelReason: _nullableText(json['cancel_reason']),
    );
  }
}

final class FamilyAttendanceRecord {
  const FamilyAttendanceRecord({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.startsAt,
    required this.statusRaw,
    this.arrivedAt,
  });

  final String id;
  final String lessonId;
  final String lessonTitle;
  final DateTime startsAt;
  final String statusRaw;
  final DateTime? arrivedAt;

  factory FamilyAttendanceRecord.fromJson(Map<String, Object?> json) {
    final lesson = _map(json['lesson']);
    return FamilyAttendanceRecord(
      id: _requiredId(json['id'], 'attendance'),
      lessonId: _requiredId(
        json['lesson_id'] ??
            (json['lesson'] is Map ? lesson['id'] : json['lesson']),
        'attendance.lesson',
      ),
      lessonTitle: _text(
        json['lesson_title'] ?? lesson['title'],
        fallback: 'Dars',
      ),
      startsAt:
          _date(json['lesson_starts_at'] ?? lesson['starts_at']) ??
          _date(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      statusRaw: _text(json['status'], fallback: 'unknown'),
      arrivedAt: _date(json['arrived_at']),
    );
  }
}

final class FamilyMaterial {
  const FamilyMaterial({
    required this.id,
    required this.title,
    required this.topic,
    required this.contentType,
    required this.detail,
    required this.statusRaw,
    required this.isActive,
    required this.familyVisible,
    required this.isDownloadable,
    required this.version,
  });

  final String id;
  final String title;
  final String topic;
  final String contentType;
  final String detail;
  final String statusRaw;
  final bool isActive;
  final bool familyVisible;
  final bool isDownloadable;
  final int version;

  bool get isPublished => statusRaw.toLowerCase() == 'published';

  factory FamilyMaterial.fromJson(Map<String, Object?> json) {
    final library = _map(json['library']);
    final visibility = _text(
      json['visibility'] ?? library['visibility'],
      fallback: 'unknown',
    ).toLowerCase();
    return FamilyMaterial(
      id: _requiredId(json['id'], 'material'),
      title: _requiredText(json['title'] ?? json['name'], 'material.title'),
      topic: _text(json['topic'], fallback: 'Material'),
      contentType: _text(
        json['content_type'] ?? json['type'],
        fallback: 'Fayl',
      ),
      detail: _text(json['detail'] ?? json['size_label']),
      statusRaw: _text(json['status'], fallback: 'unknown'),
      isActive: json.containsKey('is_active')
          ? _boolean(json['is_active'])
          : false,
      familyVisible:
          visibility == 'family' ||
          visibility == 'student' ||
          visibility == 'parent' ||
          visibility == 'public',
      isDownloadable: _boolean(json['is_downloadable']),
      version: _integer(json['version'], fallback: 1),
    );
  }
}

List<Map<String, Object?>> _rows(Object? payload) {
  Object? value = payload;
  if (value is Map) {
    final map = Map<String, Object?>.from(value);
    value = map['data'] ?? map;
  }
  if (value is Map) {
    final map = Map<String, Object?>.from(value);
    value = map['results'] ?? map['items'] ?? const <Object?>[];
  }
  if (value is! List) {
    throw const FormatException('Expected a list response.');
  }
  if (value.any((item) => item is! Map)) {
    throw const FormatException('Response contains a malformed row.');
  }
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

Map<String, Object?> _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};

String _text(Object? value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty || result == 'null' ? fallback : result;
}

String? _nullableText(Object? value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

String _requiredText(Object? value, String field) {
  final result = _text(value);
  if (result.isEmpty) throw FormatException('$field is required.');
  return result;
}

String _requiredId(Object? value, String field) =>
    _requiredText(value, '$field.id');

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value is num) {
    final milliseconds = value.abs() < 100000000000
        ? value.toInt() * 1000
        : value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  return DateTime.tryParse(_text(value));
}

DateTime _requiredDate(Object? value, String field) {
  final result = _date(value);
  if (result == null) throw FormatException('$field is required.');
  return result;
}

double _number(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse(_text(value)) ?? fallback;

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse(_text(value)) ?? fallback;

bool _boolean(Object? value) =>
    value == true ||
    value == 1 ||
    const {'true', '1', 'yes'}.contains(_text(value).toLowerCase());
