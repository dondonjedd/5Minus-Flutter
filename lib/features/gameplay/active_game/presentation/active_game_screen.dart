import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:five_minus/features/gameplay/model/active_game_params.dart';
import 'package:five_minus/resource/asset_path.dart';
import 'package:flutter/material.dart';

import '../../../../core/component/template/screen_template_view.dart';
import '../../../../core/utility/loading_overlay_utility.dart';
import '../../model/game_model.dart';
import 'active_game_controller.dart';

class ActiveGameScreen extends StatefulWidget {
  final ActiveGameController controller;
  final ActiveGameParams activeGameParams;
  const ActiveGameScreen({super.key, required this.controller, required this.activeGameParams});

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  bool isLoading = false;
  GameModel? gameModel;
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

        //INITIALIZE
        gameModel = await widget.controller.initializeGame(widget.activeGameParams.gameCode);

        //INITIALIZE ISHOST
        if (gameModel?.hostId != null) isHost = widget.controller.isHost(hostId: gameModel!.hostId);

        //LISTEN CHANGES
        _gameStreamSubscription = widget.controller.listenToChanges(gameModel, _updateLocalFromFirestore);

        setState(() {
          isLoading = false;
        });
      },
    );

    super.initState();
  }

  void _updateLocalFromFirestore(DocumentSnapshot<Map<String, dynamic>> event) {
    setState(() {
      if (event.data() != null) {
        gameModel = GameModel.fromMap(event.data()!);
      } else {
        widget.controller.navigateDashboard(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  await widget.controller.deleteGame(gameCode: gameModel?.code);
                } else {
                  await widget.controller.leaveGame(gameCode: gameModel?.code, playerModelList: gameModel?.players);
                }
                LoadingOverlay().hide();
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
          : Center(
              child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.3,
              width: MediaQuery.sizeOf(context).width * 0.3,
              child: DottedBorder(
                color: Colors.white,
                borderType: BorderType.RRect,
                radius: const Radius.circular(50),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (gameModel?.drawDeck?.cardDeck?.isNotEmpty ?? false)
                        Expanded(
                          flex: 3,
                          child: UnconstrainedBox(
                            child: SizedBox(
                              height: 80,
                              child: Image.asset(
                                AssetPath.drawDeck5Plus,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 4,
                        child: UnconstrainedBox(
                          child: SizedBox(
                            height: 80,
                            child: Image.asset(
                              AssetPath.discardPile4Plus,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
    );
  }
}
