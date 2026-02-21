import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gosshiping/ui/auth/login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zokua Home"),
      ),
     drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Text(
                'Zokua Chat',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              
              onTap:() async{
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage(),),
                (route) => false);
                print("User logged out successfully");

              },
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text("Welcome to Zokua Home!"),
      ),
    );
  }
}