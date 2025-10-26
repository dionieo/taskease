import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'config/app_colors.dart';
import 'config/app_routes.dart';
import 'config/app_constants.dart';
import 'data/models/task_model.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>(AppConstants.taskBoxName);

  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  // Minta permission notifikasi (akan memunculkan dialog di Android 13+)
  await NotificationService.requestPermission();

  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
      ],
      locale: const Locale('id', 'ID'),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}