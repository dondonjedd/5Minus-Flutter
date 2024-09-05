import 'dart:async';

import 'package:five_minus/features/gameplay/active_game/presentation/cubit/match_cubit.dart';
import 'package:five_minus/features/gameplay/model/active_game_params.dart';
import 'package:five_minus/resource/asset_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/component/template/screen_template_view.dart';
import '../../../../core/utility/loading_overlay_utility.dart';
import 'active_game_controller.dart';
import 'widgets/discard_pile_widget.dart';
import 'widgets/player_hands_widget.dart';

class ActiveGameScreen extends StatefulWidget {
  final ActiveGameController controller;
  final ActiveGameParams activeGameParams;
  const ActiveGameScreen({super.key, required this.controller, required this.activeGameParams});

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  bool isLoading = false;
  bool isHost = false;
  StreamSubscription? _gameStreamSubscription;

  @override
  void dispose() {
    _gameStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        setState(() {
          isLoading = true;
        });
        MatchCubit matchCubit = context.read<MatchCubit>();

        //INITIALIZE
        await matchCubit.initalize(widget.activeGameParams.gameCode);
        //INITIALIZE ISHOST
        isHost = matchCubit.isHost();

        //LISTEN CHANGES
        if (!context.mounted) return;
        _gameStreamSubscription = widget.controller.listenToChanges(context);

        setState(() {
          isLoading = false;
        });
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MatchCubit matchCubit = context.read<MatchCubit>();

    return ScreenTemplateView(
      //Close Button
      suffixActionList: [
        Padding(
          padding: const EdgeInsets.only(
            right: 24,
          ),
          child: IconButton(
              iconSize: 35,
              onPressed: () async {
                LoadingOverlay().show(context);
                if (isHost) {
                  await matchCubit.deleteGame();
                } else {
                  await matchCubit.leaveGame();
                }
                LoadingOverlay().hide();
                if (!context.mounted) return;
                widget.controller.navigateDashboard(context);
              },
              icon: const Icon(Icons.cancel_outlined)),
        )
      ],
      layout: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(child: SizedBox()),
                  const SizedBox(
                    height: 12,
                  ),
                  Expanded(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.4,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: (matchCubit.state?.drawDeck?.cardDeck?.isNotEmpty ?? false)
                                  ? UnconstrainedBox(
                                      child: SizedBox(
                                        height: 80,
                                        child: Image.asset(
                                          AssetPath.drawDeck5Plus,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            Expanded(
                              child: (matchCubit.state?.drawDeck?.cardDeck?.isNotEmpty ?? false)
                                  ? UnconstrainedBox(
                                      child: SizedBox(
                                        height: 60,
                                        child: Image.asset(
                                          AssetPath.backCard,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const Expanded(
                              flex: 2,
                              child: DiscardPile(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Expanded(
                    child: PlayerHands(),
                  )
                ],
              ),
            ),
    );
  }
}
