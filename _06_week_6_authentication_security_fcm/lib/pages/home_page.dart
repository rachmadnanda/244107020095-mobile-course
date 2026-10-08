import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _tokenSnippet; // untuk tampilan di layar (terpotong)
  String? _tokenFull; // untuk debug log & tombol copy

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (!mounted) return;

    // Token TIDAK dicetak ke log (prinsip keamanan). Untuk uji FCM dari
    // Firebase Console, gunakan tombol "Copy Token Penuh" di bawah.
    setState(() {
      _tokenFull = token;
      _tokenSnippet = token == null
          ? 'token null'
          : '${token.substring(0, 12)}...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Selamat datang di Campus Notify'),
            const SizedBox(height: 8),

            // Tampilkan token terpotong (untuk screenshot laporan)
            Text('FCM token: ${_tokenSnippet ?? "loading..."}'),

            const SizedBox(height: 12),

            // Tombol copy token penuh (untuk keperluan uji FCM)
            if (_tokenFull != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Token Penuh'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _tokenFull!));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token disalin ke clipboard')),
                  );
                },
              ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => context.go(AppRoutes.announcementById('3')),
              child: const Text('Buka Pengumuman #3'),
            ),
          ],
        ),
      ),
    );
  }
}
