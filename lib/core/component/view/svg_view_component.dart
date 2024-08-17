
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgViewComponent extends SvgPicture {
  SvgViewComponent.file(
    super.file, {
    super.key,
    final Widget? placeholder,
    super.width,
    super.height,
    super.fit = BoxFit.contain,
    super.color,
    super.colorBlendMode = BlendMode.srcIn,
  }) : super.file(
          placeholderBuilder: placeholder == null
              ? null
              : (context) {
                  return placeholder;
                },
        );

  SvgViewComponent.asset(
    super.assetPath, {
    super.key,
    final Widget? placeholder,
    super.width,
    super.height,
    super.fit = BoxFit.contain,
    super.color,
    super.colorBlendMode = BlendMode.srcIn,
  }) : super.asset(
          placeholderBuilder: placeholder == null
              ? null
              : (context) {
                  return placeholder;
                },
        );

  SvgViewComponent.memory(
    super.data, {
    super.key,
    final Widget? placeholder,
    super.width,
    super.height,
    super.fit = BoxFit.contain,
    super.color,
    super.colorBlendMode = BlendMode.srcIn,
  }) : super.memory(
          placeholderBuilder: placeholder == null
              ? null
              : (context) {
                  return placeholder;
                },
        );

  SvgViewComponent.network(
    super.url, {
    super.key,
    final Widget? placeholder,
    super.width,
    super.height,
    super.fit = BoxFit.contain,
    super.color,
    super.colorBlendMode = BlendMode.srcIn,
  }) : super.network(
          placeholderBuilder: placeholder == null
              ? null
              : (context) {
                  return placeholder;
                },
        );
}
