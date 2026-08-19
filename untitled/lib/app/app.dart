import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router.dart';
import 'theme/app_theme.dart';

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
class ThemeController extends Notifier<ThemeMode> {
  @override ThemeMode build() { _load(); return ThemeMode.system; }
  Future<void> _load() async { final value = (await SharedPreferences.getInstance()).getString('theme'); if (value != null) state = ThemeMode.values.byName(value); }
  Future<void> select(ThemeMode value) async { state = value; (await SharedPreferences.getInstance()).setString('theme', value.name); }
}
class NurtureNestApp extends ConsumerWidget {
  const NurtureNestApp({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'NurtureNest', debugShowCheckedModeBanner: false, routerConfig: router,
    theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: ref.watch(themeModeProvider));
}
