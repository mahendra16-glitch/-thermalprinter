import 'package:flutter/material.dart';

import '../../data/repositories/menu_repository.dart';
import '../../domain/menu/menu_models.dart';

/// The square-with-dot mark used on Indian menus (green veg, red/brown
/// non-veg, yellow egg).
class FoodTypeMark extends StatelessWidget {
  final FoodType type;
  final double size;

  const FoodTypeMark(this.type, {super.key, this.size = 14});

  Color get color => switch (type) {
    FoodType.veg => const Color(0xFF16A34A),
    FoodType.nonVeg => const Color(0xFFB91C1C),
    FoodType.egg => const Color(0xFFCA8A04),
    FoodType.other => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: type.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const SmallBadge(
    this.text, {
    super.key,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Runs [action]; shows its validation message (or error) in a SnackBar.
/// Returns true on success.
Future<bool> runMenuAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (success != null) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } on MenuValidationException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not save: $e'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
  return false;
}

/// Simple centred empty/error state.
class MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const MessageState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
