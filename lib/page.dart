import 'package:flutter/material.dart';

abstract interface class PocPage extends Widget {
  Widget get leading;
  String get title;
  String? get subtitle;
}
