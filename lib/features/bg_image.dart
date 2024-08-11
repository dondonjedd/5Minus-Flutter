import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class BgImage {
  static BgImage? _instance;
  Uint8List? bgImage;
  BgImage._internal() {
    log('instance of BgImage created');
    _instance = this;
  }
  factory BgImage() => _instance ?? BgImage._internal();

  initialise() async {
    final byteData = await rootBundle.load('asset/image/background.jpg');
    bgImage = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  }
}
