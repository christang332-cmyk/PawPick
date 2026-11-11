import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const splashDuration = Duration(milliseconds: 3000);
  static const splashLogoDuration = Duration(milliseconds: 850);
  static const splashTextDuration = Duration(milliseconds: 650);
  static const splashCurve = Curves.easeOutCubic;
  static const springCurve = Curves.elasticOut;
  static const fast = Duration(milliseconds: 180);
  static const entrance = Duration(milliseconds: 420);
}
