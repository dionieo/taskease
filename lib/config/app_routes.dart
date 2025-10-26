import 'package:flutter/material.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/task_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const task = '/task';

  static final routes = <String, WidgetBuilder>{
    splash: (context) => const SplashPage(),
    home: (context) => const HomePage(),
    task: (context) => const TaskPage(),
  };
}
