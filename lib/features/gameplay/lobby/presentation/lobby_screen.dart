import 'dart:async';
import 'dart:convert';

import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:five_minus/features/gameplay/model/lobby_params.dart';
import 'package:flutter/material.dart';

import '../../../../core/component/template/screen_template_view.dart';
import '../../../../core/utility/loading_overlay_utility.dart';
import 'lobby_controller.dart';

class LobbyScreen extends StatefulWidget {
  final LobbyController controller;
  final LobbyParams lobbyParams;
  const LobbyScreen({super.key, required this.controller, required this.lobbyParams});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool isLoading = false;
  GameModel? gameModel;
  bool isHost = false;
  StreamSubscription<GameModel?>? _gameSubscription;
  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        setState(() {
          isLoading = true;
        });
        //INITIALIZE HOST
        if (widget.lobbyParams.isCreateGame) {
          gameModel = await widget.controller.createGame();
        }
        //INITIALIZE CLIENT
        else {
          try {
            gameModel = await widget.controller.joinGame(widget.lobbyParams.gameCode ?? '');
          } catch (e) {
            if (!mounted) return;
            widget.controller.navigateDashboard(context);
            return;
          }
        }

        //INITIALIZE ISHOST
        if (gameModel?.hostId != null) isHost = widget.controller.isHost(hostId: gameModel!.hostId);

        //LISTEN CHANGES
        _gameSubscription = widget.controller.listenToChanges(gameModel, _updateLocalFromSupabase);

        setState(() {
          isLoading = false;
        });
      },
    );

    super.initState();
  }

  void _updateLocalFromSupabase(GameModel? data, {required bool deleted}) async {
    if (deleted) {
      if (!context.mounted) return;
      widget.controller.navigateDashboard(context);
      return;
    }
    if (data == null) return;

    final tmpList = await widget.controller.mergePlayersWithProfiles(
      data.players,
      previous: gameModel?.players,
    );

    gameModel = data.copyWith(gameType: data.gameType, players: tmpList);

    if (gameModel?.hasStarted ?? false) {
      if (!context.mounted) return;
      widget.controller.navigateActiveGame(context, gameCode: gameModel?.code);
    }
    if (!context.mounted) return;
    setState(() {});
  }

  bool canStart() {
    if (!isHost) return false;
    if ((gameModel?.players.length ?? 0) != LobbyController.maxPlayers) return false;
    if (gameModel?.players.any((element) => !(element.isReady ?? false)) ?? true) return false;
    return true;
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
      layout: SizedBox(
        width: double.infinity,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  //GAME CODE
                  const Text('Game Code:'),
                  Text(
                    gameModel?.code ?? '-',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Padding(padding: EdgeInsets.only(bottom: 24)),
                  //PLAYERS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        ...gameModel?.players.map(
                              (model) {
                                if (model.loadedPlayer != null) {
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            ClipOval(
                                                child: Image.memory(
                                              base64Decode(model.loadedPlayer?.icon ?? ''),
                                              width: 60,
                                              height: 60,
                                              gaplessPlayback: true,
                                            )),
                                            Positioned(
                                              top: 3,
                                              right: 3,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Icon(
                                                (model.isReady ?? false) ? Icons.check_circle : Icons.cancel,
                                                color: (model.isReady ?? false) ? Colors.green : Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (widget.controller.isHost(hostId: gameModel?.hostId ?? '', uid: model.loadedPlayer?.playerId ?? ''))
                                              const Icon(
                                                Icons.person,
                                                color: Colors.amber,
                                              ),
                                            Text(model.loadedPlayer?.username ?? '-'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(100)),
                                          child: const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              )),
                                        ),
                                      ),
                                      const Text('-'),
                                    ],
                                  ),
                                );
                              },
                            ).toList() ??
                            [],
                        ...List.generate(
                          LobbyController.maxPlayers - (gameModel?.players.length ?? 0),
                          (index) {
                            return Expanded(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Container(
                                      decoration:
                                          BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(100)),
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        // child: CircularProgressIndicator(
                                        //   strokeWidth: 2,
                                        //   color: Colors.white,
                                        // )
                                      ),
                                    ),
                                  ),
                                  const Text('-'),
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(bottom: 24)),

                  //GAME TYPE (public matchmaking out of scope — private only)
                  ToggleButtons(
                    direction: Axis.horizontal,
                    onPressed: null,
                    constraints: const BoxConstraints(minHeight: 40),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    isSelected: const [true, false],
                    children: const [
                      SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.check),
                            ),
                            Text('Private'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Public'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(bottom: 24)),
                  //START OR READY BUTTON
                  ElevatedButton(
                    onPressed: isHost
                        ? canStart()
                            ? () {
                                widget.controller.startGame(
                                  context,
                                  gameCode: gameModel?.code,
                                  players: gameModel?.players,
                                );
                              }
                            : null
                        : () {
                            widget.controller.toggleReady(gameCode: gameModel?.code, playerModelList: gameModel?.players);
                          },
                    style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
                    child: Text(isHost
                        ? 'START'
                        : widget.controller.isPlayerReady(playerModelList: gameModel?.players)
                            ? 'UNREADY'
                            : 'READY'),
                  ),
                  const SizedBox(
                    height: 200,
                  ),
                ],
              )),
      ),
    );
  }
}
