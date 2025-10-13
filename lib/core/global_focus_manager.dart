import 'package:flutter/material.dart';

class GlobalFocusManager extends NavigatorObserver {
  void _unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _unfocus();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _unfocus();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _unfocus();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _unfocus();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
