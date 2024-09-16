import 'dart:async';

import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/match_cubit.dart';

class GameOverlay extends StatefulWidget {
  const GameOverlay({
    super.key,
  });

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  Timer? timer;
  int? countdownText;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        MatchCubit matchCubit = context.read<MatchCubit>();

        if (matchCubit.state?.turnStartTime != null) {
          timer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              final now = DateTime.now();

              countdownText = matchCubit.state!.turnStartTime!.difference(now).inSeconds;
              if ((now.isAfter(matchCubit.state!.turnStartTime!)) || ((countdownText ?? 0) <= 0)) {
                countdownText = null;
                timer.cancel();
              }
              setState(() {});
            },
          );
        }
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchCubit, GameModel?>(
      listenWhen: (previous, current) {
        if (current?.turnStartTime != previous?.turnStartTime) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state?.turnStartTime != null && timer == null) {
          timer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              countdownText = state!.turnStartTime!.difference(DateTime.now()).inSeconds;
              if ((countdownText ?? 0) <= 0) {
                countdownText = null;
                timer.cancel();
              }
              setState(() {});
            },
          );
        }
      },
      child: Center(
        child: countdownText == null
            ? const SizedBox.shrink()
            : Text(
                countdownText.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36),
              ).animate().fadeIn(),
      ),
    );
  }
}
