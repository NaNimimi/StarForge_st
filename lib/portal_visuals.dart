part of 'portal_app.dart';

/// A single, labelled value rendered by [CompactBarChart].
class PortalBarDatum {
  const PortalBarDatum({
    required this.label,
    required this.value,
    this.detail,
    this.color,
    this.icon,
  });

  final String label;
  final double value;
  final String? detail;
  final Color? color;
  final IconData? icon;
}

// Library-local aliases keep the portal part files compact while preserving a
// public API for widget tests and standalone screens.
typedef _PortalBarDatum = PortalBarDatum;

/// A compact radial KPI that can be explored with mouse, keyboard, or touch.
///
/// [value] is a fraction from 0 to 1. Values outside that range are clamped so
/// untrusted API data never breaks the chart layout.
class InteractiveRingChart extends StatefulWidget {
  const InteractiveRingChart({
    super.key,
    required this.value,
    required this.label,
    this.detail,
    this.color,
    this.size = 136,
    this.onTap,
    this.centerIcon,
  });

  final double value;
  final String label;
  final String? detail;
  final Color? color;
  final double size;
  final VoidCallback? onTap;
  final IconData? centerIcon;

  @override
  State<InteractiveRingChart> createState() => InteractiveRingChartState();
}

typedef _InteractiveRingChart = InteractiveRingChart;

class InteractiveRingChartState extends State<InteractiveRingChart> {
  bool _hovered = false;
  bool _focused = false;
  bool _pinned = false;

  double get _safeValue => widget.value.clamp(0.0, 1.0);
  bool get _isActive => _hovered || _focused || _pinned;

  void _activate() {
    setState(() => _pinned = !_pinned);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.color ?? scheme.primary;
    final percentage = (_safeValue * 100).round();
    final explanation = widget.detail ?? '${widget.label}: $percentage%';
    final diameter = widget.size.clamp(92.0, 220.0);

    return Semantics(
      container: true,
      button: true,
      toggled: _pinned,
      label: widget.label,
      value: '$percentage%',
      hint: '$explanation. Tafsilotlarni ochish uchun bosing.',
      onTap: _activate,
      child: Tooltip(
        message: explanation,
        waitDuration: const Duration(milliseconds: 350),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _activate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: diameter + 32,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isActive ? accent : scheme.outlineVariant,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              widget.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isActive ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 19,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox.square(
                        dimension: diameter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: _safeValue),
                          duration: const Duration(milliseconds: 950),
                          curve: Curves.easeOutQuart,
                          builder: (context, animatedValue, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _PremiumRingPainter(
                                      progress: animatedValue,
                                      accent: accent,
                                      track: accent.withValues(alpha: 0.1),
                                      active: _isActive,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: diameter * 0.66,
                                  height: diameter * 0.66,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.surface.withValues(
                                      alpha: 0.9,
                                    ),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      // The ring can be as small as 60 px inside.
                                      // At large accessibility scales, the icon
                                      // and denominator are redundant (the outer
                                      // Semantics node already announces both),
                                      // so keep the percentage large and legible.
                                      final largeText =
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(16) >=
                                          24;
                                      return Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (!largeText &&
                                                  widget.centerIcon !=
                                                      null) ...[
                                                Icon(
                                                  widget.centerIcon,
                                                  size: diameter * 0.17,
                                                  color: accent,
                                                ),
                                                SizedBox(
                                                  height: diameter * 0.025,
                                                ),
                                              ],
                                              Text(
                                                '${(animatedValue * 100).round()}%',
                                                maxLines: 1,
                                                style: Sf.monoStyle(
                                                  size: 21,
                                                  weight: FontWeight.w700,
                                                  color: scheme.onSurface,
                                                ),
                                              ),
                                              if (!largeText) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '100% dan',
                                                  maxLines: 1,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isActive
                            ? Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 13),
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Text(
                                  explanation,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumRingPainter extends CustomPainter {
  const _PremiumRingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.active,
  });

  final double progress;
  final Color accent;
  final Color track;
  final bool active;

  static const _fullCircle = 6.283185307179586;
  static const _top = -1.5707963267948966;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = (size.shortestSide * 0.085).clamp(8.0, 16.0);
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + 2);
    final cap = StrokeCap.round;

    canvas.drawArc(
      arcRect,
      _top,
      _fullCircle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = cap
        ..color = track,
    );

    if (progress <= 0) return;
    if (active) {
      canvas.drawArc(
        arcRect,
        _top,
        _fullCircle * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 7
          ..strokeCap = cap
          ..color = accent.withValues(alpha: 0.08),
      );
    }

    canvas.drawArc(
      arcRect,
      _top,
      _fullCircle * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = cap
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        accent != oldDelegate.accent ||
        track != oldDelegate.track ||
        active != oldDelegate.active;
  }
}

/// Dense horizontal comparison chart with hover, focus, and tap details.
class CompactBarChart extends StatefulWidget {
  const CompactBarChart({
    super.key,
    required this.items,
    this.title,
    this.maxValue = 100,
    this.valueSuffix = '%',
    this.onSelected,
  });

  final List<PortalBarDatum> items;
  final String? title;
  final double maxValue;
  final String valueSuffix;
  final ValueChanged<int>? onSelected;

  @override
  State<CompactBarChart> createState() => CompactBarChartState();
}

typedef _CompactBarChart = CompactBarChart;

class CompactBarChartState extends State<CompactBarChart> {
  int? _selectedIndex;
  int? _hoveredIndex;
  int? _focusedIndex;

  int? get _activeIndex => _hoveredIndex ?? _focusedIndex ?? _selectedIndex;

  String _format(double value) {
    final normalized = value.isFinite ? value : 0;
    final number = normalized.roundToDouble() == normalized
        ? '${normalized.toInt()}'
        : normalized.toStringAsFixed(1);
    return '$number${widget.valueSuffix}';
  }

  void _select(int index) {
    setState(() => _selectedIndex = _selectedIndex == index ? null : index);
    widget.onSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = widget.maxValue > 0 && widget.maxValue.isFinite
        ? widget.maxValue
        : 1.0;

    return Semantics(
      container: true,
      label: widget.title ?? 'Ko‘rsatkichlar diagrammasi',
      child: _SectionCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 11),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.stacked_bar_chart_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? 'Natijalar dinamikasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Ustiga keling yoki batafsil ko‘rish uchun bosing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        '${widget.items.length} ta',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.query_stats_rounded,
                        size: 34,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hozircha ko‘rsatkich yo‘q',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    children: [
                      for (var index = 0; index < widget.items.length; index++)
                        _PremiumBarRow(
                          item: widget.items[index],
                          index: index,
                          ratio: (widget.items[index].value / maxValue).clamp(
                            0.0,
                            1.0,
                          ),
                          valueText: _format(widget.items[index].value),
                          active: _activeIndex == index,
                          selected: _selectedIndex == index,
                          onHover: (value) => setState(
                            () => _hoveredIndex = value ? index : null,
                          ),
                          onFocus: (value) => setState(
                            () => _focusedIndex = value ? index : null,
                          ),
                          onTap: () => _select(index),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBarRow extends StatelessWidget {
  const _PremiumBarRow({
    required this.item,
    required this.index,
    required this.ratio,
    required this.valueText,
    required this.active,
    required this.selected,
    required this.onHover,
    required this.onFocus,
    required this.onTap,
  });

  final PortalBarDatum item;
  final int index;
  final double ratio;
  final String valueText;
  final bool active;
  final bool selected;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onFocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = item.color ?? scheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      value: valueText,
      hint: item.detail == null
          ? 'Batafsil ko‘rish uchun bosing'
          : '${item.detail}. Batafsil ko‘rish uchun bosing',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: Focus(
            onFocusChange: onFocus,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
                  decoration: BoxDecoration(
                    color: active
                        ? accent.withValues(alpha: 0.085)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? accent.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? accent
                                    : accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: item.icon != null
                                  ? Icon(
                                      item.icon,
                                      size: 16,
                                      color: active ? scheme.onPrimary : accent,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: active
                                                ? scheme.onPrimary
                                                : accent,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: active
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? accent.withValues(alpha: 0.14)
                                    : scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                valueText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: active
                                      ? accent
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          height: active ? 11 : 8,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (var marker = 0; marker < 3; marker++)
                                    Container(
                                      width: 1,
                                      color: scheme.surface.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                ],
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(end: ratio),
                                duration: const Duration(milliseconds: 760),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, _) => Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: FractionallySizedBox(
                                    widthFactor: value,
                                    heightFactor: 1,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: active && item.detail != null
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    40,
                                    9,
                                    4,
                                    0,
                                  ),
                                  child: Text(
                                    item.detail!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium KPI tile with a clear trend, progress state, and hover feedback.
class RichMetricCard extends StatefulWidget {
  const RichMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.eyebrow,
    this.caption,
    this.accent,
    this.progress,
    this.trend,
    this.trendPositive = true,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? eyebrow;
  final String? caption;
  final Color? accent;
  final double? progress;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;

  @override
  State<RichMetricCard> createState() => _RichMetricCardState();
}

typedef _RichMetricCard = RichMetricCard;

class _RichMetricCardState extends State<RichMetricCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.accent ?? scheme.primary;
    final progress = widget.progress?.clamp(0.0, 1.0);
    final active = _hovered || _focused;
    final trendColor = widget.trendPositive ? Sf.success : scheme.error;

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.title,
      value: widget.value,
      hint: widget.caption,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: AnimatedScale(
            scale: active ? 1.012 : 1,
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(26),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 194),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: active
                          ? accent.withValues(alpha: 0.58)
                          : scheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? accent.withValues(alpha: 0.17)
                            : scheme.shadow.withValues(alpha: 0.07),
                        blurRadius: active ? 28 : 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -52,
                          right: -42,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: active ? 150 : 132,
                            height: active ? 150 : 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accent.withValues(alpha: 0.2),
                                  accent.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: 0,
                          top: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: active ? 5 : 3,
                            decoration: BoxDecoration(
                              color: accent,
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.45),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 43,
                                      height: 43,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            accent,
                                            Color.lerp(
                                              accent,
                                              scheme.tertiary,
                                              0.32,
                                            )!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 13,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        widget.icon,
                                        size: 22,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (widget.trend != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: trendColor.withValues(
                                            alpha: 0.11,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          border: Border.all(
                                            color: trendColor.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              widget.trendPositive
                                                  ? Icons.north_east_rounded
                                                  : Icons.south_east_rounded,
                                              size: 14,
                                              color: trendColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.trend!,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: trendColor,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Icon(
                                        active
                                            ? Icons.arrow_outward_rounded
                                            : Icons.more_horiz_rounded,
                                        color: active
                                            ? accent
                                            : scheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 17),
                                if (widget.eyebrow != null) ...[
                                  Text(
                                    widget.eyebrow!.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color: scheme.onSurface,
                                              fontWeight: FontWeight.w900,
                                              height: 1,
                                              letterSpacing: -0.9,
                                            ),
                                      ),
                                    ),
                                    if (progress != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text(
                                          '${(progress * 100).round()}%',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: accent,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (progress != null) ...[
                                  const SizedBox(height: 13),
                                  SizedBox(
                                    height: 7,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.11,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                        ),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(end: progress),
                                          duration: const Duration(
                                            milliseconds: 850,
                                          ),
                                          curve: Curves.easeOutQuart,
                                          builder: (context, value, _) => Align(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            child: FractionallySizedBox(
                                              widthFactor: value,
                                              heightFactor: 1,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      accent.withValues(
                                                        alpha: 0.58,
                                                      ),
                                                      accent,
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (widget.caption != null) ...[
                                  const SizedBox(height: 9),
                                  Text(
                                    widget.caption!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Information-dense event row for schedules, payments, grades, and messages.
class PortalActivityCard extends StatefulWidget {
  const PortalActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.time,
    this.status,
    this.statusColor,
    this.progress,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? time;
  final String? status;
  final Color? statusColor;
  final double? progress;
  final VoidCallback? onTap;

  @override
  State<PortalActivityCard> createState() => _PortalActivityCardState();
}

class _PortalActivityCardState extends State<PortalActivityCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.statusColor ?? scheme.primary;
    final progress = widget.progress?.clamp(0.0, 1.0);
    final active = _hovered || _focused;

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.title,
      value: widget.status,
      hint: widget.subtitle,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: AnimatedScale(
            scale: active ? 1.006 : 1,
            duration: const Duration(milliseconds: 180),
            child: _SectionCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
                    decoration: BoxDecoration(
                      color: active
                          ? accent.withValues(alpha: 0.045)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: active
                            ? accent.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 47,
                                height: 47,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accent.withValues(alpha: 0.18),
                                      accent.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: accent,
                                  size: 23,
                                ),
                              ),
                              PositionedDirectional(
                                end: -2,
                                bottom: -2,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent,
                                    border: Border.all(
                                      color: scheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: scheme.onSurface,
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                            ),
                                      ),
                                    ),
                                    if (widget.time != null) ...[
                                      const SizedBox(width: 9),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          widget.time!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  maxLines: active ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                                if (widget.status != null ||
                                    progress != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (widget.status != null)
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 130,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.11,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: accent.withValues(
                                                alpha: 0.17,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            widget.status!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: accent,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                      if (progress != null) ...[
                                        if (widget.status != null)
                                          const SizedBox(width: 10),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 6,
                                              color: accent,
                                              backgroundColor: accent
                                                  .withValues(alpha: 0.1),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          '${(progress * 100).round()}%',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: accent,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.onTap != null) ...[
                            const SizedBox(width: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(top: 11),
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? accent.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: active
                                    ? accent
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
