import 'dart:async';
import 'dart:developer';

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

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        // Set up the AnimationController
        _controller = AnimationController(
          duration: Duration(milliseconds: ConfigurationData.turnDuration), // Animation duration of 5 seconds
          vsync: this,
        );

        // Set up the Tween animation
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller!);
        final matchCubit = context.read<MatchCubit>();

        if (matchCubit.state?.turn == widget.userIndex) _scheduleAnimation(context);
      },
    );
  }

  void _scheduleAnimation(BuildContext context) {
    if (_timer?.isActive ?? false) return;
    final matchCubit = context.read<MatchCubit>();

    final now = DateTime.now();
    // Set the target DateTime to start the animation
    DateTime targetTime = matchCubit.state?.turnStartTime ?? now; // 10 seconds from now

    // Calculate the delay until the target DateTime
    Duration delay = targetTime.difference(now);
    log(targetTime.toString());

    // Set a timer to start the animation at the specified DateTime
    if (delay > Duration.zero) {
      _timer = Timer(delay.abs(), () {
        _controller?.forward(); // Start the animation
      });
    } else {
      // If the target time has already passed, start the animation immediately
      _controller?.forward(from: delay.inMilliseconds.abs() / ConfigurationData.turnDuration);
    }
  }

  @override
  void dispose() {
    // Dispose of the controller and timer when the widget is removed
    _controller?.dispose();
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchCubit, GameModel?>(
      listenWhen: (previous, current) {
        if (previous?.turn != current?.turn || previous?.turnStartTime != current?.turnStartTime) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state?.turn == widget.userIndex) {
          _controller?.reset();
          _scheduleAnimation(context);
        }
      },
      builder: (context, state) {
        if (!(state?.isActive ?? false)) return const SizedBox.shrink();

        if (widget.userIndex != state?.turn) return const SizedBox.shrink();

        return SizedBox(
          height: 60,
          width: 60,
          child: _animation == null
              ? const SizedBox.shrink()
              : ValueListenableBuilder(
                  valueListenable: _animation!,
                  builder: (_, val, __) {
                    if (val == 1 && state?.turn == widget.userIndex) {
                      _controller?.reset();
                      _timer?.cancel();
                      context.read<MatchCubit>().startNextTurn();
                    }
                    return CircularProgressIndicator(
                      color: Colors.lightGreen,
                      value: val,
                    );
                  }),
        );
      },
    );
  }
}
