import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

void sfToast(BuildContext context, String msg, {String? sub, Color? tone}) {
  final c = tone ?? Sf.ink;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Sf.ink,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg,
                    style: Sf.t(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Sf.bg,
                    ),
                  ),
                  if (sub != null)
                    Text(sub, style: Sf.t(size: 11, color: Sf.muted2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

/// Five-point StarForge star.
class SfStar extends StatelessWidget {
  final double size;
  final Color color;
  final Color? holeColor;
  const SfStar({
    super.key,
    this.size = 24,
    this.color = Sf.ink,
    this.holeColor,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(color, holeColor),
    ),
  );
}

class _StarPainter extends CustomPainter {
  final Color color;
  final Color? holeColor;
  _StarPainter(this.color, this.holeColor);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    final path = Path();
    const pts = [
      [16.0, 1.0],
      [19.4, 11.2],
      [29.9, 11.5],
      [21.3, 17.6],
      [24.5, 27.9],
      [16.0, 21.4],
      [7.5, 27.9],
      [10.7, 17.6],
      [2.1, 11.5],
      [12.6, 11.2],
    ];
    path.moveTo(pts[0][0] * s, pts[0][1] * s);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0] * s, pts[i][1] * s);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    if (holeColor != null) {
      canvas.drawCircle(
        Offset(16 * s, 16 * s),
        2.2 * s,
        Paint()..color = holeColor!,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const Avatar(this.name, {super.key, this.size = 36, this.color});
  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .map((p) => p.isEmpty ? '' : p[0])
        .take(2)
        .join()
        .toUpperCase();
    const palette = [
      Color(0xFFB85535),
      Color(0xFFD89A2E),
      Color(0xFF4F7B3B),
      Color(0xFF2A6F9F),
      Color(0xFF7A4A82),
      Color(0xFFA55A24),
      Color(0xFF3F6E5C),
    ];
    final hash = name.codeUnits.fold<int>(0, (a, c) => a + c) % palette.length;
    return Semantics(
      image: true,
      label: '$name avatari',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color ?? palette[hash],
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: Sf.t(
              size: size * 0.4,
              weight: FontWeight.w700,
              color: Sf.surface,
            ),
          ),
        ),
      ),
    );
  }
}

enum Tone { primary, success, warn, danger, accent, neutral }

class Pill extends StatelessWidget {
  final String text;
  final Tone tone;
  final bool dot;
  const Pill(
    this.text, {
    super.key,
    this.tone = Tone.neutral,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = _color(tone);
    final bg = _soft(tone);
    return Container(
      padding: EdgeInsets.fromLTRB(dot ? 8 : 10, 4, 10, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: Sf.t(size: 11, weight: FontWeight.w700, color: c),
          ),
        ],
      ),
    );
  }

  static Color _color(Tone t) => switch (t) {
    Tone.primary => Sf.primary,
    Tone.success => Sf.success,
    Tone.warn => Sf.warn,
    Tone.danger => Sf.danger,
    Tone.accent => Sf.accentInk,
    Tone.neutral => Sf.muted,
  };
  static Color _soft(Tone t) => switch (t) {
    Tone.primary => Sf.primarySoft,
    Tone.success => Sf.successSoft,
    Tone.warn => Sf.warnSoft,
    Tone.danger => Sf.dangerSoft,
    Tone.accent => Sf.accentSoft,
    Tone.neutral => Sf.surface2,
  };
}

/// Section card with header + body — matches `.fam-card`.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;
  final EdgeInsets bodyPadding;
  const SectionCard({
    super.key,
    required this.title,
    this.action,
    required this.child,
    this.bodyPadding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Sf.surface,
        border: Border.all(color: Sf.border),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Sf.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Sf.t(size: 13.5, weight: FontWeight.w700),
                  ),
                ),
                ?action,
              ],
            ),
          ),
          Padding(padding: bodyPadding, child: child),
        ],
      ),
    );
  }
}

/// KPI mini-card — matches `.fam-kpi`.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Sf.ink,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Sf.surface,
        border: Border.all(color: Sf.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sf.t(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: Sf.muted,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, size: 14, color: valueColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Sf.monoStyle(
              size: 24,
              weight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page header — eyebrow + big title + sub + optional right action.
class PageHeader extends StatelessWidget {
  final String eyebrow;
  final Widget title;
  final String? sub;
  final Widget? right;
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.sub,
    this.right,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: Sf.eyebrow()),
                const SizedBox(height: 7),
                DefaultTextStyle(
                  style: Sf.t(
                    size: constraints.maxWidth < 420 ? 25 : 30,
                    weight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.05,
                  ),
                  child: title,
                ),
                if (sub != null) ...[
                  const SizedBox(height: 5),
                  Text(sub!, style: Sf.t(size: 13, color: Sf.muted)),
                ],
              ],
            ),
          );
          if (constraints.maxWidth < 560 && right != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 12), right!],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              if (right != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: right!,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// "Assalomu alaykum, [first]" with the name in italic serif — matches the web `FamH` title.
Widget greetingTitle(String first) => RichText(
  text: TextSpan(
    style: Sf.t(
      size: 30,
      weight: FontWeight.w800,
      color: Sf.ink,
      letterSpacing: -0.9,
      height: 1.05,
    ),
    children: [
      const TextSpan(text: 'Assalomu alaykum, '),
      TextSpan(
        text: first,
        style: Sf.serif(size: 30, color: Sf.ink),
      ),
    ],
  ),
);

class SoftButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool primary;
  final Color? bg;
  const SoftButton(
    this.label, {
    super.key,
    this.icon,
    required this.onTap,
    this.primary = false,
    this.bg,
  });
  @override
  Widget build(BuildContext context) {
    final isP = primary;
    return Material(
      color: isP ? (bg ?? Sf.primary) : Sf.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isP ? Colors.transparent : Sf.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isP ? Colors.white : Sf.ink),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Sf.t(
                    size: 13,
                    weight: FontWeight.w600,
                    color: isP ? Colors.white : Sf.ink,
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

/// The signature Up/Down star card.
class StarCard extends StatelessWidget {
  final bool up;
  final double scale; // 0.62 sm, 0.82 md, 1.0 lg
  final String recipient;
  final String reason;
  final String issuer;
  final String when;
  final String typeName;
  const StarCard({
    super.key,
    this.up = true,
    this.scale = 0.82,
    required this.recipient,
    required this.reason,
    required this.issuer,
    required this.when,
    required this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    final grad = up
        ? const [Color(0xFFF6E0AC), Color(0xFFE9C272)]
        : const [Color(0xFFF0C9BE), Color(0xFFD88A75)];
    final border = up ? const Color(0xFFC49A3A) : const Color(0xFFA14026);
    final accent = up ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C);
    final inkC = up ? const Color(0xFF3A2406) : const Color(0xFF2D0F08);
    final chip = const Color(0x99FFFCF5);

    return Container(
      width: 240 * scale,
      height: 320 * scale,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0x2E361E0E),
            blurRadius: 20 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30 * scale,
            top: -30 * scale,
            child: Opacity(
              opacity: 0.18,
              child: SfStar(size: 140 * scale, color: accent),
            ),
          ),
          Positioned(
            right: -20 * scale,
            bottom: -20 * scale,
            child: Opacity(
              opacity: 0.08,
              child: SfStar(size: 100 * scale, color: accent),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      up ? '↑ UP CARD' : '↓ DOWN CARD',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sf.t(
                        size: 9 * scale,
                        weight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 1.4 * scale,
                      ),
                    ),
                  ),
                  SfStar(size: 18 * scale, color: accent),
                ],
              ),
              SizedBox(height: 8 * scale),
              Text(
                typeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sf.serif(size: 22 * scale, color: inkC, height: 1.05),
              ),
              SizedBox(height: 10 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Text(
                  recipient,
                  style: Sf.t(
                    size: 10 * scale,
                    weight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              if (reason.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.only(left: 8 * scale),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: accent, width: 2 * scale),
                      ),
                    ),
                    child: Text(
                      '“$reason”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sf.t(
                        size: 11 * scale,
                        color: inkC,
                        style: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 10 * scale),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      issuer,
                      maxLines: 1,
                      style: Sf.monoStyle(
                        size: 9 * scale,
                        weight: FontWeight.w400,
                        color: accent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4 * scale),
                  Text(
                    when,
                    maxLines: 1,
                    style: Sf.monoStyle(
                      size: 9 * scale,
                      weight: FontWeight.w400,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiBadge extends StatelessWidget {
  final String label;
  const AiBadge({super.key, this.label = 'Repetitor'});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Sf.aiBg1, Sf.aiBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Sf.aiBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ai', style: Sf.serif(size: 14, color: Sf.ai)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Sf.t(
                size: 11,
                weight: FontWeight.w700,
                color: Sf.ai,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted pattern background like `.sf-canvas-bg`.
class DotPattern extends StatelessWidget {
  final Widget child;
  const DotPattern({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotPainter(), child: child);
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1A361E0E);
    const gap = 22.0;
    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Responsive auto-fit grid — mirrors CSS `repeat(auto-fit, minmax(minTile, 1fr))`.
class SfGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTile;
  final double gap;
  final int? maxCols;
  const SfGrid({
    super.key,
    required this.children,
    this.minTile = 150,
    this.gap = 12,
    this.maxCols,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        var cols = ((w + gap) / (minTile + gap)).floor();
        final cap = maxCols ?? children.length;
        cols = cols.clamp(1, cap == 0 ? 1 : cap);
        if (cols > children.length) cols = children.length;
        if (cols < 1) cols = 1;
        final tile = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final ch in children) SizedBox(width: tile, child: ch),
          ],
        );
      },
    );
  }
}

/// Two-column grid that collapses to a stack below [breakpoint] — mirrors
/// `.fam-grid2` (minmax(0,1.4fr) minmax(0,1fr), stacks under 1100px).
class SfTwoCol extends StatelessWidget {
  final Widget left, right;
  final double breakpoint;
  final int leftFlex, rightFlex;
  final double gap;
  const SfTwoCol({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 1100,
    this.leftFlex = 14,
    this.rightFlex = 10,
    this.gap = 16,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: gap),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

/// Vertical stack with uniform gaps — mirrors `.fam-col { gap: 14px }`.
class SfCol extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  const SfCol(this.children, {super.key, this.gap = 14});
  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: out,
    );
  }
}

String money(int uzs) {
  final s = uzs.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${buf.toString()} so‘m';
}

double degToRad(double d) => d * math.pi / 180;
