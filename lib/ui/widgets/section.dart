import 'package:flutter/material.dart';

class Section extends StatelessWidget {
  const Section({
    required this.title,
    required this.icon,
    required this.child,
    this.expand = false,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// Stretches [child] over the remaining height when the section is placed in
  /// a bounded parent instead of a scroll view.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (expand) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
