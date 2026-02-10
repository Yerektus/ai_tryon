import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/try_on_provider.dart';
import 'screens/try_on_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer light status-bar icons on white background.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const AiTryOnApp());
}

/// Root application widget.
class AiTryOnApp extends StatelessWidget {
  const AiTryOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TryOnProvider(),
      child: MaterialApp(
        title: 'AI Примерка',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const TryOnScreen(),
      ),
    );
  }
}
