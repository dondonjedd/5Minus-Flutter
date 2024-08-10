import 'package:flutter/material.dart';

abstract class Number {
  int number = 0;
  void logNumber() {
    debugPrint('current number: $number');
  }

  int getNextNumber() {
    number = number + 1;
    debugPrint('current number: $number');
    return number;
  }
}

class ClassicLazyNumberGenerator extends Number {
  static ClassicLazyNumberGenerator? _instance;

  ClassicLazyNumberGenerator._internal() {
    debugPrint('instance of number generator created');
  }

  static ClassicLazyNumberGenerator? get instance {
    _instance ??= ClassicLazyNumberGenerator._internal();
    return _instance;
  }
}

class LazyNumberGenerator extends Number {
  static LazyNumberGenerator? _instance;

  LazyNumberGenerator._internal() {
    debugPrint('instance of number generator created');
    _instance = this;
  }

  factory LazyNumberGenerator() => _instance ?? LazyNumberGenerator._internal();
}

class EagerNumberGenerator extends Number {
  static final EagerNumberGenerator _instance = EagerNumberGenerator._internal();

  EagerNumberGenerator._internal() {
    debugPrint('instance of number generator created');
  }

  factory EagerNumberGenerator() => _instance;
}
