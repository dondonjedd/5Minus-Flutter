import 'dart:async';

import 'package:five_minus/core/data/configuration_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../model/game_model.dart';
import '../cubit/match_cubit.dart';

class PlayerTimer extends StatefulWidget {
  const PlayerTimer({
    super.key,
    required this.userIndex,
  });

  final int? userIndex;

  @override
  State<PlayerTimer> createState() => _PlayerTimerState();
}

class _PlayerTimerState extends State<PlayerTimer> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller = AnimationController(
        duration: Duration(milliseconds: ConfigurationData.turnDuration),
        vsync: this,
      );
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller!);
      setState(() {});
      _syncToState(context.read<MatchCubit>().state);
    });
  }

  /// Drive the ring from the shared `turnStartTime` so every client shows the
  /// same progress for the active turn (wall-clock based, not local animation age).
  void _syncToState(GameModel? state) {
    _timer?.cancel();
    _timer = null;

    final controller = _controller;
    if (controller == null) return;

    final isActiveTurn = (state?.isActive ?? false) && state?.turn == widget.userIndex;
    if (!isActiveTurn || state?.turnStartTime == null) {
      controller.stop();
      controller.value = 0;
      return;
    }

    final start = state!.turnStartTime!.toUtc();
    final now = DateTime.now().toUtc();
    final durationMs = ConfigurationData.turnDuration;
    final elapsedMs = now.difference(start).inMilliseconds;

    if (elapsedMs < 0) {
      // Turn start is still in the future (countdown / clock skew) — wait, then run.
      controller.value = 0;
      _timer = Timer(start.difference(now), () {
        if (!mounted) return;
        _syncToState(context.read<MatchCubit>().state);
      });
      return;
    }

    final from = (elapsedMs / durationMs).clamp(0.0, 1.0);
    controller.duration = Duration(milliseconds: durationMs);
    if (from >= 1.0) {
      controller.value = 1.0;
      return;
    }

    controller.forward(from: from);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchCubit, GameModel?>(
      listenWhen: (previous, current) {
        return previous?.turn != current?.turn ||
            previous?.turnStartTime != current?.turnStartTime ||
            previous?.isActive != current?.isActive;
      },
      listener: (context, state) => _syncToState(state),
      builder: (context, state) {
        if (!(state?.isActive ?? false)) return const SizedBox.shrink();
        if (widget.userIndex != state?.turn) return const SizedBox.shrink();

        final animation = _animation;
        if (animation == null) return const SizedBox.shrink();

        return SizedBox(
          height: 60,
          width: 60,
          child: ValueListenableBuilder<double>(
            valueListenable: animation,
            builder: (_, val, __) {
              return CircularProgressIndicator(
                color: Colors.lightGreen,
                value: val,
              );
            },
          ),
        );
      },
    );
  }
}
