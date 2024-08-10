import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SpaceShipEnum { milleniumFalcon, uNSCInfinity, uSSEnterprise, serenity }

class SpaceShipBuildContext {
  late SpaceShipEnum spaceShipType;
  late Point position;
  late Size size;
  late String displayName;
  late double speed;
}

class SpaceShipFactory {
  SpaceShipFactory._();

  static SpaceShip createSpaceShip(SpaceShipBuildContext buildContext) {
    SpaceShip result = NullSpaceShip();

    switch (buildContext.spaceShipType) {
      case SpaceShipEnum.milleniumFalcon:
        result = MilleniumFalcon(buildContext.position, buildContext.displayName);
        break;
      case SpaceShipEnum.uNSCInfinity:
        result = UNSCInfinity(buildContext.position, buildContext.displayName);
        break;
      case SpaceShipEnum.uSSEnterprise:
        result = USSEnterprise(buildContext.position, buildContext.displayName);
        break;
      case SpaceShipEnum.serenity:
        result = Serenity(buildContext.position, buildContext.displayName);
        break;
    }

    return result;
  }

  SpaceShip result = NullSpaceShip();
}

//I placed the NullSpaceShip here because I want the widget that creates the spaceship to only import the spaceship factory file
class NullSpaceShip extends SpaceShip {
  NullSpaceShip();

  @override
  getInfo() {
    debugPrint('NullShape');
  }
}

abstract class SpaceShip {
  Point _position = const Point(0, 0);
  Size _size = const Size(0, 0);
  String _displayName = "";
  double _speed = 0;

  getInfo() {
    debugPrint('displayName: $_displayName\n position: $_position\n size: $_size\n speed: $_speed');
  }

  getDisplayName() {
    return _displayName;
  }
}

class MilleniumFalcon extends SpaceShip {
  MilleniumFalcon(
    Point position,
    String displayName,
  ) {
    _size = const Size(20, 30);
    _speed = 10;
    _position = position;
    _displayName = displayName;
  }
}

class UNSCInfinity extends SpaceShip {
  UNSCInfinity(
    Point position,
    String displayName,
  ) {
    _size = const Size(10, 10);
    _speed = 30;
    _position = position;
    _displayName = displayName;
  }
}

class USSEnterprise extends SpaceShip {
  USSEnterprise(
    Point position,
    String displayName,
  ) {
    _size = const Size(50, 100);
    _speed = 5;
    _position = position;
    _displayName = displayName;
  }
}

class Serenity extends SpaceShip {
  Serenity(
    Point position,
    String displayName,
  ) {
    _size = const Size(15, 15);
    _speed = 20;
    _position = position;
    _displayName = displayName;
  }
}
