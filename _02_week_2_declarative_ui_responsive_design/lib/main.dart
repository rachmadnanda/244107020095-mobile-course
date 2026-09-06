import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// breakpoint layar refactoring challenge
const double kWideBreakpoint = 700;

void main() => runApp(const AcademicOverviewApp());

class AcademicOverviewApp extends StatefulWidget {
  const AcademicOverviewApp({super.key});

  @override
  State<AcademicOverviewApp> createState() => _AcademicOverviewAppState();
}

class _AcademicOverviewAppState extends State<AcademicOverviewApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // warna indigo sesuai tema codelab
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 8),
              CupertinoSwitch(
                value: isDark,
                onChanged: onDarkChanged,
                activeColor: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // jumlah kolom berdasarkan lebar layar
          final columns = constraints.maxWidth >= kWideBreakpoint ? 2 : 1;

          return Column(
            children: [
              // Header Profil dari tugas warm-up
              const ProfileCard(),
              // Expanded agar GridView mengisi sisa layar di bawah profil
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: const [
                    InfoCard(title: 'Tugas Selesai', value: '12'),
                    InfoCard(title: 'Kehadiran', value: '100%'),
                    InfoCard(title: 'Sisa SKS', value: '54'),
                    InfoCard(title: 'IPK Saat Ini', value: '3.80'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Ekstraksi Widget 1 ProfileCard (Refactoring Challenge)
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    // agar warna menyesuaikan dark/light mode
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rachmad Febriananda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('Teknik Informatika'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'NIM',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text('244107020095'),
            ],
          ),
        ],
      ),
    );
  }
}

// Ekstraksi Widget 2 InfoCard Refactoring Challenge
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                // semantics label untuk screen reader aksesibilitas
                semanticsLabel: 'Kategori informasi: $title',
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
