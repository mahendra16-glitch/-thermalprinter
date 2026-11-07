import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../services/error_log.dart';

/// Settings > App error log: unexpected errors saved on this device.
class ErrorLogScreen extends StatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  State<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends State<ErrorLogScreen> {
  late Future<String> _text = ErrorLog.instance.read();

  Future<void> _share() async {
    final f = await ErrorLog.instance.exportFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(f.path)], subject: 'POS error log'),
    );
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear the error log?'),
        content: const Text(
          'Share it first if someone is looking into a problem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ErrorLog.instance.clear();
    setState(() => _text = ErrorLog.instance.read());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App error log'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: _clear,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _text,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final t = snap.data!;
          if (t.trim().isEmpty) {
            return const Center(child: Text('No errors recorded.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              t,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          );
        },
      ),
    );
  }
}

/// Shown instead of the app when the local data cannot be opened.
class StartupErrorApp extends StatelessWidget {
  final Object error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('The app could not start')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'The POS data on this device could not be opened, so the '
                'app has not started. Nothing has been deleted or changed.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Try closing and opening the app again. If this keeps '
                'happening, share the error log with whoever supports your '
                'POS, and keep your latest backup file safe.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                '$error',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share error log'),
                onPressed: () async {
                  final f = await ErrorLog.instance.exportFile();
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(f.path)],
                      subject: 'POS error log',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
