import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/util/clock.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/staff_repository.dart';
import '../../domain/staff/staff_models.dart';
import '../../services/storage_service.dart';
import 'pin_pad.dart';
import 'staff_gate.dart';

/// Settings > Staff: set up the owner, add staff, roles and the activity
/// log. Open it through [allow] with [Permission.manageStaff] once staff
/// accounts exist.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final Stream<List<StaffUser>> _users = StorageService.maybeInstance!.staff
      .watchAll();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffUser>>(
      stream: _users,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final users = snap.data!;
        if (users.isEmpty) return const _SetUpScreen();
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Staff'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Staff'),
                  Tab(text: 'Roles'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _StaffList(users: users),
                const _RolesTab(),
                _ActivityTab(users: users),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<void> _run(BuildContext context, Future<void> Function() f) async {
  try {
    await f();
  } catch (e) {
    if (context.mounted) _snack(context, e.toString());
  }
}

// --- First set-up ----------------------------------------------------------

class _SetUpScreen extends StatefulWidget {
  const _SetUpScreen();

  @override
  State<_SetUpScreen> createState() => _SetUpScreenState();
}

class _SetUpScreenState extends State<_SetUpScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_name.text.trim().isEmpty) {
      _snack(context, 'Enter the owner\'s name.');
      return;
    }
    final pin = await askNewPin(context, title: 'Owner PIN');
    if (pin == null || !mounted) return;
    setState(() => _busy = true);
    // This screen is replaced by the staff list as soon as the owner
    // exists, so show the code from the route's navigator.
    final navContext = Navigator.of(context).context;
    try {
      final s = StorageService.maybeInstance!;
      final res = await s.staff.setUpOwner(name: _name.text, pin: pin);
      if (!navContext.mounted) return;
      await showRecoveryCode(navContext, res.recoveryCode);
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Staff accounts are off',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Right now anyone holding the device can do everything, and '
            'orders and payments don\'t record who did them.\n\n'
            'Set up an owner account to turn on PIN sign-in. Then add your '
            'staff with a role each (Manager, Cashier, Waiter, Kitchen). '
            'Each role can only do what it is allowed to; a manager can '
            'approve a single action with their PIN.\n\n'
            'Sign-in works without internet. PINs are stored only as a '
            'secure hash on this device.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Owner name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.lock_person),
            label: const Text('Set up owner account'),
            onPressed: _busy ? null : _go,
          ),
        ],
      ),
    );
  }
}

// --- Staff list --------------------------------------------------------------

class _StaffList extends StatelessWidget {
  final List<StaffUser> users;

  const _StaffList({required this.users});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.maybeInstance!;
    final me = s.session.current;
    final time = DateFormat('d MMM, h:mm a');
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add staff'),
        onPressed: () => _addStaff(context),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const _LoginSettings(),
          const Divider(),
          for (final u in users)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: u.active ? null : Colors.grey.shade300,
                child: Icon(u.isOwner ? Icons.verified_user : Icons.person),
              ),
              title: Text(
                u.name + (u.id == me?.id ? ' (you)' : ''),
                style: TextStyle(
                  decoration: u.active ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                [
                  u.role.label,
                  if (!u.active) 'turned off',
                  if (u.isLockedAt(DateTime.now())) 'locked (wrong PINs)',
                  if (u.lastLoginAt != null)
                    'last in ${time.format(u.lastLoginAt!)}',
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editStaff(context, u),
            ),
        ],
      ),
    );
  }
}

class _LoginSettings extends StatefulWidget {
  const _LoginSettings();

  @override
  State<_LoginSettings> createState() => _LoginSettingsState();
}

class _LoginSettingsState extends State<_LoginSettings> {
  bool? _enabled;
  int? _autoLock;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = StorageService.maybeInstance!;
    final e = await s.staff.loginEnabled();
    final m = await s.staff.autoLockMinutes();
    if (mounted) {
      setState(() {
        _enabled = e;
        _autoLock = m;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StorageService.maybeInstance!;
    final owner = !s.session.enforced || (s.session.current?.isOwner ?? false);
    if (_enabled == null) return const SizedBox(height: 56);
    return Column(
      children: [
        SwitchListTile(
          title: const Text('PIN sign-in'),
          subtitle: Text(
            _enabled!
                ? 'On: staff sign in with their PIN and can only do what '
                      'their role allows.'
                : 'Off: anyone can do everything and records don\'t show who '
                      'did them. Accounts are kept.',
          ),
          value: _enabled!,
          onChanged: !owner
              ? null
              : (v) async {
                  if (!v) {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Turn off PIN sign-in?'),
                        content: const Text(
                          'Anyone holding the device will be able to give '
                          'discounts, reverse payments, see reports and '
                          'change settings.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Turn off'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                  }
                  if (!context.mounted) return;
                  await _run(context, () => s.staff.setLoginEnabled(v));
                  _load();
                },
        ),
        ListTile(
          title: const Text('Lock after no use for'),
          trailing: DropdownButton<int>(
            value: StaffRepository.autoLockChoices.contains(_autoLock)
                ? _autoLock
                : StaffRepository.defaultAutoLockMinutes,
            items: [
              for (final m in StaffRepository.autoLockChoices)
                DropdownMenuItem(
                  value: m,
                  child: Text(m == 0 ? 'Never' : '$m min'),
                ),
            ],
            onChanged: (m) async {
              if (m == null) return;
              await _run(context, () => s.staff.setAutoLockMinutes(m));
              _load();
            },
          ),
        ),
        if (owner && s.session.enforced)
          ListTile(
            title: const Text('Owner recovery code'),
            subtitle: const Text(
              'Get a new code if the old one was lost or seen by someone '
              'else.',
            ),
            trailing: const Icon(Icons.key),
            onTap: () async {
              try {
                final code = await s.staff.renewRecoveryCode();
                if (context.mounted) {
                  await showRecoveryCode(context, code, renewed: true);
                }
              } catch (e) {
                if (context.mounted) _snack(context, e.toString());
              }
            },
          ),
      ],
    );
  }
}

List<StaffRole> _rolesFor(StorageService s) {
  final owner = !s.session.enforced || (s.session.current?.isOwner ?? false);
  return [
    for (final r in StaffRole.values)
      if (r != StaffRole.owner || owner) r,
  ];
}

Future<void> _addStaff(BuildContext context) async {
  final s = StorageService.maybeInstance!;
  final name = TextEditingController();
  var role = StaffRole.waiter;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Add staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StaffRole>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final r in _rolesFor(s))
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (r) => setState(() => role = r ?? role),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Next: set PIN'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final pin = await askNewPin(context, title: 'PIN for ${name.text.trim()}');
  if (pin == null || !context.mounted) return;
  await _run(context, () async {
    final u = await s.staff.addStaff(name: name.text, role: role, pin: pin);
    if (context.mounted) _snack(context, '${u.name} added as ${u.role.label}.');
  });
}

Future<void> _editStaff(BuildContext context, StaffUser u) async {
  final s = StorageService.maybeInstance!;
  final me = s.session.current;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              u.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(u.role.label),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Change name'),
            onTap: () async {
              Navigator.pop(ctx);
              final name = await _askText(context, 'Name', u.name);
              if (name == null || !context.mounted) return;
              await _run(context, () => s.staff.updateStaff(u.id, name: name));
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Change role'),
            onTap: () async {
              Navigator.pop(ctx);
              final role = await showDialog<StaffRole>(
                context: context,
                builder: (dctx) => SimpleDialog(
                  title: Text('Role for ${u.name}'),
                  children: [
                    for (final r in _rolesFor(s))
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(dctx, r),
                        child: Text(r.label + (r == u.role ? '  (now)' : '')),
                      ),
                  ],
                ),
              );
              if (role == null || !context.mounted) return;
              await _run(context, () => s.staff.updateStaff(u.id, role: role));
            },
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(u.id == me?.id ? 'Change my PIN' : 'Set a new PIN'),
            subtitle: u.id == me?.id
                ? null
                : const Text('For a forgotten PIN; also unlocks the account.'),
            onTap: () async {
              Navigator.pop(ctx);
              if (u.id == me?.id) {
                await changeMyPin(context);
                return;
              }
              final pin = await askNewPin(
                context,
                title: 'New PIN for ${u.name}',
              );
              if (pin == null || !context.mounted) return;
              await _run(context, () async {
                await s.staff.resetPin(u.id, pin);
                if (context.mounted) _snack(context, 'New PIN saved.');
              });
            },
          ),
          ListTile(
            leading: Icon(u.active ? Icons.person_off : Icons.person),
            title: Text(u.active ? 'Turn off account' : 'Turn account back on'),
            subtitle: u.active
                ? const Text(
                    'They can no longer sign in. Their past orders and '
                    'payments keep their name.',
                  )
                : null,
            onTap: () async {
              Navigator.pop(ctx);
              await _run(context, () => s.staff.setActive(u.id, !u.active));
            },
          ),
        ],
      ),
    ),
  );
}

Future<String?> _askText(BuildContext context, String label, String initial) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// Asks for the current PIN, then a new one.
Future<void> changeMyPin(BuildContext context) async {
  final s = StorageService.maybeInstance!;
  final me = s.session.current;
  if (me == null) return;
  final old = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Current PIN'),
      content: PinPad(
        submitLabel: 'Next',
        onSubmit: (pin) async {
          Navigator.pop(ctx, pin);
          return null;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (old == null || !context.mounted) return;
  final pin = await askNewPin(context, title: 'New PIN');
  if (pin == null || !context.mounted) return;
  await _run(context, () async {
    await s.staff.changeOwnPin(old, pin);
    if (context.mounted) _snack(context, 'PIN changed.');
  });
}

// --- Roles ---------------------------------------------------------------

class _RolesTab extends StatefulWidget {
  const _RolesTab();

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  final Stream<void> _changes = StorageService.maybeInstance!.staff
      .watchRolePermissions();

  @override
  Widget build(BuildContext context) {
    final s = StorageService.maybeInstance!;
    final owner = !s.session.enforced || (s.session.current?.isOwner ?? false);
    return StreamBuilder<void>(
      stream: _changes,
      builder: (context, _) => FutureBuilder<Map<StaffRole, Set<Permission>>>(
        future: s.staff.rolePermissions(),
        builder: (context, snap) {
          final map = snap.data;
          if (map == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              const ListTile(
                leading: Icon(Icons.verified_user),
                title: Text('Owner / Admin'),
                subtitle: Text('Can always do everything.'),
              ),
              for (final role in map.keys)
                ExpansionTile(
                  title: Text(role.label),
                  subtitle: Text(
                    '${map[role]!.length} of '
                    '${Permission.values.length} allowed',
                  ),
                  children: [
                    for (final p in Permission.values)
                      CheckboxListTile(
                        dense: true,
                        title: Text(p.label),
                        value: map[role]!.contains(p),
                        onChanged: p == Permission.manageStaff && !owner
                            ? null
                            : (v) => _run(
                                context,
                                () => s.staff.setRolePermission(
                                  role,
                                  p,
                                  v ?? false,
                                ),
                              ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            _run(context, () => s.staff.resetRole(role)),
                        child: const Text('Reset to default'),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// --- Activity --------------------------------------------------------------

class _ActivityTab extends StatefulWidget {
  final List<StaffUser> users;

  const _ActivityTab({required this.users});

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  late Future<List<AuditLogRow>> _rows;
  bool _sensitiveOnly = true;

  /// Actions shown with "Important only": money, voids, discounts, staff,
  /// settings and approvals.
  static const _sensitive = [
    'staff.',
    'role.',
    'permission.',
    'payment.',
    'bill.voided',
    'order.cancelled',
    'order.discount',
    'order.items_voided',
    'order.moved_to_due',
    'business_profile.',
    'printer.',
    'shift.',
    'cash.',
    'expense.',
    'setting.',
    'backup.',
    'report.',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _rows = StorageService.maybeInstance!.audit.recent(limit: 500);
  }

  @override
  Widget build(BuildContext context) {
    final names = {for (final u in widget.users) u.id: u.name};
    final time = DateFormat('d MMM, h:mm:ss a');
    return RefreshIndicator(
      onRefresh: () async {
        setState(_load);
        await _rows;
      },
      child: FutureBuilder<List<AuditLogRow>>(
        future: _rows,
        builder: (context, snap) {
          final rows = (snap.data ?? [])
              .where(
                (r) =>
                    !_sensitiveOnly ||
                    _sensitive.any((p) => r.action.startsWith(p)),
              )
              .toList();
          return ListView.builder(
            itemCount: rows.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return SwitchListTile(
                  title: const Text('Important only'),
                  subtitle: const Text(
                    'Money, voids, discounts, staff and settings. The last '
                    '500 entries; nothing here can be edited or deleted.',
                  ),
                  value: _sensitiveOnly,
                  onChanged: (v) => setState(() => _sensitiveOnly = v),
                );
              }
              final r = rows[i - 1];
              final who = r.staffId == null
                  ? 'no sign-in'
                  : (names[r.staffId] ?? 'unknown account');
              return ListTile(
                dense: true,
                title: Text(r.action),
                subtitle: Text(
                  '${time.format(Clock.toLocal(r.at))} · $who'
                  '${_detail(r.detailsJson)}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _detail(String? json) {
    if (json == null) return '';
    try {
      final m = jsonDecode(json);
      if (m is! Map) return '';
      final parts = <String>[];
      for (final e in m.entries) {
        if (e.value == null) continue;
        parts.add('${e.key}: ${e.value}');
        if (parts.length == 4) break;
      }
      return parts.isEmpty ? '' : '\n${parts.join(', ')}';
    } catch (_) {
      return '';
    }
  }
}
