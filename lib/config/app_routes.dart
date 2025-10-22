import 'package:flutter/material.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/pages/home_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';

  static final routes = <String, WidgetBuilder>{
    splash: (context) => const SplashPage(),
    home: (context) => const HomePage(),
  };
}
