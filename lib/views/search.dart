import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutchat/helper/constants.dart';
import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/views/converstationScreen.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

String _myName;

class _SearchScreenState extends State<SearchScreen> {
  DatabaseMethods databaseMethods = new DatabaseMethods();

  TextEditingController searchTextEditingController =
      new TextEditingController();

  QuerySnapshot searchSnapshot;

  Widget searchList() {
    return searchSnapshot != null
        ? ListView.builder(
            itemCount: searchSnapshot.documents.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return SearchTile(
                  userName: searchSnapshot.documents[index].data()["nama"],
                  userEmail: searchSnapshot.documents[index].data()["email"],
                  chatroom: searchSnapshot.documents[index]);
            })
        : Container();
  }

  initiateSearch() {
    databaseMethods
        .getUserByUsername(searchTextEditingController.text)
        .then((val) {
      setState(() {
        searchSnapshot = val;
      });
    });
  }

  // Create chat room,send user to converstation screen,push replacement
  createChatRoomAndStartConverstation({String userName, DocumentSnapshot chat}) {
    if (userName != Constants.myName) {
      String chatRoomId = getChatRoomId(userName, Constants.myName);

      List<String> users = [userName, Constants.myName];
      Map<String, dynamic> chatRoomMap = {
        "mapDocument": {
          "mapDocument1": {
            "key1": "value1",
            "key2": "value2",
          }
        },
        "users": users,
        "chatroomid": chatRoomId,
        "type": "personal"
      };
      DatabaseMethods().createChatRoom(chatRoomId, chatRoomMap);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConverstationScreen(chatRoomId, "personal",chatroom: chat,),
          ));
    } else {
      print("Username Not Found");
    }
  }

  Widget SearchTile({String userName, String userEmail,DocumentSnapshot chatroom}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                userName,
                style: biggerTextStyle(),
              ),
              Text(
                userEmail,
                style: biggerTextStyle(),
              )
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              createChatRoomAndStartConverstation(
                userName: userName,chat: chatroom
              );
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(30)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text("Message", style: biggerTextStyle()),
            ),
          )
        ],
      ),
    );
  }

  getChatRoomId(String a, String b) {
    if ((a.compareTo(b) > 0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  // @override
  // void initState() {
  //   getUserInfo();
  //   super.initState();
  // }

  // getUserInfo() async {
  //   Constants.myName = await HelperFunctions.getUserNameSharedPreference();
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMain(context),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              color: Color(0x54FFFFFF),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: searchTextEditingController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          hintText: "Search Username",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                          ),
                          border: InputBorder.none),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      initiateSearch();
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0x36FFFFFF),
                            const Color(0x0FFFFFFF)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Image.asset("assets/images/search_white.png"),
                    ),
                  )
                ],
              ),
            ),
            searchList()
          ],
        ),
      ),
    );
  }
}
