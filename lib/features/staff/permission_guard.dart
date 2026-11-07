import 'package:flutter/material.dart';

import '../../domain/staff/staff_models.dart';
import '../../services/storage_service.dart';
import 'pin_pad.dart';

/// Checks that the signed-in person may do [p] before an action starts.
///
/// - Staff login off, or the person has the permission: returns true.
/// - Otherwise asks for the PIN of someone who has it (e.g. a manager
///   approving a cashier's discount). The approval is written to the audit
///   log and covers this one action only.
///
/// Returns false when nobody approved; the caller must then do nothing.
Future<bool> allow(BuildContext context, Permission p, {String? what}) async {
  final s = await StorageService.getInstance();
  if (s.session.can(p)) return true;
  if (!context.mounted) return false;
  final approvers = await s.staff.whoCan(p);
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _ApproveDialog(permission: p, approvers: approvers, what: what),
  );
  return ok ?? false;
}

/// Whether the signed-in person may do [p] right now, without asking (for
/// hiding things they cannot use).
bool canNow(Permission p) =>
    StorageService.maybeInstance?.session.can(p) ?? true;

class _ApproveDialog extends StatefulWidget {
  final Permission permission;
  final List<StaffUser> approvers;
  final String? what;

  const _ApproveDialog({
    required this.permission,
    required this.approvers,
    this.what,
  });

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  StaffUser? _approver;

  @override
  Widget build(BuildContext context) {
    final s = StorageService.maybeInstance!;
    final me = s.session.current;
    final approvers = widget.approvers;
    final p = widget.permission;
    return AlertDialog(
      title: Text(_approver == null ? 'Approval needed' : _approver!.name),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_approver == null) ...[
                Text(
                  '${me?.name ?? 'You'} (${me?.role.label ?? ''}) may not '
                  '${p.action}. Someone who can may approve it with their PIN.',
                ),
                const SizedBox(height: 12),
                if (approvers.isEmpty)
                  const Text(
                    'No active staff account has this permission. An owner '
                    'can change it under Settings > Staff.',
                  ),
                for (final a in approvers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(_initial(a.name))),
                    title: Text(a.name),
                    subtitle: Text(a.role.label),
                    onTap: () => setState(() => _approver = a),
                  ),
              ] else ...[
                Text('${_approver!.name}, enter your PIN to allow this once.'),
                const SizedBox(height: 12),
                Center(
                  child: PinPad(
                    submitLabel: 'Allow',
                    onSubmit: (pin) async {
                      final res = await s.staff.approve(
                        _approver!.id,
                        pin,
                        p,
                        what: widget.what,
                      );
                      if (!res.ok) return res.error;
                      if (context.mounted) Navigator.of(context).pop(true);
                      return null;
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_approver != null)
          TextButton(
            onPressed: () => setState(() => _approver = null),
            child: const Text('Back'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

String _initial(String name) =>
    name.isEmpty ? '?' : name.characters.first.toUpperCase();
