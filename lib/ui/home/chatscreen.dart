import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Chatscreen extends StatefulWidget {
  const Chatscreen({
    super.key,
    required this.peerUserId,
    required this.peerUsername,
    required this.peerEmail,
  });

  final String peerUserId;
  final String peerUsername;
  final String peerEmail;

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  final TextEditingController _controller = TextEditingController();

  String get currentUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get chatId {
    final ids = [currentUid, widget.peerUserId]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final dateTime = timestamp.toDate();
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);
    final messageRef = chatRef.collection("messages").doc();

    final sortedParticipants = [currentUid, widget.peerUserId]..sort();

    final messageData = {
      "senderId": currentUid,
      "receiverId": widget.peerUserId,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      // Fallback for UI ordering while waiting for server timestamp.
      "localCreatedAt": Timestamp.now(),
    };

    try {
      await messageRef.set(messageData);

      await chatRef.set({
        "participants": sortedParticipants,
        "lastMessage": text,
        "lastMessageAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatTitle = widget.peerUserId == currentUid
        ? 'Direct Message'
        : widget.peerUsername;

    final messagesStream = FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .snapshots();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chatTitle),
            Text(
              "Gossip mode on",
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        titleSpacing: 0,
        toolbarHeight: 68,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = [...snapshot.data!.docs]
                  ..sort((a, b) {
                    final aData = a.data();
                    final bData = b.data();

                    final aTime = (aData["timestamp"] as Timestamp?) ??
                        (aData["localCreatedAt"] as Timestamp?);
                    final bTime = (bData["timestamp"] as Timestamp?) ??
                        (bData["localCreatedAt"] as Timestamp?);

                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return -1;
                    if (bTime == null) return 1;
                    return aTime.compareTo(bTime);
                  });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Say hi and start the chat.",
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final isMe = data["senderId"] == currentUid;
                    final text = (data["text"] ?? "").toString();
                    final sentAt = (data["timestamp"] as Timestamp?) ??
                        (data["localCreatedAt"] as Timestamp?);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF0EA5E9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMe ? null : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : scheme.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatMessageTime(sentAt),
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white70
                                      : scheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Type your message...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: sendMessage,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
