import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../model/card_model.dart';
import 'back_card_widget.dart';
import 'front_card_widget.dart';

/// Overlay that flies a face-down card from the deck to the drawn slot, then
/// optionally flips it face-up. Parent hides the static drawn card until
/// [onCompleted].
class DrawCardFlight extends StatefulWidget {
  const DrawCardFlight({
    super.key,
    required this.card,
    required this.revealFace,
    required this.deckKey,
    required this.drawnSlotKey,
    required this.onCompleted,
  });

  final CardModel card;
  final bool revealFace;
  final GlobalKey deckKey;
  final GlobalKey drawnSlotKey;
  final VoidCallback onCompleted;

  @override
  State<DrawCardFlight> createState() => _DrawCardFlightState();
}

class _DrawCardFlightState extends State<DrawCardFlight> with SingleTickerProviderStateMixin {
  static const Size _cardSize = Size(40, 60);
  static const double _arcHeight = 16;
  static const double _startScale = 1.15;
  static const double _startTilt = 0.12;

  final GlobalKey _layerKey = GlobalKey();

  late final AnimationController _controller;
  late final Animation<double> _travel;
  late final Animation<double> _flip;

  Offset? _start;
  Offset? _end;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.revealFace ? const Duration(milliseconds: 640) : const Duration(milliseconds: 320),
    );
    _travel = CurvedAnimation(
      parent: _controller,
      curve: widget.revealFace ? const Interval(0, 0.5, curve: Curves.easeOutCubic) : Curves.easeOutCubic,
    );
    _flip = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1, curve: Curves.easeInOutCubic),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlight());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  Offset? _globalCenter(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _startFlight() {
    if (!mounted) return;
    final layerBox = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    final deck = _globalCenter(widget.deckKey);
    final slot = _globalCenter(widget.drawnSlotKey);
    if (layerBox == null || !layerBox.hasSize || !layerBox.attached || deck == null || slot == null) {
      _finish();
      return;
    }
    setState(() {
      _start = layerBox.globalToLocal(deck);
      _end = layerBox.globalToLocal(slot);
      _started = true;
    });
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
                final arc = -_arcHeight * math.sin(t * math.pi);
                final scale = lerpDouble(_startScale, 1, t)!;
                final tilt = lerpDouble(_startTilt, 0, t)!;
                final lift = math.sin(t * math.pi);
                final angle = widget.revealFace ? _flip.value * math.pi : 0.0;
                final showFront = widget.revealFace && angle > math.pi / 2;

                return Positioned(
                  left: pos.dx - _cardSize.width / 2,
                  top: pos.dy + arc - _cardSize.height / 2,
                  width: _cardSize.width,
                  height: _cardSize.height,
                  child: Transform.rotate(
                    angle: tilt,
                    child: Transform.scale(
                      scale: scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.18 + 0.22 * lift),
                              blurRadius: 2 + 8 * lift,
                              offset: Offset(0, 2 + 6 * lift),
                            ),
                          ],
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: showFront
                              ? Transform.flip(
                                  flipX: true,
                                  child: FrontCard(cardModel: widget.card),
                                )
                              : BackCard(cardModel: widget.card),
                        ),
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
