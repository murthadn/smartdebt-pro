
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;
  const SectionHeader({super.key, required this.title, required this.icon, this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    if (action != null) ...[const Spacer(), action!],
  ]);
}
