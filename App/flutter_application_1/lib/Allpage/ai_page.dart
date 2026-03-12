import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined, size: 80, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('ปรึกษา AI', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('เร็วๆ นี้', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
