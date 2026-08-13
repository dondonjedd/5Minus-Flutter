import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/component/template/screen_template_view.dart';
import '../../../resource/asset_path.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller;
  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = controller.getUserDetails();

    return ScreenTemplateView(
      suffixActionList: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          margin: const EdgeInsets.only(right: 24),
          child: Text('${user?.points ?? 0}pts'),
        )
      ],
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.1,
              ),
              Text(
                user?.username ?? '-',
                style: const TextStyle(fontSize: 18),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 24)),
              MenuButton(
                title: 'Join Game',
                assetPath: AssetPath.findGame,
                onTap: () {
                  controller.navigateJoinGame(context);
                },
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              MenuButton(
                title: 'Create Game',
                assetPath: AssetPath.withFriends,
                onTap: () {
                  controller.navigateCreateGame(context);
                },
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              const MenuButton(
                title: 'Leaderboard',
                assetPath: AssetPath.leaderboard,
                onTap: null,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              const MenuButton(
                title: 'Tutorial',
                assetPath: AssetPath.tutorial,
                onTap: null,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              const MenuButton(
                title: 'Settings',
                assetPath: AssetPath.settings,
                onTap: null,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              MenuButton(
                title: 'Logout',
                icon: Icons.logout,
                onTap: () {
                  controller.signOut(context);
                },
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String? assetPath;
  final IconData? icon;
  final String title;
  final Function()? onTap;
  const MenuButton({super.key, this.assetPath, this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: const ButtonStyle(
        maximumSize: WidgetStatePropertyAll(
          Size(250, 45),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          assetPath != null
              ? Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                      width: 24,
                      height: 24,
                    ),
                  ),
                )
              : icon != null
                  ? Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(icon, size: 24),
                      ),
                    )
                  : const Expanded(
                      child: SizedBox(
                      width: 24,
                    )),
          Expanded(flex: 4, child: Text(title)),
        ],
      ),
    );
  }
}
