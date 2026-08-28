import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle, size: 100, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Rachmad Febriananda',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text('NIM: 244107020095', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(
                'Program Studi Teknik Informatika',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
