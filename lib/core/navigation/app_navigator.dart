import 'package:flutter/material.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

void openAppFromNotification() {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) {
    return;
  }

  navigator.popUntil((route) => route.isFirst);
}
