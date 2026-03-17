import 'package:flutter/material.dart';
import 'package:mobile_interface/src/features/group_session/pages/group_session_select_page.dart';
import 'package:mobile_interface/src/features/group_session/pages/group_session_private_select_page.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'routes.dart';
import 'theme.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:mobile_interface/src/features/onboarding/controllers/onboarding_controller.dart';
import 'package:mobile_interface/src/features/social/controllers/social_controller.dart';

import 'package:mobile_interface/src/features/courses/controllers/courses_controller.dart';

import 'package:mobile_interface/src/common/widgets/bottom_nav_bar.dart';
import 'package:mobile_interface/src/features/social/pages/social.dart';
import 'package:mobile_interface/src/features/public_profile/pages/profile.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<CoursesController>(
          create: (ctx) => CoursesController(
            api: ctx.read<ApiClient>(),
            auth: ctx.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<OnboardingController>(
          create: (ctx) => OnboardingController(),
        ),
        ChangeNotifierProvider<SocialController>(
          create: (_) => SocialController(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),

        initialRoute: AppRoutes.groupSessionSelect,

        routes: AppRoutes.table,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 3; // leo TODO start on Group Sessions 

  final _pages = const [
    SocialPage(),
    HomePage(),
    ProfilePage(),
    GroupSessionSelectPage(),
    GroupSessionPrivateSelectPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accend')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times: +1'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.courses);
              },
              child: const Text("Go to Courses"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}