import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/configuration_data.dart';
import '../button/icon_button_component.dart';

class ScreenTemplateView extends StatelessWidget {
  final String? infoTitle;
  final Widget? infoIconPrefix;
  final Widget? infoIconSuffix;
  final List<Widget>? suffixActionList;

  final Widget? layout;
  final Widget? layoutAction;

  final Widget? navigatorLeft;
  final Widget? navigatorRight;
  final Widget? navigatorBottom;

  final Color? foregroundColor;
  final Color? backgroundColor;
  final bool enableOverlapHeader;
  final Widget? prefixAction;
  final TabBar? tabBar;

  final void Function()? onBackOverride;
  final void Function()? onTapEnvironment;

  const ScreenTemplateView(
      {super.key,
      this.infoTitle,
      this.infoIconPrefix,
      this.infoIconSuffix,
      this.suffixActionList,
      this.layout,
      this.layoutAction,
      this.tabBar,
      this.navigatorLeft,
      this.navigatorRight,
      this.navigatorBottom,
      this.foregroundColor,
      this.backgroundColor,
      this.enableOverlapHeader = true,
      this.onBackOverride,
      this.onTapEnvironment,
      this.prefixAction});

  @override
  Widget build(BuildContext context) {
    final component = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/image/background.jpg'),
          fit: BoxFit.cover,
        ),
        gradient: RadialGradient(
          colors: [
            Color(0XFF108568),
            Color(0XFF038061),
            Color(0XFF01795a),
            Color(0XFF017252),
            Color(0XFF006b4b),
            Color(0XFF016444),
            Color(0XFF015a3d),
          ],
          radius: 0.8,
        ),
      ),
      child: PopScope(
        onPopInvokedWithResult: (_, __) {
          if (onBackOverride != null) {
            onBackOverride?.call();
          }
        },
        canPop: onBackOverride == null,
        child: Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: _infoComponent(
              iconPrefix: infoIconPrefix,
              iconSuffix: infoIconSuffix,
              title: infoTitle,
              foregroundColor: foregroundColor,
            ),
            titleTextStyle: Theme.of(context).textTheme.headlineMedium,
            actions: suffixActionList,
            foregroundColor: foregroundColor,
            bottom: tabBar,
            shadowColor: enableOverlapHeader ? Colors.transparent : null,
            surfaceTintColor: enableOverlapHeader ? Colors.transparent : null,
            backgroundColor: enableOverlapHeader ? Colors.transparent : backgroundColor,
            elevation: enableOverlapHeader ? 0 : null,
            leading: prefixAction ??
                (onBackOverride == null
                    ? null
                    : IconButtonComponent(
                        hint: 'Back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: onBackOverride ?? () {},
                      )),
            centerTitle: true,
          ),
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: enableOverlapHeader,
          body: layout,
          floatingActionButton: layoutAction,
          drawer: navigatorLeft,
          endDrawer: navigatorRight,
          bottomNavigationBar: navigatorBottom,
        ),
      ),
    );

    if (!ConfigurationData.isTestMode) {
      return component;
    } else {
      // return _EnvironmentBannerView(
      //   component,
      //   onTapEnvironment: onTapEnvironment,
      // );
      return component;
    }
  }
}

class CollapsibleScreenTemplate extends StatelessWidget {
  final String? infoTitle;
  final Widget? infoIconPrefix;
  final Widget? infoIconSuffix;
  final List<Widget>? infoActionList;
  final Widget? infoBackground;
  final double? infoBackgroundHeight;

  final Widget? layout;
  final Widget? layoutAction;

  final Widget? navigatorLeft;
  final Widget? navigatorRight;
  final Widget? navigatorBottom;

  final Color? foregroundColor;
  final Color? backgroundColor;
  final CollapseMode collapseMode;

  final void Function()? onBackOverride;
  final void Function()? onTapEnvironment;

  const CollapsibleScreenTemplate(
      {super.key,
      this.infoTitle,
      this.infoIconPrefix,
      this.infoIconSuffix,
      this.infoActionList,
      this.infoBackground,
      this.infoBackgroundHeight,
      this.layout,
      this.layoutAction,
      this.navigatorLeft,
      this.navigatorRight,
      this.navigatorBottom,
      this.foregroundColor,
      this.backgroundColor,
      this.collapseMode = CollapseMode.pin,
      this.onBackOverride,
      this.onTapEnvironment});

  @override
  Widget build(BuildContext context) {
    final topSpacing = MediaQuery.of(context).padding.top + kToolbarHeight - 16;

    final component = Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, isInnerBoxScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                floating: false,
                actions: infoActionList,
                automaticallyImplyLeading: false,
                leading: Navigator.canPop(context)
                    ? UnconstrainedBox(
                        child: IconButtonComponent(
                          icon: const Icon(Icons.arrow_back_rounded),
                          hint: 'Back',
                          size: 38,
                          margin: EdgeInsets.zero,
                          style: IconButtonStyle.elevated,
                          onPressed: onBackOverride ?? () => Navigator.pop(context),
                        ),
                      )
                    : null,
                expandedHeight: infoBackgroundHeight ?? MediaQuery.of(context).size.width * 2 / 3,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: LayoutBuilder(
                    builder: (context, constraint) {
                      final opacity = topSpacing / constraint.constrainHeight();

                      return Opacity(
                        opacity: opacity < 0.5 ? 0 : opacity,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: kToolbarHeight,
                            ),
                            Expanded(
                              child: _infoComponent(
                                    iconPrefix: infoIconPrefix,
                                    iconSuffix: infoIconSuffix,
                                    title: infoTitle,
                                    foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
                                  ) ??
                                  const SizedBox(),
                            ),
                            const SizedBox(
                              width: kToolbarHeight,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  centerTitle: true,
                  background: infoBackground,
                  collapseMode: collapseMode,
                ),
              ),
            ),
          ];
        },
        body: Padding(
          padding: const EdgeInsets.only(
            top: kToolbarHeight,
          ),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SafeArea(
              child: layout ?? const SizedBox(),
            ),
          ),
        ),
      ),
      floatingActionButton: layoutAction,
      drawer: navigatorLeft,
      endDrawer: navigatorRight,
      bottomNavigationBar: navigatorBottom,
    );

    final navigateComponent = onBackOverride == null
        ? component
        : PopScope(
            onPopInvoked: (didPop) async {
              if (didPop) onBackOverride?.call();
            },
            child: component,
          );

    if (!ConfigurationData.isTestMode) {
      return navigateComponent;
    } else {
      // return _EnvironmentBannerView(
      //   navigateComponent,
      //   onTapEnvironment: onTapEnvironment,
      // );
      return navigateComponent;
    }
  }
}

// class _EnvironmentBannerView extends StatelessWidget {
//   final Widget child;
//   final void Function()? onTapEnvironment;
//   const _EnvironmentBannerView(this.child, {required this.onTapEnvironment});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<EnvironmentCubit, EnvironmentState>(
//       builder: (context, state) {
//         return Banner(
//           location: BannerLocation.topStart,
//           message: state.code,
//           color: state.color,
//           child: Stack(
//             children: [
//               child,
//               Positioned(
//                   top: 0,
//                   left: 0,
//                   child: GestureDetector(
//                     behavior: HitTestBehavior.translucent,
//                     onTap: onTapEnvironment,
//                     child: const SizedBox(
//                       height: 100,
//                       width: 100,
//                     ),
//                   )),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

Widget? _infoComponent({
  required final String? title,
  required final Widget? iconPrefix,
  required final Widget? iconSuffix,
  final Color? foregroundColor,
}) {
  final titleWidgetList = <Widget>[];

  if (iconPrefix is Widget) {
    titleWidgetList.add(iconPrefix);
    titleWidgetList.add(const SizedBox(
      width: 8,
    ));
  }

  if (title?.isNotEmpty == true) {
    titleWidgetList.add(Text(
      title ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: foregroundColor,
      ),
    ));
  }

  if (iconSuffix is Widget) {
    titleWidgetList.add(const SizedBox(
      width: 8,
    ));
    titleWidgetList.add(iconSuffix);
  }

  if (titleWidgetList.isEmpty) {
    return null;
  } else if (titleWidgetList.length > 1) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: titleWidgetList,
    );
  } else {
    return titleWidgetList.first;
  }
}

Future<File> getImageFileFromAssets(String path) async {
  final byteData = await rootBundle.load('assets/$path');

  final file = File('${(await getTemporaryDirectory()).path}/$path');
  await file.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  return file;
}
