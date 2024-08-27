import 'package:five_minus/core/component/template/app_template_view.dart';
import 'package:five_minus/features/create_game/model/lobby_params.dart';
import 'package:five_minus/features/create_game/presentation/lobby_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/component/template/screen_template_view.dart';
import 'join_game_controller.dart';

class JoinGameScreen extends StatelessWidget {
  final JoinGameController controller;
  JoinGameScreen({super.key, required this.controller});
  final TextEditingController gameCodeTextEditController = TextEditingController();
  GlobalKey<FormFieldState> gameCodeFormKey = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
            child: Column(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.25,
            ),
            //PUBLIC GAME
            ElevatedButton(
              onPressed: () {},
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
              child: const Text('Join Public Game'),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 60)),

            //PRIVATE GAME

            Container(
              width: 300,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: TextFormField(
                key: gameCodeFormKey,
                controller: gameCodeTextEditController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                maxLength: 4,
                buildCounter: (context, {required currentLength, required isFocused, required maxLength}) {
                  return const SizedBox.shrink();
                },
                keyboardType: TextInputType.name,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[^A-Z0-9]'))],
                style: const TextStyle(color: Colors.black),
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                decoration: const InputDecoration(
                  labelText: 'Game Code',
                ),
                validator: (value) {
                  if (value?.length != 4) {
                    return 'Game code must have 4 characters';
                  }
                  return null;
                },
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 12)),

            ElevatedButton(
              onPressed: () {
                if (!(gameCodeFormKey.currentState?.validate() ?? false)) return;
                context.goNamed(LobbyController.routeName, extra: LobbyParams(isCreateGame: false, gameCode: gameCodeTextEditController.text));
              },
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
              child: const Text('Join Private Game'),
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
