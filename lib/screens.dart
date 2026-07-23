import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets.dart';

typedef NavCb = void Function(String id);

enum AppRole { parent, student }

const _student = 'Akbarov Akmal';
const _parent = 'Akbarova Dilnoza';

// ─────────────────────────── HOME (Bugun) — student ───────────────────────────
class HomeScreen extends StatelessWidget {
  final NavCb onNav;
  const HomeScreen({super.key, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: 'Seshanba · 19 May',
        title: greetingTitle('Akbarov'),
        sub: 'Bugun 3 ta darsing bor',
        right: SoftButton('Ustozga', icon: Icons.chat_bubble_rounded, primary: true, bg: Sf.accent, onTap: () => onNav('messages')),
      ),
      const SfGrid(minTile: 150, children: [
        KpiCard(label: 'Davomat', value: '96%', valueColor: Sf.success, icon: Icons.check_rounded),
        KpiCard(label: 'Mening kartalarim', value: '↑12', valueColor: Sf.goldUp, icon: Icons.star_rounded),
        KpiCard(label: 'Down', value: '↓1', valueColor: Sf.danger),
        KpiCard(label: 'O‘rin · sinf', value: '#2', valueColor: Sf.accent),
      ]),
      const SizedBox(height: 18),
      SfTwoCol(
        left: SfCol([
          _Hero(
            onNav: onNav,
            eyebrow: 'KEYINGI DARS · 14 DAQIQADA',
            colors: const [Sf.accent, Color(0xFF9C6E14)],
            btn2Label: 'Materiallar',
            btn2Target: 'materials',
          ),
          _RecentCards(onNav: onNav, title: 'So‘nggi kartalarim'),
        ]),
        right: SfCol([
          _AiPreviewCard(onNav: onNav),
          const _TodayScheduleCard(),
        ]),
      ),
    ]);
  }
}

/// Horizontal strip of the three most recent star cards.
class _RecentCards extends StatelessWidget {
  final NavCb onNav;
  final String title;
  const _RecentCards({required this.onNav, required this.title});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      action: _MoreLink(onTap: () => onNav('cards')),
      child: SizedBox(
        height: 320 * 0.62 + 6,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 2),
          children: const [
            StarCard(up: true, scale: 0.62, recipient: 'Akbarov A.', reason: 'Mustaqil yechim', issuer: 'N.K.', when: '09:42', typeName: 'Yulduz'),
            SizedBox(width: 10),
            StarCard(up: true, scale: 0.62, recipient: 'Akbarov A.', reason: 'Aktivlik', issuer: 'N.K.', when: 'Du', typeName: 'Aktivlik'),
            SizedBox(width: 10),
            StarCard(up: false, scale: 0.62, recipient: 'Akbarov A.', reason: 'Uy ishi', issuer: 'N.K.', when: '8 May', typeName: 'Ogohl.'),
          ],
        ),
      ),
    );
  }
}

/// AI repetitor preview (student home right column).
class _AiPreviewCard extends StatelessWidget {
  final NavCb onNav;
  const _AiPreviewCard({required this.onNav});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'AI repetitor',
      child: InkWell(
        onTap: () => onNav('ai'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: AiBadge()),
          Text('“Kvadrat tenglamalarni mashq qilaylik. 3 ta misol tayyorladim — boshlaymizmi?”',
              style: Sf.serif(size: 15, color: Sf.ink, height: 1.35)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Sf.ink,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: () => onNav('ai'),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Text('Boshlash', style: Sf.t(size: 12, weight: FontWeight.w700, color: Sf.bg)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

/// Today's three lessons (shared by both roles' home right column).
class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard();
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Bugungi jadval',
      child: Column(children: [
        for (final r in const [
          ['09:00', 'Algebra', 'now'],
          ['10:00', 'Geometriya', ''],
          ['11:30', 'Ingliz tili', ''],
        ])
          _ScheduleRow(time: r[0], subject: r[1], now: r[2] == 'now', last: r[0] == '11:30'),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  final NavCb onNav;
  final String eyebrow;
  final List<Color> colors;
  final String btn1Label, btn1Target, btn2Label, btn2Target;
  const _Hero({
    required this.onNav,
    this.eyebrow = 'KEYINGI DARS · 14 DAQIQADA',
    this.colors = const [Sf.accent, Color(0xFF9C6E14)],
    this.btn1Label = 'To‘liq jadval',
    this.btn1Target = 'schedule',
    this.btn2Label = 'Materiallar',
    this.btn2Target = 'materials',
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          right: -34,
          top: -34,
          child: Opacity(opacity: 0.16, child: SfStar(size: 150, color: Colors.white)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow,
              style: Sf.t(size: 11, weight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.3)),
          const SizedBox(height: 8),
          Text('Algebra · 9-B', style: Sf.t(size: 26, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
          const SizedBox(height: 5),
          Text('09:00–09:45 · Xona 304 · Nigora Karimova',
              style: Sf.t(size: 13, color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 18),
          Row(children: [
            _HeroBtn(btn1Label, onTap: () => onNav(btn1Target)),
            const SizedBox(width: 8),
            _HeroBtn(btn2Label, ghost: true, onTap: () => onNav(btn2Target)),
          ]),
        ]),
      ]),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final bool ghost;
  final VoidCallback onTap;
  const _HeroBtn(this.label, {this.ghost = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: ghost ? Colors.transparent : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: ghost ? Border.all(color: Colors.white54) : null,
          ),
          child: Text(label,
              style: Sf.t(size: 13, weight: FontWeight.w700, color: ghost ? Colors.white : Sf.ink)),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String time, subject;
  final bool now, last;
  const _ScheduleRow({required this.time, required this.subject, required this.now, required this.last});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(children: [
        SizedBox(width: 48, child: Text(time, style: Sf.monoStyle(size: 12.5, weight: FontWeight.w600, color: Sf.ink2))),
        const SizedBox(width: 12),
        Expanded(child: Text(subject, style: Sf.t(size: 13, weight: FontWeight.w600))),
        if (now) const Pill('Hozir', tone: Tone.primary),
      ]),
    );
  }
}

class _MoreLink extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreLink({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Text('Hammasi ›', style: Sf.t(size: 12, weight: FontWeight.w600, color: Sf.primary)),
      );
}

// ─────────────────────────── GROUPS (Guruhlarim) ───────────────────────────
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const groups = [
      ['9-B Algebra', 'Nigora Karimova', 94, Sf.primary],
      ['10-V Geometriya', 'Bobur Aliyev', 88, Sf.accent],
      ['Ingliz B2', 'Aziz Tursunov', 92, Sf.success],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageHeader(eyebrow: '9-B · 14 yosh', title: Text('Guruhlarim'), sub: '3 ta guruh'),
      SfGrid(minTile: 280, children: [
        for (final g in groups)
          _GroupTile(name: g[0] as String, teacher: g[1] as String, att: g[2] as int, color: g[3] as Color),
      ]),
    ]);
  }
}

class _GroupTile extends StatelessWidget {
  final String name, teacher;
  final int att;
  final Color color;
  const _GroupTile({required this.name, required this.teacher, required this.att, required this.color});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => sfToast(context, name, tone: Sf.primary),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Sf.border),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: const SfStar(size: 18, color: Colors.white),
            ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: Sf.t(size: 14.5, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Row(children: [
              Avatar(teacher, size: 15),
              const SizedBox(width: 5),
              Text(teacher, style: Sf.t(size: 11.5, color: Sf.muted)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$att%',
              style: Sf.monoStyle(size: 15, weight: FontWeight.w700, color: att >= 92 ? Sf.success : Sf.warn)),
          Text('DAVOMAT', style: Sf.t(size: 9, color: Sf.muted, letterSpacing: 0.5)),
        ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────── ATTENDANCE (Davomatim) ───────────────────────────
class AttendanceScreen extends StatelessWidget {
  final AppRole role;
  const AttendanceScreen({super.key, this.role = AppRole.student});
  @override
  Widget build(BuildContext context) {
    const days = [
      ['19 May', 'present'], ['18 May', 'present'], ['15 May', 'late'], ['14 May', 'present'],
      ['13 May', 'present'], ['12 May', 'absent'], ['11 May', 'present'],
    ];
    Tone tn(String s) => s == 'present' ? Tone.success : (s == 'late' ? Tone.warn : Tone.danger);
    String lbl(String s) => s == 'present' ? 'Bor' : (s == 'late' ? 'Kechikdi' : 'Yo‘q');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
          eyebrow: role == AppRole.parent ? 'Akmal · 9-B' : 'Mening davomatim',
          title: const Text('Davomat'),
          sub: 'Oxirgi 30 kun · 96% ishtirok'),
      const SfGrid(minTile: 150, children: [
        KpiCard(label: 'Ishtirok', value: '96%', valueColor: Sf.success),
        KpiCard(label: 'Kechikish', value: '2', valueColor: Sf.warn),
        KpiCard(label: 'Sababsiz', value: '1', valueColor: Sf.danger),
        KpiCard(label: 'Jami dars', value: '48'),
      ]),
      const SizedBox(height: 16),
      SectionCard(
        title: 'Kunlik tarix',
        child: Column(children: [
          for (var i = 0; i < days.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: i < days.length - 1 ? const Border(bottom: BorderSide(color: Sf.border)) : null,
              ),
              child: Row(children: [
                SizedBox(width: 70, child: Text(days[i][0], style: Sf.monoStyle(size: 12.5, weight: FontWeight.w400, color: Sf.muted))),
                Expanded(child: Text('Algebra · 9-B', style: Sf.t(size: 13, weight: FontWeight.w600))),
                Pill(lbl(days[i][1]), tone: tn(days[i][1]), dot: true),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────── CARDS (Kartalarim) ───────────────────────────
class CardsScreen extends StatelessWidget {
  final AppRole role;
  const CardsScreen({super.key, this.role = AppRole.student});
  @override
  Widget build(BuildContext context) {
    const cards = [
      ['Yulduz karta', true, 'Mustaqil yechim · 3-misol', '19 May'],
      ['Aktivlik', true, 'Sinfdoshlarga yordam', '17 May'],
      ['Yulduz karta', true, 'Toza daftar', '12 May'],
      ['Ogohlantirish', false, 'Uy ishi tayyor emas', '8 May'],
      ['Yulduz karta', true, 'Olimpiada 2-bosqich', '5 May'],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: role == AppRole.parent ? 'Akmal · 9-B' : 'Mening yutuqlarim',
        title: const Text('Kartalar'),
        sub: '12 Up · 1 Down · bu oy',
        right: const Pill('↑ 12 Up karta', tone: Tone.success),
      ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Sf.surface,
          border: Border.all(color: Sf.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 26,
          runSpacing: 18,
          children: const [
            StarCard(up: true, scale: 1.0, recipient: 'Akbarov Akmal', reason: 'Mustaqil yechim · 3-misol', issuer: 'N. Karimova', when: '19.05 · 09:42', typeName: 'Yulduz karta'),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _CardStat(value: '↑12', label: 'Up karta', color: Sf.goldUp),
              SizedBox(width: 22),
              _CardStat(value: '↓1', label: 'Down karta', color: Sf.danger),
              SizedBox(width: 22),
              _CardStat(value: '#2', label: 'Sinfda o‘rin', color: Sf.accent),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'Karta tarixi',
        child: Column(children: [
          for (var i = 0; i < cards.length; i++)
            _CardHistoryRow(
              title: cards[i][0] as String,
              up: cards[i][1] as bool,
              reason: cards[i][2] as String,
              date: cards[i][3] as String,
              last: i == cards.length - 1,
            ),
        ]),
      ),
    ]);
  }
}

class _CardStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _CardStat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: Sf.monoStyle(size: 28, weight: FontWeight.w700, color: color)),
      const SizedBox(height: 3),
      Text(label.toUpperCase(), style: Sf.t(size: 10, weight: FontWeight.w600, color: Sf.muted, letterSpacing: 0.4)),
    ]);
  }
}

class _CardHistoryRow extends StatelessWidget {
  final String title, reason, date;
  final bool up, last;
  const _CardHistoryRow({required this.title, required this.up, required this.reason, required this.date, required this.last});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(children: [
        Container(
          width: 26,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: up ? const [Color(0xFFF6E0AC), Color(0xFFE9C272)] : const [Color(0xFFF0C9BE), Color(0xFFD88A75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0x1A000000)),
          ),
          child: SfStar(size: 11, color: up ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Sf.t(size: 13, weight: FontWeight.w700, color: up ? Sf.ink : Sf.danger)),
            Text('“$reason”', style: Sf.t(size: 11.5, color: Sf.muted, style: FontStyle.italic)),
          ]),
        ),
        Text(date, style: Sf.monoStyle(size: 11, weight: FontWeight.w400, color: Sf.muted)),
      ]),
    );
  }
}

// ─────────────────────────── MATERIALS (Materiallar) ───────────────────────────
class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final files = [
      ['Kvadrat tenglama.pdf', 'PDF · 8 bet', Icons.picture_as_pdf_rounded, Sf.danger],
      ['Funksiyalar.mp4', 'Video · 6:42', Icons.play_circle_fill_rounded, Sf.primary],
      ['Mashqlar.docx', '12 bet', Icons.description_rounded, Sf.accent],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageHeader(eyebrow: '9-B Algebra', title: Text('Materiallar'), sub: 'Ustoz yuklagan fayllar'),
      SectionCard(
        title: 'Fayllar',
        child: Column(children: [
          for (var i = 0; i < files.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: i < files.length - 1 ? const Border(bottom: BorderSide(color: Sf.border)) : null,
              ),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: files[i][3] as Color, borderRadius: BorderRadius.circular(8)),
                  child: Icon(files[i][2] as IconData, size: 19, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(files[i][0] as String, style: Sf.t(size: 13, weight: FontWeight.w600)),
                    Text(files[i][1] as String, style: Sf.monoStyle(size: 10.5, weight: FontWeight.w400, color: Sf.muted)),
                  ]),
                ),
                Builder(builder: (ctx) => _IconButton(
                  icon: Icons.download_rounded,
                  onTap: () => sfToast(ctx, 'Yuklab olindi', tone: Sf.success),
                )),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Sf.border),
          ),
          child: Icon(icon, size: 16, color: Sf.ink2),
        ),
      ),
    );
  }
}

// ─────────────────────────── SCHEDULE (Jadval) ───────────────────────────
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju'];
    final lessons = {
      'Du-0': ['Algebra', Sf.primary],
      'Se-0': ['Algebra', Sf.primary],
      'Se-1': ['Geom', Sf.accent],
      'Ch-0': ['Ingliz', Sf.success],
      'Pa-0': ['Algebra', Sf.primary],
      'Ju-1': ['Geom', Sf.accent],
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageHeader(eyebrow: 'Bu hafta', title: Text('Jadval'), sub: '9-B · haftalik dars jadvali'),
      SectionCard(
        title: 'Haftalik',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final d in days)
              Expanded(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(d, style: Sf.t(size: 11, weight: FontWeight.w700, color: Sf.muted)),
                  ),
                  for (var slot = 0; slot < 3; slot++)
                    Container(
                      height: 44,
                      margin: const EdgeInsets.fromLTRB(3, 0, 3, 6),
                      child: lessons['$d-$slot'] == null
                          ? const SizedBox()
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: lessons['$d-$slot']![1] as Color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(lessons['$d-$slot']![0] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Sf.t(size: 11, weight: FontWeight.w700, color: Colors.white)),
                            ),
                    ),
                ]),
              ),
          ],
        ),
      ),
    ]);
  }
}

// ─────────────────────────── MESSAGES (Xabarlar) ───────────────────────────
class MessagesScreen extends StatefulWidget {
  final AppRole role;
  const MessagesScreen({super.key, this.role = AppRole.student});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _ctrl = TextEditingController();
  final List<_Msg> _msgs = [
    _Msg("Assalomu alaykum! Akmal bugun a'lo ishladi 🌟", false, '09:48'),
    _Msg('Rahmat ustoz! Juda xursandmiz.', true, '10:02'),
    _Msg('Uy ishini ertaga tekshiramiz.', false, '10:05'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) {
      sfToast(context, 'Xabar bo‘sh', tone: Sf.warn);
      return;
    }
    setState(() {
      _msgs.add(_Msg(t, true, '10:06'));
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
          eyebrow: widget.role == AppRole.parent ? 'Ota-ona' : 'O‘quvchi',
          title: const Text('Xabarlar'),
          sub: 'Ustoz bilan to‘g‘ridan-to‘g‘ri'),
      Container(
        height: 460,
        decoration: BoxDecoration(
          color: Sf.surface,
          border: Border.all(color: Sf.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Sf.border))),
            child: Row(children: [
              const Avatar('Nigora Karimova', size: 38),
              const SizedBox(width: 11),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nigora Karimova', style: Sf.t(size: 14, weight: FontWeight.w700)),
                Text('● onlayn · Matematika', style: Sf.t(size: 11, color: Sf.success)),
              ]),
            ]),
          ),
          Expanded(
            child: Container(
              color: Sf.bg,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final m in _msgs) _Bubble(m)],
              ),
            ),
          ),
          _ChatInput(controller: _ctrl, onSend: _send),
        ]),
      ),
    ]);
  }
}

class _Msg {
  final String text;
  final bool out;
  final String time;
  final String? lead; // serif-italic lead word for incoming bubbles
  _Msg(this.text, this.out, this.time, {this.lead});
}

class _Bubble extends StatelessWidget {
  final _Msg m;
  const _Bubble(this.m);
  @override
  Widget build(BuildContext context) {
    final baseStyle = Sf.t(size: 13.5, height: 1.4, color: m.out ? Colors.white : Sf.ink);
    final Widget body = (m.lead != null && !m.out)
        ? RichText(
            text: TextSpan(style: baseStyle, children: [
              TextSpan(text: m.lead, style: Sf.serif(size: 15, color: Sf.ink)),
              TextSpan(text: ' ${m.text}'),
            ]),
          )
        : Text(m.text, style: baseStyle);
    return LayoutBuilder(builder: (ctx, c) {
      return Align(
        alignment: m.out ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: c.maxWidth * 0.76),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: m.out ? Sf.primary : Sf.surface,
            border: m.out ? null : Border.all(color: Sf.border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(m.out ? 16 : 4),
              bottomRight: Radius.circular(m.out ? 4 : 16),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            body,
            if (m.time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(m.time, style: Sf.t(size: 9, color: m.out ? Colors.white70 : Sf.muted)),
            ],
          ]),
        ),
      );
    });
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatInput({required this.controller, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Sf.border))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSend(),
            style: Sf.t(size: 13.5),
            decoration: InputDecoration(
              hintText: 'Xabar yozing...',
              hintStyle: Sf.t(size: 13.5, color: Sf.muted),
              filled: true,
              fillColor: Sf.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Sf.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Sf.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Sf.primary)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Sf.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(width: 42, height: 42, child: Icon(Icons.send_rounded, size: 16, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────── AI repetitor ───────────────────────────
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _ctrl = TextEditingController();
  final List<_Msg> _msgs = [
    _Msg('Kvadrat tenglamani qanday yechaman?', true, ''),
    _Msg('Diskriminant formulasidan boshlaymiz: D = b² − 4ac. Keling, birga misol yechamiz: x² − 5x + 6 = 0', false, '', lead: 'Oson!'),
    _Msg('D = 25 − 24 = 1', true, ''),
    _Msg('Aynan to‘g‘ri! 🎯 Endi ildizlarni toping: x = (5 ± 1) / 2', false, ''),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ask() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) {
      sfToast(context, 'Savol yozing', tone: Sf.warn);
      return;
    }
    setState(() {
      _msgs.add(_Msg(t, true, ''));
      _msgs.add(_Msg('Yaxshi savol! Keling birga tahlil qilamiz...', false, ''));
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: 'AI repetitor',
        title: RichText(
          text: TextSpan(
            style: Sf.t(size: 30, weight: FontWeight.w800, color: Sf.ink, letterSpacing: -0.9, height: 1.05),
            children: [
              const TextSpan(text: 'AI '),
              TextSpan(text: 'repetitor', style: Sf.serif(size: 30, color: Sf.ink)),
            ],
          ),
        ),
        sub: 'Darslaringizda yordam beradi',
      ),
      Container(
        height: 470,
        decoration: BoxDecoration(
          color: Sf.surface,
          border: Border.all(color: Sf.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Expanded(
            child: Container(
              color: Sf.bg,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final m in _msgs) _Bubble(m)],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(children: [
              for (final p in const ['Yana misol', 'Tushuntir', 'Test qil'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Builder(builder: (ctx) => _Chip(p, onTap: () => sfToast(ctx, p, tone: Sf.ai))),
                ),
            ]),
          ),
          _ChatInput(controller: _ctrl, onSend: _ask),
        ]),
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Chip(this.label, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.aiBg1,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Sf.aiBorder),
          ),
          child: Text(label, style: Sf.t(size: 12, weight: FontWeight.w600, color: Sf.ai)),
        ),
      ),
    );
  }
}

// ─────────────────────────── SETTINGS (Sozlamalar) ───────────────────────────
class SettingsScreen extends StatefulWidget {
  final AppRole role;
  const SettingsScreen({super.key, this.role = AppRole.student});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _tg = {'push': true, 'att': true, 'card': true, 'pay': true};

  @override
  Widget build(BuildContext context) {
    final isP = widget.role == AppRole.parent;
    final who = isP ? _parent : _student;
    final sub = isP ? 'Akmal · 9-B ona' : '9-B · 14 yosh';
    final accent = isP ? Sf.primary : Sf.accent;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: isP ? 'Ota-ona' : 'O‘quvchi',
        title: const Text('Sozlamalar'),
        sub: who,
        right: SoftButton('Ko‘rinish', icon: Icons.star_rounded, primary: true, onTap: () => sfToast(context, 'Ko‘rinish sozlamalari', tone: Sf.primary)),
      ),
      SfGrid(minTile: 300, children: [
        SectionCard(
          title: 'Profil',
          child: Row(children: [
            Avatar(who, size: 52, color: accent),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(who, style: Sf.t(size: 15, weight: FontWeight.w800)),
                Text(sub, style: Sf.t(size: 12, color: Sf.muted)),
              ]),
            ),
            SoftButton('Tahrir', onTap: () => sfToast(context, 'Profil tahriri', tone: Sf.primary)),
          ]),
        ),
        SectionCard(
          title: 'Bildirishnomalar',
          child: Column(children: [
            for (final r in const [
              ['push', 'Push xabarlar'],
              ['att', 'Davomat'],
              ['card', 'Yangi kartalar'],
              ['pay', 'To‘lov eslatmasi'],
            ])
              _ToggleRow(
                label: r[1],
                value: _tg[r[0]]!,
                last: r[0] == 'pay',
                onChanged: (v) {
                  setState(() => _tg[r[0]] = v);
                  sfToast(context, v ? 'Yoqildi' : 'O‘chirildi', tone: v ? Sf.success : Sf.muted);
                },
              ),
          ]),
        ),
        SectionCard(
          title: 'Ko‘rinish',
          child: Column(children: [
            for (final r in const [
              ['Rang', 'Saroy'],
              ['Layout', 'Sidebar'],
              ['Rejim', 'Yorug‘'],
              ['Til', 'O‘zbekcha'],
            ])
              _LinkRow(label: r[0], value: r[1], last: r[0] == 'Til'),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => sfToast(context, 'Chiqildi'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Sf.borderStrong),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.logout_rounded, size: 14, color: Sf.danger),
              const SizedBox(width: 6),
              Text('Chiqish', style: Sf.t(size: 13, weight: FontWeight.w600, color: Sf.danger)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value, last;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.last, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: Sf.t(size: 13)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Sf.primary,
          activeThumbColor: Colors.white,
        ),
      ]),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label, value;
  final bool last;
  const _LinkRow({required this.label, required this.value, required this.last});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => sfToast(context, 'Ko‘rinish sozlamalari', tone: Sf.primary),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: Sf.border)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: Sf.t(size: 13)),
            Text('$value ›', style: Sf.t(size: 12.5, color: Sf.muted)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════ PARENT (Ota-ona) screens ═══════════════════════

// ─────────────────────────── PARENT HOME (Bosh sahifa) ───────────────────────────
class ParentHomeScreen extends StatelessWidget {
  final NavCb onNav;
  const ParentHomeScreen({super.key, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: 'Seshanba · 19 May',
        title: greetingTitle('Akbarova'),
        sub: 'Farzandingiz · Akmal bugun maktabda',
        right: SoftButton('Ustozga yozish', icon: Icons.chat_bubble_rounded, primary: true, onTap: () => onNav('messages')),
      ),
      const SfGrid(minTile: 150, children: [
        KpiCard(label: 'Davomat', value: '96%', valueColor: Sf.success, icon: Icons.check_rounded),
        KpiCard(label: 'Up kartalar', value: '↑12', valueColor: Sf.goldUp, icon: Icons.star_rounded),
        KpiCard(label: 'Down', value: '↓1', valueColor: Sf.danger),
        KpiCard(label: 'Keyingi to‘lov', value: '25 May', valueColor: Sf.warn, icon: Icons.trending_up_rounded),
      ]),
      const SizedBox(height: 18),
      SfTwoCol(
        left: SfCol([
          _Hero(
            onNav: onNav,
            eyebrow: 'FARZANDINGIZ · HOZIR',
            colors: const [Sf.primary, Color(0xFF8B3E23)],
            btn1Label: 'To‘liq jadval',
            btn1Target: 'schedule',
            btn2Label: 'Davomat tarixi',
            btn2Target: 'attendance',
          ),
          _RecentCards(onNav: onNav, title: 'Akmalning so‘nggi kartalari'),
        ]),
        right: SfCol([
          _PaymentCard(onNav: onNav),
          _MessagePreviewCard(onNav: onNav),
          const _TodayScheduleCard(),
        ]),
      ),
    ]);
  }
}

/// "Ustozdan xabar" preview (parent home right column).
class _MessagePreviewCard extends StatelessWidget {
  final NavCb onNav;
  const _MessagePreviewCard({required this.onNav});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ustozdan xabar',
      child: InkWell(
        onTap: () => onNav('messages'),
        child: Row(children: [
          const Avatar('Nigora Karimova', size: 36),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nigora Karimova', style: Sf.t(size: 12.5, weight: FontWeight.w700)),
              Text('"Akmal bugun a\'lo ishladi!"', style: Sf.t(size: 11.5, color: Sf.muted)),
            ]),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Sf.primary, borderRadius: BorderRadius.circular(10)),
            child: Text('2', style: Sf.t(size: 11, weight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final NavCb onNav;
  const _PaymentCard({required this.onNav});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onNav('payments'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Sf.warn, Color(0xFF885A15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('KEYINGI TO‘LOV',
                style: Sf.t(size: 11, weight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.6)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
              child: Text('5 kun qoldi', style: Sf.t(size: 11, weight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(money(600000), style: Sf.monoStyle(size: 26, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 3),
          Text('Iyun oyi · 9-B Algebra · 25.05 gacha',
              style: Sf.t(size: 12, color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 14),
          Builder(builder: (ctx) => Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              onTap: () => sfToast(ctx, 'To‘lovga yo‘naltirilmoqda...', sub: 'Click / Payme', tone: Sf.primary),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                child: Text('To‘lash', style: Sf.t(size: 14, weight: FontWeight.w800, color: Sf.warn)),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────── FARZANDIM (child) ───────────────────────────
class ChildScreen extends StatelessWidget {
  final NavCb onNav;
  const ChildScreen({super.key, required this.onNav});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: 'Farzandim',
        title: const Text('Akbarov Akmal'),
        sub: '9-B · 14 yosh · DEMO-2026-00042',
        right: Builder(builder: (ctx) => SoftButton('Ustozga', icon: Icons.chat_bubble_rounded, primary: true,
            onTap: () => onNav('messages'))),
      ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Sf.surface,
          border: Border.all(color: Sf.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Avatar('Akbarov Akmal', size: 72, color: Sf.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Akbarov Akmal', style: Sf.t(size: 20, weight: FontWeight.w800)),
              Text('9-B Algebra · Nigora Karimova', style: Sf.t(size: 12.5, color: Sf.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: const [
                Pill('96% davomat', tone: Tone.success),
                Pill('#2 sinfda', tone: Tone.accent),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      const SfGrid(minTile: 150, children: [
        KpiCard(label: 'Davomat', value: '96%', valueColor: Sf.success),
        KpiCard(label: 'Up karta', value: '↑12', valueColor: Sf.goldUp),
        KpiCard(label: 'Down', value: '↓1', valueColor: Sf.danger),
        KpiCard(label: 'Guruh', value: '3'),
      ]),
      const SizedBox(height: 14),
      SectionCard(
        title: 'Ustozning izohi',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '“Akmal — sinfning eng kuchli o‘quvchilaridan. Kvadrat tenglamalarni tez o‘zlashtirdi. Olimpiadaga tayyorlamoqchiman.”',
            style: Sf.serif(size: 16, color: Sf.ink, height: 1.4),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────── TO‘LOVLAR (payments) ───────────────────────────
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const hist = [
      ['May', 'Click', 'paid', '7 May'],
      ['Aprel', 'Payme', 'paid', '4 Apr'],
      ['Mart', 'Naqd', 'paid', '6 Mar'],
      ['Iyun', '—', 'due', '25 May'],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        eyebrow: 'Akmal · 9-B Algebra',
        title: const Text('To‘lovlar'),
        sub: 'To‘lov tarixi va keyingi to‘lov',
        right: SoftButton('To‘lash', icon: Icons.trending_up_rounded, primary: true,
            onTap: () => sfToast(context, 'To‘lov oynasi ochildi', sub: 'Click / Payme / Uzcard', tone: Sf.primary)),
      ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Sf.surface,
          border: Border.all(color: Sf.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(builder: (ctx, c) {
          final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('KEYINGI TO‘LOV · IYUN', style: Sf.eyebrow()),
            const SizedBox(height: 6),
            Text(money(600000), style: Sf.monoStyle(size: 30, weight: FontWeight.w700, color: Sf.ink)),
            const SizedBox(height: 3),
            Text('25.05.2026 gacha · 5 kun qoldi', style: Sf.t(size: 12, color: Sf.muted)),
          ]);
          final methods = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in const ['Click', 'Payme', 'Uzcard'])
                Builder(builder: (bctx) => _PayMethod(m, onTap: () => sfToast(bctx, '$m orqali to‘lov', tone: Sf.primary))),
            ],
          );
          if (c.maxWidth >= 520) {
            return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: info),
              const SizedBox(width: 16),
              methods,
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            info,
            const SizedBox(height: 16),
            methods,
          ]);
        }),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'To‘lov tarixi',
        child: Column(children: [
          for (var i = 0; i < hist.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: i < hist.length - 1 ? const Border(bottom: BorderSide(color: Sf.border)) : null,
              ),
              child: Row(children: [
                SizedBox(width: 56, child: Text(hist[i][0], style: Sf.t(size: 13, weight: FontWeight.w700))),
                Expanded(
                  child: Row(children: [
                    Flexible(child: Text(money(600000), maxLines: 1, overflow: TextOverflow.ellipsis, style: Sf.monoStyle(size: 12.5, weight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    Flexible(child: Text(hist[i][1], maxLines: 1, overflow: TextOverflow.ellipsis, style: Sf.t(size: 11, color: Sf.muted))),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(hist[i][3], style: Sf.monoStyle(size: 11, weight: FontWeight.w400, color: Sf.muted)),
                const SizedBox(width: 8),
                Pill(hist[i][2] == 'paid' ? 'To‘langan' : 'Kutilmoqda',
                    tone: hist[i][2] == 'paid' ? Tone.success : Tone.warn, dot: true),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _PayMethod extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PayMethod(this.label, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Sf.borderStrong, width: 1.5),
          ),
          child: Text(label, style: Sf.t(size: 13, weight: FontWeight.w700, color: Sf.ink)),
        ),
      ),
    );
  }
}
