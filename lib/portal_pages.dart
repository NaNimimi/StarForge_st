part of 'portal_app.dart';

class _RebuiltHomePortalPage extends StatelessWidget {
  const _RebuiltHomePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return portal.isParent
        ? _buildParent(context, portal)
        : _buildStudent(context, portal);
  }

  Widget _buildStudent(BuildContext context, PortalController portal) {
    final attendance = valueMap(portal.report['attendance']);
    final rank = valueMap(portal.report['rank']);
    final lessons = valueRows(portal.dashboard['next_lessons']);
    final homework = valueRows(portal.dashboard['open_homework']);
    final grades = valueRows(portal.dashboard['recent_grades']);
    final rate = (double.tryParse('${attendance['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final openCount =
        valueInt(portal.dashboard['open_homework_count']) ?? homework.length;
    final average = grades.isEmpty
        ? 0.0
        : grades.map(_gradePercentage).reduce((a, b) => a + b) / grades.length;
    return _PortalPage(
      title: 'Bugungi marshrut',
      subtitle: 'Eng muhim darslar, vazifalar va natijalar bir ekranda.',
      section: PortalSection.home,
      trailing: _LiveBadge(
        label: valueText(portal.dashboard, const [
          'group',
        ], fallback: 'Guruh biriktirilmagan'),
        icon: Icons.groups_2_outlined,
      ),
      children: [
        _CockpitHero(
          parent: false,
          name: portal.displayName.split(' ').first,
          contextTitle: valueText(portal.dashboard, const [
            'group',
          ], fallback: 'Mustaqil o‘quvchi'),
          primaryItem: lessons.firstOrNull,
          attentionTitle: openCount == 0
              ? 'Reja toza'
              : '$openCount ta vazifa kutmoqda',
          attentionBody: homework.isEmpty
              ? 'Barcha topshiriqlar nazorat ostida.'
              : '${valueText(homework.first, const ['title'])} · ${_dateLabel(homework.first['due_at'], time: true)}',
        ),
        const SizedBox(height: 16),
        _HomeActionRail(
          title: 'Tezkor o‘tish',
          items: [
            const _HomeActionData(
              label: 'Mening profilim',
              detail: 'Shaxsiy va o‘quv ma’lumotlari',
              icon: Icons.badge_outlined,
              color: Sf.accent,
              section: PortalSection.identity,
            ),
            if (portal.can('assignments:read'))
              _HomeActionData(
                label: 'Vazifalar',
                detail: openCount == 0
                    ? 'Yangi vazifa yo‘q'
                    : '$openCount ta ochiq vazifa',
                icon: Icons.assignment_outlined,
                color: Sf.primary,
                section: PortalSection.assignments,
              ),
            if (portal.can('schedule:read'))
              _HomeActionData(
                label: 'Dars jadvali',
                detail: lessons.isEmpty
                    ? 'Bugun dars yo‘q'
                    : '${lessons.length} ta yaqin dars',
                icon: Icons.calendar_month_outlined,
                color: Sf.success,
                section: PortalSection.schedule,
              ),
            if (portal.can('academics:read'))
              _HomeActionData(
                label: 'Natijalar',
                detail: grades.isEmpty
                    ? 'Natija kiritilmagan'
                    : '${grades.length} ta so‘nggi baho',
                icon: Icons.query_stats_rounded,
                color: Sf.accent,
                section: PortalSection.academics,
              ),
            if (portal.can('messaging:read'))
              _HomeActionData(
                label: 'Ustoz bilan chat',
                detail: portal.threads.isEmpty
                    ? 'Savol yoki fayl yuboring'
                    : '${portal.threads.length} ta suhbat',
                icon: Icons.forum_outlined,
                color: Sf.success,
                section: PortalSection.messages,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _CockpitMetricStrip(
          items: [
            _CockpitMetricData(
              label: 'Ochiq vazifa',
              value: '$openCount',
              note: homework.isEmpty
                  ? 'Hammasi bajarilgan'
                  : 'Muddatni kuzating',
              icon: Icons.task_alt_rounded,
              color: Sf.primary,
            ),
            _CockpitMetricData(
              label: 'Davomat',
              value: attendance['rate'] == null
                  ? '—'
                  : '${(rate * 100).round()}%',
              note:
                  '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0} dars',
              icon: Icons.how_to_reg_rounded,
              color: Sf.success,
            ),
            _CockpitMetricData(
              label: 'O‘rtacha natija',
              value: grades.isEmpty ? '—' : '${average.round()}%',
              note: rank.isEmpty
                  ? '${grades.length} ta so‘nggi baho'
                  : 'Sinfda ${rank['rank']} / ${rank['of']}',
              icon: Icons.insights_rounded,
              color: Sf.accent,
            ),
            _CockpitMetricData(
              label: 'Keyingi dars',
              value: lessons.isEmpty
                  ? '—'
                  : _timeOnly(lessons.first['starts_at']),
              note: lessons.isEmpty
                  ? 'Yaqin dars belgilanmagan'
                  : valueText(lessons.first, const ['title']),
              icon: Icons.schedule_rounded,
              color: Sf.warn,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CockpitColumns(
          primary: _TodayStack(lessons: lessons, homework: homework),
          secondary: _RecentResultsPanel(grades: grades, rank: rank),
        ),
      ],
    );
  }

  Widget _buildParent(BuildContext context, PortalController portal) {
    final attendance = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final sheet = valueRows(attendance['sheet']);
    final invoices = valueRows(portal.outstanding['invoices']);
    final nextInvoice = invoices.firstOrNull;
    final selected = portal.children
        .where((item) => valueInt(item['id']) == portal.selectedStudentId)
        .firstOrNull;
    final outstanding =
        double.tryParse(
          '${portal.outstanding['outstanding_uzs'] ?? payment['outstanding_uzs'] ?? 0}',
        ) ??
        0;
    final needsPaymentAttention = outstanding > 0;
    final rate = (double.tryParse('${attendance['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final hasAttendanceEvidence = (valueInt(attendance['of']) ?? 0) > 0;
    final hasPaymentEvidence = payment.containsKey('outstanding_uzs');
    final evidenceComplete = hasAttendanceEvidence && hasPaymentEvidence;
    final needsAttendanceAttention = hasAttendanceEvidence && rate < 0.8;
    final attentionCritical = needsPaymentAttention || needsAttendanceAttention;
    return _PortalPage(
      title: 'Oila nazorat markazi',
      subtitle:
          'Farzandingizning davomat, o‘zlashtirish va moliyaviy holati bir joyda.',
      section: PortalSection.home,
      trailing: MediaQuery.sizeOf(context).width >= 840
          ? null
          : portal.children.length > 1
          ? _ChildContextSelector(portal: portal)
          : _LiveBadge(
              label: valueText(selected ?? const {}, const [
                'full_name',
              ], fallback: 'Farzand'),
              icon: Icons.family_restroom_rounded,
            ),
      children: [
        if (portal.children.isEmpty)
          const _EmptyState(
            icon: Icons.family_restroom_rounded,
            title: 'Farzand biriktirilmagan',
            message:
                'Markaz administratori akkauntni o‘quvchiga bog‘lashi kerak.',
          )
        else ...[
          _CockpitHero(
            parent: true,
            name: valueText(selected ?? const {}, const [
              'full_name',
            ], fallback: 'Farzand'),
            contextTitle:
                '${valueText(selected ?? const {}, const ['student_id'])} · ${valueText(selected ?? const {}, const ['academic_level'], fallback: 'Daraja belgilanmagan')}',
            attentionCritical: attentionCritical,
            attentionKnown: evidenceComplete,
            attentionTitle: needsPaymentAttention
                ? 'To‘lovga e’tibor kerak'
                : needsAttendanceAttention
                ? 'Davomatni kuzatish kerak'
                : evidenceComplete
                ? 'Jiddiy ogohlantirish yo‘q'
                : 'Holat baholanmoqda',
            attentionBody: needsPaymentAttention
                ? '${_money(context, outstanding)} ochiq qarzdorlik mavjud.'
                : needsAttendanceAttention
                ? 'Joriy davomat ${(rate * 100).round()}% — tafsilotlarni tekshiring.'
                : evidenceComplete
                ? 'Davomat va to‘lov ko‘rsatkichlari me’yorda.'
                : 'Xulosa uchun davomat va to‘lov ma’lumotlari yetarli emas.',
          ),
          const SizedBox(height: 16),
          _HomeActionRail(
            title: 'Oila uchun tezkor amallar',
            items: [
              const _HomeActionData(
                label: 'Farzand profili',
                detail: 'Aloqalar va hujjatlar',
                icon: Icons.supervisor_account_outlined,
                color: Sf.primary,
                section: PortalSection.identity,
              ),
              if (portal.can('attendance:read'))
                _HomeActionData(
                  label: 'Davomat tafsiloti',
                  detail: '${attendance['present'] ?? 0} ta qatnashuv',
                  icon: Icons.fact_check_outlined,
                  color: Sf.success,
                  section: PortalSection.attendance,
                ),
              if (portal.can('academics:read'))
                const _HomeActionData(
                  label: 'O‘zlashtirish',
                  detail: 'Baholar va dinamika',
                  icon: Icons.insights_outlined,
                  color: Sf.accent,
                  section: PortalSection.academics,
                ),
              if (portal.can('schedule:read'))
                const _HomeActionData(
                  label: 'Oila taqvimi',
                  detail: 'Dars va tadbirlar',
                  icon: Icons.calendar_month_outlined,
                  color: Sf.warn,
                  section: PortalSection.schedule,
                ),
              if (portal.can('finance:read_own'))
                _HomeActionData(
                  label: 'To‘lovlar',
                  detail: needsPaymentAttention
                      ? 'Ochiq balansni ko‘ring'
                      : 'Qarzdorlik mavjud emas',
                  icon: Icons.account_balance_wallet_outlined,
                  color: needsPaymentAttention
                      ? Theme.of(context).colorScheme.error
                      : Sf.success,
                  section: PortalSection.finance,
                ),
              if (portal.can('messaging:read'))
                _HomeActionData(
                  label: 'Maktab bilan chat',
                  detail: portal.threads.isEmpty
                      ? 'Savol yoki fayl yuboring'
                      : '${portal.threads.length} ta suhbat',
                  icon: Icons.forum_outlined,
                  color: Sf.success,
                  section: PortalSection.messages,
                ),
              const _HomeActionData(
                label: 'Mening profilim',
                detail: 'Sozlamalar va xavfsizlik',
                icon: Icons.manage_accounts_outlined,
                color: Sf.accent,
                section: PortalSection.account,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CockpitMetricStrip(
            items: [
              _CockpitMetricData(
                label: 'Davomat',
                value: attendance['rate'] == null
                    ? '—'
                    : '${(rate * 100).round()}%',
                note: 'Kechikish bilan birga',
                icon: Icons.fact_check_outlined,
                color: Sf.success,
              ),
              _CockpitMetricData(
                label: 'Keyingi to‘lov',
                value: nextInvoice == null
                    ? '—'
                    : _dateLabel(nextInvoice['due_date']),
                note: nextInvoice == null
                    ? 'Ochiq hisob-faktura yo‘q'
                    : valueText(nextInvoice, const [
                        'number',
                      ], fallback: 'Hisob-faktura'),
                icon: Icons.event_available_outlined,
                color: Sf.warn,
              ),
              _CockpitMetricData(
                label: 'Sinfdagi o‘rni',
                value: rank.isEmpty ? '—' : '${rank['rank']} / ${rank['of']}',
                note: rank.isEmpty
                    ? 'Markaz yashirgan'
                    : 'O‘rtacha ${rank['average_pct'] ?? '—'}%',
                icon: Icons.leaderboard_outlined,
                color: Sf.accent,
              ),
              _CockpitMetricData(
                label: 'Ochiq to‘lov',
                value: _money(context, outstanding),
                note: invoices.isEmpty
                    ? 'To‘lanadigan summa yo‘q'
                    : '${invoices.length} ta ochiq hisob',
                icon: Icons.payments_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CockpitColumns(
            primary: _ParentPaymentPanel(
              invoices: invoices,
              outstanding: outstanding,
            ),
            secondary: _FamilyActivityPanel(rows: sheet),
          ),
        ],
      ],
    );
  }
}

class _ChildContextSelector extends StatelessWidget {
  const _ChildContextSelector({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tanlangan farzand',
    child: Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: portal.selectedStudentId,
                isExpanded: true,
                icon: portal.selectingStudentId == null
                    ? const Icon(Icons.keyboard_arrow_down_rounded)
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                items: [
                  for (final child in portal.children)
                    if (valueInt(child['id']) case final id?)
                      DropdownMenuItem(
                        value: id,
                        child: Text(
                          valueText(child, const ['full_name', 'student_id']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: portal.selectingStudentId != null
                    ? null
                    : (value) {
                        if (value != null) portal.selectChild(value);
                      },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}

class _CockpitHero extends StatelessWidget {
  const _CockpitHero({
    required this.parent,
    required this.name,
    required this.contextTitle,
    required this.attentionTitle,
    required this.attentionBody,
    this.primaryItem,
    this.attentionCritical = false,
    this.attentionKnown = true,
  });

  final bool parent;
  final String name;
  final String contextTitle;
  final String attentionTitle;
  final String attentionBody;
  final Map<String, Object?>? primaryItem;
  final bool attentionCritical;
  final bool attentionKnown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final accent = scheme.primary;
    final focusAccent = parent && !attentionKnown
        ? Sf.warn
        : parent && !attentionCritical
        ? Sf.successSoft
        : accent;
    final lessonTitle = valueText(primaryItem ?? const {}, const [
      'title',
    ], fallback: 'Bugun boshqa dars yo‘q');
    return Container(
      padding: EdgeInsets.all(mobile ? 15 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Sf.ink,
            Color.alphaBlend(accent.withValues(alpha: 0.44), Sf.ink),
            Color.alphaBlend(scheme.secondary.withValues(alpha: 0.16), Sf.ink),
          ],
        ),
        borderRadius: BorderRadius.circular(mobile ? 18 : 22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                parent ? 'TANLANGAN FARZAND' : 'BUGUN / ${_dashboardDate()}',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                parent ? name : 'Salom, $name',
                style: Sf.serif(
                  size: mobile
                      ? 23
                      : compact
                      ? 28
                      : 31,
                  color: Sf.surface,
                  height: 1.03,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contextTitle,
                style: const TextStyle(
                  color: Color(0xFFC9C0AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
          final focus = Container(
            padding: EdgeInsets.all(mobile ? 12 : 17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      parent
                          ? !attentionKnown
                                ? Icons.hourglass_top_rounded
                                : attentionCritical
                                ? Icons.priority_high_rounded
                                : Icons.verified_rounded
                          : Icons.bolt_rounded,
                      color: focusAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parent
                            ? !attentionKnown
                                  ? 'MA’LUMOT KUTILMOQDA'
                                  : attentionCritical
                                  ? 'E’TIBOR MARKAZI'
                                  : 'HOLAT BARQAROR'
                            : 'KEYINGI QADAM',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: focusAccent,
                          fontSize: 10.5,
                          letterSpacing: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mobile ? 8 : 12),
                Text(
                  parent ? attentionTitle : lessonTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Sf.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  parent
                      ? attentionBody
                      : primaryItem == null
                      ? attentionBody
                      : '${_dateLabel(primaryItem!['starts_at'], time: true)} · ${valueText(primaryItem!, const ['teacher_name'], fallback: 'Ustoz')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC9C0AF),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                intro,
                SizedBox(height: mobile ? 12 : 20),
                focus,
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 6, child: intro),
              const SizedBox(width: 28),
              Expanded(flex: 4, child: focus),
            ],
          );
        },
      ),
    );
  }
}

String _dashboardDate() {
  final now = DateTime.now();
  const months = [
    'YAN',
    'FEV',
    'MAR',
    'APR',
    'MAY',
    'IYN',
    'IYL',
    'AVG',
    'SEN',
    'OKT',
    'NOY',
    'DEK',
  ];
  return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}';
}

class _CockpitMetricData {
  const _CockpitMetricData({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
}

class _CockpitMetricStrip extends StatelessWidget {
  const _CockpitMetricStrip({required this.items});

  final List<_CockpitMetricData> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        final textScale = MediaQuery.textScalerOf(
          context,
        ).scale(1).clamp(1.0, 2.0);
        return SizedBox(
          height: 112 + (textScale - 1) * 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => SizedBox(
              width: 136 + (textScale - 1) * 22,
              child: _CockpitMetricCard(item: items[index], dense: true),
            ),
          ),
        );
      }
      final count = constraints.maxWidth >= 1000 ? 4 : 2;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: _CockpitMetricCard(item: item),
            ),
        ],
      );
    },
  );
}

class _CockpitMetricCard extends StatelessWidget {
  const _CockpitMetricCard({required this.item, this.dense = false});

  final _CockpitMetricData item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.brightness == Brightness.dark
        ? Color.lerp(item.color, colors.onSurface, .46)!
        : item.color;
    return _SectionCard(
      padding: EdgeInsets.all(dense ? 10 : 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: dense ? 28 : 32,
                height: dense ? 28 : 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: accent, size: dense ? 15 : 17),
              ),
              const Spacer(),
              Icon(Icons.north_east_rounded, size: 15, color: accent),
            ],
          ),
          SizedBox(height: dense ? 6 : 11),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: Sf.monoStyle(
                size: dense ? 17 : 20,
                weight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ),
          SizedBox(height: dense ? 3 : 6),
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Sf.eyebrow(
              color: colors.onSurfaceVariant,
            ).copyWith(fontSize: dense ? 8 : null),
          ),
          SizedBox(height: dense ? 2 : 4),
          Text(
            item.note,
            maxLines: dense ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HomeActionData {
  const _HomeActionData({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.section,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final PortalSection section;
}

class _HomeActionRail extends StatelessWidget {
  const _HomeActionRail({required this.title, required this.items});

  final String title;
  final List<_HomeActionData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    if (MediaQuery.sizeOf(context).width < 600) {
      final textScale = MediaQuery.textScalerOf(
        context,
      ).scale(1).clamp(1.0, 2.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${items.length} bo‘lim',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 104 + (textScale - 1) * 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: 146 + (textScale - 1) * 22,
                child: _HomeActionTile(item: items[index], dense: true),
              ),
            ),
          ),
        ],
      );
    }
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 600) ...[
                const SizedBox(width: 12),
                Text(
                  'Kerakli bo‘limga bir bosishda',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 920
                  ? items.length.clamp(1, 4).toInt()
                  : constraints.maxWidth >= 520
                  ? 2
                  : 2;
              const gap = 10.0;
              final width = (constraints.maxWidth - gap * (count - 1)) / count;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _HomeActionTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({required this.item, this.dense = false});

  final _HomeActionData item;
  final bool dense;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = Theme.of(context).colorScheme;
      final accent = colors.brightness == Brightness.dark
          ? Color.lerp(item.color, colors.onSurface, .46)!
          : item.color;
      final compact = dense || constraints.maxWidth < 205;
      final icon = Container(
        width: dense ? 30 : 38,
        height: dense ? 30 : 38,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(item.icon, color: accent, size: dense ? 17 : 20),
      );
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: dense
                ? 1
                : compact
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          Text(
            item.detail,
            maxLines: dense
                ? 1
                : compact
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
      return Material(
        color: accent.withValues(
          alpha: colors.brightness == Brightness.dark ? 0.13 : 0.075,
        ),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _PortalNavigationScope.go(context, item.section),
          child: Padding(
            padding: EdgeInsets.all(dense ? 10 : 13),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          icon,
                          const Spacer(),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 17,
                            color: accent,
                          ),
                        ],
                      ),
                      SizedBox(height: dense ? 7 : 11),
                      copy,
                    ],
                  )
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: 11),
                      Expanded(child: copy),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 17,
                        color: accent,
                      ),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}

class _CockpitColumns extends StatelessWidget {
  const _CockpitColumns({required this.primary, required this.secondary});

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 860) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [primary, const SizedBox(height: 16), secondary],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 11, child: primary),
          const SizedBox(width: 16),
          Expanded(flex: 9, child: secondary),
        ],
      );
    },
  );
}

class _TodayStack extends StatelessWidget {
  const _TodayStack({required this.lessons, required this.homework});

  final List<Map<String, Object?>> lessons;
  final List<Map<String, Object?>> homework;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: 'Bugungi reja',
          meta: '${lessons.length} dars · ${homework.length} vazifa',
          icon: Icons.view_timeline_outlined,
        ),
        const SizedBox(height: 12),
        if (lessons.isEmpty && homework.isEmpty)
          const _CompactEmpty(message: 'Bugungi reja bo‘sh — dam olish vaqti.')
        else ...[
          for (final lesson in lessons.take(3))
            _TimelineRow(
              time: _timeOnly(lesson['starts_at']),
              title: valueText(lesson, const ['title']),
              subtitle:
                  '${valueText(lesson, const ['teacher_name'], fallback: 'Ustoz')} · ${valueText(lesson, const ['room_name'], fallback: 'Xona belgilanmagan')}',
              color: Theme.of(context).colorScheme.primary,
            ),
          for (final task in homework.take(2))
            _TimelineRow(
              time: 'TASK',
              title: valueText(task, const ['title']),
              subtitle: 'Muddat ${_dateLabel(task['due_at'], time: true)}',
              color: Sf.warn,
            ),
        ],
      ],
    ),
  );
}

class _FamilyActivityPanel extends StatelessWidget {
  const _FamilyActivityPanel({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: 'So‘nggi faollik',
          meta: '${rows.length} davomat yozuvi',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const _CompactEmpty(message: 'Hali yangi davomat yozuvi yo‘q.')
        else
          for (final row in rows.take(5))
            _TimelineRow(
              time: _dateLabel(row['date']).split('.').first,
              title: valueText(row, const ['lesson'], fallback: 'Dars'),
              subtitle: _dateLabel(row['date'], time: true),
              color: switch ('${row['status']}') {
                'present' => Sf.success,
                'late' => Sf.warn,
                _ => Theme.of(context).colorScheme.error,
              },
              trailing: _StatusPill(
                valueText(row, const ['status']),
                positive: row['status'] == 'present',
                warning: row['status'] == 'late',
              ),
            ),
      ],
    ),
  );
}

class _RecentResultsPanel extends StatelessWidget {
  const _RecentResultsPanel({required this.grades, required this.rank});

  final List<Map<String, Object?>> grades;
  final Map<String, Object?> rank;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: 'So‘nggi natijalar',
          meta: rank.isEmpty
              ? '${grades.length} ta baho'
              : 'Sinfda ${rank['rank'] ?? '—'} / ${rank['of'] ?? '—'}',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 12),
        if (grades.isEmpty)
          const _CompactEmpty(
            message:
                'Hali baho kiritilmagan. Yangi natijalar shu yerda aniq ko‘rinadi.',
          )
        else
          for (final grade in grades.take(5))
            _TimelineRow(
              time: '${_gradePercentage(grade).round()}%',
              title: valueText(grade, const ['exam'], fallback: 'Natija'),
              subtitle:
                  '${grade['score'] ?? '—'} / ${grade['max_score'] ?? '—'} · ${_dateLabel(grade['exam_date'])}',
              color: _gradePercentage(grade) >= .7 ? Sf.success : Sf.warn,
            ),
        if (grades.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  _PortalNavigationScope.go(context, PortalSection.academics),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Barcha natijalar'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ParentPaymentPanel extends StatelessWidget {
  const _ParentPaymentPanel({
    required this.invoices,
    required this.outstanding,
  });

  final List<Map<String, Object?>> invoices;
  final double outstanding;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: 'To‘lov rejasi',
          meta: outstanding <= 0
              ? 'Balans yopilgan'
              : 'Jami ${_money(context, outstanding)}',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 12),
        if (invoices.isEmpty)
          const _CompactEmpty(
            message:
                'Ochiq to‘lov yo‘q. Yangi hisob chiqarilsa, summa va muddat shu yerda ko‘rinadi.',
          )
        else
          for (final invoice in invoices.take(4))
            _TimelineRow(
              time: _shortDueLabel(invoice['due_date']),
              title: valueText(invoice, const [
                'fee_schedule_name',
                'period',
                'number',
              ], fallback: 'O‘quv to‘lovi'),
              subtitle:
                  '${_invoiceOutstanding(context, invoice)} · ${_dateLabel(invoice['due_date'])} gacha',
              color: _isPastDue(invoice['due_date'])
                  ? Theme.of(context).colorScheme.error
                  : Sf.warn,
              trailing: _StatusPill(
                _isPastDue(invoice['due_date']) ? 'overdue' : 'pending',
                warning: true,
              ),
            ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                _PortalNavigationScope.go(context, PortalSection.finance),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('To‘lovlar tarixi'),
          ),
        ),
      ],
    ),
  );
}

String _invoiceOutstanding(BuildContext context, Map<String, Object?> invoice) {
  final total = double.tryParse('${invoice['total_uzs'] ?? 0}') ?? 0;
  final allocated = valueRows(invoice['allocations']).fold<double>(
    0,
    (sum, row) => sum + (double.tryParse('${row['amount_uzs'] ?? 0}') ?? 0),
  );
  return _money(context, (total - allocated).clamp(0, double.infinity));
}

String _shortDueLabel(Object? raw) {
  final date = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
}

bool _isPastDue(Object? raw) {
  final date = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (date == null) return false;
  final now = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).isBefore(DateTime(now.year, now.month, now.day));
}

// Retained for legacy visual fixtures.
// ignore: unused_element
class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({
    required this.title,
    required this.rate,
    required this.ringLabel,
    required this.ringDetail,
    required this.items,
  });

  final String title;
  final double rate;
  final String ringLabel;
  final String ringDetail;
  final List<_PortalBarDatum> items;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: title,
          meta: items.isEmpty
              ? 'Yangi ma’lumot kutilmoqda'
              : '${items.length} ko‘rsatkich',
          icon: Icons.donut_small_rounded,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: _CompactEmpty(
                      message: 'Tahlil uchun hali ma’lumot yetarli emas.',
                    ),
                  )
                : _CompactBarChart(items: items.take(4).toList());
            final ring = _InteractiveRingChart(
              value: rate,
              label: ringLabel,
              detail: ringDetail,
              size: 94,
              color: Theme.of(context).colorScheme.primary,
            );
            final enlargedText =
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            if (constraints.maxWidth < 390 || enlargedText) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: ring),
                  const SizedBox(height: 14),
                  chart,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ring,
                const SizedBox(width: 14),
                Expanded(child: chart),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _DensePanelHeader extends StatelessWidget {
  const _DensePanelHeader({
    required this.title,
    required this.meta,
    required this.icon,
  });

  final String title;
  final String meta;
  final IconData icon;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final titleRow = Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
      if (constraints.maxWidth < 420 || enlargedText) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow,
            const SizedBox(height: 5),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: titleRow),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              meta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    },
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
  });

  final String time;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.brightness == Brightness.dark
        ? Color.lerp(color, colors.onSurface, .42)!
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(time, style: Sf.monoStyle(size: 10.5, color: accent)),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

// Retained for deterministic legacy golden fixtures; connected runtime uses
// [_RebuiltHomePortalPage].
// ignore: unused_element
class _HomePortalPage extends StatelessWidget {
  const _HomePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return portal.isParent
        ? _parent(context, portal)
        : _student(context, portal);
  }

  Widget _student(BuildContext context, PortalController portal) {
    final attendanceReport = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final upcoming = valueRows(portal.dashboard['next_lessons']);
    final homework = valueRows(portal.dashboard['open_homework']);
    final recentGrades = valueRows(portal.dashboard['recent_grades']);
    final attendanceRate = (double.tryParse('${attendanceReport['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final openHomework =
        valueInt(portal.dashboard['open_homework_count']) ?? homework.length;
    final colors = Theme.of(context).colorScheme;
    return _PortalPage(
      title: 'Salom, ${portal.displayName.split(' ').first}',
      subtitle: 'Bugungi o‘qish holati serverdagi haqiqiy ma’lumotlar asosida.',
      section: PortalSection.home,
      children: [
        _ResponsiveGrid(
          children: [
            _RichMetricCard(
              title: 'Ochiq vazifalar',
              value: '$openHomework',
              icon: Icons.assignment_outlined,
              eyebrow: 'BUGUNGI REJA',
              caption: openHomework == 0
                  ? 'Barcha vazifalar nazorat ostida'
                  : 'Topshirish muddati yaqin ishlar',
              accent: colors.tertiary,
              progress: openHomework == 0 ? 1 : (1 / (openHomework + 1)),
            ),
            _RichMetricCard(
              title: 'Davomat',
              value: attendanceReport['rate'] == null
                  ? '—'
                  : '${(attendanceRate * 100).round()}%',
              icon: Icons.fact_check_outlined,
              eyebrow: '90 KUN',
              caption: 'Kechikishlar ham qatnashgan sifatida hisoblangan',
              accent: Sf.success,
              progress: attendanceRate,
              trend:
                  '${attendanceReport['present'] ?? 0} / ${attendanceReport['of'] ?? 0}',
            ),
            _RichMetricCard(
              title: 'Guruh',
              value: valueText(portal.dashboard, const [
                'group',
              ], fallback: 'Biriktirilmagan'),
              icon: Icons.groups_outlined,
              eyebrow: 'JAMOA',
              caption: 'Joriy o‘quv guruhi',
              accent: colors.primary,
              progress: portal.dashboard['group'] == null ? 0 : 1,
            ),
            _RichMetricCard(
              title: 'Qarzdorlik',
              value: _money(
                context,
                payment['outstanding_uzs'] ??
                    portal.dashboard['outstanding_uzs'],
              ),
              icon: Icons.account_balance_wallet_outlined,
              eyebrow: 'MOLIYA',
              caption: 'Oilaviy kabinetdagi joriy hisob',
              accent: colors.error,
            ),
          ],
        ),
        if (attendanceReport.isNotEmpty || recentGrades.isNotEmpty) ...[
          const SizedBox(height: 16),
          _LearningInsightPanel(
            title: 'O‘qish pulsi',
            ringLabel: 'Qatnashuv',
            ringValue: attendanceRate,
            ringDetail:
                '${attendanceReport['present'] ?? 0} / ${attendanceReport['of'] ?? 0} darsda qatnashgan (kechikishlar bilan).',
            items: [
              for (final grade in recentGrades)
                _PortalBarDatum(
                  label: valueText(grade, const ['exam'], fallback: 'Natija'),
                  value: _gradePercentage(grade),
                  detail:
                      '${grade['score'] ?? '—'} / ${grade['max_score'] ?? '—'} · ${_dateLabel(grade['exam_date'])}',
                  color: colors.primary,
                  icon: Icons.school_outlined,
                ),
            ],
            emptyLabel: 'Yangi baholar paydo bo‘lganda fanlar grafigi to‘ladi.',
          ),
        ],
        if (rank.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InlineMessage(
            text:
                'Sinf reytingi: ${rank['rank']} / ${rank['of']} · o‘rtacha ${rank['average_pct']}%',
            error: false,
          ),
        ],
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yaqin darslar', count: upcoming.length),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Yaqin dars yo‘q',
            message: 'Reja yangilanganda darslar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: upcoming,
            icon: Icons.schedule_rounded,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) => _dateLabel(row['starts_at'], time: true),
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yaqin vazifalar', count: homework.length),
        const SizedBox(height: 10),
        if (homework.isEmpty)
          const _EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Ochiq vazifa yo‘q',
            message: 'Hozircha barcha topshiriqlar bajarilgan.',
          )
        else
          _SimpleRows(
            rows: homework,
            icon: Icons.assignment_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                'Muddat: ${_dateLabel(row['due_at'], time: true)}',
          ),
        if (recentGrades.isNotEmpty) ...[
          const SizedBox(height: 24),
          _PageSectionTitle(
            title: 'So‘nggi natijalar',
            count: recentGrades.length,
          ),
          const SizedBox(height: 10),
          _SimpleRows(
            rows: recentGrades,
            icon: Icons.school_outlined,
            title: (row) => valueText(row, const ['exam']),
            subtitle: (row) =>
                '${row['score']} / ${row['max_score']} · ${_dateLabel(row['exam_date'])}',
          ),
        ],
      ],
    );
  }

  Widget _parent(BuildContext context, PortalController portal) {
    final attendance = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final sheet = valueRows(attendance['sheet']);
    final attendanceRate = (double.tryParse('${attendance['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final colors = Theme.of(context).colorScheme;
    final selected = portal.children
        .where((item) => valueInt(item['id']) == portal.selectedStudentId)
        .firstOrNull;
    return _PortalPage(
      title: 'Oila nazorati',
      subtitle: 'Farzandingizning o‘qish, davomat va moliyaviy holati.',
      section: PortalSection.home,
      trailing: portal.children.length > 1
          ? DropdownButton<int>(
              value: portal.selectedStudentId,
              items: [
                for (final child in portal.children)
                  if (valueInt(child['id']) case final id?)
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        valueText(child, const ['full_name', 'student_id']),
                      ),
                    ),
              ],
              onChanged: (value) {
                if (value != null) portal.selectChild(value);
              },
            )
          : null,
      children: [
        if (portal.children.isEmpty)
          const _EmptyState(
            icon: Icons.family_restroom_rounded,
            title: 'Farzand biriktirilmagan',
            message:
                'Markaz administratori ota-ona akkauntini o‘quvchiga biriktirishi kerak.',
          )
        else ...[
          _SectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    _initials(
                      valueText(selected ?? const {}, const ['full_name']),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valueText(selected ?? const {}, const ['full_name']),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${valueText(selected ?? const {}, const ['student_id'])} · ${valueText(selected ?? const {}, const ['academic_level'], fallback: 'Daraja ko‘rsatilmagan')}',
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  valueText(selected ?? const {}, const ['status']),
                  positive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ResponsiveGrid(
            children: [
              _RichMetricCard(
                title: 'Davomat',
                value: attendance['rate'] == null
                    ? '—'
                    : '${(attendanceRate * 100).round()}%',
                icon: Icons.fact_check_outlined,
                eyebrow: '90 KUNLIK NAZORAT',
                caption: 'Kechikish bilan qatnashilgan darslar',
                accent: Sf.success,
                progress: attendanceRate,
              ),
              _RichMetricCard(
                title: 'Qatnashgan',
                value:
                    '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0}',
                icon: Icons.how_to_reg_outlined,
                eyebrow: 'DARSLAR',
                caption: 'Davomat jurnalidagi real yozuvlar',
                accent: colors.primary,
                progress: attendanceRate,
              ),
              _RichMetricCard(
                title: 'Qarzdorlik',
                value: _money(context, payment['outstanding_uzs']),
                icon: Icons.payments_outlined,
                eyebrow: 'TO‘LOVLAR',
                caption: 'Ochiq hisoblar bo‘yicha jami',
                accent: colors.error,
              ),
              _RichMetricCard(
                title: 'Sinf o‘rni',
                value: rank.isEmpty
                    ? 'Yashirilgan'
                    : '${rank['rank']} / ${rank['of']}',
                icon: Icons.leaderboard_outlined,
                eyebrow: 'REYTING',
                caption: rank.isEmpty
                    ? 'Markaz reytingni oiladan yashirgan'
                    : 'O‘rtacha ${rank['average_pct'] ?? '—'}%',
                accent: colors.tertiary,
                progress: rank.isEmpty
                    ? null
                    : 1 -
                          ((valueInt(rank['rank']) ?? 1) - 1) /
                              ((valueInt(rank['of']) ?? 1).clamp(1, 999)),
              ),
            ],
          ),
          if (attendance.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LearningInsightPanel(
              title: 'Farzand o‘qish pulsi',
              ringLabel: 'Qatnashuv',
              ringValue: attendanceRate,
              ringDetail:
                  '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0} darsda qatnashgan, kechikish qatnashuvga kiradi.',
              items: _attendanceBars(sheet, colors),
              emptyLabel: 'Davomat taqsimoti uchun hali yozuv yetarli emas.',
            ),
          ],
          const SizedBox(height: 24),
          _PageSectionTitle(title: 'So‘nggi davomat', count: sheet.length),
          const SizedBox(height: 10),
          if (sheet.isEmpty)
            const _EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Davomat yozuvi yo‘q',
              message: 'Yangi belgilashlar shu yerda ko‘rinadi.',
            )
          else
            _SimpleRows(
              rows: sheet,
              icon: Icons.school_outlined,
              title: (row) => valueText(row, const ['lesson']),
              subtitle: (row) => _dateLabel(row['date'], time: true),
              trailing: (row) => _StatusPill(
                valueText(row, const ['status']),
                positive: row['status'] == 'present',
                warning: row['status'] == 'late',
              ),
            ),
        ],
      ],
    );
  }
}

class _LearningInsightPanel extends StatelessWidget {
  const _LearningInsightPanel({
    required this.title,
    required this.ringLabel,
    required this.ringValue,
    required this.ringDetail,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final String ringLabel;
  final double ringValue;
  final String ringDetail;
  final List<_PortalBarDatum> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ring = _InteractiveRingChart(
          value: ringValue,
          label: ringLabel,
          detail: ringDetail,
          color: colors.primary,
          size: constraints.maxWidth < 560 ? 108 : 128,
          centerIcon: Icons.insights_rounded,
        );
        final bars = items.isEmpty
            ? _SectionCard(
                child: SizedBox(
                  height: 130,
                  child: Center(
                    child: Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            : _CompactBarChart(title: title, items: items);
        if (constraints.maxWidth < 720) {
          return Column(children: [ring, const SizedBox(height: 12), bars]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 218, child: ring),
            const SizedBox(width: 12),
            Expanded(child: bars),
          ],
        );
      },
    );
  }
}

double _gradePercentage(Map<String, Object?> grade) {
  final score =
      double.tryParse('${grade['score'] ?? grade['value_raw'] ?? 0}') ?? 0;
  final maximum = double.tryParse('${grade['max_score'] ?? 100}') ?? 100;
  if (maximum <= 0) return 0;
  return (score / maximum * 100).clamp(0, 100).toDouble();
}

List<_PortalBarDatum> _attendanceBars(
  List<Map<String, Object?>> rows,
  ColorScheme colors,
) {
  if (rows.isEmpty) return const [];
  const definitions = [
    ('present', 'O‘z vaqtida', Icons.check_circle_outline_rounded),
    ('late', 'Kechikib keldi', Icons.schedule_rounded),
    ('absent', 'Kelmadi', Icons.cancel_outlined),
    ('excused', 'Sababli', Icons.health_and_safety_outlined),
  ];
  return [
    for (final definition in definitions)
      if (rows.where((row) => row['status'] == definition.$1).length
          case final count when count > 0)
        _PortalBarDatum(
          label: definition.$2,
          value: count / rows.length * 100,
          detail: '$count / ${rows.length} davomat yozuvi',
          color: switch (definition.$1) {
            'present' => Sf.success,
            'late' => Sf.warn,
            'absent' => colors.error,
            _ => colors.tertiary,
          },
          icon: definition.$3,
        ),
  ];
}

List<String> _linksInText(String text) {
  final links = <String>[];
  for (final match in RegExp(r'https?://[^\s<>()]+').allMatches(text)) {
    var link = match.group(0) ?? '';
    while (link.isNotEmpty && '.,;:!?)]}'.contains(link[link.length - 1])) {
      link = link.substring(0, link.length - 1);
    }
    if (link.isNotEmpty && !links.contains(link)) links.add(link);
  }
  return links;
}

class _AssignmentResource {
  const _AssignmentResource({
    required this.name,
    required this.kind,
    this.viewUrl,
    this.downloadUrl,
    this.downloadAllowed = false,
  });

  final String name;
  final String kind;
  final String? viewUrl;
  final String? downloadUrl;
  final bool downloadAllowed;

  factory _AssignmentResource.from(Object? raw) {
    final map = valueMap(raw);
    final rawText = raw is String ? raw.trim() : '';
    String? firstUrl(List<String> keys) {
      for (final key in keys) {
        final value = '${map[key] ?? ''}'.trim();
        if (Uri.tryParse(value)?.hasScheme == true) return value;
      }
      return null;
    }

    final directUrl = Uri.tryParse(rawText)?.hasScheme == true ? rawText : null;
    final viewUrl =
        firstUrl(const [
          'preview_url',
          'view_url',
          'url',
          'link',
          'public_url',
        ]) ??
        directUrl;
    final downloadUrl = firstUrl(const ['download_url', 'download_link']);
    final sourceName = valueText(map, const [
      'name',
      'title',
      'filename',
      'file_name',
      'key',
    ], fallback: rawText);
    final urlName = Uri.tryParse(
      viewUrl ?? downloadUrl ?? '',
    )?.pathSegments.lastOrNull;
    final name = (sourceName.isNotEmpty ? sourceName : urlName ?? 'Material')
        .split('/')
        .last;
    final declaredKind = valueText(map, const [
      'content_type',
      'mime_type',
      'file_type',
      'type',
    ], fallback: '').toLowerCase();
    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    final kind = declaredKind.isNotEmpty ? declaredKind : extension;
    final downloadAllowed =
        map['download_allowed'] == true ||
        map['allow_download'] == true ||
        map['is_downloadable'] == true;
    return _AssignmentResource(
      name: name,
      kind: kind,
      viewUrl: viewUrl,
      downloadUrl: downloadUrl,
      downloadAllowed: downloadAllowed,
    );
  }
}

class _AssignmentResourceTile extends StatelessWidget {
  const _AssignmentResourceTile({required this.resource, this.compact = false});

  final Object? resource;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final item = _AssignmentResource.from(resource);
    final download = item.downloadAllowed
        ? item.downloadUrl ?? item.viewUrl
        : null;
    final isVideo =
        item.kind.contains('video') ||
        const {'mp4', 'mov', 'webm', 'mkv'}.contains(item.kind);
    final isPdf = item.kind.contains('pdf');
    final isImage =
        item.kind.contains('image') ||
        const {'png', 'jpg', 'jpeg', 'webp', 'gif'}.contains(item.kind);
    final isLink = item.viewUrl != null && !isVideo && !isPdf && !isImage;
    final icon = isVideo
        ? Icons.play_circle_outline_rounded
        : isPdf
        ? Icons.picture_as_pdf_outlined
        : isImage
        ? Icons.image_outlined
        : isLink
        ? Icons.link_rounded
        : Icons.attach_file_rounded;
    final typeLabel = isVideo
        ? 'Video lesson'
        : isPdf
        ? 'PDF document'
        : isImage
        ? 'Image'
        : isLink
        ? 'Learning link'
        : item.viewUrl == null
        ? 'Protected attachment'
        : 'Learning material';
    final openLabel = isVideo
        ? 'Play'
        : isPdf
        ? 'View PDF'
        : isImage
        ? 'View'
        : 'Open';
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 9 : 11,
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: compact ? 18 : 21, color: colors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (item.viewUrl case final url?)
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: openLabel,
                onPressed: () => _launch(context, url),
                icon: Icon(
                  isVideo
                      ? Icons.play_arrow_rounded
                      : Icons.open_in_new_rounded,
                ),
              ),
            if (download != null) ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Download',
                onPressed: () => _launch(context, download),
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssignmentsPortalPage extends StatelessWidget {
  const _AssignmentsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final submissionByAssignment = latestAssignmentSubmissions(
      portal.submissions,
    );
    final visible = portal.assignments
        .where(
          (item) => const {'published', 'closed'}.contains('${item['status']}'),
        )
        .toList();
    return _PortalPage(
      title: portal.isParent ? 'Farzand vazifalari' : 'Vazifalar',
      subtitle: portal.isParent
          ? 'Topshiriqlar, muddatlar va farzandingizning topshirish holati.'
          : 'Topshiriq tafsilotlari, muddat va serverdagi topshirish holati.',
      section: PortalSection.assignments,
      children: [
        if (visible.isEmpty)
          const _EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Hozircha faol vazifa yo‘q',
            message:
                'Ustoz yangi topshiriq e’lon qilganda uning matni, muddati va materiallari shu yerda ko‘rinadi.',
          )
        else
          ...visible.map((assignment) {
            final id = valueInt(assignment['id']);
            final submission = id == null ? null : submissionByAssignment[id];
            final attempts = id == null
                ? const <Map<String, Object?>>[]
                : (portal.submissions
                      .where(
                        (item) =>
                            valueInt(item['assignment']) == id ||
                            valueInt(item['assignment_id']) == id,
                      )
                      .toList()
                    ..sort(
                      (a, b) => (valueInt(a['attempt_number']) ?? 0).compareTo(
                        valueInt(b['attempt_number']) ?? 0,
                      ),
                    ));
            final grade = valueMap(submission?['grade']);
            final resources = assignment['attachments'] is List
                ? List<Object?>.from(assignment['attachments']! as List)
                : const <Object?>[];
            final description = valueText(assignment, const [
              'description',
            ], fallback: '');
            final links = _linksInText(description);
            final canSubmit =
                portal.can('assignments:submit') &&
                assignmentAcceptsAnotherSubmission(assignment, submission);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SectionCard(
                padding: EdgeInsets.zero,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        width: 4,
                        color: submission == null
                            ? Theme.of(context).colorScheme.primary
                            : Sf.success,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.assignment_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  valueText(assignment, const ['title']),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  valueText(assignment, const [
                                    'cohort_name',
                                  ], fallback: 'Guruh'),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Muddat: ${_dateLabel(assignment['due_at'], time: true)}',
                                ),
                              ],
                            ),
                          ),
                          _StatusPill(
                            submission == null
                                ? valueText(assignment, const ['status'])
                                : valueText(submission, const ['status']),
                            positive: submission != null,
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          description,
                          maxLines: 7,
                          overflow: TextOverflow.fade,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                      if (resources.isNotEmpty || links.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Dars materiallari',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        for (final resource in resources.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: _AssignmentResourceTile(
                              resource: resource,
                              compact: true,
                            ),
                          ),
                        for (final link in links.take(2))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: _AssignmentResourceTile(
                              resource: {'url': link, 'name': link},
                              compact: true,
                            ),
                          ),
                      ],
                      if (grade['graded'] == true) ...[
                        const SizedBox(height: 12),
                        _InlineMessage(
                          text:
                              'Baho: ${grade['score']} / ${assignment['max_score']}\n${valueText(grade, const ['feedback'], fallback: 'Ustoz izoh qoldirmagan.')}',
                          error: false,
                        ),
                      ],
                      if (portal.isStudent || portal.isParent) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            key: id == null
                                ? null
                                : ValueKey('assignment-detail-$id'),
                            onPressed: id == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => PortalScope(
                                          controller: portal,
                                          child: _AssignmentDetailScreen(
                                            portal: portal,
                                            assignment: assignment,
                                            submission: submission,
                                            attempts: attempts,
                                            allowSubmit: canSubmit,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            icon: Icon(
                              portal.isParent
                                  ? Icons.visibility_outlined
                                  : submission == null && canSubmit
                                  ? Icons.upload_file_rounded
                                  : canSubmit
                                  ? Icons.replay_rounded
                                  : Icons.visibility_outlined,
                            ),
                            label: Text(
                              portal.isParent
                                  ? 'Tafsilotlar'
                                  : submission == null && canSubmit
                                  ? 'Topshirish'
                                  : canSubmit
                                  ? 'Qayta topshirish'
                                  : submission == null
                                  ? 'Tafsilotlar'
                                  : 'Ishni ko‘rish',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _AssignmentDetailScreen extends StatefulWidget {
  const _AssignmentDetailScreen({
    required this.portal,
    required this.assignment,
    required this.submission,
    required this.attempts,
    required this.allowSubmit,
  });

  final PortalController portal;
  final Map<String, Object?> assignment;
  final Map<String, Object?>? submission;
  final List<Map<String, Object?>> attempts;
  final bool allowSubmit;

  @override
  State<_AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<_AssignmentDetailScreen> {
  Map<String, Object?>? _assignment;
  Map<String, Object?>? _submission;
  List<Map<String, Object?>> _attempts = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final id = valueInt(widget.assignment['id']);
      if (id == null) {
        throw const ApiException(message: 'Vazifa identifikatori topilmadi.');
      }
      final detail = await widget.portal.loadAssignmentDetail(id);
      var fullSubmission = widget.submission;
      final submissionId = valueInt(widget.submission?['id']);
      if (submissionId != null) {
        fullSubmission = {
          ...?widget.submission,
          ...await widget.portal.loadSubmissionDetail(submissionId),
        };
      }
      final detailedAttempts = [
        for (final attempt in widget.attempts)
          if (submissionId != null && valueInt(attempt['id']) == submissionId)
            fullSubmission ?? attempt
          else
            attempt,
      ];
      if (!mounted) return;
      setState(() {
        _assignment = {...widget.assignment, ...detail};
        _submission = fullSubmission;
        _attempts = detailedAttempts;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('assignment-detail-page'),
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'Vazifa tafsilotlari',
            ru: 'Детали задания',
            en: 'Assignment details',
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: SizedBox.square(
                  dimension: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyState(
                    icon: Icons.assignment_late_outlined,
                    title: _familyCopy(
                      context,
                      uz: 'Vazifani ochib bo‘lmadi',
                      ru: 'Не удалось открыть задание',
                      en: 'Could not open the assignment',
                    ),
                    message: _error!,
                    actionLabel: _familyCopy(
                      context,
                      uz: 'Qayta urinish',
                      ru: 'Повторить',
                      en: 'Try again',
                    ),
                    onAction: _load,
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _AssignmentSubmitSheet(
                    assignment: _assignment!,
                    submission: _submission,
                    attempts: _attempts,
                    allowSubmit: widget.allowSubmit,
                  ),
                ),
              ),
      ),
    );
  }
}

class _AssignmentSubmitSheet extends StatefulWidget {
  const _AssignmentSubmitSheet({
    required this.assignment,
    required this.allowSubmit,
    required this.attempts,
    this.submission,
  });

  final Map<String, Object?> assignment;
  final Map<String, Object?>? submission;
  final List<Map<String, Object?>> attempts;
  final bool allowSubmit;

  @override
  State<_AssignmentSubmitSheet> createState() => _AssignmentSubmitSheetState();
}

class _AssignmentSubmitSheetState extends State<_AssignmentSubmitSheet> {
  late final TextEditingController _text;
  final List<PlatformFile> _files = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: valueText(widget.submission ?? const {}, const [
        'text',
      ], fallback: ''),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null) return;
    setState(() {
      _files
        ..clear()
        ..addAll(result.files.take(5));
    });
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty && _files.isEmpty) {
      setState(() => _error = 'Matn yozing yoki fayl tanlang.');
      return;
    }
    final id = valueInt(widget.assignment['id']);
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final portal = PortalScope.read(context);
      final keys = <String>[];
      for (final file in _files) {
        final bytes = await readSelectedFileBytes(file.bytes, file.path);
        keys.add(
          await portal.uploadAssignmentFile(
            filename: file.name,
            contentType: _contentType(file.extension),
            bytes: bytes,
          ),
        );
      }
      await portal.submitAssignment(
        assignmentId: id,
        text: _text.text,
        attachmentKeys: keys,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Vazifa serverga topshirildi.')),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.allowSubmit;
    final grade = valueMap(widget.submission?['grade']);
    final aiFeedback = valueText(grade, const ['ai_feedback'], fallback: '');
    final attempt = valueInt(widget.submission?['attempt_number']);
    final maxResubmits = valueInt(widget.assignment['max_resubmits']);
    final assignmentAttachments = widget.assignment['attachments'] is List
        ? List<Object?>.from(widget.assignment['attachments']! as List)
        : const <Object?>[];
    final description = valueText(widget.assignment, const [
      'description',
    ], fallback: 'Tavsif berilmagan.');
    final descriptionLinks = _linksInText(description);
    final rubric = valueRows(widget.assignment['rubric']);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        padding: const EdgeInsets.all(22),
        shrinkWrap: true,
        children: [
          Text(
            valueText(widget.assignment, const ['title']),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                'Muddat: ${_dateLabel(widget.assignment['due_at'], time: true)}',
                warning:
                    DateTime.tryParse(
                      '${widget.assignment['due_at']}',
                    )?.isBefore(DateTime.now()) ==
                    true,
              ),
              _StatusPill(
                'Maksimum: ${widget.assignment['max_score'] ?? '—'}',
                positive: true,
              ),
              _StatusPill(
                'Urinishlar: ${maxResubmits == null ? 'cheklanmagan' : maxResubmits + 1}',
              ),
            ],
          ),
          if (assignmentAttachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Dars materiallari',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final attachment in assignmentAttachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AssignmentResourceTile(resource: attachment),
              ),
          ],
          if (descriptionLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final link in descriptionLinks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AssignmentResourceTile(
                  resource: {'url': link, 'name': link},
                ),
              ),
          ],
          if (rubric.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Baholash mezonlari',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (final criterion in rubric)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.rule_folder_outlined),
                title: Text(
                  valueText(criterion, const ['criterion', 'title', 'name']),
                ),
                trailing: Text(
                  '${criterion['max_points'] ?? criterion['points'] ?? '—'} ball',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
          ],
          if (attempt != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              text: maxResubmits == null
                  ? '$attempt-urinish · ${valueText(widget.submission!, const ['status'])}'
                  : '$attempt / ${maxResubmits + 1}-urinish · ${valueText(widget.submission!, const ['status'])}',
              error: false,
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _text,
            enabled: !readOnly && !_busy,
            minLines: 5,
            maxLines: 10,
            maxLength: 20000,
            decoration: const InputDecoration(
              labelText: 'Javob matni',
              alignLabelWithHint: true,
            ),
          ),
          if (!readOnly) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _files.isEmpty
                    ? 'Fayl biriktirish'
                    : '${_files.length} ta fayl tanlandi',
              ),
            ),
            if (_files.isNotEmpty)
              ..._files.map(
                (file) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(file.name),
                  subtitle: Text('${file.size ~/ 1024} KB'),
                ),
              ),
          ],
          if (grade.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (grade['graded'] == true)
              _InlineMessage(
                text:
                    'Ustoz bahosi: ${grade['score']}\n${valueText(grade, const ['feedback'], fallback: 'Izoh yo‘q')}',
                error: false,
              ),
            if (aiFeedback.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI tahlili',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(aiFeedback),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (grade['graded'] != true && aiFeedback.isEmpty)
              const _InlineMessage(text: 'Tekshirilmoqda', error: false),
          ],
          if (widget.attempts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Topshirish tarixi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final previous in widget.attempts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SectionCard(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      '${previous['attempt_number'] ?? '—'}-urinish · ${_statusLabel('${previous['status']}')}',
                    ),
                    subtitle: Text(
                      '${_dateLabel(previous['submitted_at'], time: true)}${previous['is_late'] == true ? ' · kech topshirilgan' : ''}',
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          valueText(previous, const [
                            'text',
                          ], fallback: 'Matnli javob yo‘q.'),
                        ),
                      ),
                      if (previous['attachments'] is List &&
                          (previous['attachments']! as List).isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final attachment
                                    in previous['attachments']! as List)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: _AssignmentResourceTile(
                                      resource: attachment,
                                      compact: true,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (valueMap(previous['grade']).isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Baho: ${valueMap(previous['grade'])['score'] ?? 'tekshirilmoqda'}\n${valueText(valueMap(previous['grade']), const ['feedback'], fallback: 'Ustoz izohi yo‘q.')}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            _InlineMessage(text: error, error: true),
          ],
          const SizedBox(height: 18),
          if (!readOnly)
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _busy
                    ? 'Yuborilmoqda…'
                    : widget.submission == null
                    ? 'Serverga topshirish'
                    : 'Yangi urinishni topshirish',
              ),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Yopish'),
            ),
        ],
      ),
    );
  }
}

class _SchedulePortalPage extends StatelessWidget {
  const _SchedulePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final rows = [...portal.lessons]
      ..sort((a, b) => '${a['starts_at']}'.compareTo('${b['starts_at']}'));
    return _PortalPage(
      title: portal.isParent
          ? _familyCopy(
              context,
              uz: 'Oila taqvimi',
              ru: 'Семейный календарь',
              en: 'Family calendar',
            )
          : _familyCopy(
              context,
              uz: 'Dars jadvali',
              ru: 'Расписание занятий',
              en: 'Class schedule',
            ),
      subtitle: portal.isParent
          ? _familyCopy(
              context,
              uz: 'Farzandingizning darslari, vaqti va xonasi.',
              ru: 'Занятия ребёнка, время и кабинет.',
              en: 'Your child’s classes, times and rooms.',
            )
          : _familyCopy(
              context,
              uz: 'Dars vaqti, xonasi va ustoz haqidagi kerakli ma’lumotlar.',
              ru: 'Время, кабинет и преподаватель для каждого занятия.',
              en: 'The time, room and teacher for each class.',
            ),
      section: PortalSection.schedule,
      children: [
        _PageSectionTitle(
          title: _familyCopy(
            context,
            uz: 'Darslar',
            ru: 'Занятия',
            en: 'Classes',
          ),
          count: rows.length,
        ),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          _EmptyState(
            icon: Icons.calendar_today_outlined,
            title: _familyCopy(
              context,
              uz: 'Jadval bo‘sh',
              ru: 'Расписание пусто',
              en: 'Schedule is empty',
            ),
            message: _familyCopy(
              context,
              uz: 'Hozircha ko‘rinadigan dars mavjud emas.',
              ru: 'Пока нет доступных занятий.',
              en: 'There are no visible classes yet.',
            ),
          )
        else
          _LessonScheduleGrid(
            lessons: rows,
            onOpen: (lesson) => _openLesson(context, portal, lesson),
          ),
      ],
    );
  }

  void _openLesson(
    BuildContext context,
    PortalController portal,
    Map<String, Object?> lesson,
  ) {
    final id = valueInt(lesson['id']);
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PortalScope(
          controller: portal,
          child: _LessonDetailScreen(
            portal: portal,
            lessonId: id,
            initialLesson: lesson,
          ),
        ),
      ),
    );
  }
}

class _LessonDetailScreen extends StatefulWidget {
  const _LessonDetailScreen({
    required this.portal,
    required this.lessonId,
    required this.initialLesson,
  });

  final PortalController portal;
  final int lessonId;
  final Map<String, Object?> initialLesson;

  @override
  State<_LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<_LessonDetailScreen> {
  late Future<Map<String, Object?>> _future = _load();

  Future<Map<String, Object?>> _load() async => {
    ...widget.initialLesson,
    ...await widget.portal.loadScheduleLessonDetail(widget.lessonId),
  };

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'Dars tafsilotlari',
            ru: 'Детали занятия',
            en: 'Class details',
          ),
        ),
      ),
      body: FutureBuilder<Map<String, Object?>>(
        future: _future,
        initialData: widget.initialLesson,
        builder: (context, snapshot) {
          final lesson = snapshot.data ?? widget.initialLesson;
          return Stack(
            children: [
              _LessonDetailBody(lesson: lesson),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (snapshot.hasError)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Material(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off_rounded, color: colors.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _familyCopy(
                                context,
                                uz: 'To‘liq ma’lumot yuklanmadi. Jadvaldagi ma’lumot ko‘rsatildi.',
                                ru: 'Полные данные не загрузились. Показаны данные из расписания.',
                                en: 'Full details could not be loaded. Schedule data is shown.',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _retry,
                            child: Text(
                              _familyCopy(
                                context,
                                uz: 'Qayta',
                                ru: 'Повторить',
                                en: 'Retry',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonDetailBody extends StatelessWidget {
  const _LessonDetailBody({required this.lesson});

  final Map<String, Object?> lesson;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = valueText(
      lesson,
      const ['title', 'lesson_type_name'],
      fallback: _familyCopy(
        context,
        uz: 'Rejalashtirilgan dars',
        ru: 'Запланированное занятие',
        en: 'Scheduled class',
      ),
    );
    final status = '${lesson['status'] ?? ''}';
    final cancelled = status.toLowerCase().contains('cancel');
    final fields = <(IconData, String, String)>[
      (
        Icons.calendar_month_outlined,
        _familyCopy(context, uz: 'Davr', ru: 'Период', en: 'Term'),
        valueText(lesson, const ['term_name'], fallback: '—'),
      ),
      (
        Icons.groups_2_outlined,
        _familyCopy(context, uz: 'Guruh', ru: 'Группа', en: 'Group'),
        valueText(lesson, const ['cohort_name'], fallback: '—'),
      ),
      (
        Icons.person_outline_rounded,
        _familyCopy(context, uz: 'Ustoz', ru: 'Преподаватель', en: 'Teacher'),
        valueText(lesson, const ['teacher_name'], fallback: '—'),
      ),
      (
        Icons.meeting_room_outlined,
        _familyCopy(context, uz: 'Xona', ru: 'Кабинет', en: 'Room'),
        valueText(lesson, const ['room_name'], fallback: '—'),
      ),
      (
        Icons.school_outlined,
        _familyCopy(
          context,
          uz: 'Dars turi',
          ru: 'Тип занятия',
          en: 'Class type',
        ),
        valueText(lesson, const ['lesson_type_name'], fallback: '—'),
      ),
      (
        Icons.schedule_rounded,
        _familyCopy(context, uz: 'Boshlanish', ru: 'Начало', en: 'Starts'),
        _dateLabel(lesson['starts_at'], time: true),
      ),
      (
        Icons.timelapse_rounded,
        _familyCopy(context, uz: 'Tugash', ru: 'Окончание', en: 'Ends'),
        _dateLabel(lesson['ends_at'], time: true),
      ),
      (
        Icons.repeat_rounded,
        _familyCopy(
          context,
          uz: 'Takroriy reja',
          ru: 'Повторяющийся план',
          en: 'Recurring plan',
        ),
        lesson['detached_from_rule'] == true
            ? _familyCopy(
                context,
                uz: 'Rejadan ajratilgan',
                ru: 'Отделено от плана',
                en: 'Detached from plan',
              )
            : _familyCopy(
                context,
                uz: 'Reja bo‘yicha',
                ru: 'По плану',
                en: 'Follows the plan',
              ),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cancelled
                  ? [colors.error, colors.errorContainer]
                  : [colors.primary, colors.secondary],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _statusLabel(status).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_dateLabel(lesson['starts_at'])} · ${_timeOnly(lesson['starts_at'])}–${_timeOnly(lesson['ends_at'])}',
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 660 ? 2 : 1;
              return Wrap(
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: constraints.maxWidth / columns,
                      child: ListTile(
                        leading: Icon(field.$1, color: colors.primary),
                        title: Text(field.$2),
                        subtitle: Text(
                          field.$3,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (cancelled ||
            valueText(lesson, const ['cancel_reason']).isNotEmpty) ...[
          const SizedBox(height: 14),
          _InlineMessage(
            text: valueText(
              lesson,
              const ['cancel_reason'],
              fallback: _familyCopy(
                context,
                uz: 'Dars markaz tomonidan bekor qilingan.',
                ru: 'Занятие отменено учебным центром.',
                en: 'The class was cancelled by the learning center.',
              ),
            ),
            error: true,
          ),
        ],
      ],
    );
  }
}

class _LessonScheduleGrid extends StatelessWidget {
  const _LessonScheduleGrid({required this.lessons, required this.onOpen});

  final List<Map<String, Object?>> lessons;
  final ValueChanged<Map<String, Object?>> onOpen;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = switch (width) {
          _ when width < 280 || textScale >= 1.75 => 1,
          _ when width < 600 => 2,
          _ when width < 900 => 3,
          _ when width < 1200 => 4,
          _ => 5,
        };
        const gap = 10.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          key: const ValueKey('schedule-lessons-grid'),
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final lesson in lessons)
              SizedBox(
                width: cardWidth,
                child: _LessonScheduleCard(
                  lesson: lesson,
                  onOpen: valueInt(lesson['id']) == null
                      ? null
                      : () => onOpen(lesson),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LessonScheduleCard extends StatelessWidget {
  const _LessonScheduleCard({required this.lesson, required this.onOpen});

  final Map<String, Object?> lesson;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = '${lesson['status'] ?? ''}'.toLowerCase();
    final startsAt = DateTime.tryParse(
      '${lesson['starts_at'] ?? ''}',
    )?.toLocal();
    final endsAt = DateTime.tryParse('${lesson['ends_at'] ?? ''}')?.toLocal();
    final now = DateTime.now();
    final inProgress =
        startsAt != null &&
        endsAt != null &&
        !now.isBefore(startsAt) &&
        now.isBefore(endsAt) &&
        status != 'cancelled' &&
        status != 'canceled';
    final cancelled = status == 'cancelled' || status == 'canceled';
    final completed =
        status == 'completed' ||
        (endsAt != null && endsAt.isBefore(now) && !cancelled);
    final accent = cancelled
        ? colors.error
        : inProgress
        ? Sf.success
        : completed
        ? colors.onSurfaceVariant
        : colors.primary;
    final statusLabel = inProgress
        ? 'Hozir'
        : _statusLabel(status.isEmpty ? 'scheduled' : status);
    final id = valueInt(lesson['id']);

    return _SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('schedule-lesson-card-${id ?? 'unknown'}'),
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 172),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        _compactDateLabel(lesson['starts_at']),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.circle, size: 7, color: accent),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  valueText(lesson, const ['title'], fallback: 'Dars'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                _LessonMetaLine(
                  icon: Icons.person_outline_rounded,
                  text: valueText(lesson, const [
                    'teacher_name',
                  ], fallback: 'Ustoz'),
                ),
                const SizedBox(height: 5),
                _LessonMetaLine(
                  icon: Icons.meeting_room_outlined,
                  text: valueText(lesson, const [
                    'room_name',
                  ], fallback: 'Xona belgilanmagan'),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 15, color: accent),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${_timeOnly(lesson['starts_at'])}–${_timeOnly(lesson['ends_at'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Tooltip(
                      key: ValueKey('lesson-detail-${id ?? 'unknown'}'),
                      message: 'Dars tafsilotlari',
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: onOpen == null ? colors.outline : accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonMetaLine extends StatelessWidget {
  const _LessonMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _CatalogPill extends StatelessWidget {
  const _CatalogPill({required this.icon, required this.label, this.detail});

  final IconData icon;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            detail == null || detail == '—–—' ? label : '$label · $detail',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AttendancePortalPage extends StatelessWidget {
  const _AttendancePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final summary = portal.attendanceSummary;
    final hasSummary = summary.isNotEmpty;
    final studentId = portal.selectedStudentId;
    final rows = portal.isParent && studentId != null
        ? portal.attendance
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.attendance;
    final timelyRate =
        ((double.tryParse('${summary['percent_present']}') ?? 0) / 100)
            .clamp(0.0, 1.0)
            .toDouble();
    final colors = Theme.of(context).colorScheme;
    return _PortalPage(
      title: portal.isParent ? 'Farzand davomati' : 'Mening davomatim',
      subtitle: 'Joriy davr bo‘yicha belgilangan qatnashuv holatlari.',
      section: PortalSection.attendance,
      children: [
        if (!hasSummary) ...[
          const _InlineMessage(
            text:
                'Hisoblash uchun joriy o‘quv davri topilmadi. Bu 0% degani emas — davr yoki davomat yozuvlari serverda yaratilishi kerak.',
            error: false,
          ),
          const SizedBox(height: 12),
        ],
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'O‘z vaqtida',
              value: hasSummary ? '${summary['percent_present']}%' : '—',
              icon: Icons.donut_large_rounded,
            ),
            _MetricCard(
              label: 'Keldi',
              value: hasSummary ? '${summary['present'] ?? 0}' : '—',
              icon: Icons.check_circle_outline_rounded,
            ),
            _MetricCard(
              label: 'Kechikdi',
              value: hasSummary ? '${summary['late'] ?? 0}' : '—',
              icon: Icons.schedule_rounded,
            ),
            _MetricCard(
              label: 'Kelmadi',
              value: hasSummary ? '${summary['absent'] ?? 0}' : '—',
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasSummary)
          _LearningInsightPanel(
            title: 'Davomat taqsimoti',
            ringLabel: 'Vaqtida',
            ringValue: timelyRate,
            ringDetail:
                '${summary['present'] ?? 0} ta darsga o‘z vaqtida kelgan. Kechikish bu ko‘rsatkichka kirmaydi.',
            items: _attendanceBars(rows, colors),
            emptyLabel:
                'Davomat yozuvlari kelganda taqsimot shu yerda chiqadi.',
          ),
        const SizedBox(height: 24),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'Davomat yozuvi yo‘q',
            message: 'Ustoz belgilagan yozuvlar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: rows,
            icon: Icons.school_outlined,
            title: (row) => valueText(row, const ['lesson_title']),
            subtitle: (row) =>
                '${_dateLabel(row['lesson_starts_at'], time: true)} · ${valueText(row, const ['teacher_name'], fallback: 'Ustoz')}',
            trailing: (row) => _StatusPill(
              valueText(row, const ['status']),
              positive: row['status'] == 'present',
              warning: row['status'] == 'late',
            ),
            onTap: (row) async {
              final id = valueInt(row['id']);
              if (id == null) return;
              final loaded = await _loadApiDetail(
                context,
                () => portal.loadAttendanceRecordDetail(id),
              );
              if (loaded == null || !context.mounted) return;
              final detail = {...row, ...loaded};
              await _showJsonDetail(
                context,
                title: valueText(detail, const ['lesson_title']),
                fields: {
                  'O‘quvchi': valueText(detail, const ['student_name']),
                  'Guruh': valueText(detail, const ['cohort_name']),
                  'Ustoz': valueText(detail, const ['teacher_name']),
                  'Dars': _dateLabel(detail['lesson_starts_at'], time: true),
                  'Holat': _statusLabel('${detail['status']}'),
                  'Kelgan vaqt': _dateLabel(detail['arrived_at'], time: true),
                  'Izoh': valueText(detail, const ['note']),
                  'Belgilangan': _dateLabel(detail['marked_at'], time: true),
                  'Avtomatik': detail['auto_marked'] == true ? 'Ha' : 'Yo‘q',
                },
                rawDetail: loaded,
              );
            },
          ),
      ],
    );
  }
}

String _contentType(
  String? extension, {
  String filename = '',
}) => switch ((extension ?? '').toLowerCase()) {
  'pdf' => 'application/pdf',
  'mp3' => 'audio/mpeg',
  'm4a' => 'audio/mp4',
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

({String extension, String contentType}) recordedVoiceUploadFormat(
  Uint8List bytes,
  String fallbackExtension,
) {
  bool hasAscii(int offset, String value) {
    if (offset < 0 || bytes.length < offset + value.length) return false;
    for (var index = 0; index < value.length; index++) {
      if (bytes[offset + index] != value.codeUnitAt(index)) return false;
    }
    return true;
  }

  if (hasAscii(4, 'ftyp')) {
    if (hasAscii(8, 'M4A ')) {
      return (extension: 'm4a', contentType: 'audio/mp4');
    }
    // Safety fallback for a recording that has not passed through
    // normalizeRecordedM4aBrand yet. It must never be declared audio/mp4.
    return (extension: 'mp4', contentType: 'video/mp4');
  }
  if (hasAscii(0, 'RIFF') && hasAscii(8, 'WAVE')) {
    return (extension: 'wav', contentType: 'audio/wav');
  }
  if (hasAscii(0, 'OggS')) {
    return (extension: 'ogg', contentType: 'audio/ogg');
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x1A &&
      bytes[1] == 0x45 &&
      bytes[2] == 0xDF &&
      bytes[3] == 0xA3) {
    return (extension: 'webm', contentType: 'audio/webm');
  }
  final extension = fallbackExtension.toLowerCase();
  return (
    extension: extension,
    contentType: _contentType(extension, filename: 'voice.$extension'),
  );
}

String _timeOnly(Object? raw) {
  final date = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (date == null) return '—';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _PageSectionTitle extends StatelessWidget {
  const _PageSectionTitle({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _portalUiLiteral(context, title),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (count != null)
          _StatusPill(switch (PortalScope.of(context).preferences.language) {
            PortalLanguage.uz => '$count ta',
            PortalLanguage.ru => '$count',
            PortalLanguage.en => '$count',
          }),
      ],
    );
  }
}

class _SimpleRows extends StatelessWidget {
  const _SimpleRows({
    required this.rows,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.rowKey,
  });

  final List<Map<String, Object?>> rows;
  final IconData icon;
  final String Function(Map<String, Object?>) title;
  final String Function(Map<String, Object?>) subtitle;
  final Widget Function(Map<String, Object?>)? trailing;
  final void Function(Map<String, Object?>)? onTap;
  final Key? Function(Map<String, Object?>)? rowKey;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            ListTile(
              key: rowKey?.call(rows[index]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(child: Icon(icon, size: 20)),
              title: Text(title(rows[index])),
              subtitle: Text(subtitle(rows[index])),
              trailing: trailing?.call(rows[index]),
              onTap: onTap == null ? null : () => onTap!(rows[index]),
            ),
            if (index != rows.length - 1) const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }
}

class _AcademicsPortalPage extends StatelessWidget {
  const _AcademicsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final studentId = portal.selectedStudentId;
    final grades = portal.isParent && studentId != null
        ? portal.grades
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.grades;
    final transcripts = portal.isParent && studentId != null
        ? portal.transcripts
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.transcripts;
    final selectedChild = portal.children
        .where((item) => valueInt(item['id']) == studentId)
        .firstOrNull;
    final selectedCohortId = portal.isParent
        ? valueInt(selectedChild?['current_cohort'])
        : null;
    final visibleExams = portal.exams
        .where(
          (item) =>
              item['is_published'] == true &&
              (!portal.isParent ||
                  (selectedCohortId != null &&
                      valueInt(item['cohort']) == selectedCohortId)),
        )
        .toList();
    final gradePercentages = [
      for (final grade in grades) _gradePercentage(grade),
    ];
    final gradeAverage = gradePercentages.isEmpty
        ? 0.0
        : gradePercentages.reduce((a, b) => a + b) / gradePercentages.length;
    final colors = Theme.of(context).colorScheme;
    return _PortalPage(
      title: portal.isParent ? 'O‘zlashtirish' : 'Natijalarim',
      subtitle: portal.isParent
          ? 'Farzandingizning e’lon qilingan baholari, imtihonlari va tabeli.'
          : 'Shaxsiy baholar, nazorat ishlari va rasmiy o‘quv tabeli.',
      section: PortalSection.academics,
      trailing: FilledButton.tonalIcon(
        onPressed: studentId == null
            ? null
            : () => _requestTranscript(context, portal),
        icon: const Icon(Icons.description_outlined),
        label: const Text('Tabel so‘rash'),
      ),
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Baholash turlari',
              value: '${portal.examTypes.length}',
              icon: Icons.category_outlined,
            ),
            _MetricCard(
              label: 'Baholar',
              value: '${grades.length}',
              icon: Icons.school_outlined,
            ),
            _MetricCard(
              label: 'Imtihonlar',
              value: '${visibleExams.length}',
              icon: Icons.quiz_outlined,
            ),
            _MetricCard(
              label: 'Tabellar',
              value: '${transcripts.length}',
              icon: Icons.description_outlined,
            ),
          ],
        ),
        if (portal.examTypes.isNotEmpty || portal.subjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final subject in portal.subjects)
                  _CatalogPill(
                    icon: Icons.menu_book_outlined,
                    label:
                        '${valueText(subject, const ['name', 'title'])} · ${valueText(subject, const ['code'])}',
                    detail: valueText(subject, const ['description']),
                  ),
                for (final type in portal.examTypes)
                  _CatalogPill(
                    icon: Icons.quiz_outlined,
                    label: valueText(type, const ['name', 'title']),
                  ),
              ],
            ),
          ),
        ],
        if (grades.isNotEmpty) ...[
          const SizedBox(height: 18),
          _LearningInsightPanel(
            title: 'Fanlar bo‘yicha o‘zlashtirish',
            ringLabel: 'O‘rtacha',
            ringValue: gradeAverage / 100,
            ringDetail:
                '${grades.length} ta e’lon qilingan baho bo‘yicha o‘rtacha ${gradeAverage.round()}%.',
            items: [
              for (var index = 0; index < grades.length; index++)
                _PortalBarDatum(
                  label: valueText(grades[index], const ['subject_name']),
                  value: gradePercentages[index],
                  detail:
                      'Rasmiy qiymat: ${valueText(grades[index], const ['value_display', 'value_raw'])} · ${_dateLabel(grades[index]['published_at'] ?? grades[index]['computed_at'])}',
                  color: gradePercentages[index] >= 85
                      ? Sf.success
                      : gradePercentages[index] >= 70
                      ? colors.primary
                      : Sf.warn,
                  icon: Icons.menu_book_outlined,
                ),
            ],
            emptyLabel: 'E’lon qilingan baholar hali yo‘q.',
          ),
        ],
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yakuniy baholar', count: grades.length),
        const SizedBox(height: 10),
        if (grades.isEmpty)
          const _EmptyState(
            icon: Icons.school_outlined,
            title: 'Baho yo‘q',
            message: 'E’lon qilingan baholar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: grades,
            rowKey: (row) => ValueKey('grade-detail-${row['id']}'),
            icon: Icons.grade_outlined,
            title: (row) => valueText(row, const ['subject_name']),
            subtitle: (row) =>
                'Qiymat: ${valueText(row, const ['value_display', 'value_raw'])} · ${_dateLabel(row['published_at'] ?? row['computed_at'])}',
            trailing: (row) => _StatusPill(
              row['is_published'] == true ? 'E’lon qilingan' : 'Kutilmoqda',
              positive: row['is_published'] == true,
            ),
            onTap: (row) async {
              final id = valueInt(row['id']);
              if (id == null) return;
              final loaded = await _loadApiDetail(
                context,
                () => portal.loadGradeDetail(id),
              );
              if (loaded == null || !context.mounted) return;
              final detail = {...row, ...loaded};
              await _showJsonDetail(
                context,
                title: valueText(detail, const ['subject_name']),
                fields: {
                  'Baho': valueText(detail, const [
                    'value_display',
                    'value_raw',
                  ]),
                  'Tarkib': _gradeComponentsLabel(detail['components']),
                  'E’lon qilingan': _dateLabel(
                    detail['published_at'],
                    time: true,
                  ),
                  'Hisoblangan': _dateLabel(detail['computed_at'], time: true),
                },
                rawDetail: loaded,
              );
            },
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Imtihonlar', count: visibleExams.length),
        const SizedBox(height: 10),
        if (visibleExams.isNotEmpty)
          _SimpleRows(
            rows: visibleExams,
            icon: Icons.quiz_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['subject_name'])} · ${_dateLabel(row['exam_date'])} · maksimum ${row['max_score']}',
            trailing: (row) => _StatusPill(
              valueText(valueMap(row['exam_type_detail']), const [
                'name',
              ], fallback: 'Nazorat'),
              positive: row['is_published'] == true,
            ),
            onTap: (row) async {
              final id = valueInt(row['id']);
              if (id == null) return;
              final loaded = await _loadApiDetail(
                context,
                () => portal.loadExamDetail(id),
              );
              if (loaded == null || !context.mounted) return;
              final detail = {...row, ...loaded};
              await _showJsonDetail(
                context,
                title: valueText(detail, const ['title']),
                fields: {
                  'Fan': valueText(detail, const ['subject_name']),
                  'Guruh': valueText(detail, const ['cohort_name']),
                  'O‘quv davri': valueText(detail, const ['term_name']),
                  'Nazorat turi': valueText(
                    valueMap(detail['exam_type_detail']),
                    const ['name'],
                    fallback: 'Ko‘rsatilmagan',
                  ),
                  'Sana': _dateLabel(detail['exam_date']),
                  'Maksimal ball': '${detail['max_score'] ?? '—'}',
                  'Og‘irlik': '${detail['weight'] ?? '—'}',
                  'E’lon qilingan': _dateLabel(
                    detail['published_at'],
                    time: true,
                  ),
                },
                rawDetail: loaded,
              );
            },
          )
        else
          const _EmptyState(
            icon: Icons.quiz_outlined,
            title: 'Imtihon e’lon qilinmagan',
            message: 'E’lon qilingan nazorat ishlari shu yerda ko‘rinadi.',
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Tabel so‘rovlari', count: transcripts.length),
        const SizedBox(height: 10),
        if (transcripts.isEmpty)
          const _EmptyState(
            icon: Icons.description_outlined,
            title: 'Tabel so‘rovi yo‘q',
            message:
                'Yangi rasmiy tabel yaratish uchun yuqoridagi tugmani bosing.',
          )
        else
          _SimpleRows(
            rows: transcripts,
            icon: Icons.picture_as_pdf_outlined,
            title: (row) => 'Tabel #${row['id']}',
            subtitle: (row) =>
                '${_statusLabel('${row['status']}')} · ${_dateLabel(row['created_at'], time: true)}',
            trailing: (row) {
              final url = '${row['download_url'] ?? ''}';
              return url.isEmpty
                  ? _StatusPill(valueText(row, const ['status']))
                  : IconButton(
                      tooltip: 'Tabelni ochish',
                      onPressed: () => _launch(context, url),
                      icon: const Icon(Icons.open_in_new_rounded),
                    );
            },
            onTap: (row) async {
              final id = valueInt(row['id']);
              if (id == null) return;
              final loaded = await _loadApiDetail(
                context,
                () => portal.loadTranscriptDetail(id),
              );
              if (loaded == null || !context.mounted) return;
              final detail = {...row, ...loaded};
              await _showJsonDetail(
                context,
                title: 'Tabel #$id',
                fields: {
                  'Holat': _statusLabel('${detail['status']}'),
                  'O‘quvchi': valueText(detail, const ['student_name']),
                  'O‘quv davri': valueText(detail, const ['term_name']),
                  'So‘ralgan': _dateLabel(detail['created_at'], time: true),
                  'Tayyorlangan': _dateLabel(
                    detail['generated_at'],
                    time: true,
                  ),
                  'Xatolik': valueText(detail, const [
                    'error_message',
                    'error',
                  ]),
                },
                rawDetail: loaded,
              );
            },
          ),
      ],
    );
  }

  Future<void> _requestTranscript(
    BuildContext context,
    PortalController portal,
  ) async {
    final current = portal.terms
        .where((item) => item['is_current'] == true)
        .firstOrNull;
    int? selected = valueInt(current?['id']);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rasmiy tabel'),
          content: DropdownButtonFormField<int?>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'O‘quv davri'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Barcha davrlar'),
              ),
              for (final term in portal.terms)
                if (valueInt(term['id']) case final id?)
                  DropdownMenuItem<int?>(
                    value: id,
                    child: Text(valueText(term, const ['name'])),
                  ),
            ],
            onChanged: (value) => setDialogState(() => selected = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('So‘rash'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && context.mounted) {
      await _runAction(
        context,
        () => portal.requestTranscript(termId: selected),
        success: 'Tabel yaratish uchun navbatga qo‘yildi.',
      );
    }
  }
}

class _ContentPortalPage extends StatefulWidget {
  const _ContentPortalPage();

  @override
  State<_ContentPortalPage> createState() => _ContentPortalPageState();
}

class _ContentPortalPageState extends State<_ContentPortalPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return _PortalPage(
      title: 'O‘quv materiallari',
      subtitle:
          'Sizga ochilgan kutubxonalar, kurslar, dars fayllari va maqolalar.',
      section: PortalSection.content,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Materiallar'),
              icon: Icon(Icons.article_outlined),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Fayllar'),
              icon: Icon(Icons.folder_outlined),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Kurslar'),
              icon: Icon(Icons.library_books_outlined),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: (value) => setState(() => _tab = value.first),
        ),
        const SizedBox(height: 18),
        if (_tab == 0) _materials(context, portal),
        if (_tab == 1) _files(context, portal),
        if (_tab == 2) _courses(context, portal),
      ],
    );
  }

  Widget _materials(BuildContext context, PortalController portal) {
    if (portal.materials.isEmpty) {
      return const _EmptyState(
        icon: Icons.article_outlined,
        title: 'Material yo‘q',
        message: 'Nashr qilingan o‘quv materiallari shu yerda ko‘rinadi.',
      );
    }
    return Column(
      children: [
        for (final material in portal.materials)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 10),
                leading: const CircleAvatar(
                  child: Icon(Icons.auto_stories_outlined),
                ),
                title: Text(valueText(material, const ['title'])),
                subtitle: Text(
                  '${valueText(material, const ['library_name'], fallback: 'Kutubxona')} · ${valueText(material, const ['topic'], fallback: 'Mavzu ko‘rsatilmagan')}',
                ),
                trailing: _StatusPill(
                  valueText(material, const ['status']),
                  positive: material['status'] == 'published',
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valueText(material, const [
                        'body',
                      ], fallback: 'Material matni berilmagan.'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: valueInt(material['id']) == null
                          ? null
                          : () async {
                              final id = valueInt(material['id'])!;
                              final loaded = await _loadApiDetail(
                                context,
                                () => portal.loadContentDetail('materials', id),
                              );
                              if (loaded == null || !context.mounted) return;
                              final detail = {...material, ...loaded};
                              await _showJsonDetail(
                                context,
                                title: valueText(detail, const ['title']),
                                fields: {
                                  'Kutubxona': valueText(detail, const [
                                    'library_name',
                                  ]),
                                  'Mavzu': valueText(detail, const ['topic']),
                                  'Holat': _statusLabel('${detail['status']}'),
                                  'Matn': valueText(detail, const ['body']),
                                  'Nashr qilingan': _dateLabel(
                                    detail['published_at'],
                                    time: true,
                                  ),
                                },
                                rawDetail: loaded,
                              );
                            },
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('To‘liq tafsilotlar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _files(BuildContext context, PortalController portal) {
    if (portal.files.isEmpty && portal.folders.isEmpty) {
      return const _EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Fayl yo‘q',
        message: 'Tasdiqlangan fayllar shu yerda ko‘rinadi.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (portal.folders.isNotEmpty)
          _SectionCard(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final folder in portal.folders)
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: valueInt(folder['id']) == null
                        ? null
                        : () async {
                            final id = valueInt(folder['id'])!;
                            final loaded = await _loadApiDetail(
                              context,
                              () => portal.loadContentDetail('folders', id),
                            );
                            if (loaded == null || !context.mounted) return;
                            final detail = {...folder, ...loaded};
                            await _showJsonDetail(
                              context,
                              title: valueText(detail, const ['name', 'title']),
                              fields: {
                                'Kutubxona': valueText(detail, const [
                                  'library_name',
                                ]),
                                'Yuqori papka': valueText(detail, const [
                                  'parent_name',
                                ]),
                                'Holat': _statusLabel('${detail['status']}'),
                                'Yaratilgan': _dateLabel(
                                  detail['created_at'],
                                  time: true,
                                ),
                              },
                              rawDetail: loaded,
                            );
                          },
                    child: _CatalogPill(
                      icon: Icons.folder_outlined,
                      label:
                          valueText(folder, const [
                            'parent_name',
                          ], fallback: '').isEmpty
                          ? valueText(folder, const ['name', 'title'])
                          : '${valueText(folder, const ['parent_name'])} / ${valueText(folder, const ['name', 'title'])}',
                      detail: valueText(folder, const ['library_name']),
                    ),
                  ),
              ],
            ),
          ),
        if (portal.folders.isNotEmpty && portal.files.isNotEmpty)
          const SizedBox(height: 10),
        if (portal.files.isEmpty)
          const _CompactEmpty(message: 'Bu papkalarda hozircha fayl yo‘q.')
        else
          _SimpleRows(
            rows: portal.files,
            icon: Icons.insert_drive_file_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['lesson_title', 'folder_name'], fallback: 'Material')} · ${_fileSize(row['size_bytes'])}',
            trailing: (row) => row['is_downloadable'] == true
                ? IconButton(
                    tooltip: 'Faylni ochish',
                    onPressed: () async {
                      final id = valueInt(row['id']);
                      if (id == null) return;
                      try {
                        final url = await portal.contentDownloadUrl(id);
                        if (context.mounted) await _launch(context, url);
                      } on Object catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_errorText(error))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download_outlined),
                  )
                : const Tooltip(
                    message: 'Yuklab olish yopiq',
                    child: Icon(Icons.lock_outline_rounded),
                  ),
            onTap: (row) async {
              final id = valueInt(row['id']);
              if (id != null) {
                unawaited(portal.trackContentView(id));
                final loaded = await _loadApiDetail(
                  context,
                  () => portal.loadContentDetail('files', id),
                );
                if (loaded == null || !context.mounted) return;
                final detail = {...row, ...loaded};
                await _showJsonDetail(
                  context,
                  title: valueText(detail, const ['title']),
                  fields: {
                    'Dars yoki papka': valueText(detail, const [
                      'lesson_title',
                      'folder_name',
                    ], fallback: 'Material'),
                    'Turi': valueText(detail, const ['content_type']),
                    'Hajmi': _fileSize(detail['size_bytes']),
                    'Versiya': '${detail['version'] ?? 1}',
                    'Holat': _statusLabel('${detail['status']}'),
                    'Yuklagan': valueText(detail, const ['uploaded_by_name']),
                    'Ko‘rilgan': '${detail['view_count'] ?? 0}',
                    'Yuklab olingan': '${detail['download_count'] ?? 0}',
                    'Ustoz tasdig‘i': detail['is_approved_teacher'] == true
                        ? _dateLabel(detail['approved_teacher_at'], time: true)
                        : 'Tasdiqlanmagan',
                    'Rahbar tasdig‘i': detail['is_approved_manager'] == true
                        ? _dateLabel(detail['approved_manager_at'], time: true)
                        : 'Tasdiqlanmagan',
                    'Rad etish sababi': valueText(detail, const [
                      'reject_reason',
                    ]),
                    'Yaratilgan': _dateLabel(detail['created_at'], time: true),
                  },
                  rawDetail: loaded,
                );
              }
            },
          ),
      ],
    );
  }

  Widget _courses(BuildContext context, PortalController portal) {
    if (portal.libraries.isEmpty && portal.courses.isEmpty) {
      return const _EmptyState(
        icon: Icons.library_books_outlined,
        title: 'Kutubxona yo‘q',
        message: 'Sizga ochilgan kurslar shu yerda ko‘rinadi.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (portal.libraries.isNotEmpty) ...[
          _SectionCard(
            child: Column(
              children: [
                for (final library in portal.libraries)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_library_outlined),
                    title: Text(valueText(library, const ['name', 'title'])),
                    subtitle: Text(
                      '${valueText(library, const ['visibility'])} · ${valueText(library, const ['cohort_name', 'department_name'], fallback: 'Markaz kutubxonasi')}',
                    ),
                    trailing: _StatusPill(
                      library['is_active'] == true ? 'Faol' : 'Yopilgan',
                      positive: library['is_active'] == true,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          valueText(library, const [
                            'description',
                          ], fallback: 'Kutubxona tavsifi berilmagan.'),
                        ),
                      ),
                      if (library['allowed_roles'] is List)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Ruxsat etilgan rollar: ${_readable(library['allowed_roles'])}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: valueInt(library['id']) == null
                              ? null
                              : () async {
                                  final id = valueInt(library['id'])!;
                                  final loaded = await _loadApiDetail(
                                    context,
                                    () => portal.loadContentDetail(
                                      'libraries',
                                      id,
                                    ),
                                  );
                                  if (loaded == null || !context.mounted) {
                                    return;
                                  }
                                  final detail = {...library, ...loaded};
                                  await _showJsonDetail(
                                    context,
                                    title: valueText(detail, const [
                                      'name',
                                      'title',
                                    ]),
                                    fields: {
                                      'Tavsif': valueText(detail, const [
                                        'description',
                                      ]),
                                      'Ko‘rinish': valueText(detail, const [
                                        'visibility',
                                      ]),
                                      'Guruh yoki bo‘lim': valueText(
                                        detail,
                                        const [
                                          'cohort_name',
                                          'department_name',
                                        ],
                                      ),
                                      'Ruxsat etilgan rollar': _readable(
                                        detail['allowed_roles'],
                                      ),
                                      'Holat': detail['is_active'] == true
                                          ? 'Faol'
                                          : 'Yopilgan',
                                    },
                                    rawDetail: loaded,
                                  );
                                },
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text('To‘liq tafsilotlar'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Kutubxonalar',
              value: '${portal.libraries.length}',
              icon: Icons.local_library_outlined,
            ),
            _MetricCard(
              label: 'Kurslar',
              value: '${portal.courses.length}',
              icon: Icons.menu_book_outlined,
            ),
            _MetricCard(
              label: 'Modullar',
              value: '${portal.modules.length}',
              icon: Icons.view_module_outlined,
            ),
            _MetricCard(
              label: 'Darslar',
              value: '${portal.contentLessons.length}',
              icon: Icons.play_lesson_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (portal.courses.isNotEmpty)
          _SimpleRows(
            rows: portal.courses,
            icon: Icons.menu_book_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['library_name'])} · ${valueText(row, const ['subject_name'])}',
            onTap: (course) async {
              final courseId = valueInt(course['id']);
              if (courseId == null) return;
              final loaded = await _loadApiDetail(
                context,
                () => portal.loadContentDetail('courses', courseId),
              );
              if (loaded == null || !context.mounted) return;
              final modules = portal.modules
                  .where((item) => valueInt(item['course']) == courseId)
                  .toList();
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => PortalScope(
                  controller: portal,
                  child: _CourseSheet(
                    portal: portal,
                    course: {...course, ...loaded},
                    modules: modules,
                    lessons: portal.contentLessons,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CourseSheet extends StatelessWidget {
  const _CourseSheet({
    required this.portal,
    required this.course,
    required this.modules,
    required this.lessons,
  });

  final PortalController portal;
  final Map<String, Object?> course;
  final List<Map<String, Object?>> modules;
  final List<Map<String, Object?>> lessons;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            valueText(course, const ['title']),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            valueText(course, const [
              'description',
            ], fallback: 'Kurs tavsifi berilmagan.'),
          ),
          const SizedBox(height: 20),
          if (modules.isEmpty)
            const _EmptyState(
              icon: Icons.view_module_outlined,
              title: 'Modul yo‘q',
              message: 'Kurs hali to‘ldirilmagan.',
            )
          else
            for (final module in modules)
              ExpansionTile(
                title: Text(valueText(module, const ['title'])),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: valueInt(module['id']) == null
                          ? null
                          : () async {
                              final id = valueInt(module['id'])!;
                              final loaded = await _loadApiDetail(
                                context,
                                () => portal.loadContentDetail('modules', id),
                              );
                              if (loaded == null || !context.mounted) return;
                              final detail = {...module, ...loaded};
                              await _showJsonDetail(
                                context,
                                title: valueText(detail, const ['title']),
                                fields: {
                                  'Tavsif': valueText(detail, const [
                                    'description',
                                  ]),
                                  'Tartib': '${detail['order'] ?? '—'}',
                                  'Kurs': valueText(detail, const [
                                    'course_name',
                                  ]),
                                },
                                rawDetail: loaded,
                              );
                            },
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Modul tafsilotlari'),
                    ),
                  ),
                  for (final lesson in lessons.where(
                    (item) =>
                        valueInt(item['module']) == valueInt(module['id']),
                  ))
                    ListTile(
                      leading: const Icon(Icons.play_lesson_outlined),
                      title: Text(valueText(lesson, const ['title'])),
                      subtitle: Text(
                        valueText(lesson, const ['description'], fallback: ''),
                      ),
                      onTap: valueInt(lesson['id']) == null
                          ? null
                          : () async {
                              final id = valueInt(lesson['id'])!;
                              final loaded = await _loadApiDetail(
                                context,
                                () => portal.loadContentDetail('lessons', id),
                              );
                              if (loaded == null || !context.mounted) return;
                              final detail = {...lesson, ...loaded};
                              await _showJsonDetail(
                                context,
                                title: valueText(detail, const ['title']),
                                fields: {
                                  'Tavsif': valueText(detail, const [
                                    'description',
                                  ]),
                                  'Modul': valueText(detail, const [
                                    'module_name',
                                  ]),
                                  'Tartib': '${detail['order'] ?? '—'}',
                                  'Davomiylik': valueText(detail, const [
                                    'duration_minutes',
                                  ]),
                                },
                                rawDetail: loaded,
                              );
                            },
                    ),
                ],
              ),
        ],
      ),
    );
  }
}

String _fileSize(Object? raw) {
  final bytes = valueInt(raw);
  if (bytes == null) return '—';
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

Future<void> _launch(BuildContext context, String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null ||
      !const {'http', 'https', 'webcal'}.contains(uri.scheme.toLowerCase()) ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Havolani ochib bo‘lmadi.')));
    }
  }
}

String _readable(Object? value) {
  if (value == null) return '—';
  if (value is List) return value.map(_readable).join(', ');
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_readable(entry.value)}')
        .join('\n');
  }
  final text = '$value'.trim();
  return text.isEmpty ? '—' : text;
}

String _gradeComponentsLabel(Object? value) {
  final components = valueRows(value);
  if (components.isEmpty) return _readable(value);
  return components
      .map((component) {
        final title = valueText(component, const [
          'title',
          'exam_title',
        ], fallback: 'Nazorat');
        final score = valueText(component, const ['score', 'value']);
        final maxScore = valueText(component, const ['max_score']);
        final weight = valueText(component, const ['weight']);
        return '$title: $score${maxScore == '—' ? '' : ' / $maxScore'}${weight == '—' ? '' : ' · vazn $weight'}';
      })
      .join('\n');
}

String _invoiceLinesLabel(BuildContext context, Object? value) {
  final lines = valueRows(value);
  if (lines.isEmpty) return '—';
  return lines
      .map((line) {
        final description = valueText(line, const ['description']);
        final quantity = valueText(line, const ['quantity']);
        final unit = _money(context, line['unit_price_uzs']);
        final amount = _money(context, line['amount_uzs']);
        return '$description · $quantity × $unit = $amount';
      })
      .join('\n');
}

Future<void> _showJsonDetail(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
  Map<String, Object?>? rawDetail,
}) {
  final portal = PortalScope.read(context);
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PortalScope(
        controller: portal,
        child: _RecordDetailScreen(title: title, fields: fields),
      ),
    ),
  );
}

class _RecordDetailScreen extends StatelessWidget {
  const _RecordDetailScreen({required this.title, required this.fields});

  final String title;
  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('record-detail-page'),
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryContainer,
                        colors.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: colors.surface,
                        foregroundColor: colors.primary,
                        child: const Icon(Icons.description_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final field in fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.key,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 5),
                            SelectableText(
                              field.value,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
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
}

Future<Map<String, Object?>?> _loadApiDetail(
  BuildContext context,
  Future<Map<String, Object?>> Function() loader,
) async {
  try {
    return await loader();
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
    return null;
  }
}

class _AiPortalPage extends StatefulWidget {
  const _AiPortalPage();

  @override
  State<_AiPortalPage> createState() => _AiPortalPageState();
}

class _AiPortalPageState extends State<_AiPortalPage> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _message.text).trim();
    if (text.isEmpty) return;
    _message.clear();
    await PortalScope.read(context).askFamilyAssistant(text);
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final history = portal.aiConversation;
    final visibleHistory = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    return _PortalPage(
      title: portal.isParent
          ? 'Oila uchun AI yordamchi'
          : 'AI o‘qish yordamchisi',
      subtitle: portal.isParent
          ? 'Farzandingizning baholari, davomati va vazifalari asosida tushunarli javoblar.'
          : 'Kabinetdagi haqiqiy ma’lumotlar asosida reja, tahlil va o‘qish bo‘yicha yordam.',
      section: PortalSection.ai,
      trailing: _LiveBadge(
        label: portal.aiServiceAvailable
            ? (portal.aiFallbackMode ? 'SERVER REJIMI' : 'SERVER AI')
            : 'ULANMAGAN',
        icon: portal.aiServiceAvailable
            ? Icons.auto_awesome_rounded
            : Icons.cloud_off_rounded,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Sf.aiBg1, Sf.aiBg2]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Sf.aiBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Sf.ai.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Sf.ai),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portal.isParent
                          ? 'Farzandingiz holatini birga tushunamiz'
                          : 'O‘qishni aniq reja bilan davom ettiring',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Sf.ai,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      portal.aiServiceAvailable
                          ? 'Javoblar faqat siz ko‘rishga ruxsatli bo‘lgan kabinet ma’lumotlariga tayangan holda beriladi.'
                          : 'AI markaz serveriga ulanmaguncha savollarga javob bera olmaydi.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Sf.accentInk,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (portal.aiServiceAvailable && portal.aiSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in portal.aiSuggestions)
                ActionChip(
                  avatar: const Icon(Icons.bolt_rounded, size: 17),
                  label: Text(suggestion),
                  onPressed: portal.aiReplyBusy
                      ? null
                      : () => _send(suggestion),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (!portal.aiServiceAvailable) ...[
          _SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.cloud_off_rounded, color: colors.error),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI yordamchi ulanmagan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI yordamchi hali markaz tomonidan ulanmagan. Hozircha bu funksiya ishlamaydi.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openHistory(context, history),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Oldingi suhbatlarni ko‘rish'),
            ),
          ],
        ] else
          _SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DensePanelHeader(
                        title: 'Yordamchi bilan suhbat',
                        meta: '${history.length} ta xabar',
                        icon: Icons.forum_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      key: const ValueKey('family-ai-history'),
                      onPressed: history.isEmpty
                          ? null
                          : () => _openHistory(context, history),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('Tarix'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (history.isEmpty && !portal.aiReplyBusy)
                  const _CompactEmpty(
                    message:
                        'Savol yozing yoki yuqoridagi tayyor savollardan birini tanlang.',
                  )
                else ...[
                  if (history.length > visibleHistory.length)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () => _openHistory(context, history),
                          icon: const Icon(Icons.history_rounded, size: 17),
                          label: Text(
                            '${history.length - visibleHistory.length} ta oldingi xabar',
                          ),
                        ),
                      ),
                    ),
                  for (final item in visibleHistory)
                    _FamilyAiBubble(message: item),
                ],
                if (portal.aiReplyBusy) const _FamilyAiThinking(),
                if (portal.aiReplyError case final error?) ...[
                  const SizedBox(height: 6),
                  _InlineMessage(text: error, error: true),
                ],
                if (portal.aiSources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final source in portal.aiSources)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.verified_outlined, size: 16),
                          label: Text(
                            valueText(source, const [
                              'label',
                            ], fallback: 'Kabinet'),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('family-ai-input'),
                        controller: _message,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Savolingizni yozing…',
                          prefixIcon: Icon(Icons.auto_awesome_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      dimension: 50,
                      child: FilledButton(
                        key: const ValueKey('family-ai-send'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Sf.ai,
                          foregroundColor: colors.surface,
                        ),
                        onPressed: portal.aiReplyBusy ? null : _send,
                        child: portal.aiReplyBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openHistory(BuildContext context, List<Map<String, Object?>> history) {
    final portal = PortalScope.read(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PortalScope(
          controller: portal,
          child: _AiHistoryScreen(history: List.of(history)),
        ),
      ),
    );
  }
}

class _AiHistoryScreen extends StatelessWidget {
  const _AiHistoryScreen({required this.history});

  final List<Map<String, Object?>> history;

  @override
  Widget build(BuildContext context) {
    final rows = [...history]
      ..sort(
        (left, right) =>
            '${left['created_at']}'.compareTo('${right['created_at']}'),
      );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'AI suhbat tarixi',
            ru: 'История чата с AI',
            en: 'AI chat history',
          ),
        ),
      ),
      body: rows.isEmpty
          ? _EmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: _familyCopy(
                context,
                uz: 'Suhbat tarixi yo‘q',
                ru: 'Истории чата пока нет',
                en: 'No chat history yet',
              ),
              message: _familyCopy(
                context,
                uz: 'AI bilan yozishmalar paydo bo‘lganda shu yerda saqlanadi.',
                ru: 'Переписка с AI появится здесь после первого диалога.',
                en: 'Your AI conversations will appear here after the first chat.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final item = rows[index];
                final day = _dateLabel(item['created_at']);
                final previousDay = index == 0
                    ? null
                    : _dateLabel(rows[index - 1]['created_at']);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (day != previousDay)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                        child: Center(
                          child: Chip(
                            avatar: const Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                            ),
                            label: Text(day),
                          ),
                        ),
                      ),
                    _FamilyAiBubble(message: item),
                  ],
                );
              },
            ),
    );
  }
}

class _FamilyAiBubble extends StatelessWidget {
  const _FamilyAiBubble({required this.message});

  final Map<String, Object?> message;

  @override
  Widget build(BuildContext context) {
    final user =
        valueText(message, const ['role'], fallback: 'assistant') == 'user';
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: user ? colors.primary : colors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(user ? 15 : 4),
            bottomRight: Radius.circular(user ? 4 : 15),
          ),
          border: user ? null : Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          valueText(message, const ['content', 'answer'], fallback: '—'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: user ? colors.onPrimary : colors.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _FamilyAiThinking extends StatelessWidget {
  const _FamilyAiThinking();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

// Legacy request-ledger widgets remain for older golden references, while the
// active family route uses the conversation UI above.
// ignore: unused_element
class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.parent, required this.requests});

  final bool parent;
  final List<Map<String, Object?>> requests;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [colors.secondaryContainer, colors.surfaceContainerHigh]
              : const [Sf.aiBg1, Sf.aiBg2],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Sf.aiBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final icon = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Sf.ai.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 21,
              color: Sf.ai,
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parent ? 'Oila uchun AI signallari' : 'Shaxsiy AI faoliyati',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Sf.ai,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                requests.isEmpty
                    ? 'AI xulosasi uchun serverda hali yetarli so‘rov tarixi yo‘q.'
                    : 'Oxirgi ${requests.length} ta AI so‘rovi serverdan olindi. Har bir holat quyida ko‘rsatilgan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Sf.accentInk,
                  height: 1.4,
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 10), copy],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: copy),
              Icon(Icons.arrow_forward_rounded, color: colors.tertiary),
            ],
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _AiRequestTile extends StatelessWidget {
  const _AiRequestTile({required this.request});

  final Map<String, Object?> request;

  @override
  Widget build(BuildContext context) {
    final status = valueText(request, const [
      'status',
      'state',
    ], fallback: 'unknown');
    final positive = const {
      'completed',
      'success',
      'succeeded',
      'done',
    }.contains(status.toLowerCase());
    final pending = const {
      'pending',
      'queued',
      'processing',
      'running',
    }.contains(status.toLowerCase());
    final title = valueText(request, const [
      'title',
      'purpose',
      'request_type',
      'kind',
      'prompt',
    ], fallback: 'AI so‘rovi');
    final detail = valueText(request, const [
      'model',
      'provider',
      'response_summary',
      'error_message',
    ], fallback: 'Server so‘rovi');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Sf.ai.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: Sf.ai,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '$detail · ${_dateLabel(request['created_at'], time: true)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(status, positive: positive, warning: pending),
        ],
      ),
    );
  }
}

class _RebuiltMessagesPortalPage extends StatefulWidget {
  const _RebuiltMessagesPortalPage();

  @override
  State<_RebuiltMessagesPortalPage> createState() =>
      _RebuiltMessagesPortalPageState();
}

class _RebuiltMessagesPortalPageState extends State<_RebuiltMessagesPortalPage>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  String _filter = 'all';
  int? _selectedThreadId;
  bool _refreshing = false;
  bool _checkingContacts = false;
  bool _polling = false;
  bool _appActive = true;
  String? _contactsIssue;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _PortalCommunicationRouter.pendingThreadId.addListener(
      _consumePendingThread,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_checkContacts());
      unawaited(_primePreviews(PortalScope.read(context)));
      _consumePendingThread();
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        final visible =
            mounted &&
            _appActive &&
            (ModalRoute.of(context)?.isCurrent ?? true) &&
            TickerMode.valuesOf(context).enabled;
        if (visible && !_refreshing && !_polling) {
          _polling = true;
          unawaited(
            _refreshThreads(
              PortalScope.read(context),
              quiet: true,
            ).whenComplete(() => _polling = false),
          );
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _PortalCommunicationRouter.pendingThreadId.removeListener(
      _consumePendingThread,
    );
    _search.dispose();
    super.dispose();
  }

  void _consumePendingThread() {
    if (!mounted) return;
    final id = _PortalCommunicationRouter.takeThread();
    if (id == null) return;
    final portal = PortalScope.read(context);
    unawaited(
      portal.fetchThreadDetail(id).catchError((_) => const <String, Object?>{}),
    );
    if (MediaQuery.sizeOf(context).width >= 1100) {
      setState(() => _selectedThreadId = id);
    } else {
      _openMobileThread(portal, id);
    }
  }

  Future<void> _checkContacts() async {
    if (_checkingContacts) return;
    final portal = PortalScope.read(context);
    setState(() {
      _checkingContacts = true;
      _contactsIssue = null;
    });
    try {
      await portal.searchMessagingContacts();
    } on Object catch (error) {
      if (mounted) setState(() => _contactsIssue = _errorText(error));
    } finally {
      if (mounted) setState(() => _checkingContacts = false);
    }
  }

  Future<void> _primePreviews(PortalController portal) async {
    final ids = portal.threads
        .map((thread) => valueInt(thread['id']))
        .whereType<int>()
        .take(10);
    await Future.wait([
      for (final id in ids)
        portal.ensureLatestMessagePage(id).catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final threads = portal.threads.where((thread) {
      final unread = valueInt(thread['unread_count']) ?? 0;
      if (_filter == 'unread' && unread == 0) return false;
      if (_filter == 'muted' && thread['notifications_muted'] != true) {
        return false;
      }
      if (query.isEmpty) return true;
      return portal.threadTitle(thread).toLowerCase().contains(query) ||
          valueText(thread, const [
            'subject',
          ], fallback: '').toLowerCase().contains(query);
    }).toList();
    final selectedId = threads
        .where((item) => valueInt(item['id']) == _selectedThreadId)
        .map((item) => valueInt(item['id']))
        .firstOrNull;
    final effectiveId = selectedId ?? valueInt(threads.firstOrNull?['id']);
    final desktop = MediaQuery.sizeOf(context).width >= 1100;
    if (!desktop) {
      final availableHeight = (MediaQuery.sizeOf(context).height - 230).clamp(
        280.0,
        760.0,
      );
      return _PortalPage(
        title: portal.isParent ? 'Maktab bilan chat' : 'Chat',
        subtitle: 'Shaxsiy va guruh suhbatlari.',
        section: PortalSection.messages,
        trailing: FilledButton.icon(
          onPressed: portal.contacts.isEmpty || !portal.can('messaging:write')
              ? null
              : () => _startConversation(portal),
          icon: const Icon(Icons.edit_square),
          label: const Text('Yangi'),
        ),
        children: [
          if (_contactsIssue != null || portal.contacts.isEmpty) ...[
            _ChatDirectoryNotice(
              loading: _checkingContacts,
              error: _contactsIssue,
              onRetry: _checkContacts,
            ),
            const SizedBox(height: 10),
          ],
          _SectionCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: availableHeight,
              child: _WorkspaceConversationList(
                portal: portal,
                threads: threads,
                search: _search,
                filter: _filter,
                selectedId: null,
                onSearch: () => setState(() {}),
                onFilter: (value) => setState(() => _filter = value),
                onOpen: (thread) =>
                    _openMobileThread(portal, valueInt(thread['id'])),
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkspaceHeader(
            portal: portal,
            refreshing: _refreshing,
            onRefresh: _refreshing ? null : () => _refreshThreads(portal),
            onNewConversation:
                portal.contacts.isEmpty || !portal.can('messaging:write')
                ? null
                : () => _startConversation(portal),
          ),
          if (_contactsIssue != null || portal.contacts.isEmpty) ...[
            const SizedBox(height: 8),
            _ChatDirectoryNotice(
              loading: _checkingContacts,
              error: _contactsIssue,
              onRetry: _checkContacts,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 340,
                    child: _WorkspaceConversationList(
                      portal: portal,
                      threads: threads,
                      search: _search,
                      filter: _filter,
                      selectedId: effectiveId,
                      onSearch: () => setState(() {}),
                      onFilter: (value) => setState(() => _filter = value),
                      onOpen: (thread) => setState(
                        () => _selectedThreadId = valueInt(thread['id']),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: effectiveId == null
                        ? const _WorkspaceWelcome()
                        : _ThreadScreen(
                            key: ValueKey(effectiveId),
                            threadId: effectiveId,
                            embedded: true,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshThreads(
    PortalController portal, {
    bool quiet = false,
  }) async {
    if (!quiet) setState(() => _refreshing = true);
    try {
      await portal.refresh(PortalSection.messages);
      await _primePreviews(portal);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted && !quiet) setState(() => _refreshing = false);
    }
  }

  void _openMobileThread(PortalController portal, int? id) {
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PortalScope(
          controller: portal,
          child: _ThreadScreen(threadId: id),
        ),
      ),
    );
  }

  Future<void> _startConversation(PortalController portal) async {
    if (!portal.can('messaging:write')) return;
    final selected = <int>{};
    final contactSearch = TextEditingController();
    final subject = TextEditingController();
    final body = TextEditingController();
    var contactQuery = '';
    var contactRows = [...portal.contacts];
    var searchingContacts = false;
    String? contactSearchError;
    Timer? contactDebounce;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            22 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected.length > 1 ? 'Yangi guruh' : 'Yangi suhbat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yopish',
                      onPressed: () => Navigator.pop(sheetContext, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  selected.isEmpty
                      ? 'Maktab kontaktlaridan qabul qiluvchini tanlang.'
                      : '${selected.length} ta qabul qiluvchi tanlandi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contactSearch,
                  onChanged: (value) {
                    contactQuery = value.trim().toLowerCase();
                    contactDebounce?.cancel();
                    setSheetState(() {
                      searchingContacts = contactQuery.isNotEmpty;
                      contactSearchError = null;
                    });
                    contactDebounce = Timer(
                      const Duration(milliseconds: 350),
                      () async {
                        try {
                          final rows = await portal.searchMessagingContacts(
                            search: contactQuery,
                          );
                          if (sheetContext.mounted) {
                            setSheetState(() => contactRows = rows);
                          }
                        } on Object catch (error) {
                          if (sheetContext.mounted) {
                            setSheetState(
                              () => contactSearchError = _errorText(error),
                            );
                          }
                        } finally {
                          if (sheetContext.mounted) {
                            setSheetState(() => searchingContacts = false);
                          }
                        }
                      },
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Kontaktni qidirish',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                if (searchingContacts)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Kontaktlar qidirilmoqda…',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (contactSearchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      contactSearchError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Flexible(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final contact in contactRows)
                          if (contactQuery.isEmpty ||
                              '${contact['display_name']} ${contact['username']} ${contact['role_label']}'
                                  .toLowerCase()
                                  .contains(contactQuery))
                            if (valueInt(contact['user_id'] ?? contact['id'])
                                case final id?)
                              CheckboxListTile(
                                value: selected.contains(id),
                                secondary: _ChatAvatar(
                                  portal: portal,
                                  contact: contact,
                                  name: valueText(contact, const [
                                    'display_name',
                                    'username',
                                  ]),
                                  radius: 20,
                                ),
                                title: Text(
                                  valueText(contact, const [
                                    'display_name',
                                    'username',
                                  ]),
                                ),
                                subtitle: Text(
                                  '${valueText(contact, const ['role_label'])}${contact['is_online'] == true ? ' · online' : ''}',
                                ),
                                onChanged: (checked) => setSheetState(() {
                                  if (checked == true) {
                                    selected.add(id);
                                  } else {
                                    selected.remove(id);
                                  }
                                }),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subject,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    labelText: selected.length > 1
                        ? 'Guruh nomi (majburiy)'
                        : 'Mavzu',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  onChanged: (_) => setSheetState(() {}),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Birinchi xabar',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      selected.isEmpty ||
                          (selected.length > 1
                              ? subject.text.trim().isEmpty
                              : subject.text.trim().isEmpty &&
                                    body.text.trim().isEmpty)
                      ? null
                      : () => Navigator.pop(sheetContext, true),
                  icon: Icon(
                    selected.length > 1
                        ? Icons.group_add_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    selected.length > 1
                        ? 'Guruhni yaratish'
                        : 'Suhbatni boshlash',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      if (accepted == true && selected.isNotEmpty && mounted) {
        final id = await portal.createThread(
          participantIds: selected.toList(),
          subject: subject.text,
          firstBody: body.text,
        );
        if (mounted && id > 0) setState(() => _selectedThreadId = id);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      contactDebounce?.cancel();
      contactSearch.dispose();
      subject.dispose();
      body.dispose();
    }
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.portal,
    required this.refreshing,
    this.onRefresh,
    this.onNewConversation,
  });

  final PortalController portal;
  final bool refreshing;
  final VoidCallback? onRefresh;
  final VoidCallback? onNewConversation;

  @override
  Widget build(BuildContext context) {
    final unread = portal.threads.fold<int>(
      0,
      (total, item) => total + (valueInt(item['unread_count']) ?? 0),
    );
    final online = portal.contacts
        .where((contact) => contact['is_online'] == true)
        .length;
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.forum_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  portal.isParent ? 'Maktab bilan aloqa' : 'Suhbatlar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  unread == 0
                      ? 'Barcha xabarlar o‘qilgan'
                      : '$unread ta yangi xabar',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _WorkspaceStat(
            value: '${portal.threads.length}',
            label: 'suhbat',
            icon: Icons.chat_bubble_outline_rounded,
          ),
          const SizedBox(width: 8),
          _WorkspaceStat(
            value: '$online',
            label: 'online',
            icon: Icons.circle,
            positive: true,
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Suhbatlarni yangilash',
            onPressed: onRefresh,
            icon: refreshing
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNewConversation,
            icon: const Icon(Icons.edit_square, size: 18),
            label: const Text('Yangi suhbat'),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceStat extends StatelessWidget {
  const _WorkspaceStat({
    required this.value,
    required this.label,
    required this.icon,
    this.positive = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: icon == Icons.circle ? 8 : 16,
          color: positive ? Sf.success : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _WorkspaceConversationList extends StatelessWidget {
  const _WorkspaceConversationList({
    required this.portal,
    required this.threads,
    required this.search,
    required this.filter,
    required this.selectedId,
    required this.onSearch,
    required this.onFilter,
    required this.onOpen,
  });

  final PortalController portal;
  final List<Map<String, Object?>> threads;
  final TextEditingController search;
  final String filter;
  final int? selectedId;
  final VoidCallback onSearch;
  final ValueChanged<String> onFilter;
  final ValueChanged<Map<String, Object?>> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = portal.threads.fold<int>(
      0,
      (total, item) => total + (valueInt(item['unread_count']) ?? 0),
    );
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 9),
            child: TextField(
              key: const ValueKey('message-thread-search'),
              controller: search,
              onChanged: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Suhbatlarni qidirish',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Qidiruvni tozalash',
                        onPressed: () {
                          search.clear();
                          onSearch();
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _WorkspaceFilter(
                  label: 'Barchasi',
                  selected: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 6),
                _WorkspaceFilter(
                  label: unread == 0 ? 'Yangi' : 'Yangi · $unread',
                  selected: filter == 'unread',
                  onTap: () => onFilter('unread'),
                ),
                const SizedBox(width: 6),
                _WorkspaceFilter(
                  label: 'Ovozsiz',
                  selected: filter == 'muted',
                  onTap: () => onFilter('muted'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 2, 15, 9),
            child: Row(
              children: [
                Text(
                  filter == 'all'
                      ? 'SO‘NGGI SUHBATLAR'
                      : filter == 'unread'
                      ? 'O‘QILMAGANLAR'
                      : 'OVOZSIZ SUHBATLAR',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Text(
                  '${threads.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: threads.isEmpty
                ? _WorkspaceEmpty(
                    filtered: search.text.trim().isNotEmpty || filter != 'all',
                  )
                : ListView.builder(
                    key: const ValueKey('message-thread-list'),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      final id = valueInt(thread['id']);
                      final cached = id == null ? null : portal.messages[id];
                      return _WorkspaceConversationTile(
                        key: ValueKey('message-thread-${id ?? index}'),
                        portal: portal,
                        thread: thread,
                        contact: _threadContact(portal, thread),
                        latestMessage: cached?.lastOrNull,
                        selected: id == selectedId,
                        onTap: () => onOpen(thread),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceFilter extends StatelessWidget {
  const _WorkspaceFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _WorkspaceConversationTile extends StatelessWidget {
  const _WorkspaceConversationTile({
    super.key,
    required this.portal,
    required this.thread,
    required this.contact,
    required this.latestMessage,
    required this.selected,
    required this.onTap,
  });

  final PortalController portal;
  final Map<String, Object?> thread;
  final Map<String, Object?> contact;
  final Map<String, Object?>? latestMessage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = _workspaceThreadTitle(portal, thread);
    final unread = valueInt(thread['unread_count']) ?? 0;
    final muted = thread['notifications_muted'] == true;
    final online = contact['is_online'] == true;
    final participants = thread['participants'] is List
        ? (thread['participants'] as List).length
        : 0;
    final attachment = latestMessage?['attachments'];
    final hasAttachment = attachment is List && attachment.isNotEmpty;
    final attachmentKey = hasAttachment
        ? _messageAttachmentKey(attachment.first)
        : '';
    final mine =
        valueInt(latestMessage?['sender']) == portal.messagingSelfUserId;
    final latestBody = valueText(latestMessage ?? const {}, const [
      'body',
    ], fallback: '');
    final subject = valueText(thread, const [
      'subject',
    ], fallback: participants > 2 ? 'Guruh suhbati' : 'Shaxsiy suhbat');
    final preview = latestBody.isNotEmpty
        ? latestBody
        : hasAttachment
        ? _attachmentPreviewLabel(attachmentKey)
        : subject;
    final time = _dateLabel(
      thread['last_message_at'] ?? thread['created_at'],
      time: true,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title. $preview${unread > 0 ? '. $unread ta yangi' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(9, 10, 10, 10),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer.withValues(alpha: 0.72)
                  : unread > 0
                  ? colors.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? colors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              boxShadow: unread > 0 && !selected
                  ? [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.035),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _ChatAvatar(
                      portal: portal,
                      contact: contact,
                      name: title,
                      radius: 24,
                      group: participants > 2,
                    ),
                    if (online)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Sf.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerLowest,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: unread > 0
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: unread > 0
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                  fontWeight: unread > 0
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (muted) ...[
                            Icon(
                              Icons.volume_off_rounded,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (latestMessage != null && mine) ...[
                            Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (hasAttachment) ...[
                            Icon(
                              _attachmentIcon(attachmentKey),
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: unread > 0
                                        ? colors.onSurface
                                        : colors.onSurfaceVariant,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              constraints: const BoxConstraints(minWidth: 22),
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
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
  }
}

class _WorkspaceWelcome extends StatelessWidget {
  const _WorkspaceWelcome();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Suhbatni tanlang',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              'Xabarlar, ovoz va fayllar faqat suhbat ishtirokchilariga ko‘rinadi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            const _LiveBadge(
              label: 'Yopiq maktab kanali',
              icon: Icons.lock_outline_rounded,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WorkspaceEmpty extends StatelessWidget {
  const _WorkspaceEmpty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              filtered ? Icons.search_off_rounded : Icons.forum_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            filtered ? 'Suhbat topilmadi' : 'Hozircha suhbat yo‘q',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Qidiruv yoki filtrni o‘zgartiring.'
                : 'Yangi suhbat orqali maktab kontaktiga yozing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _MessagesPortalPage extends StatefulWidget {
  const _MessagesPortalPage();

  @override
  State<_MessagesPortalPage> createState() => _MessagesPortalPageState();
}

class _MessagesPortalPageState extends State<_MessagesPortalPage> {
  final _search = TextEditingController();
  String _filter = 'all';
  int? _selectedThreadId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final visibleThreads = portal.threads.where((thread) {
      if (_filter == 'unread' && (valueInt(thread['unread_count']) ?? 0) == 0) {
        return false;
      }
      if (_filter == 'muted' && thread['notifications_muted'] != true) {
        return false;
      }
      if (query.isEmpty) return true;
      return portal.threadTitle(thread).toLowerCase().contains(query) ||
          valueText(thread, const [
            'subject',
          ], fallback: '').toLowerCase().contains(query);
    }).toList();
    final online = portal.contacts
        .where((item) => item['is_online'] == true)
        .length;
    final unread = portal.threads.fold<int>(
      0,
      (total, item) => total + (valueInt(item['unread_count']) ?? 0),
    );
    final desktop = MediaQuery.sizeOf(context).width >= 1180;
    final selectedId =
        visibleThreads.any(
          (thread) => valueInt(thread['id']) == _selectedThreadId,
        )
        ? _selectedThreadId
        : visibleThreads.firstOrNull == null
        ? null
        : valueInt(visibleThreads.first['id']);

    void openThread(Map<String, Object?> thread) {
      final id = valueInt(thread['id']);
      if (id == null) return;
      if (desktop) {
        setState(() => _selectedThreadId = id);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PortalScope(
            controller: portal,
            child: _ThreadScreen(threadId: id),
          ),
        ),
      );
    }

    return _PortalPage(
      title: portal.isParent ? 'Maktab bilan chat' : 'Chat',
      subtitle: portal.isParent
          ? 'Ustozlar va markaz xodimlari bilan xavfsiz oilaviy muloqot.'
          : 'Ustozlar bilan tezkor, himoyalangan va faylli muloqot.',
      section: PortalSection.messages,
      trailing: FilledButton.tonalIcon(
        onPressed: portal.contacts.isEmpty
            ? null
            : () => _newConversation(context, portal),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Yangi suhbat'),
      ),
      children: [
        _MessengerOverview(
          conversations: portal.threads.length,
          contacts: portal.contacts.length,
          online: online,
          unread: unread,
        ),
        const SizedBox(height: 12),
        if (desktop)
          Container(
            height: (MediaQuery.sizeOf(context).height - 320).clamp(
              360.0,
              690.0,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 350,
                  child: _ConversationBrowser(
                    portal: portal,
                    threads: visibleThreads,
                    search: _search,
                    filter: _filter,
                    unread: unread,
                    selectedThreadId: selectedId,
                    fill: true,
                    onChanged: () => setState(() {}),
                    onFilter: (value) => setState(() => _filter = value),
                    onOpen: openThread,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: selectedId == null
                      ? const _ChatWelcomePane()
                      : _ThreadScreen(
                          key: ValueKey(selectedId),
                          threadId: selectedId,
                          embedded: true,
                        ),
                ),
              ],
            ),
          )
        else
          _SectionCard(
            padding: EdgeInsets.zero,
            child: _ConversationBrowser(
              portal: portal,
              threads: visibleThreads,
              search: _search,
              filter: _filter,
              unread: unread,
              selectedThreadId: null,
              fill: false,
              onChanged: () => setState(() {}),
              onFilter: (value) => setState(() => _filter = value),
              onOpen: openThread,
            ),
          ),
      ],
    );
  }

  Future<void> _newConversation(
    BuildContext context,
    PortalController portal,
  ) async {
    final selected = <int>{};
    final subject = TextEditingController();
    final body = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yangi suhbat'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Qabul qiluvchilar',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 230),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final contact in portal.contacts)
                          if (valueInt(contact['user_id'] ?? contact['id'])
                              case final id?)
                            CheckboxListTile(
                              value: selected.contains(id),
                              secondary: CircleAvatar(
                                child: Text(
                                  _initials(
                                    valueText(contact, const ['display_name']),
                                  ),
                                ),
                              ),
                              title: Text(
                                valueText(contact, const [
                                  'display_name',
                                  'username',
                                ]),
                              ),
                              subtitle: Text(
                                '${valueText(contact, const ['role_label'])}${contact['is_online'] == true ? ' · online' : ''}',
                              ),
                              onChanged: (checked) => setDialogState(() {
                                if (checked == true) {
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                }
                              }),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subject,
                    decoration: const InputDecoration(labelText: 'Mavzu'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: body,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Birinchi xabar',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Boshlash'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || selected.isEmpty || !context.mounted) {
      subject.dispose();
      body.dispose();
      return;
    }
    try {
      final id = await portal.createThread(
        participantIds: selected.toList(),
        subject: subject.text,
        firstBody: body.text,
      );
      if (context.mounted && id > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PortalScope(
              controller: portal,
              child: _ThreadScreen(threadId: id),
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      subject.dispose();
      body.dispose();
    }
  }
}

class _ConversationBrowser extends StatelessWidget {
  const _ConversationBrowser({
    required this.portal,
    required this.threads,
    required this.search,
    required this.filter,
    required this.unread,
    required this.selectedThreadId,
    required this.fill,
    required this.onChanged,
    required this.onFilter,
    required this.onOpen,
  });

  final PortalController portal;
  final List<Map<String, Object?>> threads;
  final TextEditingController search;
  final String filter;
  final int unread;
  final int? selectedThreadId;
  final bool fill;
  final VoidCallback onChanged;
  final ValueChanged<String> onFilter;
  final ValueChanged<Map<String, Object?>> onOpen;

  @override
  Widget build(BuildContext context) {
    final list = threads.isEmpty
        ? _ChatEmptyPane(
            filtered: search.text.trim().isNotEmpty || filter != 'all',
          )
        : ListView.separated(
            shrinkWrap: !fill,
            physics: fill ? null : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final threadId = valueInt(thread['id']);
              final cachedRows = threadId == null
                  ? null
                  : portal.messages[threadId];
              final latest = cachedRows?.lastOrNull;
              return _ConversationTile(
                thread: thread,
                title: portal.threadTitle(thread),
                contact: _threadContact(portal, thread),
                latestMessage: latest,
                selfUserId: portal.messagingSelfUserId,
                selected: threadId == selectedThreadId,
                onTap: () => onOpen(thread),
              );
            },
          );
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: search,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: 'Suhbatlarni qidirish',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Tozalash',
                        onPressed: () {
                          search.clear();
                          onChanged();
                        },
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                isDense: true,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _ChatFilterChip(
                  label: 'Barchasi',
                  selected: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 7),
                _ChatFilterChip(
                  label: 'O‘qilmagan',
                  count: unread,
                  selected: filter == 'unread',
                  onTap: () => onFilter('unread'),
                ),
                const SizedBox(width: 7),
                _ChatFilterChip(
                  label: 'Ovozsiz',
                  icon: Icons.volume_off_outlined,
                  selected: filter == 'muted',
                  onTap: () => onFilter('muted'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          if (fill) Expanded(child: list) else list,
        ],
      ),
    );
  }
}

class _ChatFilterChip extends StatelessWidget {
  const _ChatFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? colors.onPrimary.withValues(alpha: 0.18)
                    : colors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      backgroundColor: selected ? colors.primary : colors.surfaceContainerHigh,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      onPressed: onTap,
    );
  }
}

class _ChatEmptyPane extends StatelessWidget {
  const _ChatEmptyPane({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.search_off_rounded : Icons.forum_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? 'Suhbat topilmadi' : 'Hozircha suhbat yo‘q',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Qidiruv yoki filtrni o‘zgartiring.'
                : 'Yuqoridagi tugma orqali maktab kontaktiga yozing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ChatWelcomePane extends StatelessWidget {
  const _ChatWelcomePane();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceContainerLowest,
            colors.primaryContainer.withValues(alpha: 0.42),
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.mark_chat_unread_rounded,
                  size: 32,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Suhbatni tanlang',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                'Xabarlar faqat suhbat ishtirokchilariga ko‘rinadi. Tarix o‘zgartirilmaydi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessengerOverview extends StatelessWidget {
  const _MessengerOverview({
    required this.conversations,
    required this.contacts,
    required this.online,
    required this.unread,
  });

  final int conversations;
  final int contacts;
  final int online;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.tertiaryContainer.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.forum_rounded, color: colors.onPrimary, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread == 0
                      ? 'Barcha xabarlar o‘qilgan'
                      : '$unread ta yangi xabar bor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Maktab bilan yopiq va xavfsiz aloqa',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 7,
              runSpacing: 7,
              children: [
                _MessengerStat(
                  label: 'suhbat',
                  value: '$conversations',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                _MessengerStat(
                  label: 'kontakt',
                  value: '$contacts',
                  icon: Icons.people_outline_rounded,
                ),
                _MessengerStat(
                  label: 'online',
                  value: '$online',
                  icon: Icons.circle,
                  positive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessengerStat extends StatelessWidget {
  const _MessengerStat({
    required this.label,
    required this.value,
    required this.icon,
    this.positive = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: icon == Icons.circle ? 9 : 16,
            color: positive ? Sf.success : colors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.thread,
    required this.title,
    required this.contact,
    required this.latestMessage,
    required this.selfUserId,
    required this.selected,
    required this.onTap,
  });

  final Map<String, Object?> thread;
  final Map<String, Object?> contact;
  final Map<String, Object?>? latestMessage;
  final int? selfUserId;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = valueInt(thread['unread_count']) ?? 0;
    final online = contact['is_online'] == true;
    final participants = thread['participants'] is List
        ? (thread['participants'] as List).length
        : 0;
    final latestBody = valueText(latestMessage ?? const {}, const [
      'body',
    ], fallback: '');
    final latestAttachments = latestMessage?['attachments'];
    final hasLatestAttachment =
        latestAttachments is List && latestAttachments.isNotEmpty;
    final latestAttachmentKey = hasLatestAttachment
        ? _messageAttachmentKey(latestAttachments.first)
        : '';
    final subject = valueText(thread, const [
      'subject',
    ], fallback: participants > 2 ? 'Guruh suhbati' : 'Shaxsiy suhbat');
    final preview = latestBody.isNotEmpty
        ? latestBody
        : hasLatestAttachment
        ? _attachmentPreviewLabel(latestAttachmentKey)
        : subject;
    final mine = valueInt(latestMessage?['sender']) == selfUserId;
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.68)
              : count > 0
              ? colors.surfaceContainerHigh.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary,
                        colors.tertiary.withValues(alpha: 0.86),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: participants > 2
                      ? Icon(
                          Icons.groups_2_rounded,
                          color: colors.onPrimary,
                          size: 23,
                        )
                      : Text(
                          _initials(title),
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Sf.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? colors.primaryContainer
                              : colors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: count > 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        _dateLabel(
                          thread['last_message_at'] ?? thread['created_at'],
                          time: true,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: count > 0
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: count > 0
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (thread['notifications_muted'] == true) ...[
                        Icon(
                          Icons.volume_off_rounded,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (latestMessage != null && mine) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (hasLatestAttachment) ...[
                        Icon(
                          _attachmentIcon(latestAttachmentKey),
                          size: 15,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: count > 0
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant,
                                fontWeight: count > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (count > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                    ],
                  ),
                  if (latestMessage == null && contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      valueText(contact, const ['role_label']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _workspaceThreadTitle(
  PortalController portal,
  Map<String, Object?> thread,
) {
  final participants = thread['participants'];
  final subject = valueText(thread, const ['subject'], fallback: '');
  if (participants is List && participants.length > 2) {
    return subject.isNotEmpty ? subject : 'Guruh suhbati';
  }
  return portal.threadTitle(thread);
}

Map<String, Object?> _threadContact(
  PortalController portal,
  Map<String, Object?> thread,
) {
  final participants = thread['participants'];
  if (participants is List) {
    for (final raw in participants) {
      if (raw is! Map) continue;
      final id = valueInt(raw['user']);
      if (id == null || id == portal.messagingSelfUserId) continue;
      return portal.messagingContactByUserId(id);
    }
  }
  return const {};
}

List<Map<String, Object?>> _threadContacts(
  PortalController portal,
  Map<String, Object?> thread,
) {
  final participants = thread['participants'];
  if (participants is! List) return const [];
  final contacts = <Map<String, Object?>>[];
  for (final raw in participants) {
    if (raw is! Map) continue;
    final id = valueInt(raw['user']);
    if (id == null || id == portal.messagingSelfUserId) continue;
    final contact = portal.messagingContactByUserId(id);
    contacts.add(
      contact.isNotEmpty
          ? contact
          : <String, Object?>{
              'id': id,
              'user_id': id,
              'display_name': 'Foydalanuvchi #$id',
              'role_label': 'Suhbat ishtirokchisi',
            },
    );
  }
  return contacts;
}

String _chatAvatarValue(Map<String, Object?> contact) {
  String from(Object? raw) {
    if (raw is String) {
      final value = raw.trim();
      return value == 'null' ? '' : value;
    }
    if (raw is Map) {
      for (final key in const [
        'url',
        'download_url',
        'file_url',
        'src',
        'path',
        'file',
      ]) {
        final value = from(raw[key]);
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  for (final key in const [
    'avatar_url',
    'photo_url',
    'profile_photo_url',
    'avatar',
    'photo',
    'profile_photo',
    'picture',
    'image_url',
    'image',
  ]) {
    final value = from(contact[key]);
    if (value.isNotEmpty) return value;
  }
  for (final key in const [
    'profile',
    'user',
    'person',
    'identity',
    'contact',
    'student',
  ]) {
    final nested = contact[key];
    if (nested is Map) {
      final value = _chatAvatarValue(Map<String, Object?>.from(nested));
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

String _resolvedChatAvatarUrl(PortalController portal, String raw) {
  if (raw.isEmpty || raw.startsWith('data:')) return raw;
  final parsed = Uri.tryParse(raw);
  if (parsed != null && parsed.hasScheme) return raw;
  final origin = Uri.parse(portal.baseUrl);
  if (raw.startsWith('//')) return '${origin.scheme}:$raw';
  final normalized = raw.startsWith('/') ? raw : '/$raw';
  return origin.resolve(normalized).toString();
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.portal,
    required this.contact,
    required this.name,
    this.radius = 22,
    this.group = false,
    this.onTap,
  });

  final PortalController portal;
  final Map<String, Object?> contact;
  final String name;
  final double radius;
  final bool group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userId = valueInt(contact['user_id'] ?? contact['id']);
    final cached = userId == null
        ? const <String, Object?>{}
        : portal.messagingContactByUserId(userId);
    final effective = {...contact, ...cached};
    if (!group &&
        _chatAvatarValue(effective).isEmpty &&
        userId != null &&
        effective['principal_kind'] == 'student' &&
        effective['_profile_detail_attempted'] != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          portal
              .loadMessagingContactProfile(contact)
              .catchError((_) => contact),
        );
      });
    }
    Widget fallback() => ColoredBox(
      color: colors.primary,
      child: Center(
        child: group
            ? Icon(
                Icons.groups_2_rounded,
                color: colors.onPrimary,
                size: radius,
              )
            : Text(
                _initials(name),
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: radius * .52,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );

    final raw = group ? '' : _chatAvatarValue(effective);
    Widget image = fallback();
    if (raw.startsWith('data:image/') && raw.contains(',')) {
      try {
        image = Image.memory(
          base64Decode(raw.substring(raw.indexOf(',') + 1)),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback(),
        );
      } on FormatException {
        image = fallback();
      }
    } else if (raw.isNotEmpty) {
      image = Image.network(
        _resolvedChatAvatarUrl(portal, raw),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback(),
      );
    }
    final avatar = Semantics(
      image: true,
      label: '$name avatar',
      child: SizedBox.square(
        dimension: radius * 2,
        child: ClipOval(child: image),
      ),
    );
    if (onTap == null) return avatar;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: avatar,
    );
  }
}

Future<void> _openChatContactProfile(
  BuildContext context,
  PortalController portal,
  Map<String, Object?> contact, {
  Map<String, Object?> thread = const {},
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (_) => PortalScope(
      controller: portal,
      child: _ChatContactProfilePage(
        portal: portal,
        initial: contact,
        thread: thread,
      ),
    ),
  ),
);

Future<void> _openThreadInfo(
  BuildContext context,
  PortalController portal,
  Map<String, Object?> thread,
) {
  final contacts = _threadContacts(portal, thread);
  if (contacts.length == 1) {
    return _openChatContactProfile(
      context,
      portal,
      contacts.first,
      thread: thread,
    );
  }
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PortalScope(
        controller: portal,
        child: _ChatGroupInfoPage(
          portal: portal,
          thread: thread,
          contacts: contacts,
        ),
      ),
    ),
  );
}

class _ChatContactProfilePage extends StatefulWidget {
  const _ChatContactProfilePage({
    required this.portal,
    required this.initial,
    this.thread = const {},
  });

  final PortalController portal;
  final Map<String, Object?> initial;
  final Map<String, Object?> thread;

  @override
  State<_ChatContactProfilePage> createState() =>
      _ChatContactProfilePageState();
}

class _ChatContactProfilePageState extends State<_ChatContactProfilePage> {
  late final Future<Map<String, Object?>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.portal.loadMessagingContactProfile(
      widget.initial,
      force: true,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, Object?>>(
    future: _profile,
    initialData: widget.initial,
    builder: (context, snapshot) {
      final portal = PortalScope.of(context);
      final snapshotContact = snapshot.data ?? widget.initial;
      final userId = valueInt(
        snapshotContact['user_id'] ?? snapshotContact['id'],
      );
      final cached = portal.messagingContactByUserId(userId);
      final contact = cached.isEmpty
          ? snapshotContact
          : {...snapshotContact, ...cached};
      final name = valueText(contact, const [
        'display_name',
        'full_name',
        'username',
      ], fallback: 'Suhbat ishtirokchisi');
      String t(String uz, String ru, String en) =>
          switch (portal.preferences.language) {
            PortalLanguage.uz => uz,
            PortalLanguage.ru => ru,
            PortalLanguage.en => en,
          };
      String value(List<String> keys) {
        for (final key in keys) {
          final raw = contact[key];
          if (raw is List) {
            final parts = raw
                .map(
                  (item) => item is Map
                      ? valueText(Map<String, Object?>.from(item), const [
                          'name',
                          'title',
                          'label',
                        ])
                      : '$item'.trim(),
                )
                .where((item) => item.isNotEmpty && item != 'null')
                .toList(growable: false);
            if (parts.isNotEmpty) return parts.join(', ');
          }
          final text = '${raw ?? ''}'.trim();
          if (text.isNotEmpty && text != 'null') return text;
        }
        return '';
      }

      (IconData, String, String)? row(
        IconData icon,
        String label,
        List<String> keys, {
        bool date = false,
      }) {
        final raw = value(keys);
        if (raw.isEmpty) return null;
        return (icon, label, date ? _dateLabel(raw) : raw);
      }

      final role = value(const ['role_label', 'role_slug']);
      final phone = value(const ['phone']);
      final email = value(const ['email']);
      final genderRaw = value(const ['gender']).toLowerCase();
      final gender = switch (genderRaw) {
        'm' || 'male' => t('Erkak', 'Мужской', 'Male'),
        'f' || 'female' => t('Ayol', 'Женский', 'Female'),
        _ => '',
      };
      final profileId = valueInt(contact['profile_id']);
      final matchingLessons =
          portal.lessons.where((lesson) {
            if (contact['principal_kind'] != 'teacher') return false;
            final teacherId = valueInt(
              lesson['teacher'] ?? lesson['teacher_id'],
            );
            if (profileId != null && teacherId == profileId) return true;
            final teacherName = valueText(lesson, const [
              'teacher_name',
            ], fallback: '').trim().toLowerCase();
            return teacherName.isNotEmpty &&
                teacherName == name.trim().toLowerCase();
          }).toList()..sort(
            (left, right) =>
                '${left['starts_at']}'.compareTo('${right['starts_at']}'),
          );
      final nextLesson = matchingLessons
          .where(
            (lesson) =>
                DateTime.tryParse(
                  '${lesson['starts_at'] ?? ''}',
                )?.isAfter(DateTime.now()) ==
                true,
          )
          .firstOrNull;
      final threadId = valueInt(widget.thread['id']);
      final chatMessages = threadId == null
          ? const <Map<String, Object?>>[]
          : portal.messages[threadId] ?? const <Map<String, Object?>>[];
      final attachmentKeys = <String>[
        for (final message in chatMessages)
          if (message['attachments'] is List)
            for (final attachment in message['attachments'] as List)
              if (_messageAttachmentKey(attachment).isNotEmpty)
                _messageAttachmentKey(attachment),
      ];
      final voiceCount = attachmentKeys.where(_isAudioAttachment).length;
      final mediaCount = attachmentKeys
          .where((key) => _isImageAttachment(key) || _isVideoAttachment(key))
          .length;
      final accountRows = <(IconData, String, String)>[
        if (role.isNotEmpty)
          (Icons.badge_outlined, t('Lavozim', 'Роль', 'Role'), role),
        ?row(
          Icons.alternate_email_rounded,
          t('Login', 'Логин', 'Username'),
          const ['username'],
        ),
        ?row(
          Icons.confirmation_number_outlined,
          t('O‘quvchi ID', 'ID ученика', 'Student ID'),
          const ['student_id'],
        ),
        ?row(Icons.verified_outlined, t('Holat', 'Статус', 'Status'), const [
          'status',
        ]),
      ];
      final contactRows = <(IconData, String, String)>[
        ?row(Icons.phone_outlined, t('Telefon', 'Телефон', 'Phone'), const [
          'phone',
        ]),
        ?row(Icons.mail_outline_rounded, 'Email', const ['email']),
        ?row(
          Icons.location_on_outlined,
          t('Manzil', 'Местоположение', 'Location'),
          const ['location'],
        ),
      ];
      final educationRows = <(IconData, String, String)>[
        ?row(Icons.apartment_rounded, t('Filial', 'Филиал', 'Branch'), const [
          'branch_name',
        ]),
        ?row(Icons.groups_2_outlined, t('Guruh', 'Группа', 'Group'), const [
          'current_cohort_name',
          'cohort_name',
        ]),
        ?row(Icons.school_outlined, t('Bo‘lim', 'Отдел', 'Department'), const [
          'department_name',
        ]),
        ?row(Icons.trending_up_rounded, t('Daraja', 'Уровень', 'Level'), const [
          'academic_level',
        ]),
        ?row(
          Icons.menu_book_outlined,
          t('Fanlar', 'Предметы', 'Subjects'),
          const ['subjects'],
        ),
        ?row(
          Icons.workspace_premium_outlined,
          t('Malaka', 'Квалификация', 'Qualifications'),
          const ['qualifications'],
        ),
        ?row(
          Icons.business_center_outlined,
          t('Ish joyi', 'Место работы', 'Workplace'),
          const ['workplace'],
        ),
        ?row(
          Icons.event_available_outlined,
          t('Qabul sanasi', 'Дата зачисления', 'Enrollment date'),
          const ['enrollment_date', 'hire_date'],
          date: true,
        ),
        if (nextLesson != null)
          (
            Icons.upcoming_outlined,
            t('Keyingi dars', 'Следующий урок', 'Next lesson'),
            '${valueText(nextLesson, const ['title'], fallback: t('Dars', 'Урок', 'Lesson'))} · ${_dateLabel(nextLesson['starts_at'], time: true)}',
          ),
      ];
      final personalRows = <(IconData, String, String)>[
        if (gender.isNotEmpty)
          (Icons.person_outline_rounded, t('Jins', 'Пол', 'Gender'), gender),
        ?row(
          Icons.cake_outlined,
          t('Tug‘ilgan sana', 'Дата рождения', 'Birth date'),
          const ['birthdate'],
          date: true,
        ),
        ?row(
          Icons.calendar_month_outlined,
          t('Profil yaratilgan', 'Профиль создан', 'Profile created'),
          const ['created_at', 'date_joined'],
          date: true,
        ),
      ];
      final chatRows = <(IconData, String, String)>[
        if (threadId != null)
          (
            Icons.chat_bubble_outline_rounded,
            t('Xabarlar', 'Сообщения', 'Messages'),
            '${chatMessages.length}',
          ),
        if (threadId != null)
          (
            Icons.perm_media_outlined,
            t('Media', 'Медиа', 'Media'),
            '$mediaCount',
          ),
        if (threadId != null)
          (
            Icons.graphic_eq_rounded,
            t('Ovozli xabarlar', 'Голосовые сообщения', 'Voice messages'),
            '$voiceCount',
          ),
        if (threadId != null)
          (
            Icons.attach_file_rounded,
            t('Barcha fayllar', 'Все файлы', 'All files'),
            '${attachmentKeys.length}',
          ),
      ];
      return Scaffold(
        key: const ValueKey('chat-contact-profile-page'),
        appBar: AppBar(title: Text(t('Profil', 'Профиль', 'Profile'))),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        _ChatAvatar(
                          portal: widget.portal,
                          contact: contact,
                          name: name,
                          radius: 52,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          contact['is_online'] == true
                              ? 'online'
                              : role.isEmpty
                              ? t(
                                  'Maktab kontakti',
                                  'Контакт школы',
                                  'School contact',
                                )
                              : role,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: .82),
                              ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: Text(
                            t(
                              'Suhbatga qaytish',
                              'Вернуться в чат',
                              'Back to chat',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (phone.isNotEmpty || email.isNotEmpty)
                    Row(
                      children: [
                        if (phone.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri(scheme: 'tel', path: phone)),
                              icon: const Icon(Icons.phone_outlined),
                              label: Text(t('Qo‘ng‘iroq', 'Позвонить', 'Call')),
                            ),
                          ),
                        if (phone.isNotEmpty && email.isNotEmpty)
                          const SizedBox(width: 10),
                        if (email.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri(scheme: 'mailto', path: email)),
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: const Text('Email'),
                            ),
                          ),
                      ],
                    ),
                  if (phone.isNotEmpty || email.isNotEmpty)
                    const SizedBox(height: 16),
                  if (accountRows.isNotEmpty)
                    _ChatProfileSection(
                      title: t('Asosiy', 'Основное', 'Overview'),
                      rows: accountRows,
                    ),
                  if (contactRows.isNotEmpty)
                    _ChatProfileSection(
                      title: t('Aloqa', 'Контакты', 'Contact'),
                      rows: contactRows,
                    ),
                  if (educationRows.isNotEmpty)
                    _ChatProfileSection(
                      title: t(
                        'Ta’lim va ish',
                        'Учёба и работа',
                        'Education and work',
                      ),
                      rows: educationRows,
                    ),
                  if (personalRows.isNotEmpty)
                    _ChatProfileSection(
                      title: t('Shaxsiy', 'Личное', 'Personal'),
                      rows: personalRows,
                    ),
                  if (chatRows.isNotEmpty)
                    _ChatProfileSection(
                      title: t('Suhbat', 'Чат', 'Chat'),
                      rows: chatRows,
                    ),
                  if (accountRows.isEmpty &&
                      contactRows.isEmpty &&
                      educationRows.isEmpty &&
                      personalRows.isEmpty)
                    _EmptyState(
                      icon: Icons.person_search_outlined,
                      title: t(
                        'Profil ma’lumotlari cheklangan',
                        'Данные профиля ограничены',
                        'Profile information is limited',
                      ),
                      message: t(
                        'Bu kontaktda hozircha faqat ism ko‘rsatilgan.',
                        'Сейчас для этого контакта доступно только имя.',
                        'Only the contact name is currently available.',
                      ),
                    ),
                  if (snapshot.connectionState == ConnectionState.waiting) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Row(
                        children: [
                          const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t(
                                'Profil ma’lumotlari yangilanmoqda…',
                                'Обновляем данные профиля…',
                                'Updating profile information…',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ChatProfileSection extends StatelessWidget {
  const _ChatProfileSection({required this.title, required this.rows});

  final String title;
  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        _SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      rows[index].$1,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(rows[index].$2),
                  subtitle: SelectableText(rows[index].$3),
                ),
                if (index != rows.length - 1)
                  const Divider(height: 1, indent: 66),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChatGroupInfoPage extends StatelessWidget {
  const _ChatGroupInfoPage({
    required this.portal,
    required this.thread,
    required this.contacts,
  });

  final PortalController portal;
  final Map<String, Object?> thread;
  final List<Map<String, Object?>> contacts;

  @override
  Widget build(BuildContext context) {
    final title = _workspaceThreadTitle(portal, thread);
    return Scaffold(
      key: const ValueKey('chat-group-info-page'),
      appBar: AppBar(title: const Text('Guruh ma’lumoti')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Center(
                  child: _ChatAvatar(
                    portal: portal,
                    contact: const {},
                    name: title,
                    radius: 52,
                    group: true,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${contacts.length + 1} ishtirokchi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Ishtirokchilar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    children: [
                      for (var index = 0; index < contacts.length; index++) ...[
                        ListTile(
                          onTap: () => _openChatContactProfile(
                            context,
                            portal,
                            contacts[index],
                            thread: thread,
                          ),
                          leading: _ChatAvatar(
                            portal: portal,
                            contact: contacts[index],
                            name: valueText(contacts[index], const [
                              'display_name',
                              'username',
                            ]),
                            radius: 22,
                          ),
                          title: Text(
                            valueText(contacts[index], const [
                              'display_name',
                              'username',
                            ]),
                          ),
                          subtitle: Text(
                            valueText(contacts[index], const ['role_label']),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                        if (index != contacts.length - 1)
                          const Divider(height: 1, indent: 66),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadScreen extends StatefulWidget {
  const _ThreadScreen({
    super.key,
    required this.threadId,
    this.embedded = false,
  });

  final int threadId;
  final bool embedded;

  @override
  State<_ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<_ThreadScreen>
    with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _messageSearch = TextEditingController();
  final List<PlatformFile> _pendingFiles = [];
  final Map<String, String> _pendingContentTypes = {};
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _messagePollTimer;
  bool _messagePolling = false;
  bool _appActive = true;
  bool _sending = false;
  bool _searching = false;
  bool _recording = false;
  bool _preparingVoice = false;
  bool _loadingMessages = true;
  Object? _loadError;
  String _sendingProgress = '';
  String? _sendError;
  Duration _recordDuration = Duration.zero;
  double _recordLevel = 0;
  String _voiceExtension = 'webm';
  DateTime? _voiceStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadCurrentMessages());
        _messagePollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
          final visible =
              mounted &&
              _appActive &&
              (ModalRoute.of(context)?.isCurrent ?? true) &&
              TickerMode.valuesOf(context).enabled;
          if (visible && !_sending && !_recording && !_messagePolling) {
            _messagePolling = true;
            unawaited(
              PortalScope.read(context)
                  .ensureLatestMessagePage(widget.threadId)
                  .catchError((_) {})
                  .whenComplete(() => _messagePolling = false),
            );
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (!_appActive && _recording) {
      unawaited(_finishVoiceRecording(discard: true));
    }
  }

  Future<void> _loadCurrentMessages({bool force = false}) async {
    final portal = PortalScope.read(context);
    if (mounted) {
      setState(() {
        _loadingMessages = true;
        _loadError = null;
      });
    }
    try {
      await portal.loadMessages(widget.threadId, force: true);
      await portal.ensureLatestMessagePage(widget.threadId);
      final controllerError = portal.messageErrors[widget.threadId];
      if (controllerError != null && mounted) {
        setState(() => _loadError = controllerError);
        if (portal.messages.containsKey(widget.threadId)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(controllerError)));
        }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
        if (portal.messages.containsKey(widget.threadId)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorText(error))));
        }
      }
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  @override
  void dispose() {
    _messagePollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_disposeRecorder());
    _composer.dispose();
    _messageSearch.dispose();
    super.dispose();
  }

  Future<void> _disposeRecorder() async {
    try {
      await _recorder.cancel();
    } on Object {
      // The native recorder can already be stopped during lifecycle teardown.
    }
    await _recorder.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    _addPickedFiles(result);
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb,
    );
    _addPickedFiles(result);
  }

  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
      withData: kIsWeb,
    );
    _addPickedFiles(result);
  }

  void _addPickedFiles(FilePickerResult? result) {
    if (result == null || !mounted) return;
    const safeMemoryLimit = 100 * 1024 * 1024;
    final accepted = result.files
        .where((file) => file.size <= safeMemoryLimit)
        .toList(growable: false);
    final remaining = 10 - _pendingFiles.length;
    setState(() {
      _pendingFiles.addAll(accepted.take(remaining));
    });
    if (result.files.length != accepted.length && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitta fayl 100 MB dan katta bo‘lmasligi kerak.'),
        ),
      );
    } else if (accepted.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitta xabarga ko‘pi bilan 10 ta fayl.')),
      );
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'ogg', 'opus', 'wav'],
      withData: kIsWeb,
    );
    _addPickedFiles(result);
  }

  Future<void> _startVoiceRecording() async {
    if (_sending || _recording || _preparingVoice) return;
    setState(() => _preparingVoice = true);
    try {
      if (!await _recorder.hasPermission()) {
        throw const ApiException(
          message: 'Ovoz yozish uchun mikrofon ruxsatini bering.',
          code: 'microphone_permission_denied',
        );
      }
      final aacSupported =
          !kIsWeb && await _recorder.isEncoderSupported(AudioEncoder.aacLc);
      final opusSupported = await _recorder.isEncoderSupported(
        AudioEncoder.opus,
      );
      final encoder = aacSupported
          ? AudioEncoder.aacLc
          : opusSupported
          ? AudioEncoder.opus
          : AudioEncoder.wav;
      _voiceExtension = aacSupported
          ? 'm4a'
          : opusSupported
          ? (kIsWeb ? 'webm' : 'opus')
          : 'wav';
      final recordingPath = await createVoiceRecordingPath(_voiceExtension);
      await _recorder.start(
        RecordConfig(
          encoder: encoder,
          bitRate: 64000,
          sampleRate: 48000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: recordingPath,
      );
      _recordDuration = Duration.zero;
      _recordLevel = 0;
      _voiceStartedAt = DateTime.now();
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        }
      });
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
            if (!mounted) return;
            final normalized = ((amplitude.current + 60) / 60)
                .clamp(0.0, 1.0)
                .toDouble();
            setState(() => _recordLevel = normalized);
          });
      if (mounted) setState(() => _recording = true);
    } on Object catch (error) {
      _recordTimer?.cancel();
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      try {
        await _recorder.cancel();
      } on Object {
        // A start failure can leave the platform recorder half-initialized.
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _preparingVoice = false);
    }
  }

  Future<void> _finishVoiceRecording({required bool discard}) async {
    if (!_recording) return;
    final duration = _voiceStartedAt == null
        ? _recordDuration
        : DateTime.now().difference(_voiceStartedAt!);
    _recordTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    setState(() {
      _recording = false;
      _preparingVoice = true;
      _recordLevel = 0;
    });
    try {
      if (discard) {
        await _recorder.cancel();
        return;
      }
      if (duration < const Duration(milliseconds: 350)) {
        await _recorder.cancel();
        throw const ApiException(
          message:
              'Ovozli xabar juda qisqa. Mikrofonni biroz uzoqroq bosib turing.',
          code: 'voice_too_short',
        );
      }
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        throw const ApiException(
          message: 'Ovozli xabarni saqlab bo‘lmadi.',
          code: 'voice_recording_failed',
        );
      }
      if (_voiceExtension == 'm4a' && !await normalizeRecordedM4aBrand(path)) {
        throw const ApiException(
          message: 'Ovoz yozuvining M4A formati noto‘g‘ri qaytdi.',
          code: 'voice_container_invalid',
        );
      }
      final bytes = await readRecordedFileBytes(path);
      if (bytes.length < 128) {
        throw const ApiException(
          message:
              'Ovoz yozuvi bo‘sh chiqdi. Mikrofon ruxsatini tekshirib qayta urinib ko‘ring.',
          code: 'voice_recording_empty',
        );
      }
      final format = recordedVoiceUploadFormat(bytes, _voiceExtension);
      try {
        await deleteRecordedFile(path);
      } on Object {
        // A failed cache cleanup must never discard an otherwise valid voice.
      }
      final seconds = duration.inSeconds.clamp(1, 599);
      final filename =
          'voice-${seconds}s-${DateTime.now().millisecondsSinceEpoch}.${format.extension}';
      final file = PlatformFile(
        name: filename,
        size: bytes.length,
        bytes: bytes,
      );
      if (mounted) {
        if (_pendingFiles.length >= 10) {
          throw const ApiException(
            message: 'Bitta xabarga ko‘pi bilan 10 ta fayl yuboriladi.',
          );
        }
        setState(() {
          _pendingFiles.add(file);
          _pendingContentTypes[filename] = format.contentType;
        });
        await _send();
      }
    } on Object catch (error) {
      try {
        await _recorder.cancel();
      } on Object {
        // The recorder may already be stopped after a platform-side failure.
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _preparingVoice = false;
          _recordDuration = Duration.zero;
          _voiceStartedAt = null;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if ((text.isEmpty && _pendingFiles.isEmpty) || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final portal = PortalScope.read(context);
      final attachments = <String>[];
      for (var index = 0; index < _pendingFiles.length; index++) {
        final file = _pendingFiles[index];
        if (mounted) {
          setState(
            () => _sendingProgress =
                '${index + 1}/${_pendingFiles.length} fayl yuklanmoqda',
          );
        }
        final bytes = await readSelectedFileBytes(file.bytes, file.path);
        attachments.add(
          await portal.uploadMessageFile(
            filename: file.name,
            contentType:
                _pendingContentTypes[file.name] ??
                _contentType(file.extension, filename: file.name),
            bytes: bytes,
          ),
        );
      }
      if (mounted) setState(() => _sendingProgress = 'Xabar yuborilmoqda');
      await portal.sendMessage(widget.threadId, text, attachments: attachments);
      await portal.ensureLatestMessagePage(widget.threadId);
      _composer.clear();
      _pendingFiles.clear();
      _pendingContentTypes.clear();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _sendError = _errorText(error));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendingProgress = '';
        });
      }
    }
  }

  Future<void> _showMessageActions(
    Map<String, Object?> message, {
    required bool mine,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Xabar amallari',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final emoji in const [
                      '👍',
                      '❤️',
                      '😂',
                      '😮',
                      '😢',
                      '🙏',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ActionChip(
                          label: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          onPressed: () =>
                              Navigator.pop(sheetContext, 'reaction:$emoji'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.forward_rounded),
                title: const Text('Boshqa suhbatga yuborish'),
                onTap: () => Navigator.pop(sheetContext, 'forward'),
              ),
              if (mine)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Tahrirlash'),
                  enabled: valueText(message, const [
                    'body',
                  ], fallback: '').isNotEmpty,
                  onTap: () => Navigator.pop(sheetContext, 'edit'),
                ),
              if (mine)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(
                    'O‘chirish',
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'delete'),
                ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Nusxalash'),
                enabled: valueText(message, const [
                  'body',
                ], fallback: '').isNotEmpty,
                onTap: () => Navigator.pop(sheetContext, 'copy'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(
        ClipboardData(text: valueText(message, const ['body'], fallback: '')),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xabar nusxalandi.')));
      }
      return;
    }
    if (action == 'forward') {
      await _forwardMessage(message);
      return;
    }
    final messageId = valueInt(message['id']);
    if (messageId == null) return;
    if (action.startsWith('reaction:')) {
      final emoji = action.substring('reaction:'.length);
      final portal = PortalScope.read(context);
      await _setReaction(
        message,
        emoji,
        remove: _messageHasOwnReaction(
          message,
          emoji,
          portal.messagingSelfUserId,
        ),
      );
      return;
    }
    if (action == 'edit') {
      await _editMessage(message);
      return;
    }
    if (action == 'delete') await _deleteMessage(message);
  }

  Future<void> _setReaction(
    Map<String, Object?> message,
    String emoji, {
    required bool remove,
  }) async {
    final id = valueInt(message['id']);
    if (id == null) return;
    try {
      await PortalScope.read(context).setMessageReaction(
        threadId: widget.threadId,
        messageId: id,
        emoji: emoji,
        remove: remove,
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    }
  }

  Future<void> _editMessage(Map<String, Object?> message) async {
    final id = valueInt(message['id']);
    final current = valueText(message, const ['body'], fallback: '');
    if (id == null || current.isEmpty) return;
    final controller = TextEditingController(text: current);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xabarni tahrirlash'),
        content: TextField(
          key: const ValueKey('chat-edit-message-field'),
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Xabar matni'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    final next = controller.text.trim();
    controller.dispose();
    if (accepted != true || next.isEmpty || next == current || !mounted) return;
    try {
      await PortalScope.read(
        context,
      ).editMessage(threadId: widget.threadId, messageId: id, body: next);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xabar tahrirlandi.')));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    }
  }

  Future<void> _deleteMessage(Map<String, Object?> message) async {
    final id = valueInt(message['id']);
    if (id == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xabar o‘chirilsinmi?'),
        content: const Text('Bu amalni ortga qaytarib bo‘lmaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('O‘chirish'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await PortalScope.read(
        context,
      ).deleteMessage(threadId: widget.threadId, messageId: id);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    }
  }

  Future<void> _forwardMessage(Map<String, Object?> message) async {
    final portal = PortalScope.read(context);
    final targets = portal.threads
        .where((thread) => valueInt(thread['id']) != widget.threadId)
        .toList(growable: false);
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yuborish uchun boshqa ochiq suhbat mavjud emas.'),
        ),
      );
      return;
    }
    final targetId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              Text(
                'Kimga yuborilsin?',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              for (final thread in targets)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(_initials(portal.threadTitle(thread))),
                  ),
                  title: Text(portal.threadTitle(thread)),
                  subtitle: Text(
                    valueText(thread, const ['subject'], fallback: 'Suhbat'),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, valueInt(thread['id'])),
                ),
            ],
          ),
        ),
      ),
    );
    if (targetId == null || !mounted) return;
    setState(() {
      _sending = true;
      _sendingProgress = 'Xabar boshqa suhbatga yuborilmoqda';
      _sendError = null;
    });
    try {
      await portal.forwardMessage(
        sourceThreadId: widget.threadId,
        targetThreadId: targetId,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xabar yuborildi.')));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _sendError = _errorText(error));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendingProgress = '';
        });
      }
    }
  }

  Future<void> _showAttachmentPicker() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Text(
                  'Xabarga biriktirish',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _AttachmentChoice(
                icon: Icons.photo_library_outlined,
                title: 'Rasm',
                subtitle: 'Chat ichida surat sifatida ko‘rinadi',
                onTap: () => Navigator.pop(context, 'images'),
              ),
              const SizedBox(height: 8),
              _AttachmentChoice(
                icon: Icons.video_library_outlined,
                title: 'Video',
                subtitle: 'MP4, MOV, M4V yoki WEBM video yuboring',
                onTap: () => Navigator.pop(context, 'videos'),
              ),
              const SizedBox(height: 8),
              _AttachmentChoice(
                icon: Icons.insert_drive_file_outlined,
                title: 'Hujjat',
                subtitle: 'PDF, DOCX va boshqa fayllar',
                onTap: () => Navigator.pop(context, 'files'),
              ),
              const SizedBox(height: 8),
              _AttachmentChoice(
                icon: Icons.audio_file_outlined,
                title: 'Tayyor audio',
                subtitle: 'MP3, M4A, OGG, OPUS yoki WAV',
                onTap: () => Navigator.pop(context, 'audio'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'images') await _pickImages();
    if (choice == 'videos') await _pickVideos();
    if (choice == 'files') await _pickFiles();
    if (choice == 'audio') await _pickAudioFile();
  }

  void _insertEmoji(String emoji) {
    final selection = _composer.selection;
    final start = selection.isValid ? selection.start : _composer.text.length;
    final end = selection.isValid ? selection.end : _composer.text.length;
    _composer.value = TextEditingValue(
      text: _composer.text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _showEmojiPicker() async {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final emoji = wide
        ? await showDialog<String>(
            context: context,
            builder: (context) => const Dialog(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 440,
                height: 430,
                child: _EmojiPickerContent(),
              ),
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => const SafeArea(
              child: SizedBox(height: 410, child: _EmojiPickerContent()),
            ),
          );
    if (emoji != null && mounted) _insertEmoji(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final thread = portal.threads
        .where((item) => valueInt(item['id']) == widget.threadId)
        .firstOrNull;
    final contact = _threadContact(portal, thread ?? const {});
    final allRows = portal.messages[widget.threadId];
    final effectiveLoadError =
        _loadError ?? portal.messageErrors[widget.threadId];
    final query = _messageSearch.text.trim().toLowerCase();
    final rows = allRows
        ?.where(
          (message) =>
              query.isEmpty ||
              valueText(message, const [
                'body',
              ], fallback: '').toLowerCase().contains(query),
        )
        .toList();
    rows?.sort(
      (left, right) =>
          '${left['created_at']}'.compareTo('${right['created_at']}'),
    );
    final self = portal.messagingSelfUserId;
    final participants = thread?['participants'] is List
        ? (thread!['participants'] as List).length
        : 0;
    final title = _workspaceThreadTitle(portal, thread ?? const {});
    final subject = valueText(thread ?? const {}, const [
      'subject',
    ], fallback: '');
    final canWrite = portal.can('messaging:write');
    final colors = Theme.of(context).colorScheme;
    final narrowHeader = MediaQuery.sizeOf(context).width < 430;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        key: const ValueKey('family-chat-header'),
        automaticallyImplyLeading: false,
        toolbarHeight: 62,
        shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
        leading: widget.embedded
            ? null
            : IconButton(
                tooltip: 'Suhbatlarga qaytish',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        title: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: thread == null
              ? null
              : () => _openThreadInfo(context, portal, thread),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _ChatAvatar(
                    portal: portal,
                    contact: contact,
                    name: title,
                    radius: 19,
                    group: participants > 2,
                  ),
                  if (contact['is_online'] == true)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Sf.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    Text(
                      contact['is_online'] == true
                          ? 'online'
                          : participants > 2
                          ? '$participants ishtirokchi'
                          : valueText(contact, const [
                              'role_label',
                            ], fallback: 'Maktab kontakti'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: contact['is_online'] == true
                            ? Sf.success
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Qidiruvni yopish' : 'Suhbat ichida qidirish',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _messageSearch.clear();
            }),
            icon: Icon(
              _searching ? Icons.search_off_rounded : Icons.search_rounded,
            ),
          ),
          if (!narrowHeader)
            IconButton(
              tooltip: 'Yangilash',
              onPressed: _loadingMessages
                  ? null
                  : () => _loadCurrentMessages(force: true),
              icon: _loadingMessages
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          if (!narrowHeader)
            IconButton(
              tooltip: thread?['notifications_muted'] == true
                  ? 'Bildirishnomani yoqish'
                  : 'Ovozsiz qilish',
              onPressed: thread == null
                  ? null
                  : () => _runAction(
                      context,
                      () => portal.setThreadMuted(
                        widget.threadId,
                        thread['notifications_muted'] != true,
                      ),
                      success: thread['notifications_muted'] == true
                          ? 'Bildirishnomalar yoqildi.'
                          : 'Suhbat ovozsiz qilindi.',
                    ),
              icon: Icon(
                thread?['notifications_muted'] == true
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_outlined,
              ),
            ),
          if (narrowHeader)
            PopupMenuButton<String>(
              tooltip: 'Suhbat amallari',
              onSelected: (value) {
                if (value == 'refresh') {
                  _loadCurrentMessages(force: true);
                  return;
                }
                if (value == 'mute' && thread != null) {
                  _runAction(
                    context,
                    () => portal.setThreadMuted(
                      widget.threadId,
                      thread['notifications_muted'] != true,
                    ),
                    success: thread['notifications_muted'] == true
                        ? 'Bildirishnomalar yoqildi.'
                        : 'Suhbat ovozsiz qilindi.',
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Yangilash'),
                  ),
                ),
                PopupMenuItem(
                  value: 'mute',
                  enabled: thread != null,
                  child: ListTile(
                    leading: Icon(
                      thread?['notifications_muted'] == true
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                    ),
                    title: Text(
                      thread?['notifications_muted'] == true
                          ? 'Bildirishnomani yoqish'
                          : 'Ovozsiz qilish',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_searching)
            Container(
              key: const ValueKey('family-chat-search-header'),
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('family-chat-message-search'),
                      controller: _messageSearch,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        hintText: 'Xabar matnini qidiring',
                        isDense: true,
                        suffixIcon: _messageSearch.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _messageSearch.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      query.isEmpty ? '—' : '${rows?.length ?? 0} ta',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (subject.isNotEmpty && subject != title)
            Container(
              height: 37,
              color: colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.tag_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'yopiq kanal',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: _chatWallpaperColor(
                      portal.preferences.chatWallpaper,
                      colors,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChatBackgroundPainter(
                      color: colors.primary.withValues(alpha: 0.055),
                      wallpaper: portal.preferences.chatWallpaper,
                    ),
                  ),
                ),
                if (allRows == null && effectiveLoadError != null)
                  _MessageErrorPane(
                    error: effectiveLoadError,
                    onRetry: () => _loadCurrentMessages(force: true),
                  )
                else if (rows == null)
                  const _MessageLoadingPane()
                else if (rows.isEmpty)
                  _MessageEmptyPane(searching: query.isNotEmpty)
                else
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    itemCount:
                        rows.length +
                        (portal.hasOlderMessages(widget.threadId) ? 1 : 0),
                    itemBuilder: (context, reverseIndex) {
                      if (reverseIndex == rows.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: OutlinedButton.icon(
                              onPressed:
                                  portal.loadingOlderMessages(widget.threadId)
                                  ? null
                                  : () => _runAction(
                                      context,
                                      () => portal.loadOlderMessages(
                                        widget.threadId,
                                      ),
                                      success: 'Oldingi xabarlar yuklandi.',
                                    ),
                              icon: portal.loadingOlderMessages(widget.threadId)
                                  ? const SizedBox.square(
                                      dimension: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.history_rounded),
                              label: const Text('Oldingi xabarlarni yuklash'),
                            ),
                          ),
                        );
                      }
                      final messageIndex = rows.length - reverseIndex - 1;
                      final message = rows[messageIndex];
                      final sender = valueInt(message['sender']);
                      final mine = sender == self;
                      final currentDay = _dateLabel(message['created_at']);
                      final previous = messageIndex > 0
                          ? rows[messageIndex - 1]
                          : null;
                      final next = messageIndex + 1 < rows.length
                          ? rows[messageIndex + 1]
                          : null;
                      final previousDay = previous == null
                          ? null
                          : _dateLabel(previous['created_at']);
                      final nextDay = next == null
                          ? null
                          : _dateLabel(next['created_at']);
                      final firstInGroup =
                          previous == null ||
                          valueInt(previous['sender']) != sender ||
                          previousDay != currentDay;
                      final lastInGroup =
                          next == null ||
                          valueInt(next['sender']) != sender ||
                          nextDay != currentDay;
                      final senderContact = portal.contacts
                          .where(
                            (item) =>
                                valueInt(item['user_id'] ?? item['id']) ==
                                sender,
                          )
                          .firstOrNull;
                      return _MessageBubble(
                        message: message,
                        mine: mine,
                        showDate:
                            messageIndex == 0 || currentDay != previousDay,
                        firstInGroup: firstInGroup,
                        lastInGroup: lastInGroup,
                        senderName: mine
                            ? portal.displayName
                            : valueText(senderContact ?? const {}, const [
                                'display_name',
                                'username',
                              ], fallback: 'Maktab vakili'),
                        senderContact: senderContact ?? const {},
                        readByOther: mine
                            ? _messageReadByOther(
                                thread: thread,
                                message: message,
                                selfUserId: self,
                              )
                            : false,
                        onAttachment: (key) => portal
                            .messageAttachmentDownloadUrl(widget.threadId, key),
                        onActions: () =>
                            _showMessageActions(message, mine: mine),
                        onSenderProfile: mine || senderContact == null
                            ? null
                            : () => _openChatContactProfile(
                                context,
                                portal,
                                senderContact,
                                thread: thread ?? const {},
                              ),
                        onReaction: (emoji, remove) =>
                            _setReaction(message, emoji, remove: remove),
                      );
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 0,
              color: colors.surface,
              shape: Border(top: BorderSide(color: colors.outlineVariant)),
              child: canWrite
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_sendingProgress.isNotEmpty) ...[
                            Row(
                              children: [
                                const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _sendingProgress,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                          ],
                          if (_sendError != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: colors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Yuborilmadi: $_sendError. Matn va fayllar saqlandi — qayta yuboring.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xatoni yopish',
                                    onPressed: () =>
                                        setState(() => _sendError = null),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                          ],
                          if (_pendingFiles.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  'TAYYOR FAYLLAR',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_pendingFiles.length}/10',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 50,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _pendingFiles.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 7),
                                itemBuilder: (context, index) =>
                                    _PendingFileChip(
                                      file: _pendingFiles[index],
                                      onRemove: _sending
                                          ? null
                                          : () => setState(() {
                                              final removed = _pendingFiles
                                                  .removeAt(index);
                                              _pendingContentTypes.remove(
                                                removed.name,
                                              );
                                            }),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 7),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_recording) ...[
                                IconButton(
                                  tooltip: 'Yozuvni bekor qilish',
                                  onPressed: () =>
                                      _finishVoiceRecording(discard: true),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: _VoiceRecordingBar(
                                    duration: _recordDuration,
                                    level: _recordLevel,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  tooltip: 'Ovozli xabarni yuborish',
                                  onPressed: () =>
                                      _finishVoiceRecording(discard: false),
                                  icon: const Icon(Icons.check_rounded),
                                ),
                              ] else ...[
                                IconButton.filledTonal(
                                  tooltip: 'Fayl biriktirish',
                                  onPressed: _sending || _preparingVoice
                                      ? null
                                      : _showAttachmentPicker,
                                  icon: const Icon(Icons.attach_file_rounded),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: colors.outlineVariant.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: 'Emoji tanlash',
                                          onPressed: _showEmojiPicker,
                                          icon: const Icon(
                                            Icons
                                                .sentiment_satisfied_alt_rounded,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            key: const ValueKey(
                                              'family-chat-composer',
                                            ),
                                            controller: _composer,
                                            onChanged: (_) => setState(() {}),
                                            minLines: 1,
                                            maxLines: 6,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            textInputAction:
                                                TextInputAction.newline,
                                            decoration: const InputDecoration(
                                              hintText: 'Xabar yozing…',
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_composer.text.trim().isEmpty &&
                                    _pendingFiles.isEmpty)
                                  IconButton.filled(
                                    tooltip: 'Ovozli xabar yozish',
                                    onPressed: _sending || _preparingVoice
                                        ? null
                                        : _startVoiceRecording,
                                    icon: _preparingVoice
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.mic_rounded),
                                  )
                                else
                                  IconButton.filled(
                                    tooltip: 'Xabar yuborish',
                                    onPressed: _sending || _preparingVoice
                                        ? null
                                        : _send,
                                    icon: _sending
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.send_rounded),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    )
                  : const _ReadOnlyChatBar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceRecordingBar extends StatelessWidget {
  const _VoiceRecordingBar({required this.duration, required this.level});

  final Duration duration;
  final double level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: colors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$minutes:$seconds',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var index = 0; index < 18; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 3,
                    height:
                        5 +
                        23 * (((index % 4) + 1) / 4) * (0.22 + level * 0.78),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ovoz yozilmoqda',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _AttachmentChoice extends StatelessWidget {
  const _AttachmentChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _ReadOnlyChatBar extends StatelessWidget {
  const _ReadOnlyChatBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu suhbat faqat o‘qish uchun ochilgan.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

bool _messageReadByOther({
  required Map<String, Object?>? thread,
  required Map<String, Object?> message,
  required int? selfUserId,
}) {
  final createdAt = DateTime.tryParse('${message['created_at'] ?? ''}');
  final participants = thread?['participants'];
  if (createdAt == null || participants is! List) return false;
  for (final raw in participants) {
    if (raw is! Map || valueInt(raw['user']) == selfUserId) continue;
    final lastReadAt = DateTime.tryParse('${raw['last_read_at'] ?? ''}');
    if (lastReadAt != null && !lastReadAt.isBefore(createdAt)) return true;
  }
  return false;
}

bool _isAudioAttachment(String key) {
  final normalized = key.toLowerCase().split('?').first;
  final isVoice = _attachmentDisplayName(normalized).startsWith('voice-');
  if (isVoice &&
      const [
        '.webm',
        '.mp4',
        '.m4a',
        '.ogg',
        '.opus',
        '.wav',
      ].any(normalized.endsWith)) {
    return true;
  }
  return const [
    '.mp3',
    '.m4a',
    '.aac',
    '.ogg',
    '.opus',
    '.wav',
  ].any(normalized.endsWith);
}

bool _isImageAttachment(String key) {
  final normalized = key.toLowerCase().split('?').first;
  return const [
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
  ].any(normalized.endsWith);
}

bool _isVideoAttachment(String key) {
  if (_isAudioAttachment(key)) return false;
  final normalized = key.toLowerCase().split('?').first;
  return const ['.mp4', '.mov', '.m4v', '.3gp'].any(normalized.endsWith) ||
      normalized.endsWith('.webm');
}

String _messageAttachmentKey(Object? value) {
  if (value is Map) {
    for (final key in const [
      'key',
      'attachment_key',
      'file_key',
      'storage_key',
      'path',
    ]) {
      final text = '${value[key] ?? ''}'.trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }
  final text = '${value ?? ''}'.trim();
  return text == 'null' ? '' : text;
}

String _audioTime(Duration value) {
  final total = value.inSeconds.clamp(0, 359999);
  final minutes = total ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _attachmentDisplayName(String key) {
  final name = Uri.decodeComponent(key.split('?').first.split('/').last);
  final withoutGrantPrefix = name.replaceFirst(
    RegExp(r'^[0-9a-f]{8,}-', caseSensitive: false),
    '',
  );
  return withoutGrantPrefix.isEmpty ? 'Biriktirilgan fayl' : withoutGrantPrefix;
}

String _voiceDurationLabel(String key) {
  final match = RegExp(r'voice-(\d+)s-').firstMatch(key.toLowerCase());
  final totalSeconds = int.tryParse(match?.group(1) ?? '');
  if (totalSeconds == null) return 'Ovozli xabar';
  final minutes = (totalSeconds ~/ 60).toString();
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return 'Ovozli xabar · $minutes:$seconds';
}

String _attachmentPreviewLabel(String key) {
  if (_isImageAttachment(key)) return 'Rasm';
  if (_isVideoAttachment(key)) return 'Video';
  if (_isAudioAttachment(key)) return 'Ovozli xabar';
  return 'Biriktirilgan fayl';
}

IconData _attachmentIcon(String key) {
  final normalized = key.toLowerCase().split('?').first;
  if (_isAudioAttachment(key)) return Icons.graphic_eq_rounded;
  if (_isVideoAttachment(key)) return Icons.play_circle_outline_rounded;
  if (normalized.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (_isImageAttachment(key)) {
    return Icons.image_outlined;
  }
  if (normalized.endsWith('.doc') || normalized.endsWith('.docx')) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

class _PendingFileChip extends StatelessWidget {
  const _PendingFileChip({required this.file, required this.onRemove});

  final PlatformFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.fromLTRB(9, 6, 4, 6),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isImageAttachment(file.name) && file.bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      file.bytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.image_outlined,
                        size: 19,
                        color: colors.primary,
                      ),
                    ),
                  )
                : Icon(
                    _attachmentIcon(file.name),
                    size: 19,
                    color: colors.primary,
                  ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _fileSize(file.size),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Olib tashlash',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmojiPickerContent extends StatelessWidget {
  const _EmojiPickerContent();

  static const _popular = [
    '👍',
    '❤️',
    '😊',
    '😂',
    '👏',
    '🎉',
    '🙏',
    '🔥',
    '✨',
    '💯',
    '✅',
    '🤝',
    '💪',
    '👌',
    '🙌',
    '🌟',
    '🤩',
    '🥳',
    '😍',
    '🤗',
    '💙',
    '💜',
    '🤍',
    '😁',
    '😉',
    '😎',
    '🤔',
    '😅',
    '🙂',
    '😇',
    '🫶',
    '👋',
  ];
  static const _faces = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '🥹',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😌',
    '😉',
    '🙃',
    '🙂',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😋',
    '😛',
    '🤪',
    '🤓',
    '🧐',
    '🤔',
    '🫡',
    '🤗',
    '🤭',
    '🫢',
    '😶',
    '😐',
    '😴',
    '🥱',
    '😔',
    '😕',
    '🫤',
    '😟',
    '🥺',
    '😢',
    '😭',
    '😤',
  ];
  static const _school = [
    '📚',
    '📖',
    '✏️',
    '📝',
    '🎓',
    '🏫',
    '🧠',
    '💡',
    '📌',
    '📎',
    '📐',
    '📏',
    '🔬',
    '🧪',
    '💻',
    '🎨',
    '🏆',
    '🥇',
    '⭐',
    '🚀',
    '⏰',
    '📅',
    '🔔',
    '📣',
    '✅',
    '❗',
    '❓',
    '➡️',
    '⬆️',
    '💬',
    '📨',
    '🎯',
  ];

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Emoji tanlang',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Yopish',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.schedule_rounded), text: 'Mashhur'),
            Tab(icon: Icon(Icons.mood_rounded), text: 'Kayfiyat'),
            Tab(icon: Icon(Icons.school_rounded), text: 'O‘qish'),
          ],
        ),
        const Expanded(
          child: TabBarView(
            children: [
              _EmojiGrid(emojis: _popular),
              _EmojiGrid(emojis: _faces),
              _EmojiGrid(emojis: _school),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(14),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 58,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
    ),
    itemCount: emojis.length,
    itemBuilder: (context, index) => InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => Navigator.pop(context, emojis[index]),
      child: Center(
        child: Text(emojis[index], style: const TextStyle(fontSize: 27)),
      ),
    ),
  );
}

class _MessageLoadingPane extends StatelessWidget {
  const _MessageLoadingPane();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Xabarlar yuklanmoqda…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MessageErrorPane extends StatelessWidget {
  const _MessageErrorPane({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 38,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Xabarlar ochilmadi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            error is String ? error as String : _errorText(error),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 15),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Qayta urinish'),
          ),
        ],
      ),
    ),
  );
}

class _MessageEmptyPane extends StatelessWidget {
  const _MessageEmptyPane({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.waving_hand_rounded,
              size: 38,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              searching ? 'Mos xabar topilmadi' : 'Suhbatni boshlang',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Boshqa so‘z bilan qidirib ko‘ring.'
                  : 'Savol yozing yoki vazifaga tegishli fayl yuboring.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBackgroundPainter extends CustomPainter {
  const _ChatBackgroundPainter({required this.color, required this.wallpaper});

  final Color color;
  final PortalChatWallpaper wallpaper;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke;
    final step = switch (wallpaper) {
      PortalChatWallpaper.whatsappPattern => 42.0,
      PortalChatWallpaper.space => 68.0,
      PortalChatWallpaper.sakura => 62.0,
      PortalChatWallpaper.abstract => 46.0,
      _ => 54.0,
    };
    for (var y = 18.0; y < size.height; y += step) {
      for (var x = 18.0; x < size.width; x += step) {
        final shiftedX = x + (((y / step).round().isEven) ? 0 : step / 2);
        final center = Offset(shiftedX, y);
        if (wallpaper == PortalChatWallpaper.mountains) {
          canvas.drawLine(center, center.translate(10, -12), line);
          canvas.drawLine(
            center.translate(10, -12),
            center.translate(20, 0),
            line,
          );
        } else if (wallpaper == PortalChatWallpaper.sakura) {
          canvas.drawCircle(center, 3.4, dot);
          canvas.drawCircle(center.translate(5, 2), 2.2, dot);
        } else {
          canvas.drawCircle(
            center,
            wallpaper == PortalChatWallpaper.space ? 1.2 : 2,
            dot,
          );
        }
        if (((x + y) / step).round().isEven &&
            wallpaper != PortalChatWallpaper.mountains &&
            wallpaper != PortalChatWallpaper.space) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(shiftedX + 12, y + 12), radius: 5),
            0.2,
            2.25,
            false,
            line,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBackgroundPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.wallpaper != wallpaper;
}

Color _chatWallpaperColor(PortalChatWallpaper wallpaper, ColorScheme colors) =>
    switch (wallpaper) {
      PortalChatWallpaper.telegramClouds => colors.surfaceContainerLow,
      PortalChatWallpaper.whatsappPattern => Color.alphaBlend(
        colors.primary.withValues(alpha: .06),
        colors.surfaceContainerLow,
      ),
      PortalChatWallpaper.mountains => Color.alphaBlend(
        colors.secondary.withValues(alpha: .09),
        colors.surfaceContainerLow,
      ),
      PortalChatWallpaper.aurora => Color.alphaBlend(
        colors.tertiary.withValues(alpha: .13),
        colors.surfaceContainerLow,
      ),
      PortalChatWallpaper.space =>
        colors.brightness == Brightness.dark
            ? const Color(0xFF111827)
            : const Color(0xFFE8EDF5),
      PortalChatWallpaper.ocean => Color.alphaBlend(
        const Color(0x1F168AAD),
        colors.surfaceContainerLow,
      ),
      PortalChatWallpaper.sakura => Color.alphaBlend(
        const Color(0x20D6608A),
        colors.surfaceContainerLow,
      ),
      PortalChatWallpaper.abstract => colors.surfaceContainer,
      PortalChatWallpaper.gradient => Color.alphaBlend(
        colors.primary.withValues(alpha: .1),
        colors.surfaceContainerLow,
      ),
      PortalChatWallpaper.blur => colors.surface.withValues(alpha: .92),
    };

typedef _MessageReaction = ({String emoji, int count, bool mine});

List<_MessageReaction> _messageReactions(
  Map<String, Object?> message,
  int? selfUserId,
) {
  final merged = <String, _MessageReaction>{};
  final myRaw = message['my_reactions'] ?? message['viewer_reactions'];
  final myReactions = myRaw is List
      ? myRaw.map((value) => '$value').toSet()
      : <String>{};

  void add(String emoji, int count, bool mine) {
    final value = emoji.trim();
    if (value.isEmpty || count < 1) return;
    final previous = merged[value];
    merged[value] = (
      emoji: value,
      count: previous == null ? count : previous.count + count,
      mine: mine || (previous?.mine ?? false) || myReactions.contains(value),
    );
  }

  bool isMine(Map raw, String emoji) {
    if (raw['reacted_by_me'] == true ||
        raw['mine'] == true ||
        raw['selected'] == true ||
        raw['has_reacted'] == true ||
        myReactions.contains(emoji)) {
      return true;
    }
    final users = raw['user_ids'] ?? raw['users'];
    return selfUserId != null &&
        users is List &&
        users.any(
          (value) => valueInt(value is Map ? value['id'] : value) == selfUserId,
        );
  }

  final raw = message['reactions'] ?? message['reaction_counts'];
  if (raw is Map) {
    for (final entry in raw.entries) {
      final emoji = '${entry.key}';
      final value = entry.value;
      if (value is num) {
        add(emoji, value.toInt(), myReactions.contains(emoji));
      } else if (value is Map) {
        add(
          valueText(Map<String, Object?>.from(value), const [
            'emoji',
            'reaction',
          ], fallback: emoji),
          valueInt(value['count'] ?? value['total']) ?? 1,
          isMine(value, emoji),
        );
      }
    }
  } else if (raw is List) {
    for (final value in raw) {
      if (value is String) {
        add(value, 1, myReactions.contains(value));
      } else if (value is Map) {
        final emoji = valueText(Map<String, Object?>.from(value), const [
          'emoji',
          'reaction',
          'code',
        ], fallback: '');
        add(
          emoji,
          valueInt(value['count'] ?? value['total']) ?? 1,
          isMine(value, emoji),
        );
      }
    }
  }
  return merged.values.toList(growable: false);
}

bool _messageHasOwnReaction(
  Map<String, Object?> message,
  String emoji,
  int? selfUserId,
) => _messageReactions(
  message,
  selfUserId,
).any((reaction) => reaction.emoji == emoji && reaction.mine);

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showDate,
    required this.firstInGroup,
    required this.lastInGroup,
    required this.senderName,
    required this.senderContact,
    required this.readByOther,
    required this.onAttachment,
    required this.onActions,
    required this.onReaction,
    this.onSenderProfile,
  });

  final Map<String, Object?> message;
  final bool mine;
  final bool showDate;
  final bool firstInGroup;
  final bool lastInGroup;
  final String senderName;
  final Map<String, Object?> senderContact;
  final bool readByOther;
  final Future<String> Function(String) onAttachment;
  final VoidCallback onActions;
  final void Function(String emoji, bool remove) onReaction;
  final VoidCallback? onSenderProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final portal = PortalScope.of(context);
    final chatStyle = portal.preferences.chatStyle;
    final body = valueText(message, const ['body'], fallback: '');
    final rawAttachments = message['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
              .map(_messageAttachmentKey)
              .where((item) => item.isNotEmpty)
              .toList()
        : const <String>[];
    final reactions = _messageReactions(message, portal.messagingSelfUserId);
    final bubbleColor = switch ((chatStyle, mine)) {
      (PortalChatStyle.whatsapp, true) => const Color(0xFF176B5B),
      (PortalChatStyle.modernDark, true) => const Color(0xFF315C89),
      (PortalChatStyle.modernDark, false) => const Color(0xFF252A31),
      (PortalChatStyle.glass, true) => colors.primary.withValues(alpha: .82),
      (PortalChatStyle.glass, false) => colors.surface.withValues(alpha: .78),
      (PortalChatStyle.minimal, true) => colors.primaryContainer,
      (PortalChatStyle.minimal, false) => colors.surface,
      (PortalChatStyle.neon, true) => const Color(0xFF263264),
      (PortalChatStyle.neon, false) => const Color(0xFF202333),
      (PortalChatStyle.nature, true) => const Color(0xFF486B45),
      (PortalChatStyle.gradient, true) => colors.primary,
      (_, true) => colors.primary,
      (_, false) => colors.surface,
    };
    final darkBubble =
        chatStyle == PortalChatStyle.modernDark ||
        chatStyle == PortalChatStyle.neon ||
        (mine && chatStyle != PortalChatStyle.minimal);
    final foreground = darkBubble
        ? Colors.white
        : mine && chatStyle == PortalChatStyle.minimal
        ? colors.onPrimaryContainer
        : colors.onSurface;
    final maxBubbleWidth = (MediaQuery.sizeOf(context).width * 0.76)
        .clamp(220.0, 560.0)
        .toDouble();
    return Column(
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.04),
                    blurRadius: 9,
                  ),
                ],
              ),
              child: Text(
                _dateLabel(message['created_at']),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                SizedBox.square(
                  dimension: 32,
                  child: lastInGroup
                      ? _ChatAvatar(
                          portal: portal,
                          contact: senderContact,
                          name: senderName,
                          radius: 16,
                          onTap: onSenderProfile,
                        )
                      : null,
                ),
                const SizedBox(width: 7),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxBubbleWidth - (mine ? 0 : 39),
                ),
                child: GestureDetector(
                  onLongPress: onActions,
                  child: Container(
                    margin: EdgeInsets.only(bottom: lastInGroup ? 9 : 2),
                    padding: const EdgeInsets.fromLTRB(13, 9, 9, 6),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      border: Border.all(
                        color: chatStyle == PortalChatStyle.neon
                            ? (mine
                                  ? const Color(0xFF7DD3FC)
                                  : const Color(0xFFA78BFA))
                            : mine
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          !mine && !firstInGroup ? 7 : 15,
                        ),
                        topRight: Radius.circular(
                          mine && !firstInGroup ? 7 : 15,
                        ),
                        bottomLeft: Radius.circular(
                          !mine && lastInGroup ? 4 : 15,
                        ),
                        bottomRight: Radius.circular(
                          mine && lastInGroup ? 4 : 15,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!mine && firstInGroup) ...[
                          Text(
                            senderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        if (body.isNotEmpty)
                          SelectableText(
                            body,
                            style: TextStyle(color: foreground, height: 1.35),
                          ),
                        for (final key in attachments) ...[
                          if (body.isNotEmpty || key != attachments.first)
                            const SizedBox(height: 8),
                          _MessageAttachmentTile(
                            keyName: key,
                            mine: mine,
                            urlResolver: () => onAttachment(key),
                          ),
                        ],
                        if (reactions.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final reaction in reactions)
                                InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () =>
                                      onReaction(reaction.emoji, reaction.mine),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: reaction.mine
                                          ? colors.primaryContainer
                                          : foreground.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: reaction.mine
                                            ? colors.primary
                                            : foreground.withValues(alpha: .16),
                                      ),
                                    ),
                                    child: Text(
                                      '${reaction.emoji} ${reaction.count}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: reaction.mine
                                                ? colors.onPrimaryContainer
                                                : foreground,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _timeOnly(message['created_at']),
                              style: Sf.monoStyle(
                                size: 8.5,
                                weight: FontWeight.w500,
                                color: foreground.withValues(alpha: 0.72),
                              ),
                            ),
                            if (mine) ...[
                              const SizedBox(width: 3),
                              Tooltip(
                                message: readByOther
                                    ? 'O‘qilgan'
                                    : 'Yuborilgan',
                                child: Icon(
                                  readByOther
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  size: 16,
                                  color: readByOther
                                      ? (mine
                                            ? colors.onPrimary
                                            : colors.primary)
                                      : foreground.withValues(alpha: 0.68),
                                ),
                              ),
                            ],
                            const SizedBox(width: 2),
                            Tooltip(
                              message: 'Xabar amallari',
                              child: InkWell(
                                key: ValueKey(
                                  'message-actions-${message['id']}',
                                ),
                                borderRadius: BorderRadius.circular(99),
                                onTap: onActions,
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.more_horiz_rounded,
                                    size: 16,
                                    color: foreground.withValues(alpha: 0.72),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageAttachmentTile extends StatefulWidget {
  const _MessageAttachmentTile({
    required this.keyName,
    required this.mine,
    required this.urlResolver,
  });

  final String keyName;
  final bool mine;
  final Future<String> Function() urlResolver;

  @override
  State<_MessageAttachmentTile> createState() => _MessageAttachmentTileState();
}

class _MessageAttachmentTileState extends State<_MessageAttachmentTile> {
  bool _opening = false;
  AudioPlayer? _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _audioUrl;
  String? _mediaUrl;
  Object? _mediaError;
  VideoPlayerController? _videoController;

  bool get _audio => _isAudioAttachment(widget.keyName);
  bool get _image => _isImageAttachment(widget.keyName);
  bool get _video => _isVideoAttachment(widget.keyName);

  @override
  void initState() {
    super.initState();
    if (_audio) {
      final player = _player = AudioPlayer();
      player.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _playerState = state);
      });
      player.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      player.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });
      player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _position = _duration;
            _playerState = PlayerState.completed;
          });
        }
      });
    }
    if (_image || _video) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_prepareMedia());
      });
    }
  }

  @override
  void dispose() {
    final player = _player;
    if (player != null) unawaited(player.dispose());
    final video = _videoController;
    if (video != null) unawaited(video.dispose());
    super.dispose();
  }

  Future<void> _prepareMedia() async {
    if (_opening || _mediaUrl != null) return;
    setState(() {
      _opening = true;
      _mediaError = null;
    });
    VideoPlayerController? initializingController;
    try {
      final url = await widget.urlResolver();
      VideoPlayerController? controller;
      if (_video) {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
        initializingController = controller;
        await controller.initialize();
        await controller.setLooping(false);
        controller.addListener(() {
          if (mounted) setState(() {});
        });
      }
      if (!mounted) {
        await controller?.dispose();
        return;
      }
      setState(() {
        _mediaUrl = url;
        _videoController = controller;
      });
    } on Object catch (error) {
      await initializingController?.dispose();
      if (mounted) setState(() => _mediaError = error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _retryMedia() async {
    final previous = _videoController;
    if (previous != null) await previous.dispose();
    if (!mounted) return;
    setState(() {
      _videoController = null;
      _mediaUrl = null;
      _mediaError = null;
    });
    await _prepareMedia();
  }

  Future<void> _openVideoFullscreen() async {
    final controller = _videoController;
    final url = _mediaUrl;
    if (controller == null || url == null || !mounted) return;
    await controller.pause();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _VideoViewerScreen(
          url: url,
          name: _attachmentDisplayName(widget.keyName),
        ),
      ),
    );
  }

  Future<void> _open() async {
    if (_opening) return;
    if (_image) {
      if (_mediaUrl == null) await _prepareMedia();
      if (mounted && _mediaUrl != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ImageViewerScreen(
              url: _mediaUrl!,
              name: _attachmentDisplayName(widget.keyName),
            ),
          ),
        );
      }
      return;
    }
    if (_video) {
      if (_videoController == null) await _prepareMedia();
      final controller = _videoController;
      if (controller == null) return;
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        if (controller.value.position >= controller.value.duration) {
          await controller.seekTo(Duration.zero);
        }
        await controller.play();
      }
      return;
    }
    if (_audio && _playerState == PlayerState.playing) {
      await _player?.pause();
      return;
    }
    if (_audio && _audioUrl != null && _playerState == PlayerState.paused) {
      await _player?.resume();
      return;
    }
    setState(() => _opening = true);
    try {
      final url = _audioUrl ?? await widget.urlResolver();
      if (_audio) {
        _audioUrl = url;
        if (_playerState == PlayerState.completed) {
          await _player?.seek(Duration.zero);
        }
        await _player?.play(UrlSource(url));
      } else if (mounted) {
        await _launch(context, url);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _seek(double milliseconds) async {
    await _player?.seek(Duration(milliseconds: milliseconds.round()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_image) return _buildImage(context, colors);
    if (_video) return _buildVideo(context, colors);
    final audio = _audio;
    final playing = _playerState == PlayerState.playing;
    final foreground = widget.mine ? colors.onPrimary : colors.onSurfaceVariant;
    return Material(
      color: widget.mine
          ? colors.surface.withValues(alpha: 0.18)
          : colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _opening ? null : _open,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: audio ? 230 : 190),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _opening
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : Icon(
                          audio
                              ? playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded
                              : _attachmentIcon(widget.keyName),
                          color: colors.onPrimary,
                          size: audio ? 25 : 21,
                        ),
                ),
                const SizedBox(width: 9),
                if (audio) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 11,
                            ),
                          ),
                          child: Slider(
                            value: _duration.inMilliseconds == 0
                                ? 0
                                : _position.inMilliseconds
                                      .clamp(0, _duration.inMilliseconds)
                                      .toDouble(),
                            max: _duration.inMilliseconds == 0
                                ? 1
                                : _duration.inMilliseconds.toDouble(),
                            onChanged: _duration.inMilliseconds == 0
                                ? null
                                : (value) => unawaited(_seek(value)),
                          ),
                        ),
                        Text(
                          _opening
                              ? 'Audio tayyorlanmoqda…'
                              : '${_audioTime(_position)} / ${_duration == Duration.zero ? _voiceDurationLabel(widget.keyName) : _audioTime(_duration)}${playing ? ' · ijro etilmoqda' : ''}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: foreground),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachmentDisplayName(widget.keyName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          _opening ? 'Yuklanmoqda…' : 'Ochish uchun bosing',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: foreground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(Icons.download_rounded, color: foreground, size: 19),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme colors) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: widget.mine
              ? colors.surface.withValues(alpha: .16)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _opening ? null : _open,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_mediaUrl case final url?)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, error, _) => _MediaLoadFailure(
                      label: 'Rasmni ochib bo‘lmadi',
                      onRetry: _retryMedia,
                    ),
                  )
                else if (_mediaError != null)
                  _MediaLoadFailure(
                    label: 'Rasmni ochib bo‘lmadi',
                    onRetry: _retryMedia,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                if (_mediaUrl != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                if (_opening)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: .16),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context, ColorScheme colors) {
    final controller = _videoController;
    final ready = controller?.value.isInitialized == true;
    final activeController = ready ? controller! : null;
    final playing = activeController?.value.isPlaying == true;
    final ratio =
        activeController != null && activeController.value.aspectRatio > 0
        ? activeController.value.aspectRatio.clamp(.75, 1.8).toDouble()
        : 16 / 9;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _opening ? null : _open,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (activeController != null)
                  VideoPlayer(activeController)
                else if (_mediaError != null)
                  _MediaLoadFailure(
                    label: 'Videoni ochib bo‘lmadi',
                    onRetry: _prepareMedia,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                if (activeController != null && !playing)
                  const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xA6000000),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                if (activeController != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      activeController,
                      allowScrubbing: true,
                      padding: const EdgeInsets.only(top: 18),
                      colors: VideoProgressColors(
                        playedColor: colors.primary,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                if (activeController != null)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: IconButton.filledTonal(
                      tooltip: 'To‘liq ekran',
                      onPressed: _openVideoFullscreen,
                      icon: const Icon(Icons.fullscreen_rounded, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaLoadFailure extends StatelessWidget {
  const _MediaLoadFailure({required this.label, required this.onRetry});

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, color: Colors.white70),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
          TextButton(onPressed: onRetry, child: const Text('Qayta urinish')),
        ],
      ),
    ),
  );
}

class _ImageViewerScreen extends StatelessWidget {
  const _ImageViewerScreen({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: .8,
        maxScale: 5,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
          errorBuilder: (_, _, _) => const _MediaLoadFailure(
            label: 'Rasmni ochib bo‘lmadi',
            onRetry: _noopMediaRetry,
          ),
        ),
      ),
    ),
  );
}

void _noopMediaRetry() {}

class _VideoViewerScreen extends StatefulWidget {
  const _VideoViewerScreen({required this.url, required this.name});

  final String url;
  final String name;

  @override
  State<_VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<_VideoViewerScreen> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    unawaited(
      _controller.initialize().then((_) => _controller.play()).catchError((
        Object error,
      ) {
        if (mounted) setState(() => _error = error);
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _error != null
            ? const _MediaLoadFailure(
                label: 'Videoni ochib bo‘lmadi',
                onRetry: _noopMediaRetry,
              )
            : !ready
            ? const CircularProgressIndicator(color: Colors.white)
            : GestureDetector(
                onTap: () => _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play(),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!_controller.value.isPlaying)
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.only(top: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// Retained temporarily for compatibility with older golden-test harnesses.
// ignore: unused_element
class _NotificationsPortalPage extends StatelessWidget {
  const _NotificationsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final unread = portal.unreadNotificationCount;
    return _PortalPage(
      title: portal.isParent ? 'Muhim xabarlar' : 'Bildirishnomalar',
      subtitle: portal.isParent
          ? 'Davomat, baho, to‘lov va markazdan kelgan oilaviy yangiliklar.'
          : 'Vazifa, dars, baho va akkaunt bo‘yicha shaxsiy yangiliklar.',
      section: PortalSection.notifications,
      trailing: unread == 0
          ? null
          : TextButton.icon(
              onPressed: () => _runAction(
                context,
                portal.markAllNotificationsRead,
                success: 'Barcha bildirishnomalar o‘qildi.',
              ),
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Hammasini o‘qish'),
            ),
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Yuklangan xabarlar',
              value: '${portal.notifications.length}',
              icon: Icons.notifications_outlined,
            ),
            _MetricCard(
              label: 'Yangi',
              value: '$unread',
              icon: Icons.mark_email_unread_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (portal.notifications.isEmpty)
          const _EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirishnoma yo‘q',
            message: 'Yangi voqealar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: portal.notifications,
            icon: Icons.notifications_outlined,
            title: (row) =>
                valueText(row, const ['title'], fallback: 'Bildirishnoma'),
            subtitle: (row) =>
                '${valueText(row, const ['body'], fallback: '')}\n${_dateLabel(row['created_at'], time: true)}',
            trailing: (row) => row['read_at'] == null
                ? const Badge(child: Icon(Icons.circle, size: 12))
                : const Icon(Icons.done_all_rounded),
            onTap: (row) {
              final id = valueInt(row['id']);
              if (id != null && row['read_at'] == null) {
                unawaited(
                  _runAction(
                    context,
                    () => portal.markNotificationRead(id),
                    success: 'O‘qildi.',
                  ),
                );
              }
              final destination = _notificationDestination(row, portal);
              if (destination != null) {
                _PortalNavigationScope.go(context, destination);
                return;
              }
              _showJsonDetail(
                context,
                title: valueText(row, const [
                  'title',
                ], fallback: 'Bildirishnoma'),
                fields: {
                  'Xabar': valueText(row, const ['body'], fallback: ''),
                  'Turi': valueText(row, const ['event_type']),
                  'Vaqt': _dateLabel(row['created_at'], time: true),
                },
              );
            },
          ),
        if (portal.notificationPreferences.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _PageSectionTitle(title: 'Bildirishnoma sozlamalari'),
          const SizedBox(height: 10),
          _NotificationPreferences(rows: portal.notificationPreferences),
        ],
      ],
    );
  }
}

PortalSection? _notificationDestination(
  Map<String, Object?> notification,
  PortalController portal,
) => _completeNotificationDestination(notification, portal);

class _NotificationPreferences extends StatefulWidget {
  const _NotificationPreferences({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  State<_NotificationPreferences> createState() =>
      _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<_NotificationPreferences> {
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
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < _rows.length; index++)
            SwitchListTile(
              value: _rows[index]['enabled'] == true,
              title: Text(_statusLabel('${_rows[index]['event_type']}')),
              subtitle: Text(switch ('${_rows[index]['channel']}'
                  .toLowerCase()) {
                'push' || 'in_app' => 'Ilova ichida',
                'email' => 'Elektron pochta',
                'sms' => 'SMS',
                _ => 'Bildirishnoma kanali',
              }),
              onChanged: _busy
                  ? null
                  : (value) async {
                      final messenger = ScaffoldMessenger.of(context);
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
                            SnackBar(content: Text(_errorText(error))),
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
}

bool _formCanSubmit(Map<String, Object?> form) {
  if (form['can_submit'] == false || '${form['status']}' != 'published') {
    return false;
  }
  final now = DateTime.now();
  final opens = DateTime.tryParse('${form['opens_at'] ?? ''}')?.toLocal();
  final closes = DateTime.tryParse('${form['closes_at'] ?? ''}')?.toLocal();
  if (opens != null && now.isBefore(opens)) return false;
  if (closes != null && now.isAfter(closes)) return false;
  if (form['allow_multiple'] != true &&
      (valueInt(form['self_submitted_count']) ?? 0) > 0) {
    return false;
  }
  return true;
}

String _formAvailability(Map<String, Object?> form) {
  final submitted = valueInt(form['self_submitted_count']) ?? 0;
  if (form['allow_multiple'] != true && submitted > 0) {
    return 'Javob qabul qilingan: $submitted marta';
  }
  final now = DateTime.now();
  final opens = DateTime.tryParse('${form['opens_at'] ?? ''}')?.toLocal();
  final closes = DateTime.tryParse('${form['closes_at'] ?? ''}')?.toLocal();
  if (opens != null && now.isBefore(opens)) {
    return '${_dateLabel(opens.toIso8601String(), time: true)} da ochiladi';
  }
  if (closes != null && now.isAfter(closes)) {
    return '${_dateLabel(closes.toIso8601String(), time: true)} da yopilgan';
  }
  if ('${form['status']}' != 'published') return 'Forma yopilgan';
  return closes == null
      ? 'Muddat belgilanmagan'
      : '${_dateLabel(closes.toIso8601String(), time: true)} gacha ochiq';
}

class _FormsPortalPage extends StatelessWidget {
  const _FormsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return _PortalPage(
      title: 'So‘rovnomalar',
      subtitle: 'Sizga yuborilgan ochiq shakllar va so‘rovlar.',
      section: PortalSection.forms,
      children: [
        if (portal.forms.isEmpty)
          const _EmptyState(
            icon: Icons.dynamic_form_outlined,
            title: 'Ochiq so‘rovnoma yo‘q',
            message: 'Markaz yangi so‘rov yuborganda shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: portal.forms,
            icon: Icons.assignment_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['description'], fallback: 'Tavsifsiz')} · ${valueRows(row['form_fields']).length} savol\n${_formAvailability(row)}',
            trailing: (row) => _StatusPill(
              _formCanSubmit(row) ? 'Ochiq' : 'Yopilgan',
              positive: _formCanSubmit(row),
              warning: !_formCanSubmit(row),
            ),
            onTap: (row) {
              if (!_formCanSubmit(row)) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(_formAvailability(row))));
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PortalScope(
                    controller: portal,
                    child: _FormFillScreen(form: row),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _FormFillScreen extends StatefulWidget {
  const _FormFillScreen({required this.form});

  final Map<String, Object?> form;

  @override
  State<_FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<_FormFillScreen> {
  final Map<int, Object?> _answers = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _busy = false;
  String? _error;

  List<Map<String, Object?>> get fields =>
      valueRows(widget.form['form_fields']);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(int id) =>
      _controllers.putIfAbsent(id, TextEditingController.new);

  TextEditingController? _controllerFor(Map<String, Object?> field) {
    final id = valueInt(field['id']);
    final type = '${field['field_type']}';
    if (id == null ||
        !const {'text', 'textarea', 'number', 'date'}.contains(type)) {
      return null;
    }
    return _controller(id);
  }

  Object? _answerFor(Map<String, Object?> field) {
    final id = valueInt(field['id']);
    return id == null ? null : _answers[id];
  }

  Future<void> _submit() async {
    for (final field in fields) {
      final id = valueInt(field['id']);
      if (id == null || field['required'] != true) continue;
      final value = _answers[id] ?? _controllers[id]?.text;
      if (value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty)) {
        setState(
          () => _error =
              '“${valueText(field, const ['label'])}” savoliga javob bering.',
        );
        return;
      }
    }
    final formId = valueInt(widget.form['id']);
    if (formId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = <Map<String, Object?>>[];
      for (final field in fields) {
        final id = valueInt(field['id']);
        if (id == null) continue;
        Object? value = _answers[id];
        if (_controllers[id] case final controller?) {
          value = switch ('${field['field_type']}') {
            'number' => num.tryParse(controller.text),
            _ => controller.text.trim(),
          };
        }
        if (value != null && value != '') {
          payload.add({'field': id, 'value': value});
        }
      }
      await PortalScope.read(context).submitForm(formId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Javob serverga yuborildi.')),
      );
      Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(valueText(widget.form, const ['title']))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                valueText(widget.form, const ['description'], fallback: ''),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (widget.form['is_anonymous'] == true) ...[
                const SizedBox(height: 12),
                const _InlineMessage(
                  text:
                      'Bu anonim so‘rovnoma. Ismingiz javobga biriktirilmaydi.',
                  error: false,
                ),
              ],
              const SizedBox(height: 12),
              _InlineMessage(
                text:
                    '${_formAvailability(widget.form)}\n${widget.form['allow_multiple'] == true ? 'Bir necha marta javob berish mumkin.' : 'Faqat bitta javob qabul qilinadi.'}',
                error: false,
              ),
              const SizedBox(height: 20),
              for (final field in fields) ...[
                _FormFieldEditor(
                  field: field,
                  controller: _controllerFor(field),
                  value: _answerFor(field),
                  onChanged: (value) {
                    final id = valueInt(field['id']);
                    if (id != null) setState(() => _answers[id] = value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_error case final error?)
                _InlineMessage(text: error, error: true),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_busy ? 'Yuborilmoqda…' : 'Javobni yuborish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormFieldEditor extends StatelessWidget {
  const _FormFieldEditor({
    required this.field,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final Map<String, Object?> field;
  final TextEditingController? controller;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = '${field['field_type']}';
    final label =
        '${valueText(field, const ['label'])}${field['required'] == true ? ' *' : ''}';
    final options = field['options'] is List
        ? List<Object?>.from(field['options']! as List)
        : const <Object?>[];
    if (type == 'boolean') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(valueText(field, const ['help_text'], fallback: '')),
        value: value == true,
        onChanged: onChanged,
      );
    }
    if (type == 'single_choice') {
      return DropdownButtonFormField<String>(
        initialValue: value?.toString(),
        decoration: InputDecoration(
          labelText: label,
          helperText: valueText(field, const ['help_text'], fallback: ''),
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: '$option', child: Text('$option')),
        ],
        onChanged: onChanged,
      );
    }
    if (type == 'multi_choice') {
      final selected = value is List
          ? (value as List).map((item) => '$item').toSet()
          : <String>{};
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            for (final option in options)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.contains('$option'),
                title: Text('$option'),
                onChanged: (checked) {
                  final next = <String>{...selected};
                  if (checked == true) {
                    next.add('$option');
                  } else {
                    next.remove('$option');
                  }
                  onChanged(next.toList());
                },
              ),
          ],
        ),
      );
    }
    if (type == 'rating') {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (var index = 1; index <= 5; index++)
                  ButtonSegment(value: index, label: Text('$index')),
              ],
              selected: value is int ? {value! as int} : const <int>{},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) =>
                  onChanged(selection.firstOrNull),
            ),
          ],
        ),
      );
    }
    if (type == 'date') {
      return TextField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final now = DateTime.now();
          final current = DateTime.tryParse(controller?.text ?? '');
          final selected = await showDatePicker(
            context: context,
            initialDate: current ?? now,
            firstDate: DateTime(now.year - 100),
            lastDate: DateTime(now.year + 10),
          );
          if (selected == null) return;
          final formatted =
              '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
          controller?.text = formatted;
          onChanged(formatted);
        },
        decoration: InputDecoration(
          labelText: label,
          helperText: valueText(field, const ['help_text'], fallback: ''),
          hintText: 'YYYY-MM-DD',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
      );
    }
    return TextField(
      controller: controller,
      minLines: type == 'textarea' ? 4 : 1,
      maxLines: type == 'textarea' ? 8 : 1,
      keyboardType: type == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: valueText(field, const ['help_text'], fallback: ''),
        alignLabelWithHint: type == 'textarea',
      ),
    );
  }
}

class _AchievementsPortalPage extends StatelessWidget {
  const _AchievementsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final studentId = portal.selectedStudentId;
    final rows = portal.isParent && studentId != null
        ? portal.achievementGrants
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.achievementGrants;
    final catalog = portal.achievementCatalog
        .where((item) => item['status'] == 'active')
        .toList();
    final earnedIds = rows
        .map((item) => valueInt(item['achievement']))
        .whereType<int>()
        .toSet();
    final completion = catalog.isEmpty
        ? 0.0
        : (earnedIds.length / catalog.length).clamp(0.0, 1.0);
    return _PortalPage(
      title: portal.isParent ? 'Farzand yutuqlari' : 'Mening yutuqlarim',
      subtitle: 'Markaz tasdiqlagan va o‘quvchiga berilgan yutuqlar devori.',
      section: PortalSection.achievements,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Qo‘lga kiritilgan',
              value: '${rows.length}',
              icon: Icons.emoji_events_outlined,
            ),
            _MetricCard(
              label: 'Mavjud yutuqlar',
              value: '${catalog.length}',
              icon: Icons.workspace_premium_outlined,
            ),
            _MetricCard(
              label: 'To‘plam bajarilishi',
              value: '${(completion * 100).round()}%',
              icon: Icons.donut_large_rounded,
            ),
          ],
        ),
        if (catalog.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Yutuqlar yo‘li',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text('${earnedIds.length} / ${catalog.length}'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completion,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 8),
                Text(
                  earnedIds.length == catalog.length
                      ? 'Barcha mavjud yutuqlar qo‘lga kiritilgan.'
                      : 'Qolgan yutuqlar va ularning shartlarini quyidagi katalogdan ko‘ring.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yutuqlar devori', count: rows.length),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Yutuq hali yo‘q',
            message: 'Yangi mukofot berilganda shu yerda ko‘rinadi.',
          )
        else
          _ResponsiveGrid(
            minWidth: 270,
            children: [
              for (final grant in rows)
                Builder(
                  builder: (context) {
                    final detail = valueMap(grant['achievement_detail']);
                    return _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                valueText(detail, const [
                                  'emoji',
                                ], fallback: '🏆'),
                                style: const TextStyle(fontSize: 36),
                              ),
                              const Spacer(),
                              _StatusPill(
                                valueText(detail, const ['status']),
                                positive: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            valueText(detail, const ['name']),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            valueText(detail, const [
                              'description',
                            ], fallback: 'Tavsif berilmagan.'),
                          ),
                          if (valueText(grant, const [
                            'note',
                          ], fallback: '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Izoh: ${grant['note']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Berilgan: ${_dateLabel(grant['granted_at'])}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed:
                                  valueInt(
                                        grant['achievement'] ?? detail['id'],
                                      ) ==
                                      null
                                  ? null
                                  : () async {
                                      final id = valueInt(
                                        grant['achievement'] ?? detail['id'],
                                      )!;
                                      final loaded = await _loadApiDetail(
                                        context,
                                        () => portal.loadAchievementDetail(id),
                                      );
                                      if (loaded == null || !context.mounted) {
                                        return;
                                      }
                                      await _showJsonDetail(
                                        context,
                                        title: valueText(loaded, const [
                                          'name',
                                        ]),
                                        fields: {
                                          'Tavsif': valueText(loaded, const [
                                            'description',
                                          ]),
                                          'Ko‘lam': valueText(loaded, const [
                                            'scope',
                                          ]),
                                          'Berilgan': _dateLabel(
                                            grant['granted_at'],
                                            time: true,
                                          ),
                                          'Izoh': valueText(grant, const [
                                            'note',
                                          ]),
                                        },
                                        rawDetail: loaded,
                                      );
                                    },
                              icon: const Icon(Icons.info_outline_rounded),
                              label: const Text('Tafsilotlar'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        if (catalog.isNotEmpty) ...[
          const SizedBox(height: 24),
          _PageSectionTitle(title: 'Yutuqlar katalogi', count: catalog.length),
          const SizedBox(height: 10),
          _ResponsiveGrid(
            minWidth: 260,
            children: [
              for (final achievement in catalog)
                Builder(
                  builder: (context) {
                    final id = valueInt(achievement['id']);
                    final earned = id != null && earnedIds.contains(id);
                    return _SectionCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            child: Text(
                              valueText(achievement, const [
                                'emoji',
                              ], fallback: '🏆'),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        valueText(achievement, const ['name']),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    _StatusPill(
                                      earned ? 'Olingan' : 'Kutilmoqda',
                                      positive: earned,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  valueText(
                                    achievement,
                                    const ['description'],
                                    fallback:
                                        'Shartlar markaz tomonidan belgilanadi.',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  achievement['scope'] == 'global'
                                      ? 'Markaz bo‘yicha'
                                      : 'Guruh yutug‘i',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: id == null
                                        ? null
                                        : () async {
                                            final loaded = await _loadApiDetail(
                                              context,
                                              () => portal
                                                  .loadAchievementDetail(id),
                                            );
                                            if (loaded == null ||
                                                !context.mounted) {
                                              return;
                                            }
                                            await _showJsonDetail(
                                              context,
                                              title: valueText(loaded, const [
                                                'name',
                                              ]),
                                              fields: {
                                                'Tavsif': valueText(
                                                  loaded,
                                                  const ['description'],
                                                ),
                                                'Ko‘lam': valueText(
                                                  loaded,
                                                  const ['scope'],
                                                ),
                                                'Holat': _statusLabel(
                                                  '${loaded['status']}',
                                                ),
                                                'Natija': earned
                                                    ? 'Qo‘lga kiritilgan'
                                                    : 'Kutilmoqda',
                                              },
                                              rawDetail: loaded,
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                    ),
                                    label: const Text('Tafsilotlar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DisciplinePortalPage extends StatelessWidget {
  const _DisciplinePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final studentId = portal.selectedStudentId;
    final penalties = portal.isParent && studentId != null
        ? portal.penalties
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.penalties;
    return _PortalPage(
      title: 'Qoidalar va intizom',
      subtitle:
          'Sizga tegishli ichki qoidalar, tasdiqlashlar va intizom yozuvlari.',
      section: PortalSection.discipline,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Qoidalar',
              value: '${portal.rules.length}',
              icon: Icons.menu_book_outlined,
            ),
            _MetricCard(
              label: 'Tasdiqlanmagan',
              value: '${portal.pendingRules.length}',
              icon: Icons.pending_actions_outlined,
            ),
            _MetricCard(
              label: 'Intizom yozuvlari',
              value: '${penalties.length}',
              icon: Icons.gavel_outlined,
            ),
          ],
        ),
        if (portal.pendingRules.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _InlineMessage(
            text:
                'Tasdiqlash kutilayotgan qoidalar bor. Har birini o‘qib, “Tanishdim” tugmasini bosing.',
            error: false,
          ),
          const SizedBox(height: 10),
          for (final rule in portal.pendingRules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      valueText(rule, const ['title']),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(valueText(rule, const ['body'])),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _withId(
                          rule['id'],
                          (id) => _runAction(
                            context,
                            () => portal.acknowledgeRule(id),
                            success: 'Qoida bilan tanishganingiz tasdiqlandi.',
                          ),
                        ),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Tanishdim'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
        _PageSectionTitle(
          title: 'Menga tegishli qoidalar',
          count: portal.rules.length,
        ),
        const SizedBox(height: 10),
        if (portal.rules.isEmpty)
          const _EmptyState(
            icon: Icons.rule_outlined,
            title: 'Qoida yo‘q',
            message: 'Faol qoidalar shu yerda ko‘rinadi.',
          )
        else
          ...portal.rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SectionCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(valueText(rule, const ['title'])),
                  subtitle: Text('Versiya ${rule['version']}'),
                  trailing: rule['acknowledged'] == true
                      ? const _StatusPill('Tasdiqlangan', positive: true)
                      : const _StatusPill('Tasdiqlash kerak', warning: true),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(valueText(rule, const ['body'])),
                    ),
                    if (rule['acknowledged'] != true) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _withId(
                            rule['id'],
                            (id) => _runAction(
                              context,
                              () => portal.acknowledgeRule(id),
                              success:
                                  'Qoida bilan tanishganingiz tasdiqlandi.',
                            ),
                          ),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Tanishdim'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Intizom yozuvlari', count: penalties.length),
        const SizedBox(height: 10),
        if (penalties.isEmpty)
          const _EmptyState(
            icon: Icons.verified_user_outlined,
            title: 'Intizom yozuvi yo‘q',
            message: 'Faol yoki bekor qilingan yozuvlar mavjud emas.',
          )
        else
          _SimpleRows(
            rows: penalties,
            icon: Icons.gavel_outlined,
            title: (row) => valueText(row, const ['reason']),
            subtitle: (row) =>
                '${row['points']} ball · ${_dateLabel(row['issued_at'], time: true)}',
            trailing: (row) => _StatusPill(
              valueText(row, const ['status']),
              positive: row['status'] == 'waived',
            ),
            onTap: (row) => _showJsonDetail(
              context,
              title: 'Intizom yozuvi #${row['id']}',
              fields: {
                'Sabab': valueText(row, const ['reason']),
                'Ball': '${row['points']}',
                'Holat': _statusLabel('${row['status']}'),
                'Berilgan': _dateLabel(row['issued_at'], time: true),
                if (row['waived_at'] != null)
                  'Bekor qilingan': _dateLabel(row['waived_at'], time: true),
                if (row['waive_reason'] != null)
                  'Bekor qilish sababi': '${row['waive_reason']}',
              },
            ),
          ),
      ],
    );
  }
}

class _PlacementPortalPage extends StatelessWidget {
  const _PlacementPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    if (!portal.isStudent) {
      return const _PortalPage(
        title: 'Daraja sinovi',
        subtitle: 'Bu bo‘lim o‘quvchining shaxsiy sinov kabinetidir.',
        section: PortalSection.placement,
        children: [
          _InlineMessage(
            text:
                'Ota-ona uchun daraja natijalari backendda xavfsiz guardian-scoping bilan ochilmaguncha bu sahifa so‘rov yubormaydi.',
            error: false,
          ),
        ],
      );
    }
    final attempts = portal.placementAttempts;
    final completed = attempts
        .where((item) => '${item['status'] ?? ''}' == 'graded')
        .length;
    final assigned = attempts.length - completed;
    final percentages = attempts
        .map(_placementPercent)
        .whereType<double>()
        .toList(growable: false);
    final best = percentages.isEmpty
        ? null
        : percentages.reduce((left, right) => left > right ? left : right);

    return _PortalPage(
      title: portal.isParent ? 'Farzand daraja sinovlari' : 'Daraja sinovim',
      subtitle: portal.isParent
          ? 'Markaz ota-ona kabinetiga ochgan daraja sinovlari va natijalari.'
          : 'Sizga biriktirilgan til darajasi sinovlari va ularning natijalari.',
      section: PortalSection.placement,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Jami sinov',
              value: '${attempts.length}',
              icon: Icons.assignment_outlined,
            ),
            _MetricCard(
              label: 'Topshirish kerak',
              value: '$assigned',
              icon: Icons.hourglass_top_rounded,
            ),
            _MetricCard(
              label: 'Eng yaxshi natija',
              value: best == null ? '—' : '${best.toStringAsFixed(0)}%',
              icon: Icons.workspace_premium_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _InlineMessage(
          text: portal.isParent
              ? 'Maxfiylik sabab faqat backend aynan shu ota-ona akkauntiga ruxsat bergan sinovlar ko‘rsatiladi.'
              : 'Savollar faqat sizga biriktirilgan sinov ichidan olinadi. To‘g‘ri javob kalitlari ilovaga yuklanmaydi.',
          error: false,
        ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Sinovlar tarixi', count: attempts.length),
        const SizedBox(height: 10),
        if (attempts.isEmpty)
          _EmptyState(
            icon: Icons.psychology_alt_outlined,
            title: portal.isParent
                ? 'Ko‘rinadigan sinov yo‘q'
                : 'Sinov biriktirilmagan',
            message: portal.isParent
                ? 'Markaz oilaviy ko‘rishga ruxsat bergan natijalar shu yerda paydo bo‘ladi.'
                : 'Markaz sizga daraja sinovini biriktirganda u shu yerda paydo bo‘ladi.',
          )
        else
          _SimpleRows(
            rows: attempts,
            icon: Icons.psychology_alt_outlined,
            title: (row) =>
                valueText(row, const ['test_title'], fallback: 'Daraja sinovi'),
            subtitle: (row) {
              final percent = _placementPercent(row);
              final level = valueText(row, const ['level'], fallback: '—');
              final date = row['submitted_at'] ?? row['expires_at'];
              return [
                if (percent != null) '${percent.toStringAsFixed(0)}%',
                if (level != '—') 'Daraja: $level',
                if (date != null)
                  '${row['submitted_at'] != null ? 'Topshirildi' : 'Muddat'}: ${_dateLabel(date, time: true)}',
              ].join(' · ');
            },
            trailing: (row) => _StatusPill(
              _placementStatus('${row['status'] ?? ''}'),
              positive: row['status'] == 'graded',
              warning: row['status'] == 'assigned',
            ),
            onTap: (row) => _openPlacementAttempt(context, portal, row),
          ),
      ],
    );
  }

  Future<void> _openPlacementAttempt(
    BuildContext context,
    PortalController portal,
    Map<String, Object?> row,
  ) async {
    final id = valueInt(row['id']);
    if (id == null) return;
    final loaded = await _loadApiDetail(
      context,
      () => portal.loadPlacementAttemptDetail(id),
    );
    if (loaded == null || !context.mounted) return;
    final detail = {...row, ...loaded};
    if ('${detail['status'] ?? ''}'.toLowerCase() == 'assigned' &&
        portal.isStudent) {
      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PortalScope(
            controller: portal,
            child: _PlacementAttemptScreen(attempt: detail),
          ),
        ),
      );
      if (submitted == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daraja sinovi topshirildi.')),
        );
      }
      return;
    }
    final percent = _placementPercent(detail);
    await _showJsonDetail(
      context,
      title: valueText(detail, const [
        'test_title',
      ], fallback: 'Daraja sinovi #$id'),
      fields: {
        'Holat': _placementStatus('${detail['status'] ?? ''}'),
        'Natija': percent == null
            ? 'Hali baholanmagan'
            : '${detail['score'] ?? 0} / ${detail['max_score'] ?? 0} (${percent.toStringAsFixed(0)}%)',
        'Aniqlangan daraja': valueText(detail, const [
          'level',
        ], fallback: 'Hali aniqlanmagan'),
        'Biriktirilgan': _dateLabel(detail['created_at'], time: true),
        'Oxirgi muddat': _dateLabel(detail['expires_at'], time: true),
        'Topshirilgan': _dateLabel(detail['submitted_at'], time: true),
        'Savollar va javoblar': _placementQuestionsLabel(detail),
      },
    );
  }
}

class _PlacementAttemptScreen extends StatefulWidget {
  const _PlacementAttemptScreen({required this.attempt});

  final Map<String, Object?> attempt;

  @override
  State<_PlacementAttemptScreen> createState() =>
      _PlacementAttemptScreenState();
}

class _PlacementAttemptScreenState extends State<_PlacementAttemptScreen> {
  final Map<int, Object?> _answers = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _busy = false;
  String? _error;

  List<Map<String, Object?>> get _questions =>
      valueRows(widget.attempt['questions']);

  DateTime? get _deadline =>
      DateTime.tryParse('${widget.attempt['expires_at'] ?? ''}')?.toLocal();

  bool get _expired => _deadline?.isBefore(DateTime.now()) ?? false;

  @override
  void initState() {
    super.initState();
    for (final answer in valueRows(widget.attempt['answers'])) {
      final questionId = valueInt(answer['question']);
      if (questionId != null) _answers[questionId] = answer['response'];
    }
    for (final question in _questions) {
      final id = valueInt(question['id']);
      if (id == null || _placementUsesChoiceControl(question)) continue;
      final current = _answers[id];
      _controllers[id] = TextEditingController(
        text: current is String ? current : '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Object? _answerFor(Map<String, Object?> question) {
    final id = valueInt(question['id']);
    if (id == null) return null;
    final controller = _controllers[id];
    return controller == null ? _answers[id] : controller.text.trim();
  }

  bool _isAnswered(Map<String, Object?> question) {
    final answer = _answerFor(question);
    return switch (answer) {
      String value => value.trim().isNotEmpty,
      List value => value.isNotEmpty,
      bool _ => true,
      _ => false,
    };
  }

  int get _answeredCount => _questions.where(_isAnswered).length;

  Future<void> _submit() async {
    if (_busy) return;
    if (_questions.isEmpty) {
      setState(() => _error = 'Sinov savollari serverdan qaytmadi.');
      return;
    }
    if (_expired) {
      setState(() => _error = 'Sinov uchun ajratilgan vaqt tugagan.');
      return;
    }
    final missing = _questions.where((question) => !_isAnswered(question));
    if (missing.isNotEmpty) {
      setState(
        () => _error =
            'Barcha savollarga javob bering. ${missing.length} ta javob qolgan.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Javoblarni yuboraymi?'),
        content: const Text(
          'Yuborilgandan keyin javoblarni o‘zgartirib bo‘lmaydi. Natija serverda hisoblanadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tekshirib chiqish'),
          ),
          FilledButton(
            key: const ValueKey('placement-confirm-submit'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final attemptId = valueInt(widget.attempt['id']);
    if (attemptId == null) {
      setState(() => _error = 'Sinov identifikatori topilmadi.');
      return;
    }
    final payload = <Map<String, Object?>>[
      for (final question in _questions)
        if (valueInt(question['id']) case final questionId?)
          {'question': questionId, 'response': _answerFor(question)},
    ];
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await PortalScope.read(
        context,
      ).submitPlacementAttempt(attemptId, payload);
      if (!mounted) return;
      final percent = _placementPercent(result);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.task_alt_rounded, size: 38),
          title: const Text('Sinov topshirildi'),
          content: Text(
            percent == null
                ? 'Javoblar qabul qilindi. Yozma yoki og‘zaki qismlar ustoz tomonidan tekshiriladi.'
                : 'Natija: ${percent.toStringAsFixed(0)}%\nDaraja: ${valueText(result, const ['level'], fallback: 'aniqlanmoqda')}',
          ),
          actions: [
            FilledButton(
              key: const ValueKey('placement-result-close'),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Natijani ko‘rish'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = valueText(widget.attempt, const [
      'test_title',
    ], fallback: 'Daraja sinovi');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_answeredCount / ${_questions.length} ta savolga javob berildi',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _questions.isEmpty
                            ? 0
                            : _answeredCount / _questions.length,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      if (_deadline case final deadline?) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              _expired
                                  ? Icons.timer_off_outlined
                                  : Icons.timer_outlined,
                              size: 18,
                              color: _expired ? colors.error : colors.primary,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                '${_expired ? 'Vaqt tugagan' : 'Oxirgi muddat'}: ${_dateLabel(deadline.toIso8601String(), time: true)}',
                                style: TextStyle(
                                  color: _expired
                                      ? colors.error
                                      : colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _InlineMessage(
                  text:
                      'Javob kalitlari bu ekranga yuklanmaydi. Yuborishdan oldin barcha javoblarni tekshiring.',
                  error: false,
                ),
                const SizedBox(height: 18),
                if (_questions.isEmpty)
                  const _EmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'Savollar topilmadi',
                    message: 'Markaz sinovni qayta biriktirishi kerak.',
                  )
                else
                  for (final (index, question) in _questions.indexed) ...[
                    _PlacementQuestionCard(
                      index: index,
                      question: question,
                      answer: _answerFor(question),
                      controller: _controllers[valueInt(question['id'])],
                      enabled: !_busy && !_expired,
                      onChanged: (value) {
                        final id = valueInt(question['id']);
                        if (id == null) return;
                        setState(() {
                          _answers[id] = value;
                          _error = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                if (_error case final error?) ...[
                  const SizedBox(height: 4),
                  _InlineMessage(text: error, error: true),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const ValueKey('placement-submit'),
                  onPressed: _busy || _expired || _questions.isEmpty
                      ? null
                      : _submit,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_busy ? 'Yuborilmoqda…' : 'Sinovni topshirish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementQuestionCard extends StatelessWidget {
  const _PlacementQuestionCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final int index;
  final Map<String, Object?> question;
  final Object? answer;
  final TextEditingController? controller;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final id = valueInt(question['id']);
    final type = '${question['question_type'] ?? ''}'.trim().toLowerCase();
    final options = _placementOptionValues(question['options']);
    final selected = answer is List
        ? (answer! as List).map((item) => '$item').toSet()
        : <String>{};
    return _SectionCard(
      child: Column(
        key: id == null ? null : ValueKey('placement-question-$id'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPill('${index + 1}-SAVOL'),
              _StatusPill('${question['points'] ?? 1} BALL', positive: true),
              _StatusPill(_placementQuestionTypeLabel(type)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valueText(question, const ['prompt'], fallback: 'Savol'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _PlacementQuestionMedia(media: valueMap(question['media'])),
          const SizedBox(height: 14),
          if (type == 'single_choice')
            if (options.isEmpty)
              const _InlineMessage(
                text: 'Javob variantlari serverdan qaytmadi.',
                error: true,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (optionIndex, option) in options.indexed)
                    ChoiceChip(
                      key: id == null
                          ? null
                          : ValueKey('placement-option-$id-$optionIndex'),
                      label: Text(option),
                      selected: answer == option,
                      onSelected: enabled ? (_) => onChanged(option) : null,
                    ),
                ],
              )
          else if (type == 'multiple_choice')
            if (options.isEmpty)
              const _InlineMessage(
                text: 'Javob variantlari serverdan qaytmadi.',
                error: true,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (optionIndex, option) in options.indexed)
                    FilterChip(
                      key: id == null
                          ? null
                          : ValueKey('placement-option-$id-$optionIndex'),
                      label: Text(option),
                      selected: selected.contains(option),
                      onSelected: enabled
                          ? (checked) {
                              final next = <String>{...selected};
                              checked ? next.add(option) : next.remove(option);
                              onChanged(next.toList(growable: false));
                            }
                          : null,
                    ),
                ],
              )
          else if (type == 'true_false')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: id == null
                      ? null
                      : ValueKey('placement-boolean-$id-true'),
                  label: const Text('To‘g‘ri'),
                  selected: answer == true,
                  onSelected: enabled ? (_) => onChanged(true) : null,
                ),
                ChoiceChip(
                  key: id == null
                      ? null
                      : ValueKey('placement-boolean-$id-false'),
                  label: const Text('Noto‘g‘ri'),
                  selected: answer == false,
                  onSelected: enabled ? (_) => onChanged(false) : null,
                ),
              ],
            )
          else
            TextField(
              key: id == null ? null : ValueKey('placement-text-$id'),
              controller: controller,
              enabled: enabled,
              minLines: type == 'short_answer' ? 1 : 4,
              maxLines: type == 'short_answer' ? 2 : 10,
              maxLength: type == 'short_answer' ? 500 : 10000,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: _placementAnswerLabel(type),
                alignLabelWithHint: true,
                helperText: type == 'speaking'
                    ? 'Backend og‘zaki javob uchun audio kalit yoki havolani qabul qiladi.'
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlacementQuestionMedia extends StatelessWidget {
  const _PlacementQuestionMedia({required this.media});

  final Map<String, Object?> media;

  @override
  Widget build(BuildContext context) {
    final text = _firstAllowedPlacementMediaText(media);
    final links = _allowedPlacementMediaLinks(media);
    if (text == null && links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(text),
            ),
          if (links.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final link in links)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      link.$2,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: Icon(
                      link.$1 == 'Audio' ? Icons.headphones : Icons.open_in_new,
                    ),
                    label: Text('${link.$1}ni ochish'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

bool _placementUsesChoiceControl(Map<String, Object?> question) => const {
  'single_choice',
  'multiple_choice',
  'true_false',
}.contains('${question['question_type'] ?? ''}'.trim().toLowerCase());

String _placementQuestionTypeLabel(String type) => switch (type) {
  'single_choice' => 'BITTA VARIANT',
  'multiple_choice' => 'BIR NECHA VARIANT',
  'short_answer' => 'QISQA JAVOB',
  'true_false' => 'TO‘G‘RI / NOTO‘G‘RI',
  'writing' => 'YOZMA JAVOB',
  'reading' => 'O‘QIB TUSHUNISH',
  'listening' => 'TINGLAB TUSHUNISH',
  'speaking' => 'OG‘ZAKI JAVOB',
  _ => 'JAVOB',
};

String _placementAnswerLabel(String type) => switch (type) {
  'short_answer' => 'Qisqa javob',
  'reading' => 'Matn bo‘yicha javob',
  'listening' => 'Eshitganingiz bo‘yicha javob',
  'speaking' => 'Audio javob kaliti yoki havolasi',
  _ => 'Javobingiz',
};

List<String> _placementOptionValues(Object? raw) {
  if (raw is! Iterable) return const [];
  final values = <String>[];
  for (final item in raw) {
    final value = _allowedPlacementOptionValue(item);
    if (value != null && !values.contains(value)) values.add(value);
  }
  return values;
}

String? _allowedPlacementOptionValue(Object? raw) {
  if (raw is String) {
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }
  if (raw is num || raw is bool) return '$raw';
  if (raw is Map) {
    for (final key in const ['label', 'text', 'value', 'title', 'name']) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num || value is bool) return '$value';
    }
  }
  return null;
}

String? _firstAllowedPlacementMediaText(Map<String, Object?> media) {
  for (final key in const [
    'passage',
    'text',
    'instruction',
    'instructions',
    'transcript',
  ]) {
    final value = media[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

List<(String, Uri)> _allowedPlacementMediaLinks(Map<String, Object?> media) {
  final links = <(String, Uri)>[];
  for (final entry in const {
    'audio_url': 'Audio',
    'image_url': 'Rasm',
    'file_url': 'Fayl',
  }.entries) {
    final raw = media[entry.key];
    if (raw is! String) continue;
    final uri = Uri.tryParse(raw.trim());
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      links.add((entry.value, uri));
    }
  }
  return links;
}

double? _placementPercent(Map<String, Object?> row) {
  final score = valueInt(row['score']);
  final maxScore = valueInt(row['max_score']);
  if (score == null || maxScore == null || maxScore <= 0) return null;
  return (score / maxScore * 100).clamp(0, 100).toDouble();
}

String _placementStatus(String raw) => switch (raw.trim().toLowerCase()) {
  'assigned' => 'TOPSHIRISH KERAK',
  'graded' => 'BAHOLANGAN',
  _ => raw.trim().isEmpty ? 'NOMA’LUM' : raw.trim().toUpperCase(),
};

String _placementQuestionsLabel(Map<String, Object?> attempt) {
  final questions = valueRows(attempt['questions']);
  final answers = valueRows(attempt['answers']);
  if (questions.isEmpty) return 'Savol tafsilotlari berilmagan.';
  return [
    for (var index = 0; index < questions.length; index++)
      () {
        final question = questions[index];
        final questionId = valueInt(question['id']);
        final answer = answers
            .where((item) => valueInt(item['question']) == questionId)
            .firstOrNull;
        final optionLabel = _placementOptionValues(
          question['options'],
        ).join(', ');
        return '${index + 1}. ${valueText(question, const ['prompt'], fallback: 'Savol')}\n'
            '${optionLabel.isEmpty ? '' : 'Variantlar: $optionLabel\n'}'
            'Javob: ${answer == null ? 'Topshirilmagan' : _readable(answer['response'])}';
      }(),
  ].join('\n\n');
}

class _FinancePortalPage extends StatelessWidget {
  const _FinancePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final invoices = valueRows(portal.outstanding['invoices']);
    final overdue = invoices
        .where((item) => item['status'] == 'overdue')
        .length;
    return _PortalPage(
      title: 'To‘lov holati',
      subtitle:
          'Farzandingiz bo‘yicha hisob-fakturalar va qolgan qarzdorlik. Bu kabinet pul yechmaydi.',
      section: PortalSection.finance,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Jami qarzdorlik',
              value: _money(context, portal.outstanding['outstanding_uzs']),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _MetricCard(
              label: 'Hisob-fakturalar',
              value: '${invoices.length}',
              icon: Icons.receipt_long_outlined,
            ),
            _MetricCard(
              label: 'Muddati o‘tgan',
              value: '$overdue',
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _InlineMessage(
          text:
              'Bu kabinet balansni kuzatish uchun mo‘ljallangan. To‘lovni amalga oshirish yoki kvitansiyani aniqlashtirish uchun markaz bilan bog‘laning.',
          error: false,
        ),
        const SizedBox(height: 24),
        if (invoices.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Hisob-faktura yo‘q',
            message: 'Yangi hisob chiqarilganda shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: invoices,
            icon: Icons.receipt_long_outlined,
            title: (row) => valueText(row, const [
              'fee_schedule_name',
              'number',
            ], fallback: 'Hisob-faktura'),
            subtitle: (row) =>
                '${valueText(row, const ['number'])} · muddat ${_dateLabel(row['due_date'])} · ${_money(context, row['total_uzs'])}',
            trailing: (row) => _StatusPill(
              valueText(row, const ['status']),
              positive: row['status'] == 'paid',
              warning: row['status'] == 'overdue',
            ),
            onTap: (row) => _showJsonDetail(
              context,
              title: valueText(row, const [
                'number',
              ], fallback: 'Hisob-faktura'),
              fields: {
                'Xizmat': valueText(row, const [
                  'fee_schedule_name',
                ], fallback: 'Ta’lim xizmati'),
                'Davr': valueText(row, const ['period']),
                'Summa': _money(context, row['total_uzs']),
                'Valyuta': valueText(row, const ['currency']),
                'USD qiymati': _money(
                  context,
                  row['total_usd'],
                  sourceCurrency: PortalCurrency.usd,
                ),
                'Valyuta kursi': valueText(row, const ['fx_rate_usd']),
                'Guruh': valueText(row, const ['cohort_name']),
                'Holat': _statusLabel('${row['status']}'),
                'Chiqarilgan': _dateLabel(row['issue_date']),
                'Muddat': _dateLabel(row['due_date']),
                'Qatorlar': _invoiceLinesLabel(context, row['lines']),
                'Ajratilgan to‘lovlar': _readable(row['allocations']),
              },
            ),
          ),
      ],
    );
  }
}

class _CardsPortalPage extends StatelessWidget {
  const _CardsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final walletData = valueMap(portal.wallet['wallet']);
    final transactions = valueRows(portal.wallet['transactions']);
    String typeName(Object? id) {
      final type = portal.cardTypes
          .where((item) => valueInt(item['id']) == valueInt(id))
          .firstOrNull;
      return valueText(type ?? const {}, const [
        'name',
      ], fallback: 'O‘quvchi kartasi');
    }

    return _PortalPage(
      title: 'Karta va hamyon',
      subtitle:
          'O‘zingizga tegishli karta va markaz ichidagi saqlangan mablag‘.',
      section: PortalSection.cards,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Hamyon balansi',
              value: _money(context, walletData['balance_uzs']),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _MetricCard(
              label: 'Faol kartalar',
              value:
                  '${portal.cards.where((item) => item['is_active'] == true).length}',
              icon: Icons.credit_card_outlined,
            ),
            _MetricCard(
              label: 'Operatsiyalar',
              value: '${transactions.length}',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PageSectionTitle(
          title: 'Mening kartalarim',
          count: portal.cards.length,
        ),
        const SizedBox(height: 10),
        if (portal.cards.isEmpty)
          const _EmptyState(
            icon: Icons.credit_card_off_outlined,
            title: 'Karta berilmagan',
            message: 'Markaz karta chiqarganda shu yerda ko‘rinadi.',
          )
        else
          _ResponsiveGrid(
            minWidth: 280,
            children: [
              for (final card in portal.cards)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: valueInt(card['id']) == null
                      ? null
                      : () async {
                          final id = valueInt(card['id'])!;
                          final loaded = await _loadApiDetail(
                            context,
                            () => portal.loadCardDetail(id),
                          );
                          if (loaded == null || !context.mounted) return;
                          final detail = {...card, ...loaded};
                          await _showJsonDetail(
                            context,
                            title: typeName(detail['card_type']),
                            fields: {
                              'Kod': valueText(detail, const ['code']),
                              'Holat': detail['is_active'] == true
                                  ? 'Faol'
                                  : 'Yopilgan',
                              'Berilgan': _dateLabel(
                                detail['issued_at'],
                                time: true,
                              ),
                              'Bekor qilingan': _dateLabel(
                                detail['revoked_at'],
                                time: true,
                              ),
                              'Bekor qilish sababi': valueText(detail, const [
                                'revoke_reason',
                              ]),
                            },
                            rawDetail: loaded,
                          );
                        },
                  child: Container(
                    height: 174,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                              ),
                              const Spacer(),
                              Text(
                                card['is_active'] == true ? 'FAOL' : 'YOPILGAN',
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            typeName(card['card_type']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            valueText(card, const ['code']),
                            style: const TextStyle(
                              fontFamily: Sf.mono,
                              fontSize: 20,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Berilgan: ${_dateLabel(card['issued_at'])}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Hamyon tarixi', count: transactions.length),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Operatsiya yo‘q',
            message: 'Hamyon harakatlari shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: transactions,
            icon: Icons.payments_outlined,
            title: (row) =>
                '${row['kind'] == 'credit' || row['kind'] == 'topup' ? '+' : '−'} ${_money(context, row['amount_uzs'])}',
            subtitle: (row) =>
                '${valueText(row, const ['note'], fallback: 'Hamyon operatsiyasi')} · ${_dateLabel(row['created_at'], time: true)}',
            trailing: (row) => Text(
              _money(context, row['balance_after_uzs']),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }
}

class _AccountPortalPage extends StatelessWidget {
  const _AccountPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return _PortalPage(
      title: _familyCopy(
        context,
        uz: 'Sozlamalar',
        ru: 'Настройки',
        en: 'Settings',
      ),
      subtitle: _familyCopy(
        context,
        uz: 'Akkaunt, ilova ko‘rinishi, xavfsizlik va maxfiylik.',
        ru: 'Аккаунт, внешний вид, безопасность и конфиденциальность.',
        en: 'Account, appearance, security, and privacy.',
      ),
      section: PortalSection.account,
      children: [
        _SectionCard(child: _AccountIdentityHeader(portal: portal)),
        const SizedBox(height: 18),
        _AccountHubTile(
          icon: Icons.person_outline_rounded,
          color: Sf.primary,
          title: _familyCopy(
            context,
            uz: 'Shaxsiy ma’lumotlar',
            ru: 'Личные данные',
            en: 'Personal information',
          ),
          subtitle: _familyCopy(
            context,
            uz: 'Profilni ko‘rish va tahrirlash',
            ru: 'Просмотр и редактирование профиля',
            en: 'View and edit your profile',
          ),
          onTap: () => _openAccountScreen(
            context,
            portal,
            const _PersonalInformationScreen(),
          ),
        ),
        const SizedBox(height: 9),
        _AccountHubTile(
          icon: Icons.palette_outlined,
          color: Sf.accent,
          title: _familyCopy(
            context,
            uz: 'Ilova ko‘rinishi va til',
            ru: 'Внешний вид и язык',
            en: 'Appearance and language',
          ),
          subtitle: _familyCopy(
            context,
            uz: 'Til, mavzu, ranglar va qulaylik',
            ru: 'Язык, тема, цвета и доступность',
            en: 'Language, theme, colors, and accessibility',
          ),
          onTap: () => _openAccountScreen(
            context,
            portal,
            const _AppearanceSettingsScreen(),
          ),
        ),
        const SizedBox(height: 9),
        _AccountHubTile(
          icon: Icons.notifications_none_rounded,
          color: Sf.warn,
          title: _familyCopy(
            context,
            uz: 'Bildirishnomalar',
            ru: 'Уведомления',
            en: 'Notifications',
          ),
          subtitle: _familyCopy(
            context,
            uz: 'Xabar kanallari va ogohlantirishlar',
            ru: 'Каналы сообщений и оповещения',
            en: 'Message channels and alerts',
          ),
          onTap: () =>
              _PortalNavigationScope.go(context, PortalSection.notifications),
        ),
        const SizedBox(height: 9),
        _AccountHubTile(
          icon: Icons.shield_outlined,
          color: Sf.success,
          title: _familyCopy(
            context,
            uz: 'Xavfsizlik va sessiyalar',
            ru: 'Безопасность и сеансы',
            en: 'Security and sessions',
          ),
          subtitle: _familyCopy(
            context,
            uz: 'Parol va faol qurilmalar',
            ru: 'Пароль и активные устройства',
            en: 'Password and active devices',
          ),
          onTap: () => _openAccountScreen(
            context,
            portal,
            const _SecuritySessionsScreen(),
          ),
        ),
        const SizedBox(height: 9),
        _AccountHubTile(
          icon: Icons.privacy_tip_outlined,
          color: Theme.of(context).colorScheme.secondary,
          title: _familyCopy(
            context,
            uz: 'Maxfiylik siyosati',
            ru: 'Политика конфиденциальности',
            en: 'Privacy policy',
          ),
          subtitle: _familyCopy(
            context,
            uz: 'Ma’lumotlar qanday ishlatilishini biling',
            ru: 'Как используются ваши данные',
            en: 'Understand how your data is used',
          ),
          onTap: () =>
              _openAccountScreen(context, portal, const _PrivacyPolicyScreen()),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
              color: Theme.of(context).colorScheme.error.withValues(alpha: .35),
            ),
          ),
          onPressed: () => _confirmAccountLogout(context, portal),
          icon: const Icon(Icons.logout_rounded),
          label: Text(
            _familyCopy(
              context,
              uz: 'Akkauntdan chiqish',
              ru: 'Выйти из аккаунта',
              en: 'Log out',
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountHubTile extends StatelessWidget {
  const _AccountHubTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

void _openAccountScreen(
  BuildContext context,
  PortalController portal,
  Widget screen,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PortalScope(controller: portal, child: screen),
    ),
  );
}

class _PersonalInformationScreen extends StatelessWidget {
  const _PersonalInformationScreen();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final roleProfile = portal.isParent
        ? portal.parentProfile
        : portal.studentProfile;
    final profile = <String, Object?>{...portal.profile, ...roleProfile};
    String value(List<String> keys) => valueText(profile, keys, fallback: '');
    final fields = <(IconData, String, String)>[
      (
        Icons.person_outline_rounded,
        _familyCopy(
          context,
          uz: 'To‘liq ism',
          ru: 'Полное имя',
          en: 'Full name',
        ),
        value(const ['full_name']),
      ),
      (
        Icons.alternate_email_rounded,
        _familyCopy(context, uz: 'Login', ru: 'Логин', en: 'Username'),
        value(const ['username']),
      ),
      (
        Icons.phone_iphone_rounded,
        _familyCopy(context, uz: 'Telefon', ru: 'Телефон', en: 'Phone'),
        value(const ['phone']),
      ),
      (Icons.email_outlined, 'Email', value(const ['email'])),
      (
        Icons.cake_outlined,
        _familyCopy(
          context,
          uz: 'Tug‘ilgan sana',
          ru: 'Дата рождения',
          en: 'Date of birth',
        ),
        _dateLabel(profile['birthdate']),
      ),
      (
        Icons.location_on_outlined,
        _familyCopy(context, uz: 'Hudud', ru: 'Регион', en: 'Region'),
        value(const ['location', 'address']),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'Shaxsiy ma’lumotlar',
            ru: 'Личные данные',
            en: 'Personal information',
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                _openAccountScreen(context, portal, const _ProfileEditScreen()),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              _familyCopy(
                context,
                uz: 'Tahrirlash',
                ru: 'Изменить',
                en: 'Edit',
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final field in fields)
                        ListTile(
                          leading: Icon(
                            field.$1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(field.$2),
                          subtitle: Text(
                            _filled(field.$3)
                                ? field.$3
                                : _familyCopy(
                                    context,
                                    uz: 'Kiritilmagan',
                                    ru: 'Не указано',
                                    en: 'Not provided',
                                  ),
                          ),
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
  }
}

class _AppearanceSettingsScreen extends StatelessWidget {
  const _AppearanceSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final preferences = PortalScope.of(context).preferences;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'Ko‘rinish va til',
            ru: 'Внешний вид и язык',
            en: 'Appearance and language',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResponsiveGrid(
                  minWidth: 230,
                  children: [
                    _PreferenceActionTile(
                      key: const ValueKey('account-language-setting'),
                      icon: Icons.language_rounded,
                      label: _familyCopy(
                        context,
                        uz: 'Til',
                        ru: 'Язык',
                        en: 'Language',
                      ),
                      value: preferences.language.label,
                      onTap: () => _showPortalChoiceSheet<PortalLanguage>(
                        context,
                        title: context.tr('language.choose'),
                        selected: preferences.language,
                        options: [
                          for (final language in PortalLanguage.values)
                            _PortalChoice(
                              value: language,
                              title: language.label,
                              subtitle: language.code.toUpperCase(),
                              icon: Icons.translate_rounded,
                            ),
                        ],
                        onSelected: preferences.setLanguage,
                      ),
                    ),
                    _PreferenceActionTile(
                      key: const ValueKey('account-currency-setting'),
                      icon: Icons.currency_exchange_rounded,
                      label: _familyCopy(
                        context,
                        uz: 'Valyuta',
                        ru: 'Валюта',
                        en: 'Currency',
                      ),
                      value:
                          '${preferences.currency.code} · ${preferences.currency.symbol}',
                      onTap: () => _showPortalChoiceSheet<PortalCurrency>(
                        context,
                        title: _familyCopy(
                          context,
                          uz: 'Ko‘rsatish valyutasi',
                          ru: 'Валюта отображения',
                          en: 'Display currency',
                        ),
                        selected: preferences.currency,
                        options: [
                          for (final currency in PortalCurrency.values)
                            _PortalChoice(
                              value: currency,
                              title: currency.code,
                              subtitle: currency.symbol,
                              icon: Icons.payments_outlined,
                            ),
                        ],
                        onSelected: preferences.setCurrency,
                      ),
                    ),
                    _PreferenceActionTile(
                      key: const ValueKey('account-theme-setting'),
                      icon: Icons.brightness_6_outlined,
                      label: _familyCopy(
                        context,
                        uz: 'Mavzu',
                        ru: 'Тема',
                        en: 'Theme',
                      ),
                      value: _themePreferenceLabel(
                        preferences.themePreference,
                        preferences.language,
                      ),
                      onTap: () =>
                          _showPortalChoiceSheet<PortalThemePreference>(
                            context,
                            title: _familyCopy(
                              context,
                              uz: 'Ilova mavzusi',
                              ru: 'Тема приложения',
                              en: 'App theme',
                            ),
                            selected: preferences.themePreference,
                            options: [
                              _PortalChoice(
                                value: PortalThemePreference.system,
                                title: _familyCopy(
                                  context,
                                  uz: 'Tizim bo‘yicha',
                                  ru: 'Системная',
                                  en: 'System',
                                ),
                                subtitle: _familyCopy(
                                  context,
                                  uz: 'Qurilma sozlamasiga mos',
                                  ru: 'Как на устройстве',
                                  en: 'Matches your device',
                                ),
                                icon: Icons.brightness_auto_rounded,
                              ),
                              _PortalChoice(
                                value: PortalThemePreference.light,
                                title: _familyCopy(
                                  context,
                                  uz: 'Yorug‘',
                                  ru: 'Светлая',
                                  en: 'Light',
                                ),
                                subtitle: _familyCopy(
                                  context,
                                  uz: 'Yorug‘ ko‘rinish',
                                  ru: 'Светлое оформление',
                                  en: 'Light appearance',
                                ),
                                icon: Icons.light_mode_outlined,
                              ),
                              _PortalChoice(
                                value: PortalThemePreference.dark,
                                title: _familyCopy(
                                  context,
                                  uz: 'Qorong‘i',
                                  ru: 'Тёмная',
                                  en: 'Dark',
                                ),
                                subtitle: _familyCopy(
                                  context,
                                  uz: 'Qorong‘i ko‘rinish',
                                  ru: 'Тёмное оформление',
                                  en: 'Dark appearance',
                                ),
                                icon: Icons.dark_mode_outlined,
                              ),
                            ],
                            onSelected: preferences.setThemePreference,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _familyCopy(
                          context,
                          uz: 'Rang palitrasi',
                          ru: 'Цветовая палитра',
                          en: 'Color palette',
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      _PortalPalettePicker(
                        selected: preferences.paletteIndex,
                        onSelected: preferences.setPaletteIndex,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _familyCopy(
                          context,
                          uz: 'Interfeys zichligi',
                          ru: 'Плотность интерфейса',
                          en: 'Interface density',
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _PortalChoiceChips<PortalDensity>(
                        selected: preferences.density,
                        values: PortalDensity.values,
                        label: (value) =>
                            _densityLabel(value, preferences.language),
                        onSelected: preferences.setDensity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.text_increase_rounded),
                        title: Text(
                          _familyCopy(
                            context,
                            uz: 'Katta matn',
                            ru: 'Крупный текст',
                            en: 'Large text',
                          ),
                        ),
                        value: preferences.largeText,
                        onChanged: preferences.setLargeText,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.contrast_rounded),
                        title: Text(
                          _familyCopy(
                            context,
                            uz: 'Yuqori kontrast',
                            ru: 'Высокий контраст',
                            en: 'High contrast',
                          ),
                        ),
                        value: preferences.highContrast,
                        onChanged: preferences.setHighContrast,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.motion_photos_off_outlined),
                        title: Text(
                          _familyCopy(
                            context,
                            uz: 'Animatsiyani kamaytirish',
                            ru: 'Уменьшить анимацию',
                            en: 'Reduce motion',
                          ),
                        ),
                        value: preferences.reduceMotion,
                        onChanged: preferences.setReduceMotion,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.visibility_off_outlined),
                        title: Text(
                          _familyCopy(
                            context,
                            uz: 'Summalarni yashirish',
                            ru: 'Скрывать суммы',
                            en: 'Hide amounts',
                          ),
                        ),
                        value: preferences.hideAmounts,
                        onChanged: preferences.setHideAmounts,
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
  }
}

class _SecuritySessionsScreen extends StatelessWidget {
  const _SecuritySessionsScreen();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'Xavfsizlik va sessiyalar',
            ru: 'Безопасность и сеансы',
            en: 'Security and sessions',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AccountHubTile(
                  icon: Icons.password_rounded,
                  color: Sf.primary,
                  title: _familyCopy(
                    context,
                    uz: 'Parolni almashtirish',
                    ru: 'Изменить пароль',
                    en: 'Change password',
                  ),
                  subtitle: _familyCopy(
                    context,
                    uz: 'Akkauntingiz uchun yangi parol o‘rnating',
                    ru: 'Установите новый пароль для аккаунта',
                    en: 'Set a new password for your account',
                  ),
                  onTap: () => _openAccountScreen(
                    context,
                    portal,
                    const _PasswordChangeScreen(),
                  ),
                ),
                const SizedBox(height: 20),
                _PageSectionTitle(
                  title: _familyCopy(
                    context,
                    uz: 'Faol qurilmalar',
                    ru: 'Активные устройства',
                    en: 'Active devices',
                  ),
                  count: portal.devices.length,
                ),
                const SizedBox(height: 9),
                if (portal.devices.isEmpty)
                  _EmptyState(
                    icon: Icons.devices_other_outlined,
                    title: _familyCopy(
                      context,
                      uz: 'Faol qurilma topilmadi',
                      ru: 'Активные устройства не найдены',
                      en: 'No active devices found',
                    ),
                    message: _familyCopy(
                      context,
                      uz: 'Yangi qurilma ro‘yxatdan o‘tganda uning sessiyasi shu yerda ko‘rinadi.',
                      ru: 'Сессия появится здесь после регистрации нового устройства.',
                      en: 'A session will appear here after a new device is registered.',
                    ),
                  )
                else
                  _SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final device in portal.devices)
                          ListTile(
                            leading: const Icon(Icons.devices_outlined),
                            title: Text(
                              valueText(
                                device,
                                const ['name', 'platform'],
                                fallback: _familyCopy(
                                  context,
                                  uz: 'Qurilma',
                                  ru: 'Устройство',
                                  en: 'Device',
                                ),
                              ),
                            ),
                            subtitle: Text(
                              '${valueText(device, const ['platform'], fallback: '')} · ${_dateLabel(device['last_seen_at'], time: true)}',
                            ),
                            trailing: IconButton(
                              tooltip: _familyCopy(
                                context,
                                uz: 'Sessiyani tugatish',
                                ru: 'Завершить сеанс',
                                en: 'End session',
                              ),
                              onPressed: _withId(
                                device['id'],
                                (id) =>
                                    _confirmSessionRevoke(context, portal, id),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                            ),
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
  }
}

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    final sections = [
      (
        _familyCopy(
          context,
          uz: 'Qanday ma’lumotlar saqlanadi',
          ru: 'Какие данные хранятся',
          en: 'Information we store',
        ),
        _familyCopy(
          context,
          uz: 'Akkaunt, aloqa, o‘quv jarayoni, davomat, topshiriqlar, xabarlar va to‘lovga oid ma’lumotlar faqat xizmatni taqdim etish uchun ishlatiladi.',
          ru: 'Данные аккаунта, контакты, обучение, посещаемость, задания, сообщения и платежи используются для предоставления сервиса.',
          en: 'Account, contact, learning, attendance, assignment, message, and payment information is used to provide the service.',
        ),
      ),
      (
        _familyCopy(
          context,
          uz: 'Kim ko‘ra oladi',
          ru: 'Кто имеет доступ',
          en: 'Who can access it',
        ),
        _familyCopy(
          context,
          uz: 'Ma’lumotlar rol va ruxsatlar asosida o‘quvchi, rasmiy ota-ona hamda markazning vakolatli xodimlariga ko‘rsatiladi.',
          ru: 'Доступ предоставляется ученику, официальному родителю и уполномоченным сотрудникам центра на основе ролей и разрешений.',
          en: 'Access is limited by role and permission to the student, official parent, and authorized center staff.',
        ),
      ),
      (
        _familyCopy(
          context,
          uz: 'Xavfsizlik',
          ru: 'Безопасность',
          en: 'Security',
        ),
        _familyCopy(
          context,
          uz: 'Kirish sessiyalari himoyalanadi. Parolni hech kim bilan ulashmang va noma’lum qurilma sessiyasini darhol yakunlang.',
          ru: 'Сеансы входа защищены. Не сообщайте пароль и завершайте незнакомые сеансы устройств.',
          en: 'Sign-in sessions are protected. Never share your password and end any device session you do not recognize.',
        ),
      ),
      (
        _familyCopy(
          context,
          uz: 'Sizning huquqlaringiz',
          ru: 'Ваши права',
          en: 'Your choices',
        ),
        _familyCopy(
          context,
          uz: 'Noto‘g‘ri ma’lumotni tahrirlashingiz yoki o‘quv markazidan tuzatish, eksport va o‘chirish bo‘yicha yordam so‘rashingiz mumkin.',
          ru: 'Вы можете исправить данные или обратиться в учебный центр за исправлением, экспортом или удалением.',
          en: 'You can edit incorrect details or ask your learning center for help with correction, export, or deletion.',
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _familyCopy(
            context,
            uz: 'Maxfiylik siyosati',
            ru: 'Политика конфиденциальности',
            en: 'Privacy policy',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SectionCard(
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 30),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _familyCopy(
                              context,
                              uz: 'Starforge Family sizning oilaviy va o‘quv ma’lumotlaringizga ehtiyotkorlik bilan munosabatda bo‘ladi.',
                              ru: 'Starforge Family бережно относится к учебным и семейным данным.',
                              en: 'Starforge Family treats your family and learning information with care.',
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final section = sections[index - 1];
                return _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.$1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        section.$2,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmSessionRevoke(
  BuildContext context,
  PortalController portal,
  int id,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        _familyCopy(
          context,
          uz: 'Sessiyani tugatish',
          ru: 'Завершить сеанс',
          en: 'End session',
        ),
      ),
      content: Text(
        _familyCopy(
          context,
          uz: 'Tanlangan qurilma akkauntdan chiqariladi.',
          ru: 'Выбранное устройство выйдет из аккаунта.',
          en: 'The selected device will be signed out.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            _familyCopy(
              context,
              uz: 'Bekor qilish',
              ru: 'Отмена',
              en: 'Cancel',
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            _familyCopy(
              context,
              uz: 'Tugatish',
              ru: 'Завершить',
              en: 'End session',
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await _runAction(
      context,
      () => portal.revokeDevice(id),
      success: _familyCopy(
        context,
        uz: 'Sessiya tugatildi.',
        ru: 'Сеанс завершён.',
        en: 'Session ended.',
      ),
    );
  }
}

Future<void> _confirmAccountLogout(
  BuildContext context,
  PortalController portal,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        _familyCopy(
          context,
          uz: 'Akkauntdan chiqish',
          ru: 'Выйти из аккаунта',
          en: 'Log out',
        ),
      ),
      content: Text(
        _familyCopy(
          context,
          uz: 'Davom etsangiz, qayta kirish uchun login va parol kerak bo‘ladi.',
          ru: 'Для повторного входа понадобятся логин и пароль.',
          en: 'You will need your username and password to sign in again.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            _familyCopy(
              context,
              uz: 'Bekor qilish',
              ru: 'Отмена',
              en: 'Cancel',
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            _familyCopy(context, uz: 'Chiqish', ru: 'Выйти', en: 'Log out'),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) await portal.logout();
}

// Retained while older settings routes migrate to focused settings pages.
// ignore: unused_element
class _LegacyAccountPortalPage extends StatelessWidget {
  const _LegacyAccountPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final preferences = portal.preferences;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return _PortalPage(
      title: _familyCopy(
        context,
        uz: 'Profil va xavfsizlik',
        ru: 'Профиль и безопасность',
        en: 'Profile and security',
      ),
      subtitle: _familyCopy(
        context,
        uz: 'Shaxsiy ma’lumotlar, qurilmalar, parol va ilova ko‘rinishi.',
        ru: 'Личные данные, устройства, пароль и внешний вид приложения.',
        en: 'Personal details, devices, password and app appearance.',
      ),
      section: PortalSection.account,
      children: [
        _SectionCard(child: _AccountIdentityHeader(portal: portal)),
        SizedBox(height: compact ? 14 : 24),
        _PageSectionTitle(
          title: _familyCopy(
            context,
            uz: 'Tezkor sozlamalar',
            ru: 'Быстрые настройки',
            en: 'Quick settings',
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _ResponsiveGrid(
          minWidth: compact ? 145 : 210,
          children: [
            _PreferenceActionTile(
              key: const ValueKey('account-language-setting'),
              icon: Icons.language_rounded,
              label: _familyCopy(
                context,
                uz: 'Til',
                ru: 'Язык',
                en: 'Language',
              ),
              value: preferences.language.label,
              onTap: () => _showPortalChoiceSheet<PortalLanguage>(
                context,
                title: context.tr('language.choose'),
                selected: preferences.language,
                options: [
                  for (final language in PortalLanguage.values)
                    _PortalChoice(
                      value: language,
                      title: language.label,
                      subtitle: language.code.toUpperCase(),
                      icon: Icons.translate_rounded,
                    ),
                ],
                onSelected: preferences.setLanguage,
              ),
            ),
            _PreferenceActionTile(
              key: const ValueKey('account-currency-setting'),
              icon: Icons.currency_exchange_rounded,
              label: _familyCopy(
                context,
                uz: 'Valyuta',
                ru: 'Валюта',
                en: 'Currency',
              ),
              value:
                  '${preferences.currency.code} · ${preferences.currency.symbol}',
              onTap: () => _showPortalChoiceSheet<PortalCurrency>(
                context,
                title: _familyCopy(
                  context,
                  uz: 'Ko‘rsatish valyutasi',
                  ru: 'Валюта отображения',
                  en: 'Display currency',
                ),
                selected: preferences.currency,
                options: [
                  for (final currency in PortalCurrency.values)
                    _PortalChoice(
                      value: currency,
                      title: currency.code,
                      subtitle: currency.symbol,
                      icon: Icons.payments_outlined,
                    ),
                ],
                onSelected: preferences.setCurrency,
              ),
            ),
            _PreferenceActionTile(
              key: const ValueKey('account-theme-setting'),
              icon: Icons.palette_outlined,
              label: _familyCopy(context, uz: 'Mavzu', ru: 'Тема', en: 'Theme'),
              value: _themePreferenceLabel(
                preferences.themePreference,
                preferences.language,
              ),
              onTap: () => _showPortalChoiceSheet<PortalThemePreference>(
                context,
                title: _familyCopy(
                  context,
                  uz: 'Ilova mavzusi',
                  ru: 'Тема приложения',
                  en: 'App theme',
                ),
                selected: preferences.themePreference,
                options: [
                  _PortalChoice(
                    value: PortalThemePreference.system,
                    title: _familyCopy(
                      context,
                      uz: 'Tizim bo‘yicha',
                      ru: 'Системная',
                      en: 'System',
                    ),
                    subtitle: _familyCopy(
                      context,
                      uz: 'Telefon sozlamasiga mos',
                      ru: 'Как в настройках устройства',
                      en: 'Matches device settings',
                    ),
                    icon: Icons.brightness_auto_rounded,
                  ),
                  _PortalChoice(
                    value: PortalThemePreference.light,
                    title: _familyCopy(
                      context,
                      uz: 'Yorug‘',
                      ru: 'Светлая',
                      en: 'Light',
                    ),
                    subtitle: _familyCopy(
                      context,
                      uz: 'Kunduzgi ko‘rinish',
                      ru: 'Дневное оформление',
                      en: 'Day appearance',
                    ),
                    icon: Icons.light_mode_outlined,
                  ),
                  _PortalChoice(
                    value: PortalThemePreference.dark,
                    title: _familyCopy(
                      context,
                      uz: 'Qorong‘i',
                      ru: 'Тёмная',
                      en: 'Dark',
                    ),
                    subtitle: _familyCopy(
                      context,
                      uz: 'Tungi ko‘rinish',
                      ru: 'Ночное оформление',
                      en: 'Night appearance',
                    ),
                    icon: Icons.dark_mode_outlined,
                  ),
                ],
                onSelected: preferences.setThemePreference,
              ),
            ),
            _PreferenceActionTile(
              key: const ValueKey('account-notification-setting'),
              icon: Icons.notifications_active_outlined,
              label: _familyCopy(
                context,
                uz: 'Bildirishnomalar',
                ru: 'Уведомления',
                en: 'Notifications',
              ),
              value: portal.notificationPreferences.isEmpty
                  ? 'Tizim sozlamasi'
                  : '${portal.notificationPreferences.where((row) => row['enabled'] == true).length} ta kanal faol',
              onTap: () => _PortalNavigationScope.go(
                context,
                PortalSection.notifications,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 14 : 24),
        _PageSectionTitle(
          title: _familyCopy(
            context,
            uz: 'Ilova ko‘rinishi',
            ru: 'Внешний вид',
            en: 'Appearance',
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _SectionCard(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _familyCopy(
                  context,
                  uz: 'Rang palitrasi',
                  ru: 'Цветовая палитра',
                  en: 'Color palette',
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              _PortalPalettePicker(
                selected: preferences.paletteIndex,
                onSelected: preferences.setPaletteIndex,
              ),
              const SizedBox(height: 18),
              Text(
                _familyCopy(
                  context,
                  uz: 'Interfeys zichligi',
                  ru: 'Плотность интерфейса',
                  en: 'Interface density',
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _PortalChoiceChips<PortalDensity>(
                selected: preferences.density,
                values: PortalDensity.values,
                label: (value) => _densityLabel(value, preferences.language),
                onSelected: preferences.setDensity,
              ),
              const SizedBox(height: 18),
              Text(
                _familyCopy(context, uz: 'Shrift', ru: 'Шрифт', en: 'Font'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _PortalChoiceChips<int>(
                selected: preferences.fontIndex,
                values: const [0, 1, 2],
                label: (value) =>
                    const ['Manrope', 'Instrument', 'JetBrains'][value],
                onSelected: preferences.setFontIndex,
              ),
              const SizedBox(height: 18),
              Text(
                _familyCopy(
                  context,
                  uz: 'Fon naqshi',
                  ru: 'Фоновый узор',
                  en: 'Background pattern',
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _PortalChoiceChips<PortalPattern>(
                selected: preferences.pattern,
                values: PortalPattern.values,
                label: (value) => _patternLabel(value, preferences.language),
                onSelected: preferences.setPattern,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 24),
        _PageSectionTitle(
          title: _familyCopy(
            context,
            uz: 'Qulaylik',
            ru: 'Доступность',
            en: 'Accessibility',
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                dense: compact,
                visualDensity: compact ? VisualDensity.compact : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                ),
                secondary: const Icon(Icons.text_increase_rounded),
                title: Text(
                  _familyCopy(
                    context,
                    uz: 'Katta matn',
                    ru: 'Крупный текст',
                    en: 'Large text',
                  ),
                ),
                value: preferences.largeText,
                onChanged: preferences.setLargeText,
              ),
              SwitchListTile(
                dense: compact,
                visualDensity: compact ? VisualDensity.compact : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                ),
                secondary: const Icon(Icons.contrast_rounded),
                title: Text(
                  _familyCopy(
                    context,
                    uz: 'Yuqori kontrast',
                    ru: 'Высокий контраст',
                    en: 'High contrast',
                  ),
                ),
                value: preferences.highContrast,
                onChanged: preferences.setHighContrast,
              ),
              SwitchListTile(
                dense: compact,
                visualDensity: compact ? VisualDensity.compact : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                ),
                secondary: const Icon(Icons.motion_photos_off_outlined),
                title: Text(
                  _familyCopy(
                    context,
                    uz: 'Animatsiyani kamaytirish',
                    ru: 'Уменьшить анимацию',
                    en: 'Reduce motion',
                  ),
                ),
                value: preferences.reduceMotion,
                onChanged: preferences.setReduceMotion,
              ),
              SwitchListTile(
                dense: compact,
                visualDensity: compact ? VisualDensity.compact : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                ),
                secondary: const Icon(Icons.visibility_off_outlined),
                title: Text(
                  _familyCopy(
                    context,
                    uz: 'Summalarni yashirish',
                    ru: 'Скрывать суммы',
                    en: 'Hide amounts',
                  ),
                ),
                subtitle: Text(
                  _familyCopy(
                    context,
                    uz: 'Moliyaviy ma’lumotni ko‘zlardan himoyalash',
                    ru: 'Скрывает финансовые данные от посторонних',
                    en: 'Keeps financial data away from onlookers',
                  ),
                ),
                value: preferences.hideAmounts,
                onChanged: preferences.setHideAmounts,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 24),
        _PageSectionTitle(
          title: _familyCopy(
            context,
            uz: 'Chat ko‘rinishi',
            ru: 'Оформление чата',
            en: 'Chat appearance',
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactPreferenceRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: _familyCopy(
                  context,
                  uz: 'Xabarlar uslubi',
                  ru: 'Стиль сообщений',
                  en: 'Message style',
                ),
                value: _chatStyleLabel(preferences.chatStyle),
                onTap: () => _showPortalChoiceSheet<PortalChatStyle>(
                  context,
                  title: _familyCopy(
                    context,
                    uz: 'Chat uslubini tanlang',
                    ru: 'Выберите стиль чата',
                    en: 'Choose chat style',
                  ),
                  selected: preferences.chatStyle,
                  options: [
                    for (final style in PortalChatStyle.values)
                      _PortalChoice(
                        value: style,
                        title: _chatStyleLabel(style),
                        subtitle: _familyCopy(
                          context,
                          uz: 'Xabar pufakchalari va ranglar',
                          ru: 'Пузырьки сообщений и цвета',
                          en: 'Message bubbles and colors',
                        ),
                        icon: Icons.forum_outlined,
                      ),
                  ],
                  onSelected: preferences.setChatStyle,
                ),
              ),
              const Divider(height: 22),
              _CompactPreferenceRow(
                icon: Icons.wallpaper_rounded,
                title: _familyCopy(
                  context,
                  uz: 'Chat foni',
                  ru: 'Фон чата',
                  en: 'Chat background',
                ),
                value: _chatWallpaperLabel(preferences.chatWallpaper),
                onTap: () => _showPortalChoiceSheet<PortalChatWallpaper>(
                  context,
                  title: _familyCopy(
                    context,
                    uz: 'Chat fonini tanlang',
                    ru: 'Выберите фон чата',
                    en: 'Choose chat background',
                  ),
                  selected: preferences.chatWallpaper,
                  options: [
                    for (final wallpaper in PortalChatWallpaper.values)
                      _PortalChoice(
                        value: wallpaper,
                        title: _chatWallpaperLabel(wallpaper),
                        subtitle: _familyCopy(
                          context,
                          uz: 'Suhbatlar uchun alohida fon',
                          ru: 'Отдельный фон для переписки',
                          en: 'A separate background for conversations',
                        ),
                        icon: Icons.image_outlined,
                      ),
                  ],
                  onSelected: preferences.setChatWallpaper,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 24),
        Row(
          children: [
            const Expanded(child: _PageSectionTitle(title: 'Faol qurilmalar')),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PortalScope(
                    controller: portal,
                    child: const _PasswordChangeScreen(),
                  ),
                ),
              ),
              icon: const Icon(Icons.password_rounded),
              label: const Text('Parolni almashtirish'),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
        if (portal.devices.isEmpty)
          const _EmptyState(
            icon: Icons.devices_other_outlined,
            title: 'Qurilma ro‘yxati bo‘sh',
            message: 'Ro‘yxatdan o‘tgan qurilmalar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: portal.devices,
            icon: Icons.devices_outlined,
            title: (row) => valueText(row, const [
              'name',
              'platform',
            ], fallback: 'Faol qurilma'),
            subtitle: (row) =>
                '${valueText(row, const ['platform'])} · ${valueText(row, const ['user_agent'], fallback: 'Qurilma tavsifi yo‘q')}\nOxirgi faollik: ${_dateLabel(row['last_seen_at'], time: true)}',
            trailing: (row) => IconButton(
              tooltip: 'Qurilmani chiqarish',
              onPressed: _withId(
                row['id'],
                (id) => _confirmDeviceRevoke(context, portal, id),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
            onTap: (row) => _showJsonDetail(
              context,
              title: valueText(row, const [
                'name',
                'platform',
              ], fallback: 'Qurilma'),
              fields: {
                'Platforma': valueText(row, const ['platform']),
                'Qurilma ID': valueText(row, const ['device_id']),
                'User agent': valueText(row, const ['user_agent']),
                'Push holati': _filled(row['push_token'])
                    ? 'Ulangan'
                    : 'Ulanmagan',
                'Oxirgi faollik': _dateLabel(row['last_seen_at'], time: true),
                'Bekor qilingan': _dateLabel(row['revoked_at'], time: true),
              },
            ),
          ),
        SizedBox(height: compact ? 14 : 24),
        _SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ExpansionTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: const Text('Yordam uchun texnik ma’lumot'),
                subtitle: const Text(
                  'Faqat markaz mutaxassisi so‘raganda oching',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    portal.baseUrl,
                    style: const TextStyle(fontFamily: Sf.mono, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _TechnicalProfileRows(profile: portal.profile),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _confirmPreferenceReset(context, preferences.reset),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Ko‘rinish sozlamalarini tiklash'),
                    ),
                    const SizedBox(height: 9),
                    OutlinedButton.icon(
                      onPressed: portal.logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Akkauntdan chiqish'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeviceRevoke(
    BuildContext context,
    PortalController portal,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Qurilmani chiqarish'),
        content: const Text('Bu qurilmadagi faol sessiya bekor qilinadi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chiqarish'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runAction(
        context,
        () => portal.revokeDevice(id),
        success: 'Qurilma chiqarildi.',
      );
    }
  }
}

class _PortalChoice<T> {
  const _PortalChoice({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final T value;
  final String title;
  final String subtitle;
  final IconData icon;
}

Future<void> _showPortalChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required List<_PortalChoice<T>> options,
  required ValueChanged<T> onSelected,
}) async {
  final value = await showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 620),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Material(
                  color: option.value == selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(13),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    leading: Icon(option.icon),
                    title: Text(option.title),
                    subtitle: Text(option.subtitle),
                    trailing: option.value == selected
                        ? const Icon(Icons.check_circle_rounded)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(sheetContext, option.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (value != null) onSelected(value);
}

Future<void> _confirmPreferenceReset(
  BuildContext context,
  VoidCallback reset,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sozlamalarni tiklash'),
      content: const Text(
        'Til, ranglar, zichlik, chat ko‘rinishi va qulaylik sozlamalari boshlang‘ich holatga qaytadi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Tiklash'),
        ),
      ],
    ),
  );
  if (confirmed == true) reset();
}

class _PreferenceActionTile extends StatelessWidget {
  const _PreferenceActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sf.eyebrow(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactPreferenceRow extends StatelessWidget {
  const _CompactPreferenceRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _PortalChoiceChips<T> extends StatelessWidget {
  const _PortalChoiceChips({
    required this.selected,
    required this.values,
    required this.label,
    required this.onSelected,
  });

  final T selected;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      for (final value in values)
        ChoiceChip(
          label: Text(label(value)),
          selected: value == selected,
          onSelected: (_) => onSelected(value),
        ),
    ],
  );
}

class _PortalPalettePicker extends StatelessWidget {
  const _PortalPalettePicker({
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  static const colors = <Color>[
    Color(0xFF4F6A3A),
    Color(0xFF1F6B66),
    Color(0xFF2A3D8F),
    Color(0xFFB85535),
    Color(0xFFC2410C),
    Color(0xFF0E7C5A),
    Color(0xFFB3122F),
    Color(0xFF2563A8),
    Color(0xFFB8791C),
    Color(0xFF2B2A26),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: [
      for (var index = 0; index < colors.length; index++)
        Semantics(
          button: true,
          selected: selected == index,
          label: 'Palitra ${index + 1}',
          child: InkWell(
            key: ValueKey('portal-palette-$index'),
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == index
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: selected == index
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
          ),
        ),
    ],
  );
}

String _familyCopy(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (PortalScope.of(context).preferences.language) {
  PortalLanguage.uz => uz,
  PortalLanguage.ru => ru,
  PortalLanguage.en => en,
};

String _themePreferenceLabel(
  PortalThemePreference value,
  PortalLanguage language,
) => switch ((value, language)) {
  (PortalThemePreference.system, PortalLanguage.ru) => 'Системная',
  (PortalThemePreference.system, PortalLanguage.en) => 'System',
  (PortalThemePreference.light, PortalLanguage.ru) => 'Светлая',
  (PortalThemePreference.light, PortalLanguage.en) => 'Light',
  (PortalThemePreference.dark, PortalLanguage.ru) => 'Тёмная',
  (PortalThemePreference.dark, PortalLanguage.en) => 'Dark',
  (PortalThemePreference.system, _) => 'Tizim bo‘yicha',
  (PortalThemePreference.light, _) => 'Yorug‘',
  (PortalThemePreference.dark, _) => 'Qorong‘i',
};

String _densityLabel(PortalDensity value, PortalLanguage language) =>
    switch ((value, language)) {
      (PortalDensity.compact, PortalLanguage.ru) => 'Компактно',
      (PortalDensity.compact, PortalLanguage.en) => 'Compact',
      (PortalDensity.standard, PortalLanguage.ru) => 'Обычно',
      (PortalDensity.standard, PortalLanguage.en) => 'Standard',
      (PortalDensity.comfortable, PortalLanguage.ru) => 'Свободно',
      (PortalDensity.comfortable, PortalLanguage.en) => 'Comfortable',
      (PortalDensity.compact, _) => 'Ixcham',
      (PortalDensity.standard, _) => 'O‘rta',
      (PortalDensity.comfortable, _) => 'Keng',
    };

String _patternLabel(PortalPattern value, PortalLanguage language) =>
    switch ((value, language)) {
      (PortalPattern.none, PortalLanguage.ru) => 'Без узора',
      (PortalPattern.none, PortalLanguage.en) => 'None',
      (PortalPattern.dots, PortalLanguage.ru) => 'Точки',
      (PortalPattern.dots, PortalLanguage.en) => 'Dots',
      (PortalPattern.grid, PortalLanguage.ru) => 'Сетка',
      (PortalPattern.grid, PortalLanguage.en) => 'Grid',
      (PortalPattern.tile, PortalLanguage.ru) => 'Плитка',
      (PortalPattern.tile, PortalLanguage.en) => 'Tile',
      (PortalPattern.topo, PortalLanguage.ru) => 'Топография',
      (PortalPattern.topo, PortalLanguage.en) => 'Topo',
      (PortalPattern.none, _) => 'Toza',
      (PortalPattern.dots, _) => 'Nuqtalar',
      (PortalPattern.grid, _) => 'To‘r',
      (PortalPattern.tile, _) => 'Koshin',
      (PortalPattern.topo, _) => 'Xarita',
    };

String _chatStyleLabel(PortalChatStyle value) => switch (value) {
  PortalChatStyle.telegram => 'Telegram',
  PortalChatStyle.whatsapp => 'WhatsApp',
  PortalChatStyle.modernDark => 'Modern Dark',
  PortalChatStyle.glass => 'Glass',
  PortalChatStyle.gradient => 'Gradient',
  PortalChatStyle.minimal => 'Minimal',
  PortalChatStyle.neon => 'Neon',
  PortalChatStyle.nature => 'Nature',
};

String _chatWallpaperLabel(PortalChatWallpaper value) => switch (value) {
  PortalChatWallpaper.telegramClouds => 'Telegram Clouds',
  PortalChatWallpaper.whatsappPattern => 'WhatsApp Pattern',
  PortalChatWallpaper.mountains => 'Mountains',
  PortalChatWallpaper.aurora => 'Aurora',
  PortalChatWallpaper.space => 'Space',
  PortalChatWallpaper.ocean => 'Ocean',
  PortalChatWallpaper.sakura => 'Sakura',
  PortalChatWallpaper.abstract => 'Abstract',
  PortalChatWallpaper.gradient => 'Gradient',
  PortalChatWallpaper.blur => 'Blur',
};

class _AccountIdentityHeader extends StatelessWidget {
  const _AccountIdentityHeader({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = Theme.of(context).colorScheme;
    final roleProfile = portal.isParent
        ? portal.parentProfile
        : portal.studentProfile;
    final identity = roleProfile.isEmpty ? portal.profile : roleProfile;
    final roleLabel = portal.isParent
        ? context.tr('role.parent')
        : context.tr('role.student');
    final username = valueText(
      portal.profile,
      const ['username'],
      fallback: _familyCopy(
        context,
        uz: 'Akkaunt',
        ru: 'Аккаунт',
        en: 'Account',
      ),
    );
    final branch = valueText(identity, const [
      'branch_name',
      'branch',
    ], fallback: _familyCopy(context, uz: 'Markaz', ru: 'Центр', en: 'Center'));
    final cohort = valueText(
      identity,
      const [
        'current_cohort_name',
        'cohort_name',
        'group_name',
        'academic_level',
      ],
      fallback: portal.isParent
          ? _familyCopy(
              context,
              uz: '${portal.children.length} farzand',
              ru: 'Детей: ${portal.children.length}',
              en: 'Children: ${portal.children.length}',
            )
          : _familyCopy(context, uz: 'Guruh', ru: 'Группа', en: 'Group'),
    );
    final contact = valueText(
      identity,
      const ['phone', 'email'],
      fallback: valueText(portal.profile, const [
        'phone',
        'email',
      ], fallback: 'Aloqa ma’lumoti yo‘q'),
    );
    final avatar = Container(
      width: compact ? 62 : 76,
      height: compact ? 62 : 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 3),
        boxShadow: Sf.shadowMd,
      ),
      child: Text(
        _initials(portal.displayName),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            roleLabel.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          portal.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(fontWeight: FontWeight.w900, height: 1.05),
        ),
        const SizedBox(height: 5),
        Text(
          '$username · $contact',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _AccountMetaChip(icon: Icons.apartment_rounded, label: branch),
            _AccountMetaChip(
              icon: portal.isParent
                  ? Icons.family_restroom_rounded
                  : Icons.groups_2_outlined,
              label: cohort,
            ),
          ],
        ),
      ],
    );
    final edit = FilledButton.tonalIcon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PortalScope(
            controller: portal,
            child: const _ProfileEditScreen(),
          ),
        ),
      ),
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Tahrirlash'),
    );
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceContainerLowest,
            colors.primaryContainer.withValues(alpha: .42),
          ],
        ),
        borderRadius: BorderRadius.circular(Sf.radiusLarge),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 13),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 13),
                edit,
              ],
            );
          }
          return Row(
            children: [
              avatar,
              const SizedBox(width: 18),
              Expanded(child: details),
              const SizedBox(width: 16),
              edit,
            ],
          );
        },
      ),
    );
  }
}

class _AccountMetaChip extends StatelessWidget {
  const _AccountMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalProfileRows extends StatelessWidget {
  const _TechnicalProfileRows({required this.profile});

  final Map<String, Object?> profile;

  @override
  Widget build(BuildContext context) {
    final permissions = profile['effective_permissions'] is List
        ? List<Object?>.from(profile['effective_permissions']! as List)
        : profile['permission_codes'] is List
        ? List<Object?>.from(profile['permission_codes']! as List)
        : const <Object?>[];
    final memberships = valueRows(profile['role_memberships']);
    final rows = <(String, String)>[
      ('Tenant', valueText(profile, const ['tenant_slug'])),
      (
        'Til',
        valueText(profile, const ['organization_locale', 'preferred_language']),
      ),
      ('Vaqt mintaqasi', valueText(profile, const ['organization_timezone'])),
      ('Valyuta', valueText(profile, const ['primary_currency'])),
      ('Sessiya', valueText(profile, const ['session_id'])),
      (
        'Sessiya yaratilgan',
        _dateLabel(profile['session_created_at'], time: true),
      ),
      (
        'Oxirgi faollik',
        _dateLabel(profile['session_last_activity_at'], time: true),
      ),
      (
        'Sessiya tugashi',
        _dateLabel(profile['session_expires_at'], time: true),
      ),
      ('Read-only', profile['read_only_session'] == true ? 'Ha' : 'Yo‘q'),
      (
        'Rollar',
        memberships
            .map(
              (item) =>
                  valueText(item, const ['role', 'role_name', 'account_kind']),
            )
            .join(', '),
      ),
      ('Ruxsatlar', permissions.join(', ')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 142,
                  child: Text(
                    row.$1,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    row.$2.trim().isEmpty ? '—' : row.$2,
                    style: const TextStyle(fontFamily: Sf.mono, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProfileEditScreen extends StatefulWidget {
  const _ProfileEditScreen();

  @override
  State<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<_ProfileEditScreen> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _middle;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _birthdate;
  String _gender = '';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = PortalScope.read(context).profile;
    _first = TextEditingController(
      text: valueText(profile, const ['first_name'], fallback: ''),
    );
    _last = TextEditingController(
      text: valueText(profile, const ['last_name'], fallback: ''),
    );
    _middle = TextEditingController(
      text: valueText(profile, const ['middle_name'], fallback: ''),
    );
    _phone = TextEditingController(
      text: valueText(profile, const ['phone'], fallback: ''),
    );
    _email = TextEditingController(
      text: valueText(profile, const ['email'], fallback: ''),
    );
    _birthdate = TextEditingController(
      text: valueText(profile, const ['birthdate'], fallback: ''),
    );
    final rawGender = '${profile['gender'] ?? ''}'.trim().toLowerCase();
    _gender = switch (rawGender) {
      'm' || 'male' => 'm',
      'f' || 'female' => 'f',
      _ => '',
    };
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _middle.dispose();
    _phone.dispose();
    _email.dispose();
    _birthdate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PortalScope.read(context).updateProfile({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'middle_name': _middle.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'birthdate': _birthdate.text.trim().isEmpty
            ? null
            : _birthdate.text.trim(),
        'gender': _gender,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil saqlandi.')));
      Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilni tahrirlash')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'Ism'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _last,
                decoration: const InputDecoration(labelText: 'Familiya'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _middle,
                decoration: const InputDecoration(labelText: 'Otasining ismi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _birthdate,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tug‘ilgan sana',
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                onTap: _busy
                    ? null
                    : () async {
                        final now = DateTime.now();
                        final selected = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(_birthdate.text) ??
                              DateTime(now.year - 18),
                          firstDate: DateTime(now.year - 100),
                          lastDate: now,
                        );
                        if (selected == null) return;
                        _birthdate.text =
                            '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Jins'),
                items: const [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text('Ko‘rsatilmagan'),
                  ),
                  DropdownMenuItem(value: 'm', child: Text('Erkak')),
                  DropdownMenuItem(value: 'f', child: Text('Ayol')),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _gender = value ?? ''),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 14),
                _InlineMessage(text: error, error: true),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saqlanmoqda…' : 'Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordChangeScreen extends StatefulWidget {
  const _PasswordChangeScreen();

  @override
  State<_PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<_PasswordChangeScreen> {
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
      setState(() => _error = 'Yangi parollar mos emas yoki 8 belgidan qisqa.');
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parol yangilandi.')));
      Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parolni almashtirish')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _old,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Hozirgi parol'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yangi parol'),
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
                child: Text(_busy ? 'Yangilanmoqda…' : 'Parolni yangilash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

VoidCallback? _withId(Object? raw, void Function(int) action) {
  final id = valueInt(raw);
  return id == null ? null : () => action(id);
}
