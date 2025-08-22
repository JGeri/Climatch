import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:moon_phase/moon_phase.dart';
import 'features/weather/application/weather_controller.dart';
import 'core/utils/icon_mapper.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final wc = context.watch<WeatherController>();
    return Scaffold(
      backgroundColor: const Color(0xFF1f1f1f),
      body: RefreshIndicator(
        onRefresh: () => wc.refreshAll(),
        color: Colors.white,
        backgroundColor: Colors.black26,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.only(left: 20, top: 50),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              // Header + hero
              Container(
                padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
                child: Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wc.cityName ??
                                    (wc.locationError == null
                                        ? 'Loading…'
                                        : 'Unknown'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                wc.headerDateHu(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),

                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.air_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  wc.aqi?.toString() ?? '—',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 340,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            ClipPath(
                              clipper: const _TrapezoidClipper(
                                slant: 40,
                                flipVertical: true,
                                borderRadius: 50,
                              ),
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 50,
                                  right: 50,
                                  top: 25,
                                  bottom: 120,
                                ),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFfd60e8),
                                      Color(0xFF3763ee),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      wc.conditionText ?? '—',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        height: 0,
                                      ),
                                    ),
                                    Text(
                                      wc.tempC != null
                                          ? ' ${wc.tempC}°'
                                          : ' --°',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 128,
                                        fontWeight: FontWeight.bold,
                                        height: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 170,
                              child: Image(
                                height: 250,
                                image: AssetImage(wc.iconAsset),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Tabs + hourly list
              DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-25, 0),
                      child: SizedBox(
                        width: 250,
                        child: Stack(
                          children: [
                            TabBar(
                              labelStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: "GolosText",
                              ),
                              unselectedLabelColor: Colors.white54,
                              isScrollable: false,
                              dividerColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              indicator: const BoxDecoration(),
                              onTap: wc.onTabChanged,
                              tabs: const [
                                Tab(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text('Ma'),
                                  ),
                                ),
                                Tab(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text('Holnap'),
                                  ),
                                ),
                              ],
                            ),
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: FadingDotIndicator(
                                  color: Colors.white,
                                  radius: 2.0,
                                  bottomPadding: 6.0,
                                  slideDy: 8.0,
                                  duration: Duration(milliseconds: 220),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: _TabContent(onIndexChanged: wc.onTabChanged),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: wc.hourly.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 15),
                          itemBuilder: (context, index) {
                            final item = wc.hourly[index];
                            final iconAsset = IconMapper.fromOwmIcon(
                              item.condition,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: (index == 0 && wc.tabIndex == 0)
                                  ? BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFfd60e8),
                                          Color(0xFF3763ee),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                    )
                                  : BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),

                                      borderRadius: BorderRadius.circular(100),
                                    ),
                              child: SizedBox(
                                width: 45,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.hour}:00',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Image.asset(iconAsset, height: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item.temp}°',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Responsive half-circle slider clipped to bottom half without shrinking
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenW = MediaQuery.of(context).size.width;
                        const sidePadding = 20.0;
                        final double size = (screenW - sidePadding * 2).clamp(
                          180.0,
                          320.0,
                        );
                        return Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Napállás',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      width: size + 25,
                                      height: (size / 2) + 50,
                                      child: ClipRect(
                                        child: OverflowBox(
                                          alignment: Alignment.topCenter,
                                          minWidth: size,
                                          maxWidth: size,
                                          minHeight: size + 50,
                                          maxHeight: size + 50,
                                          child: SizedBox(
                                            width: size,
                                            height: size,
                                            child: IgnorePointer(
                                              ignoring: true,
                                              child: SleekCircularSlider(
                                                min: 0,
                                                max: (wc.dayLengthMin ?? 500)
                                                    .toDouble(),
                                                initialValue:
                                                    (wc.sunElapsedMin ?? 0)
                                                        .toDouble(),
                                                appearance:
                                                    CircularSliderAppearance(
                                                      size: size,
                                                      startAngle: 180,
                                                      angleRange: 180,
                                                      customWidths:
                                                          CustomSliderWidths(
                                                            trackWidth: 24,
                                                            progressBarWidth:
                                                                24,
                                                            shadowWidth: 0,
                                                            handlerSize: 24,
                                                          ),
                                                      customColors:
                                                          CustomSliderColors(
                                                            trackColors: [
                                                              Color(0xFF3763ee),
                                                              Color(0xFFfd60e8),
                                                            ],

                                                            progressBarColor:
                                                                Colors
                                                                    .transparent,
                                                            dotColor: Color(
                                                              0xffce2fb9,
                                                            ),
                                                            shadowColor: Colors
                                                                .transparent,
                                                            hideShadow: true,
                                                          ),
                                                      infoProperties:
                                                          InfoProperties(
                                                            mainLabelStyle:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .transparent,
                                                                  fontSize: 0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                    ),
                                                onChange: (_) {},
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: size + 40,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Napkelte\n${wc.formatHm(wc.sunriseSecUtc)}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Napnyugta\n${wc.formatHm(wc.sunsetSecUtc)}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: screenW - 40,
                                height: 250,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Holdállás',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      MoonWidget(
                                        date: DateTime.now(),
                                        resolution: 228,
                                        size: 104,
                                        moonColor: Color(0xffce2fb9),
                                        earthshineColor: Colors.grey.shade800,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Holdkelte\n${wc.formatHm(wc.moonriseSecUtc)}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Holdnyugta\n${wc.formatHm(wc.moonsetSecUtc)}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
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

// New: tab content that collapses to the intrinsic height of the active tab
class _TabContent extends StatefulWidget {
  const _TabContent({super.key, required this.onIndexChanged});
  final ValueChanged<int> onIndexChanged;
  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  TabController? _controller;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (_controller == newController) return;
    _controller?.removeListener(_onTab);
    _controller = newController;
    if (_controller != null) {
      _index = _controller!.index;
      // Notify parent after this frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onIndexChanged(_index);
      });
      _controller!.addListener(_onTab);
    }
  }

  void _onTab() {
    if (!mounted || _controller == null) return;
    if (_controller!.indexIsChanging) {
      setState(() => _index = _controller!.index);
      // Defer notification to next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onIndexChanged(_index);
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedSwitcher to swap minimal-height tab bodies
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: (_index == 0)
          ? const _TabBodyMa(key: ValueKey('ma'))
          : const _TabBodyHolnap(key: ValueKey('holnap')),
    );
  }
}

class _TabBodyMa extends StatelessWidget {
  const _TabBodyMa({super.key});
  @override
  Widget build(BuildContext context) {
    // Column with MainAxisSize.min ensures minimal vertical size
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Ma'),
        // Add more widgets; keep them non-expanding so height stays minimal
      ],
    );
  }
}

class _TabBodyHolnap extends StatelessWidget {
  const _TabBodyHolnap({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [Text('Holnap')],
    );
  }
}

class DotTabIndicator extends Decoration {
  final Color color;
  final double radius;

  const DotTabIndicator({required this.color, this.radius = 4.0});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DotPainter(color: color, radius: radius);
  }
}

class _DotPainter extends BoxPainter {
  final Color color;
  final double radius;

  _DotPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final double x = offset.dx + configuration.size!.width / 2;
    final double y = offset.dy + configuration.size!.height - radius - 4;
    canvas.drawCircle(Offset(x, y), radius, paint);
  }
}

class _TrapezoidClipper extends CustomClipper<Path> {
  const _TrapezoidClipper({
    this.slant = 30,
    this.flipVertical = false,
    this.borderRadius = 0,
  });

  // slant represents how much offset is applied to the slanted edge
  final double slant;
  final bool flipVertical;
  final double borderRadius;

  @override
  Path getClip(Size size) {
    final drop = slant.clamp(0, size.height).toDouble();

    // Define the trapezoid corners in order (clockwise)
    final points = flipVertical
        ? [
            // flipped vertically (upside down)
            Offset(0, size.height), // bottom-left
            Offset(
              size.width,
              size.height - drop,
            ), // near bottom-right (raised)
            Offset(size.width, 0), // top-right
            Offset(0, 0), // top-left
          ]
        : [
            // original (slanted top)
            Offset(0, 0), // top-left
            Offset(size.width, drop), // top-right (dropped)
            Offset(size.width, size.height), // bottom-right
            Offset(0, size.height), // bottom-left
          ];

    if (borderRadius <= 0) {
      final p = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(points[2].dx, points[2].dy)
        ..lineTo(points[3].dx, points[3].dy)
        ..close();
      return p;
    }

    // Build a rounded polygon path using quadratic beziers
    final rPath = Path();
    final n = points.length;

    Offset cornerPoint(int i) => points[(i + n) % n];

    Offset _limitRadius(Offset from, Offset to, double r) {
      final dist = (to - from).distance;
      final lim = dist / 2.0;
      final used = r.clamp(0, lim).toDouble();
      final dir = (to - from) / (dist == 0 ? 1 : dist);
      return from + dir * used;
    }

    for (int i = 0; i < n; i++) {
      final prev = cornerPoint(i - 1);
      final curr = cornerPoint(i);
      final next = cornerPoint(i + 1);

      final start = _limitRadius(curr, prev, borderRadius);
      final end = _limitRadius(curr, next, borderRadius);

      if (i == 0) {
        rPath.moveTo(start.dx, start.dy);
      } else {
        rPath.lineTo(start.dx, start.dy);
      }
      // round the corner using the corner as control point
      rPath.quadraticBezierTo(curr.dx, curr.dy, end.dx, end.dy);
    }

    rPath.close();
    return rPath;
  }

  @override
  bool shouldReclip(covariant _TrapezoidClipper oldClipper) =>
      oldClipper.slant != slant ||
      oldClipper.flipVertical != flipVertical ||
      oldClipper.borderRadius != borderRadius;
}

// Custom animated dot indicator overlay that fades out/down on previous tab and fades in/up on new tab
class FadingDotIndicator extends StatefulWidget {
  final Color color;
  final double radius;
  final double bottomPadding; // distance from bottom edge of TabBar
  final double slideDy; // how many pixels to slide up/down during fade
  final Duration duration;
  // New: horizontal inset from the start of each tab when aligning left

  const FadingDotIndicator({
    super.key,
    required this.color,
    this.radius = 3.0,
    this.bottomPadding = 6.0,
    this.slideDy = 8.0,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  State<FadingDotIndicator> createState() => _FadingDotIndicatorState();
}

class _FadingDotIndicatorState extends State<FadingDotIndicator>
    with TickerProviderStateMixin {
  TabController? _controller;
  late AnimationController _inCtrl;
  late AnimationController _outCtrl;
  int _currentIndex = 0;
  int? _outgoingIndex;

  @override
  void initState() {
    super.initState();
    _inCtrl = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1.0;
    _outCtrl = AnimationController(vsync: this, duration: widget.duration)
      ..value = 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (_controller == newController) return;
    _controller?.removeListener(_handleTabChange);
    _controller = newController;
    if (_controller != null) {
      _currentIndex = _controller!.index;
      _controller!.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    if (!mounted || _controller == null) return;
    if (_controller!.indexIsChanging) {
      // Start animations: current becomes outgoing, target becomes current
      setState(() {
        _outgoingIndex = _currentIndex;
        _currentIndex = _controller!.index;
      });
      _outCtrl
        ..reset()
        ..forward();
      _inCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    _inCtrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _controller?.length ?? 0;
    if (tabs == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double cell = w / tabs;
        // Current dot animations (fade in up)
        final inOpacity = CurvedAnimation(
          parent: _inCtrl,
          curve: Curves.easeOut,
        );
        final inDy = Tween<double>(
          begin: widget.slideDy,
          end: 0,
        ).animate(inOpacity);
        // Outgoing dot animations (fade out down)
        final outOpacity = CurvedAnimation(
          parent: _outCtrl,
          curve: Curves.easeIn,
        );
        final outDy = Tween<double>(
          begin: 0,
          end: widget.slideDy,
        ).animate(outOpacity);

        List<Widget> dots = [];

        // Incoming/current dot
        final double cx = cell * (_currentIndex + 0.5);
        dots.add(
          Positioned(
            left: cx - widget.radius,
            bottom: widget.bottomPadding,
            child: AnimatedBuilder(
              animation: _inCtrl,
              builder: (context, child) {
                return Opacity(
                  opacity: inOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, inDy.value),
                    child: child,
                  ),
                );
              },
              child: _Dot(color: widget.color, radius: widget.radius),
            ),
          ),
        );

        // Outgoing/previous dot
        if (_outgoingIndex != null) {
          final double px = cell * (_outgoingIndex! + 0.5);
          dots.add(
            Positioned(
              left: px - widget.radius,
              bottom: widget.bottomPadding,
              child: AnimatedBuilder(
                animation: _outCtrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1.0 - outOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, outDy.value),
                      child: child,
                    ),
                  );
                },
                child: _Dot(color: widget.color, radius: widget.radius),
              ),
            ),
          );
        }

        return Stack(children: dots);
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double radius;
  const _Dot({required this.color, required this.radius});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
