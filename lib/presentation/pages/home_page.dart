import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../pages/task_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Langsung tampilkan TaskPage
    return const TaskPage();
  }
}
