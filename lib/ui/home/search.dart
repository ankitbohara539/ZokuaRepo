import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gosshiping/ui/home/chatscreen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String query = "";

  String get currentUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> getUsersQuery() {
    return FirebaseFirestore.instance
        .collection("users")
        .where("usernameLower", isGreaterThanOrEqualTo: query)
        .where("usernameLower", isLessThan: "$query\uf8ff")
        .limit(20);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool showResults = query.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Find Friends"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Search by username",
                  prefixIcon: Icon(Icons.search_rounded),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    query = value.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: !showResults
                ? Center(
                    child: Text(
                      "Search friends and start gossiping.",
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: getUsersQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(
                                color: scheme.onSurfaceVariant),
                          ),
                        );
                      }

                      final users = snapshot.data!.docs
                          .where((doc) => doc.id != currentUid)
                          .toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(
                                color: scheme.onSurfaceVariant),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userDoc = users[index];
                          final data = userDoc.data();

                          final uid = userDoc.id;
                          final username =
                              data["username"] ?? "Unknown";
                          final email = data["email"] ?? "";

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: scheme.outlineVariant),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6),
                              leading: CircleAvatar(
                                radius: 23,
                                child: Text(
                                  username.isNotEmpty
                                      ? username[0]
                                          .toUpperCase()
                                      : "?",
                                ),
                              ),
                              title: Text(
                                username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                email,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.chat_bubble_rounded,
                                color: scheme.primary,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Chatscreen(
                                      peerUserId: uid,
                                      peerUsername: username,
                                      peerEmail: email,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}