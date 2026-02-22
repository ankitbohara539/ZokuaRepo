import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:gosshiping/ui/auth/SignUp.dart';
import 'package:gosshiping/ui/home/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? username;
  String? email;
  String? password;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  const Text(
                    "Zokua Login",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Log in to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 40),

                  /// EMAIL
                  TextFormField(
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    decoration: _inputDecoration("Email"),
                    validator: ValidationBuilder()
                        .email()
                        .maxLength(50)
                        .build(),
                    onSaved: (value) => email = value,
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD
                  TextFormField(
                    focusNode: _passwordFocus,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration("Password"),
              
                    onSaved: (value) => password = value,
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState!.save();
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                  email: email!,
                                  password: password!,
                                );

                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            }
                            print("User logged in successfully");
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'wrong-password') {
                              print('The password wrong');
                            }
                            if (e.code == 'user-not-found') {
                              print('The user not found');
                            }
                          } catch (e) {
                            print("Error: $e");
                          }
                        }
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignUp(),
                            ),
                          );
                        },
                        child: const Text("Sign Up"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}
