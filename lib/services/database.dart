import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutchat/views/chatRoom.dart';
import 'package:path/path.dart';

class DatabaseMethods {

  final String uid;
  DatabaseMethods({
    this.uid
  });

  static CollectionReference usersCollection = Firestore.instance.collection("users");
  final CollectionReference groupCollection = Firestore.instance.collection('groups');
  static CollectionReference chatRoomCollection = Firestore.instance.collection('ChatRoom');
  final db = Firestore.instance;

  static Future<Map<String, dynamic>> getUserProfile(String uid) async {
    DocumentSnapshot user = await usersCollection.document(uid).get();
    Map<String, dynamic> userData = user.data;

    return userData;
  }

  static Future<Map<String, dynamic>> getChatRoomDetail(String chatroomid) async {
    DocumentSnapshot chatRoom = await chatRoomCollection.document(chatroomid).get();
    Map<String, dynamic> chatRoomData = chatRoom.data;

    return chatRoomData;
  }

  static Future<dynamic> getUrlImage(String path) {
    return FirebaseStorage.instance.ref().child(path).getDownloadURL();
  }

  getUserByUsername(String username) async {
    return await Firestore.instance
        .collection("users")
        .where("nama", isEqualTo: username)
        .getDocuments();
  }

  getUserByUserEmail(String userEmail) async {
    return await Firestore.instance
        .collection("users")
        .where("email", isEqualTo: userEmail)
        .getDocuments();
  }

  uploadUserInfo(userMap) {
    Firestore.instance.collection("users").add(userMap);
  }

  createChatRoom(String chatRoomId, chatRoomMap) {
    Firestore.instance
        .collection("ChatRoom")
        .document(chatRoomId)
        .setData(chatRoomMap)
        .catchError((e) {
      print(e.toString());
    });
  }

  Future createGroup(String userName, String groupName) async {
    DocumentReference groupDocRef = await chatRoomCollection.add({
      'groupName': groupName,
      'groupIcon': '',
      'admin': userName,
      'users': [],
      //'messages': ,
      'groupId': '',
      'chatroomid': '',
      'recentMessage': '',
      'recentMessageSender': ''
    });

    await groupDocRef.updateData({
        'users': FieldValue.arrayUnion([uid + '_' + userName]),
        'chatroomid': groupDocRef.documentID
    });
  }

  Future togglingGroupJoin(String groupId, String groupName, String userName) async {

    DocumentReference userDocRef = usersCollection.document(uid);
    DocumentSnapshot userDocSnapshot = await userDocRef.get();

    DocumentReference groupDocRef = chatRoomCollection.document(groupId);

    // List<dynamic> groups = await userDocSnapshot.data['ChatRoom'];

    await groupDocRef.updateData({
      'users': FieldValue.arrayUnion([uid + '_' + userName])
    });
  }

  addConverstationMessage(String chatRoomId, messageMap) {
    Firestore.instance
        .collection("ChatRoom")
        .document(chatRoomId)
        .collection("chats")
        .add(messageMap)
        .catchError((e) {
      print(e.toString());
    });
  }

  getConverstationMessage(String chatRoomId) async {
    return await Firestore.instance
        .collection("ChatRoom")
        .document(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: false)
        .snapshots();
  }

  getChatRooms(String userUID,String userName) async {
    return await Firestore.instance
        .collection("ChatRoom")
        .where("users", arrayContains: userUID + '_' +userName)
        .snapshots();
  }
  
  // getChatRoomDetail(String chatRoomID) async{
  //   return await Firestore.instance
  //       .collection("ChatRoom")
  //       .where("chatroomid",isEqualTo: chatRoomID)
  //       .getDocuments();
  // }

  getGroups(String userUID,String userName) async {
    return await Firestore.instance
        .collection("groups")
        .where("member", arrayContains: userUID + '_' +userName)
        .snapshots();
  }

  static Future<String> uploadImage(File imageFile) async{
    String fileName = basename(imageFile.path);

    StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask task = ref.putFile(imageFile);
    StorageTaskSnapshot snapshot = await task.onComplete;

    return await snapshot.ref.getDownloadURL();
  }
}
