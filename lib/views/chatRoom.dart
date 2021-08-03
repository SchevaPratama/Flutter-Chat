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
  User _user;
  String _groupName;
  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  Stream chatRoomStream;

  Widget chatRoomList() {
    return StreamBuilder(
      stream: chatRoomStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  if (snapshot.data.documents[index].data()["type"] ==
                      "group") {
                    return ChatRoomsTile(
                      snapshot.data.documents[index].data()["groupName"],
                      snapshot.data.documents[index].data()["chatroomid"],
                      snapshot.data.documents[index].data()["type"]);
                  } else {
                    return ChatRoomsTile(
                      snapshot.data.documents[index].data()["chatroomid"]
                          .toString()
                          .replaceAll("_", "")
                          .replaceAll(Constants.myName, ""),
                      snapshot.data.documents[index].data()["chatroomid"],
                      snapshot.data.documents[index].data()["type"],
                      chatroom: snapshot.data.documents[index],
                      );
                  }
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
    _user = await AuthMethods.getCurentUser();
    print(_user.uid + "asd");
    Constants.myName = await HelperFunctions.getUserNameSharedPreference();
    databaseMethods.getChatRooms(_user.uid).then((value) {
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
        brightness: Brightness.dark,
        elevation: 8,
        leading: IconButton(
          icon: Icon(Icons.search),
          color: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            );
          },
        ),
        title: Text(
          'Inbox',
          style: TextStyle(
            color: Colors.white,
          ),
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
        child: Icon(Icons.add),
        onPressed: () async {
          await HelperFunctions.getUserNameSharedPreference().then((val) {
            DatabaseMethods(uid: _user.uid)
                .togglingGroupJoin("SGwvp3NpkBRGPDAHGxrg", "Testing", val);
          });
          // await DatabaseMethods(uid: _user.uid).togglingGroupJoin("sin0gvnSrtZX3q0OxSEV", "Testing", userName);
          // await HelperFunctions.getUserNameSharedPreference().then((val) {
          //   DatabaseMethods(uid: _user.uid).createGroup(val, "Testing");
          // });
        },
      ),
    );
  }
}

class ChatRoomsTile extends StatelessWidget {
  final String userName;
  final String chatRoomId;
  final String type;
  final DocumentSnapshot chatroom;
  ChatRoomsTile(this.userName, this.chatRoomId,this.type,{this.chatroom});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConverstationScreen(
                chatRoomId,
                type,
                chatroom: chatroom,
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
