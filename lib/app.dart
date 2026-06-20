import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'navigation/app_router.dart';

class CarbonAwareApp extends ConsumerWidget {
  const CarbonAwareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CarbonAware',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Curated Forest Green theme
      routerConfig: router,
    );
  }
}
