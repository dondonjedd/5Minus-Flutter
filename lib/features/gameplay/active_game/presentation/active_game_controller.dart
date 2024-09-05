import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/cubit/match_cubit.dart';
import 'package:five_minus/features/gameplay/model/active_game_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../dashboard/presentation/dashboard_controller.dart';
import 'active_game_screen.dart';

class ActiveGameController {
  static const String routeName = '/ActiveGameController';
  static Widget screen({
    required ActiveGameParams activeGameParams,
  }) {
    return BlocProvider(
      create: (context) => MatchCubit(),
      child: ActiveGameScreen(
        controller: ActiveGameController._(),
        activeGameParams: activeGameParams,
      ),
    );
  }

  ActiveGameController._();
  final matchesCollection = FirebaseFirestore.instance.collection('matches');

  StreamSubscription? listenToChanges(BuildContext context) {
    bool isGameExist = true;
    MatchCubit matchCubit = context.read<MatchCubit>();

    if (matchCubit.state?.code != null) {
      return FirebaseFirestore.instance.collection('matches').doc(matchCubit.state?.code).snapshots().listen(
        (event) {
          isGameExist = matchCubit.updateFromFirestore(event);
          if (!isGameExist) {
            if (context.mounted) navigateDashboard(context);
          }
        },
      );
    }
    return null;
  }

  navigateDashboard(BuildContext context) {
    context.goNamed(DashboardController.routeName);
  }
}
