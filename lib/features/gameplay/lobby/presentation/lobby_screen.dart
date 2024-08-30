import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
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
        //INITIALIZE HOST
        if (widget.lobbyParams.isCreateGame) {
          gameModel = await widget.controller.createGame();
        }
        //INITIALIZE CLIENT
        else {
          gameModel = await widget.controller.joinGame(widget.lobbyParams.gameCode ?? '');
        }

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
        if (gameModel?.gameType != null) {
          for (int i = 0; i < selectedGameType.length; i++) {
            selectedGameType[i] = i == gameModel!.gameType;
          }
        }
        if (gameModel?.isActive == true) {
          widget.controller.navigateActiveGame(context, gameCode: gameModel?.code);
        }
      } else {
        widget.controller.navigateDashboard(context);
      }
    });
  }

  bool canStart() {
    if ((gameModel?.players.length ?? 0) < 2) return false;
    if (!isHost) return false;
    if (gameModel?.players.any(
          (element) {
            return !(element.isReady ?? false);
          },
        ) ??
        true) return false;

    return true;
  }

  List<bool> selectedGameType = <bool>[
    true,
    false,
  ];
  bool isToggleButtonLoading = false;

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
                                return FutureBuilder(
                                  future: model.player?.get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final userModel = FirebaseUserModel.fromMap(snapshot.data?.data() ?? {});
                                      return Expanded(
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                ClipOval(
                                                    child: Image.memory(
                                                  base64Decode(userModel.icon ?? ''),
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
                                                if (widget.controller.isHost(hostId: gameModel?.hostId ?? '', uid: userModel.playerId ?? ''))
                                                  const Icon(
                                                    Icons.person,
                                                    color: Colors.amber,
                                                  ),
                                                Text(userModel.username),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
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
                                    }
                                  },
                                );
                              },
                            ).toList() ??
                            [],
                        ...List.generate(
                          4 - (gameModel?.players.length ?? 0),
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

                  //GAME TYPE
                  StatefulBuilder(builder: (context, setStateFn) {
                    return ToggleButtons(
                      direction: Axis.horizontal,
                      onPressed: !isHost
                          ? null
                          : (int index) async {
                              selectedGameType = widget.controller.toggleGameTypeLocal(index: index, selectedGameType: selectedGameType);

                              setStateFn(() {
                                isToggleButtonLoading = true;
                              });

                              await widget.controller.toggleGameTypeFstore(gameCode: gameModel?.code, gameType: index);

                              setStateFn(() {
                                isToggleButtonLoading = false;
                              });
                            },
                      constraints: const BoxConstraints(minHeight: 40),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      isSelected: selectedGameType,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (selectedGameType[0])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: isToggleButtonLoading
                                      ? const SizedBox(
                                          height: 15,
                                          width: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ))
                                      : const Icon(Icons.check),
                                ),
                              const Text('Private'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (selectedGameType[1])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: isToggleButtonLoading
                                      ? const SizedBox(
                                          height: 15,
                                          width: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ))
                                      : const Icon(Icons.check),
                                ),
                              const Text('Public'),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const Padding(padding: EdgeInsets.only(bottom: 24)),
                  //START OR READY BUTTON
                  ElevatedButton(
                    onPressed: isHost
                        ? canStart()
                            ? () {
                                widget.controller.startGame(gameCode: gameModel?.code);
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
