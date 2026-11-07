import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/util/clock.dart';
import '../../domain/staff/staff_models.dart';
import '../../services/storage_service.dart';
import 'pin_pad.dart';

/// Covers the whole app with the sign-in screen while staff login is on and
/// nobody is signed in. The app underneath stays as it was (hidden), so an
/// order being taken is not lost when the screen locks.
///
/// Locks after the idle time set under Settings > Staff, and when a
/// different person signs in the app goes back to its first screen.
class StaffGate extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const StaffGate({super.key, required this.child, this.navigatorKey});

  @override
  State<StaffGate> createState() => _StaffGateState();
}

class _StaffGateState extends State<StaffGate> with WidgetsBindingObserver {
  StorageService? _s;
  Timer? _timer;
  int _autoLockMinutes = 0;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StorageService.getInstance().then((s) {
      if (!mounted) return;
      setState(() => _s = s);
      _lastUserId = s.session.current?.id;
      s.session.addListener(_onSession);
      _loadAutoLock();
      _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _s?.session.removeListener(_onSession);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _loadAutoLock() async {
    final s = _s;
    if (s == null) return;
    final m = await s.staff.autoLockMinutes();
    if (mounted) _autoLockMinutes = m;
  }

  void _onSession() {
    final s = _s!;
    final id = s.session.current?.id;
    if (id != null && _lastUserId != null && id != _lastUserId) {
      // Someone else took over: don't leave them inside the last person's
      // screen.
      widget.navigatorKey?.currentState?.popUntil((r) => r.isFirst);
    }
    if (id != null) _lastUserId = id;
    _loadAutoLock();
    if (mounted) setState(() {});
  }

  void _check() {
    final s = _s;
    if (s == null || s.session.current == null || _autoLockMinutes <= 0) {
      return;
    }
    final idle = Clock.now().difference(s.session.lastActivity);
    if (idle >= Duration(minutes: _autoLockMinutes)) {
      s.staff.signOut(reason: 'auto_lock');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final locked = s?.session.locked ?? false;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => s?.session.touch(),
      child: Stack(
        children: [
          Offstage(
            offstage: locked,
            child: TickerMode(
              enabled: !locked,
              child: ExcludeFocus(excluding: locked, child: widget.child),
            ),
          ),
          if (locked)
            Positioned.fill(
              // Its own navigator (dialogs, recovery screen); the app's
              // hero controller belongs to the app's navigator.
              child: HeroControllerScope.none(
                child: Navigator(
                  onGenerateRoute: (_) =>
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pick your name, then enter your PIN.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  StaffUser? _picked;
  final Stream<List<StaffUser>> _users = StorageService.maybeInstance!.staff
      .watchAll();

  @override
  Widget build(BuildContext context) {
    final s = StorageService.maybeInstance!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_picked == null ? 'Who is using the app?' : _picked!.name),
        leading: _picked == null
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _picked = null),
              ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: _picked == null ? _list(s) : _pin(s, _picked!)),
    );
  }

  Widget _list(StorageService s) {
    return StreamBuilder<List<StaffUser>>(
      stream: _users,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!.where((u) => u.active).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final u in users)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                      maxWidth: 160,
                      minHeight: 96,
                    ),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _picked = u),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                u.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                u.role.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.help_outline),
                label: const Text('Owner forgot their PIN?'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecoverOwnerScreen()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pin(StorageService s, StaffUser u) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(u.role.label),
            const SizedBox(height: 16),
            PinPad(
              key: ValueKey(u.id),
              submitLabel: 'Sign in',
              onSubmit: (pin) async {
                final res = await s.staff.signIn(u.id, pin);
                if (res.ok) return null;
                return res.error;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Forgot your PIN? Ask a manager or the owner to set a new one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uses the recovery code shown when staff accounts were set up.
class RecoverOwnerScreen extends StatefulWidget {
  const RecoverOwnerScreen({super.key});

  @override
  State<RecoverOwnerScreen> createState() => _RecoverOwnerScreenState();
}

class _RecoverOwnerScreenState extends State<RecoverOwnerScreen> {
  final _code = TextEditingController();
  StaffUser? _owner;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _go(StorageService s) async {
    if (_owner == null || _code.text.trim().isEmpty) {
      setState(() => _error = 'Pick the owner and type the recovery code.');
      return;
    }
    final pin = await askNewPin(context, title: 'New PIN for ${_owner!.name}');
    if (pin == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await s.staff.recoverOwner(
        ownerId: _owner!.id,
        code: _code.text,
        newPin: pin,
      );
      if (!mounted) return;
      await showRecoveryCode(context, res.recoveryCode, renewed: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New PIN saved. ${res.owner.name}, sign in.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StorageService.maybeInstance!;
    return Scaffold(
      appBar: AppBar(title: const Text('Owner recovery')),
      body: FutureBuilder<List<StaffUser>>(
        future: s.staff.active(),
        builder: (context, snap) {
          final owners = (snap.data ?? []).where((u) => u.isOwner).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Type the recovery code that was shown when staff accounts '
                'were set up (it looks like ABCD-EFGH-JKLM). It sets a new '
                'PIN for an owner. Other staff: ask a manager or owner to '
                'reset your PIN instead.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StaffUser>(
                initialValue: _owner,
                decoration: const InputDecoration(
                  labelText: 'Owner',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final o in owners)
                    DropdownMenuItem(value: o, child: Text(o.name)),
                ],
                onChanged: (v) => setState(() => _owner = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Recovery code',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : () => _go(s),
                child: const Text('Set a new PIN'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows a recovery code once, with a clear warning to write it down.
Future<void> showRecoveryCode(
  BuildContext context,
  String code, {
  bool renewed = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(renewed ? 'New recovery code' : 'Owner recovery code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write this down and keep it somewhere safe, away from the '
            'device. If every owner forgets their PIN, this code is the only '
            'way back in. It will not be shown again.',
          ),
          const SizedBox(height: 16),
          Center(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (renewed) ...[
            const SizedBox(height: 12),
            const Text('The old recovery code no longer works.'),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('I have written it down'),
        ),
      ],
    ),
  );
}
