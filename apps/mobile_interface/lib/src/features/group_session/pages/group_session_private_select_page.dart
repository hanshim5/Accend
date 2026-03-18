import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../../../app/routes.dart' as routes;
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
    final t = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, routes.AppRoutes.groupSessionSelect),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(top:8),
                          child: RichText(
                            text: TextSpan(
                              style: t.textTheme.headlineMedium,
                              children: [
                                const TextSpan(text: 'Private Sessions '),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Divider(
                    color: AppColors.border,
                    thickness: 5,
                  ),

                  Spacer(),
                  // const SizedBox(height: 30),

                  private_button.PrivateButton(
                    title: "Create Lobby", 
                    subtitle: "Create or join with a code", 
                    icon: Icons.add_circle_outline_rounded, 
                    onTap: () {Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateCreate);} // leo TODO Need to make it actually do something later
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

                      SizedBox(width: 10),
                      Text(
                        'Or', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20
                        ),
                      ),
                      SizedBox(width: 10),

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
                      // Error text above the TextField
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),

                      // The lobby code input
                      TextField(
                        controller: _lobbyCode,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 112233',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: error != null ? Colors.red : Colors.grey, // red if error
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: error != null ? Colors.red : Colors.blue, // red if error
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
                        // Show an error message or update a state variable
                        setState(() {
                          error = "Missing lobby code";
                        });
                        return; // stop further execution
                      }

                      if (code.length != 6) {
                        // Show an error message or update a state variable
                        setState(() {
                          error = "Lobby code must be exactly 6 digits";
                        });
                        return; // stop further execution
                      }
                      
                      // Clear any previous error
                      setState(() {
                        error = null;
                      });

                      // If valid, call your join function or navigate
                      Navigator.pushNamed(
                        context, 
                        routes.AppRoutes.groupSessionPrivateJoin,
                        arguments: _lobbyCode.text.trim(),
                      );  
                    ;}
                  ),

                  

                  Spacer(),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}