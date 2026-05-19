import 'package:flutter/material.dart';
import 'package:starplan/presentation/pages/home_page.dart';
import 'package:starplan/presentation/pages/root.dart';

import 'logic/ThemeProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.init(); // Сначала загружаем тему из настроек

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'StarPlan',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentThemeData, // Передаем динамическую тему!
          home: const RootPage(), // главный экран
        );
      },
    );
  }
}
