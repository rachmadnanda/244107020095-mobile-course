import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../providers/settings_providers.dart';

/// Halaman pengaturan. Hanya membaca state dari provider.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  String? _lastOpened;
  bool _obscureKey = true;
  bool _savingKey = false;

  @override
  void initState() {
    super.initState();
    _loadLastOpened();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadLastOpened() async {
    final prefs = ref.read(prefsRepositoryProvider);
    await prefs.markOpenedNow();
    final value = await prefs.getLastOpened();
    if (!mounted) return;
    setState(() => _lastOpened = value);
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _savingKey = true);
    await ref.read(apiKeyRepositoryProvider).save(key);
    ref.invalidate(apiKeyConfiguredProvider);
    if (!mounted) return;
    setState(() {
      _savingKey = false;
      _apiKeyController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key disimpan di secure storage')),
    );
  }

  Future<void> _deleteApiKey() async {
    await ref.read(apiKeyRepositoryProvider).delete();
    ref.invalidate(apiKeyConfiguredProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('API key dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    final keyConfigured = ref.watch(apiKeyConfiguredProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: darkMode.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (enabled) => ListView(
          children: [
            SwitchListTile(
              title: const Text('Mode Gelap'),
              subtitle: const Text('Simpan preferensi tema secara lokal'),
              value: enabled,
              onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
            ),
            const Divider(),
            ListTile(
              title: const Text('Waktu terakhir dibuka'),
              subtitle: Text(_lastOpened ?? 'Memuat...'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Asisten AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'API key Gemini disimpan di secure storage perangkat. '
                'Key tidak pernah ditulis ke kode sumber atau dikirim ke '
                'server lain selain Google.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            keyConfigured.when(
              loading: () => const ListTile(
                title: Text('Status API key'),
                subtitle: Text('Memeriksa…'),
              ),
              error: (error, _) => ListTile(
                title: const Text('Status API key'),
                subtitle: Text('Gagal membaca: $error'),
              ),
              data: (configured) => Column(
                children: [
                  ListTile(
                    leading: Icon(
                      configured ? Icons.check_circle : Icons.key_off_outlined,
                      color: configured ? Colors.green : null,
                    ),
                    title: const Text('Status API key'),
                    subtitle: Text(
                      configured ? 'Tersimpan di perangkat' : 'Belum diatur',
                    ),
                    trailing: configured
                        ? IconButton(
                            tooltip: 'Hapus API key',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _deleteApiKey,
                          )
                        : null,
                  ),
                  if (!configured)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiKeyController,
                              obscureText: _obscureKey,
                              decoration: InputDecoration(
                                labelText: 'API key Gemini',
                                hintText: 'AIza…',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  tooltip: _obscureKey
                                      ? 'Tampilkan'
                                      : 'Sembunyikan',
                                  icon: Icon(
                                    _obscureKey
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureKey = !_obscureKey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _savingKey ? null : _saveApiKey,
                            child: _savingKey
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
