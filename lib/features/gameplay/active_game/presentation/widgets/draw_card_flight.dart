import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../model/card_model.dart';
import 'back_card_widget.dart';
import 'front_card_widget.dart';

/// How the flying card's face is shown.
enum CardFlightFace {
  /// Stay face-down for the whole flight.
  hidden,

  /// Stay face-up for the whole flight.
  visible,

  /// Travel face-down, then flip face-up at the destination.
  reveal,

  /// Travel face-up, then flip face-down at the destination.
  conceal,
}

/// Overlay that flies a card from [sourceKey] to [destKey], with an optional
/// flip at the end. Parent hides the static destination until [onCompleted].
class DrawCardFlight extends StatefulWidget {
  const DrawCardFlight({
    super.key,
    required this.card,
    required this.face,
    required this.sourceKey,
    required this.destKey,
    required this.onCompleted,
    this.onStarted,
    this.holdAfter = Duration.zero,
    this.arcHeight = 22,
    this.flipAtEnd = false,
  });

  final CardModel card;
  final CardFlightFace face;
  final GlobalKey sourceKey;
  final GlobalKey destKey;
  final VoidCallback onCompleted;
  final VoidCallback? onStarted;
  final Duration holdAfter;

  /// Vertical bulge along the path. 0 flies in a straight line.
  final double arcHeight;

  /// If true, the card finishes traveling before it starts flipping.
  final bool flipAtEnd;

  @override
  State<DrawCardFlight> createState() => _DrawCardFlightState();
}

class _DrawCardFlightState extends State<DrawCardFlight> with SingleTickerProviderStateMixin {
  static const Size _cardSize = Size(40, 60);
  static const double _peakScale = 0.06;
  static const double _peakTilt = 0.06;
  static const Duration _flipDuration = Duration(milliseconds: 780);
  static const Duration _slideDuration = Duration(milliseconds: 420);

  final GlobalKey _layerKey = GlobalKey();

  late final AnimationController _controller;
  late final Animation<double> _travel;
  late final Animation<double> _flip;

  Offset? _start;
  Offset? _end;
  bool _started = false;
  bool _completed = false;
  Timer? _holdTimer;

  bool get _flips => widget.face == CardFlightFace.reveal || widget.face == CardFlightFace.conceal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _flips ? _flipDuration : _slideDuration,
    );
    final travelEnd = widget.flipAtEnd ? 0.62 : 0.68;
    final flipStart = widget.flipAtEnd ? 0.62 : 0.52;
    _travel = CurvedAnimation(
      parent: _controller,
      curve: _flips ? Interval(0, travelEnd, curve: Curves.easeInOutCubic) : Curves.easeInOutCubic,
    );
    _flip = CurvedAnimation(
      parent: _controller,
      curve: Interval(flipStart, 1, curve: Curves.easeInOutCubic),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlight());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_completed || !mounted) return;
    if (widget.holdAfter > Duration.zero) {
      _holdTimer?.cancel();
      _holdTimer = Timer(widget.holdAfter, _complete);
      return;
    }
    _complete();
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  Offset? _globalCenter(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Widget _faceAt(double angle) {
    final showFrontAfterFlip = angle > math.pi / 2;
    switch (widget.face) {
      case CardFlightFace.hidden:
        return BackCard(cardModel: widget.card, tight: true);
      case CardFlightFace.visible:
        return FrontCard(cardModel: widget.card, tight: true);
      case CardFlightFace.reveal:
        return showFrontAfterFlip
            ? Transform.flip(flipX: true, child: FrontCard(cardModel: widget.card, tight: true))
            : BackCard(cardModel: widget.card, tight: true);
      case CardFlightFace.conceal:
        return showFrontAfterFlip
            ? Transform.flip(flipX: true, child: BackCard(cardModel: widget.card, tight: true))
            : FrontCard(cardModel: widget.card, tight: true);
    }
  }

  void _startFlight() {
    if (!mounted) return;
    final layerBox = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    final source = _globalCenter(widget.sourceKey);
    final dest = _globalCenter(widget.destKey);
    if (layerBox == null || !layerBox.hasSize || !layerBox.attached || source == null || dest == null) {
      _finish();
      return;
    }
    setState(() {
      _start = layerBox.globalToLocal(source);
      _end = layerBox.globalToLocal(dest);
      _started = true;
    });
    widget.onStarted?.call();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        key: _layerKey,
        clipBehavior: Clip.none,
        children: [
          if (_started && _start != null && _end != null)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _travel.value;
                final pos = Offset.lerp(_start!, _end!, t)!;
                final arc = -widget.arcHeight * math.sin(t * math.pi);
                final lift = widget.arcHeight == 0 ? 0.0 : math.sin(t * math.pi);
                final scale = 1 + _peakScale * lift;
                final tilt = _peakTilt * lift;
                final angle = _flips ? _flip.value * math.pi : 0.0;

                return Positioned(
                  left: pos.dx - _cardSize.width / 2,
                  top: pos.dy + arc - _cardSize.height / 2,
                  width: _cardSize.width,
                  height: _cardSize.height,
                  child: RepaintBoundary(
                    child: Transform(
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateZ(tilt)
                        ..scaleByDouble(scale, scale, 1, 1)
                        ..rotateY(angle),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.16 + 0.2 * lift),
                              blurRadius: 2 + 10 * lift,
                              offset: Offset(0, 2 + 5 * lift),
                            ),
                          ],
                        ),
                        child: _faceAt(angle),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
