import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String username = "";
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search For User")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search by username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  username = val.trim().toLowerCase();
                });
              },
            ),
          ),

          if (username.length >= 2)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('username',
                        isGreaterThanOrEqualTo: username)
                    .where('username',
                        isLessThan: username + '\uf8ff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No users found"));
                  }

                  final users = snapshot.data!.docs
                      .where((doc) => doc.id != currentUid)
                      .toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return _buildUserTile(user);
                    },
                  );
                },
              ),
            ),

          if (username.isNotEmpty && username.length < 2)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Type at least 2 characters"),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(DocumentSnapshot userDoc) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        List following = snapshot.data!['following'] ?? [];
        bool isFollowing = following.contains(userDoc.id);

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(userDoc['username']),
          subtitle: Text(userDoc['email']),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isFollowing ? Colors.grey : Colors.blue,
            ),
            onPressed: () =>
                _toggleFollow(userDoc.id, isFollowing),
            child: Text(
              isFollowing ? "Unfollow" : "Follow",
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow(
      String targetUid, bool isFollowing) async {
    if (isFollowing) {
      /// UNFOLLOW
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .update({
        'following': FieldValue.arrayRemove([targetUid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .update({
        'followers': FieldValue.arrayRemove([currentUid])
      });
    } else {
      /// FOLLOW
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .update({
        'following': FieldValue.arrayUnion([targetUid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .update({
        'followers': FieldValue.arrayUnion([currentUid])
      });
    }
  }
}