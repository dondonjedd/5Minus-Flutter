import 'dart:developer';

import 'package:flutter/material.dart';

class BgImage {
  static BgImage? _instance;

  ImageProvider? bgImage;
  BgImage._internal() {
    log('instance of BgImage created');
    _instance = this;
  }
  factory BgImage() => _instance ?? BgImage._internal();

  initialise() async {
    bgImage = Image.asset('asset/image/background.jpg').image;
  }
}
