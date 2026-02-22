import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:gosshiping/ui/home/home.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? username;
  String? email;
  String? password;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email!.trim(),
        password: password!.trim(),
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "username": username!.trim(),
        "email": email!.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Authentication failed");
    } on FirebaseException catch (e) {
      _showSnackBar("Firestore Error: ${e.message}");
    } catch (e) {
      _showSnackBar("Unexpected Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  const Text(
                    "Zokua Chat",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Join the conversation",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 40),

                  /// USERNAME
                  TextFormField(
                    focusNode: _usernameFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocus),
                    decoration: _inputDecoration("Username"),
                    validator: ValidationBuilder()
                        .required()
                        .minLength(5)
                        .maxLength(20)
                        .build(),
                    onSaved: (value) => username = value,
                  ),

                  const SizedBox(height: 16),

                  /// EMAIL
                  TextFormField(
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    decoration: _inputDecoration("Email"),
                    validator: ValidationBuilder()
                        .required()
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
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration("Password"),
                    validator: ValidationBuilder()
                        .required()
                        .minLength(6)
                        .maxLength(20)
                        .build(),
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
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Sign Up",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Login"),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}