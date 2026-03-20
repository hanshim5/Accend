import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_interface/src/app/theme.dart';
import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:mobile_interface/src/features/social/controllers/social_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/social.dart';

// Run with:
// flutter run -d <device> -t lib/src/features/social/social_debug.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: kIsWeb ? 'assets/.env.web' : 'assets/.env.mobile');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<SocialController>(
          create: (ctx) => SocialController(
            api: ctx.read<ApiClient>(),
            auth: ctx.read<AuthService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Social Debug',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const SocialPage(),
      ),
    ),
  );
}
