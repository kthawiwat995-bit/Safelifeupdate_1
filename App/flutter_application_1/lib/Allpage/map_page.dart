import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 80, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('แผนที่', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('เร็วๆ นี้', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
