import 'dart:async';

import 'package:flutter/material.dart';

import '../printers/paired_bluetooth.dart';

/// Searches for Bluetooth devices that are switched on and in range right
/// now, pairs the one staff pick, and returns it (already paired).
class NearbyPrintersScreen extends StatefulWidget {
  const NearbyPrintersScreen({super.key});

  @override
  State<NearbyPrintersScreen> createState() => _NearbyPrintersScreenState();
}

class _NearbyPrintersScreenState extends State<NearbyPrintersScreen> {
  final Map<String, NearbyBluetoothDevice> _found = {};
  StreamSubscription<BluetoothScanEvent>? _sub;
  bool _searching = false;
  bool _showAll = false;
  String? _error;
  String? _pairing;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _search() {
    _sub?.cancel();
    setState(() {
      _found.clear();
      _searching = true;
      _error = null;
    });
    _sub = scanNearbyBluetooth().listen(
      (d) {
        if (!mounted) return;
        setState(() {
          if (d == null) {
            _searching = false;
          } else {
            _found[d.address] = d;
          }
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _searching = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      },
      onDone: () {
        if (mounted) setState(() => _searching = false);
      },
    );
  }

  Future<void> _use(NearbyBluetoothDevice d) async {
    if (d.paired) {
      Navigator.of(context).pop(d);
      return;
    }
    await _sub?.cancel();
    setState(() {
      _searching = false;
      _pairing = d.address;
    });
    try {
      final ok = await pairBluetoothDevice(d.address);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(
          NearbyBluetoothDevice(
            name: d.name,
            address: d.address,
            major: d.major,
            paired: true,
            rssi: d.rssi,
            classic: d.classic,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pairing was cancelled or refused. If the printer asks for a PIN, '
            'try 0000 or 1234 (or see its self-test page).',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _pairing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _found.values.toList()
      ..sort((a, b) {
        if (a.maybePrinter != b.maybePrinter) return a.maybePrinter ? -1 : 1;
        return (b.rssi ?? -999).compareTo(a.rssi ?? -999);
      });
    final printers = all.where((d) => d.maybePrinter).toList();
    final others = all.where((d) => !d.maybePrinter).toList();
    final shown = _showAll ? all : printers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find nearby printers'),
        actions: [
          IconButton(
            tooltip: 'Search again',
            icon: const Icon(Icons.refresh),
            onPressed: _searching || _pairing != null ? null : _search,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_searching) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _searching
                  ? 'Searching for printers that are switched on and in '
                        'range… (about 12 seconds)'
                  : _error == null
                  ? 'Found ${printers.length} possible printer(s). Tap one to '
                        'pair and use it.'
                  : '',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(_error!),
                trailing: TextButton(
                  onPressed: _search,
                  child: const Text('Try again'),
                ),
              ),
            ),
          for (final d in shown)
            ListTile(
              leading: Icon(
                d.maybePrinter ? Icons.print_rounded : Icons.devices_other,
                color: d.classic ? null : Colors.grey,
              ),
              title: Text(d.name.isEmpty ? 'Unnamed device' : d.name),
              subtitle: Text(
                [
                  d.address,
                  if (d.major != BtMajor.imaging) BtMajor.label(d.major),
                  if (d.paired) 'already paired',
                  if (!d.classic) 'Bluetooth LE only: not usable',
                ].join(' · '),
              ),
              trailing: _pairing == d.address
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SignalBars(d.bars),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: !d.classic || _pairing != null
                              ? null
                              : () => _use(d),
                          child: Text(d.paired ? 'Use' : 'Pair'),
                        ),
                      ],
                    ),
            ),
          if (!_searching && _error == null && printers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No printer found. Check that the printer is switched on, '
                'close to this phone, and not connected to another phone or '
                'tablet (most printers allow only one at a time). Then tap '
                'search again.',
              ),
            ),
          if (others.isNotEmpty)
            SwitchListTile(
              title: Text('Show other devices (${others.length})'),
              subtitle: const Text('Phones, headphones, computers…'),
              value: _showAll,
              onChanged: (v) => setState(() => _showAll = v),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Only printers that are switched on show up here. A printer '
              'that is already paired and switched on also appears, so this '
              'is a quick way to see which of your printers are working.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int bars;

  const _SignalBars(this.bars);

  @override
  Widget build(BuildContext context) {
    if (bars == 0) return const SizedBox(width: 20);
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Signal $bars of 4',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 1; i <= 4; i++)
            Container(
              width: 4,
              height: 4.0 + i * 3,
              margin: const EdgeInsets.only(right: 1),
              color: i <= bars ? color : color.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }
}
