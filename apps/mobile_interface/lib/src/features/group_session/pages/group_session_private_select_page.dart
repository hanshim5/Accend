import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../../../app/routes.dart' as routes;
import '../../../common/widgets/bottom_nav_bar.dart';
import '../widgets/private_button.dart' as private_button;
import 'package:flutter/services.dart';

class GroupSessionPrivateSelectPage extends StatefulWidget {
  const GroupSessionPrivateSelectPage({super.key});

  @override
  State<GroupSessionPrivateSelectPage> createState() => _GroupSessionSelectPageState();
}

class _GroupSessionSelectPageState extends State<GroupSessionPrivateSelectPage> {
  final _lobbyCode = TextEditingController();
  String? error;

  @override
  void dispose() {
    _lobbyCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onDestinationSelected: (i) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            routes.AppRoutes.shell,
            (_) => false,
            arguments: i,
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 69,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E293B), width: 2),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 4,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ),
                  const Text(
                    'Private Sessions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // When the keyboard is closed, give the column a "viewport height" minimum so we
                  // can vertically center content like the old `Spacer()` layout — without using
                  // flex children inside a scroll view (unbounded height -> assert).
                  final minHeight = bottomInset > 0 ? 0.0 : constraints.maxHeight;

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minHeight,
                        maxWidth: 420,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          child: Column(
                            mainAxisAlignment: bottomInset > 0
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              private_button.PrivateButton(
                                title: "Create Lobby",
                                subtitle: "Create or join with a code",
                                icon: Icons.add_circle_outline_rounded,
                                onTap: () {
                                  Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateCreate);
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 2,
                                    width: 100,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Or',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    height: 2,
                                    width: 100,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        error!,
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                  TextField(
                                    controller: _lobbyCode,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 112233',
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: error != null ? Colors.red : Colors.grey,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: error != null ? Colors.red : Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              private_button.PrivateButton(
                                title: "Join Lobby",
                                subtitle: "Create or join with a code",
                                icon: Icons.arrow_circle_right_outlined,
                                onTap: () {
                                  final code = _lobbyCode.text.trim();

                                  if (int.tryParse(code) == null) {
                                    setState(() {
                                      error = "Missing lobby code";
                                    });
                                    return;
                                  }

                                  if (code.length != 6) {
                                    setState(() {
                                      error = "Lobby code must be exactly 6 digits";
                                    });
                                    return;
                                  }

                                  setState(() {
                                    error = null;
                                  });

                                  Navigator.pushNamed(
                                    context,
                                    routes.AppRoutes.groupSessionPrivateJoin,
                                    arguments: _lobbyCode.text.trim(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
