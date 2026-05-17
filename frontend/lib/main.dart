import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config.dart';
import 'core/google_sign_in_web_meta_stub.dart'
    if (dart.library.html) 'core/google_sign_in_web_meta_web.dart';
import 'core/auth_session_coordinator.dart';
import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  ensureGoogleSignInWebMeta(AppConfig.googleClientIdWeb);
  runApp(const ProviderScope(child: BotAIApp()));
}

class BotAIApp extends ConsumerWidget {
  const BotAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return AuthSessionCoordinator(
      child: MaterialApp.router(
        title: 'BotAI Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
