import 'dart:convert';

import 'package:five_minus/extension.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';

import '../../../core/component/template/screen_template_view.dart';
import '../../../core/data/configuration_data.dart';
import 'leaderboard_controller.dart';

class LeaderboardScreen extends StatefulWidget {
  final LeaderboardController controller;
  const LeaderboardScreen({super.key, required this.controller});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool isLoading = false;
  String playerId = '';
  List<LeaderboardScoreData> leaderboardList = [];
  LeaderboardScoreData? player;

  @override
  void initState() {
    playerId = widget.controller.getPlayerId();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        setState(() {
          isLoading = true;
        });

        leaderboardList = await GamesServices.loadLeaderboardScores(
              androidLeaderboardID: ConfigurationData.androidLeaderboardId,
              maxResults: 30,
              scope: PlayerScope.global,
              timeScope: TimeScope.allTime,
            ) ??
            [];

        player = leaderboardList.firstWhere(
          (element) {
            return element.scoreHolder.playerID == playerId;
          },
        );

        setState(() {
          isLoading = false;
        });
      },
    );
    super.initState();
  }

  List<Widget> leaderboards = <Widget>[
    const Text('All Time'),
    const Text('Weekly'),
  ];
  final List<bool> _selectedLeaderboard = <bool>[
    true,
    false,
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      infoTitle: 'Leaderboards',
      layout: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.2,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(left: 100, right: 30),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(8)),
                          child: Text('Rank ${player?.rank.getOrdinalString()}' ?? 'No Rank'),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return ToggleButtons(
                            constraints: BoxConstraints.expand(width: (constraints.maxWidth / 2) - 3),
                            direction: Axis.horizontal,
                            onPressed: (int index) async {
                              setState(() {
                                for (int i = 0; i < _selectedLeaderboard.length; i++) {
                                  _selectedLeaderboard[i] = i == index;
                                }
                              });
                              leaderboardList = await GamesServices.loadLeaderboardScores(
                                    androidLeaderboardID: ConfigurationData.androidLeaderboardId,
                                    maxResults: 30,
                                    scope: PlayerScope.global,
                                    timeScope: index == 0 ? TimeScope.allTime : TimeScope.week,
                                  ) ??
                                  [];

                              setState(() {});
                            },
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: Colors.white,
                            borderColor: Colors.white,
                            selectedColor: Colors.black,
                            fillColor: Theme.of(context).colorScheme.secondaryContainer,
                            color: Colors.white,
                            isSelected: _selectedLeaderboard,
                            children: leaderboards,
                          );
                        }),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: 100, left: 30),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(8)),
                          child: const Text('${0}W ${0}L ${0}pts'),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        ...leaderboardList.map(
                          (player) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 24,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide()),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      textAlign: TextAlign.start,
                                      player.rank.getOrdinalString(),
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipOval(
                                        child: Image.memory(
                                      base64Decode(player.scoreHolder.iconImage ?? ''),
                                      width: 30,
                                      height: 30,
                                    )),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      textAlign: TextAlign.start,
                                      player.scoreHolder.displayName,
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      textAlign: TextAlign.end,
                                      '${player.displayScore}pts',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  const Divider()
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              )),
            ),
    );
  }
}
