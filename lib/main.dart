import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/task_model.dart';
import 'data/services/hive_storage.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Inisialisasi format tanggal lokal Indonesia
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>('tasks');

  // ✅ Inisialisasi notifikasi lokal
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskEase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TaskPage(),

      // 🔽 Tambahkan ini agar DatePicker & lokal Indonesia berfungsi
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
        Locale('en', 'US'), // Bahasa Inggris (fallback)
      ],
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final HiveStorage _storage = HiveStorage();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;

  // Hitung sisa waktu deadline
  String _calculateDeadline(TaskModel task) {
    if (task.deadline == null) return 'Tidak ada deadline';
    final now = DateTime.now();
    final diff = task.deadline!.difference(now).inDays;

    if (diff > 1) return '⏰ Tersisa $diff hari lagi';
    if (diff == 1) return '🕐 Deadline besok';
    if (diff == 0) return '⚠️ Deadline hari ini!';
    return '❌ Terlambat ${diff.abs()} hari';
  }

  Future<void> _showAddTaskSheet() async {
    _titleController.clear();
    _descriptionController.clear();
    _selectedDeadline = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

        // Gunakan StatefulBuilder agar pemilihan tanggal & waktu dapat diupdate di dalam sheet
        return StatefulBuilder(builder: (context, setModalState) {
          DateTime? tempDeadline = _selectedDeadline;
          TimeOfDay? tempTime = tempDeadline != null
              ? TimeOfDay(hour: tempDeadline.hour, minute: tempDeadline.minute)
              : null;

          String formatSelected() {
            if (tempDeadline == null) return 'Belum pilih tanggal & waktu';
            final datePart = DateFormat('dd MMM yyyy', 'id_ID').format(tempDeadline!);
            final timePart = DateFormat('HH:mm').format(tempDeadline!);
            return '$datePart, $timePart';
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            builder: (_, controller) => Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tambah Tugas Baru',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul tugas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatSelected(),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempDeadline ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 0)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('id', 'ID'),
                          );
                          if (pickedDate != null) {
                            // jika sudah ada waktu yang dipilih, gabungkan; jika belum, default ke 00:00
                            final hour = tempTime?.hour ?? TimeOfDay.now().hour;
                            final minute = tempTime?.minute ?? TimeOfDay.now().minute;
                            setModalState(() {
                              tempDeadline = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Pilih Tanggal'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: tempTime ?? TimeOfDay.now(),
                            
                          );
                          if (pickedTime != null) {
                            setModalState(() {
                              tempTime = pickedTime;
                              final baseDate = tempDeadline ?? DateTime.now();
                              tempDeadline = DateTime(baseDate.year, baseDate.month, baseDate.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 18),
                        label: const Text('Pilih Waktu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (_titleController.text.trim().isEmpty) return;

                        // Perbaiki: Gunakan tempDeadline, bukan _selectedDeadline
                        final newTask = TaskModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: _titleController.text.trim(),
                          description: _descriptionController.text.trim(),
                          deadline: tempDeadline, // Gunakan tempDeadline langsung
                          isDone: false,
                        );

                        debugPrint('DEBUG: tempDeadline = $tempDeadline');
                        debugPrint('DEBUG: newTask.deadline = ${newTask.deadline}');

                        await _storage.addTask(newTask);

                        // DEBUG: cek apa yang tersimpan di storage
                        final all = _storage.getTasks();
                        debugPrint('DEBUG: all deadlines = ${all.map((t) => t.deadline).toList()}');

                        // Jadwalkan notifikasi jika ada deadline
                        if (tempDeadline != null) { // Gunakan tempDeadline
                          await NotificationService.showNotification(
                            title: 'Pengingat Tugas',
                            body: 'Deadline tugas "${_titleController.text}" sebentar lagi!',
                            scheduledTime: tempDeadline
                          );
                        }

                        if (mounted) {
                          setState(() {});
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _storage.getTasks();
    final dateFormat = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskEase'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Halo 👋',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(DateTime.now()),
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.inbox, size: 56, color: Colors.black26),
                            SizedBox(height: 8),
                            Text('Belum ada tugas 😴',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            margin:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              leading: Checkbox(
                                value: task.isDone,
                                activeColor: Colors.green,
                                onChanged: (value) async {
                                  final updated = TaskModel(
                                    id: task.id,
                                    title: task.title,
                                    description: task.description,
                                    deadline: task.deadline,
                                    isDone: value ?? false,
                                  );
                                  await _storage.updateTask(index, updated);
                                  setState(() {});
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              subtitle: Text(_calculateDeadline(task)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await _storage.deleteTask(index);
                                  setState(() {});
                                },
                              ),
                              children: [
                                if (task.description?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(task.description!),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}