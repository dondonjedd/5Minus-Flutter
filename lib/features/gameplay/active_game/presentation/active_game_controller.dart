import 'dart:async';

import 'package:five_minus/core/service/supabase_service.dart';
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

  StreamSubscription<Map<String, dynamic>?>? listenToChanges(BuildContext context) {
    MatchCubit matchCubit = context.read<MatchCubit>();
    final code = matchCubit.state?.code;
    if (code == null) return null;

    return SupabaseService.watchMatch(code).listen((data) {
      final isGameExist = matchCubit.updateFromSupabase(
        data,
        deleted: data == null,
      );
      if (!isGameExist) {
        if (context.mounted) navigateDashboard(context);
      }
    });
  }

  navigateDashboard(BuildContext context) {
    context.goNamed(DashboardController.routeName);
  }
}
