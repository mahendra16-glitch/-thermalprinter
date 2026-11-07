import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/staff/staff_models.dart';

/// Large-button PIN pad. Digits can also be typed on a hardware keyboard.
///
/// [onSubmit] gets the PIN and returns an error to show, or null when it
/// was accepted. The pad clears itself after a wrong PIN.
class PinPad extends StatefulWidget {
  final Future<String?> Function(String pin) onSubmit;
  final String submitLabel;

  /// Submit as soon as this many digits are typed (null: wait for OK).
  final int? autoSubmitLength;

  const PinPad({
    super.key,
    required this.onSubmit,
    this.submitLabel = 'OK',
    this.autoSubmitLength,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _add(String d) {
    if (_busy || _pin.length >= PinPolicy.maxLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (widget.autoSubmitLength != null &&
        _pin.length == widget.autoSubmitLength) {
      _submit();
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_pin.length < PinPolicy.minLength) {
      setState(() => _error = 'Enter at least ${PinPolicy.minLength} digits.');
      return;
    }
    setState(() => _busy = true);
    final err = await widget.onSubmit(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
      if (err != null) _pin = '';
    });
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final ch = e.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _add(ch);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _back();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _key(String label, {VoidCallback? onTap, Widget? child}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 76,
        height: 64,
        child: FilledButton.tonal(
          onPressed: _busy ? null : onTap,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: child ?? Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'PIN, ${_pin.length} digits entered',
            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < (_pin.length < 4 ? 4 : _pin.length); i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length ? scheme.primary : null,
                        border: Border.all(color: scheme.primary, width: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _error ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error, fontSize: 13),
                    ),
            ),
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final d in row) _key(d, onTap: () => _add(d))],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _key(
                'Delete',
                onTap: _back,
                child: const Icon(
                  Icons.backspace_outlined,
                  semanticLabel: 'Delete',
                ),
              ),
              _key('0', onTap: () => _add('0')),
              _key(
                widget.submitLabel,
                onTap: _submit,
                child: Text(
                  widget.submitLabel,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for a new PIN twice. Returns it, or null on cancel.
Future<String?> askNewPin(BuildContext context, {required String title}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NewPinDialog(title: title),
  );
}

class _NewPinDialog extends StatefulWidget {
  final String title;

  const _NewPinDialog({required this.title});

  @override
  State<_NewPinDialog> createState() => _NewPinDialogState();
}

class _NewPinDialogState extends State<_NewPinDialog> {
  String? _first;
  String? _note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _first == null
                  ? 'Enter a new PIN (${PinPolicy.minLength}–'
                        '${PinPolicy.maxLength} digits).'
                  : 'Enter the same PIN again.',
            ),
            if (_note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _note!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            PinPad(
              key: ValueKey(_first == null),
              submitLabel: _first == null ? 'Next' : 'Save',
              onSubmit: (pin) async {
                if (_first == null) {
                  final problem = PinPolicy.problem(pin);
                  if (problem != null) return problem;
                  setState(() {
                    _first = pin;
                    _note = null;
                  });
                  return null;
                }
                if (pin != _first) {
                  setState(() {
                    _first = null;
                    _note = 'The two PINs were different. Start again.';
                  });
                  return null;
                }
                Navigator.of(context).pop(pin);
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
