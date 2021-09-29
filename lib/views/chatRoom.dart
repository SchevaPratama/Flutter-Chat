import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutchat/helper/authenticate.dart';
import 'package:flutchat/helper/constants.dart';
import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/services/auth.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/views/converstationScreen.dart';
import 'package:flutchat/views/search.dart';
import 'package:flutchat/views/signin.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoom extends StatefulWidget {
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  Stream? chatRoomStream;

  Widget chatRoomList() {
    return StreamBuilder(
      stream: chatRoomStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: (snapshot.data! as QuerySnapshot).docs.length,
                itemBuilder: (context, index) {
                  return ChatRoomsTile(
                      ((snapshot.data! as QuerySnapshot).docs[index].data() as Map<String, dynamic>)["chatroomid"]
                          .toString()
                          .replaceAll("_", "")
                          .replaceAll(Constants.myName!, ""),
                      ((snapshot.data! as QuerySnapshot).docs[index].data() as Map<String, dynamic>)["chatroomid"]);
                },
              )
            : Container();
      },
    );
  }

  @override
  void initState() {
    getUserInfo();
    super.initState();
  }

  getUserInfo() async {
    Constants.myName = await HelperFunctions.getUserNameSharedPreference();
    databaseMethods.getChatRooms(Constants.myName).then((value) {
      setState(() {
        chatRoomStream = value;
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/images/logo.png",
          height: 50,
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              authMethods.SignOut();

              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Authenticate()));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.exit_to_app),
            ),
          ),
        ],
      ),
      body: chatRoomList(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
      ),
    );
  }
}

class ChatRoomsTile extends StatelessWidget {
  final String userName;
  final String? chatRoomId;
  ChatRoomsTile(this.userName, this.chatRoomId);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConverstationScreen(
                chatRoomId,
              ),
            ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(40)),
              child: Text(
                "${userName.substring(0, 1)}",
                style: biggerTextStyle(),
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Text(userName, style: biggerTextStyle())
          ],
        ),
      ),
    );
  }
}
