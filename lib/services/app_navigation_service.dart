import 'dart:async';

import 'package:flutter/material.dart';

class AppNavigationService {
  const AppNavigationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _mainWrapperReady = Completer<void>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void markMainWrapperReady() {
    if (!_mainWrapperReady.isCompleted) {
      _mainWrapperReady.complete();
    }
  }

  static Future<bool> waitForMainWrapper({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_mainWrapperReady.isCompleted) return true;

    try {
      await _mainWrapperReady.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }
}
