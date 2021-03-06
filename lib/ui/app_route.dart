import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'shared/adaptive_page_layout.dart';

class AppRoute extends PageRouteBuilder {
  static Route defaultRoute(BuildContext context, Widget page) {
    return context != null && !AdaptivePageLayout.columnMode(context)
        ? CupertinoPageRoute(
            builder: (BuildContext context) => page,
          )
        : AppRoute(page);
  }

  final Widget page;
  AppRoute(this.page)
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
}
