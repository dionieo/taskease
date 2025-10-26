class AppConstants {
  // App Info
  static const String appName = 'TaskEase';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String taskBoxName = 'tasks';
  
  // Priority
  static const int priorityLow = 1;
  static const int priorityMedium = 2;
  static const int priorityHigh = 3;
  
  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double spacing = 16.0;
  
  // Priority Labels
  static const Map<int, String> priorityLabels = {
    1: '🟢 Rendah',
    2: '🟠 Sedang',
    3: '🔴 Tinggi',
  };
}