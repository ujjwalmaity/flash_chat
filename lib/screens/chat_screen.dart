import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flashchat/components/message_bubble.dart';
import 'package:flashchat/constants.dart';
import 'package:flutter/material.dart';

final _firestore = Firestore.instance;
String userEmail;

const String MESSAGES_COLLECTION = 'messages';
const String SENDER_KEY = 'sender';
const String TEXT_KEY = 'text';
const String TIME_KEY = 'time';

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;

  FirebaseUser loggedInUser;
  String messageText;

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        userEmail = user.email;
      }
    } catch (e) {
      print(e);
    }
  }

  // Fetching data from Firestore
  void futureMessages() async {
    final querySnapshot = await _firestore.collection(MESSAGES_COLLECTION).getDocuments();
    final documentSnapshot = querySnapshot.documents;
    for (var document in documentSnapshot) {
      print(document.data);
    }
  }

  // Listening for data from Firestore
  void streamMessages() async {
    await for (var querySnapshot in _firestore.collection(MESSAGES_COLLECTION).snapshots()) {
      final documentSnapshot = querySnapshot.documents;
      for (var document in documentSnapshot) {
        print(document.data);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      if (messageText == null || messageText.trim().length == 0) return;
                      _firestore.collection(MESSAGES_COLLECTION).add({TEXT_KEY: messageText.trim(), SENDER_KEY: loggedInUser.email, TIME_KEY: DateTime.now()});
                      _controller.clear();
                      messageText = '';
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(MESSAGES_COLLECTION).orderBy(TIME_KEY).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || userEmail == null) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final querySnapshot = snapshot.data;
        final documentSnapshot = querySnapshot.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var document in documentSnapshot) {
          final messageText = document.data[TEXT_KEY];
          final messageSender = document.data[SENDER_KEY];
          final messageBubble = MessageBubble(text: messageText, sender: messageSender, isMe: userEmail == messageSender);
          messageBubbles.add(messageBubble);
        }
        try {
          _scrollController.animateTo(0.0, curve: Curves.easeOut, duration: const Duration(milliseconds: 300));
        } catch (e) {}
        return Expanded(
          child: ListView(
            reverse: true,
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}
