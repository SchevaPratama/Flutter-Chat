import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutchat/model/user.dart';
import 'package:flutchat/views/chatRoom.dart';
import 'package:path/path.dart';

class DatabaseMethods {
  final String uid;
  DatabaseMethods({this.uid});

  static CollectionReference usersCollection =
      Firestore.instance.collection("users");
  final CollectionReference groupCollection =
      Firestore.instance.collection('groups');
  static CollectionReference chatRoomCollection =
      Firestore.instance.collection('ChatRoom');
  static CollectionReference pertolonganCancel = 
      Firestore.instance.collection('cancelPertolongan');
  final db = Firestore.instance;

  static Future<Map<String, dynamic>> getUserProfile(String uid) async {
    DocumentSnapshot user = await usersCollection.document(uid).get();
    Map<String, dynamic> userData = user.data();

    return userData;
  }

  static Future getChatRoomDetail(
      String chatroomid) async {
    DocumentSnapshot chatRoom =
        await chatRoomCollection.doc(chatroomid).get();
    var chatRoomData = chatRoom.data;

    return chatRoom;
  }

  static Future<dynamic> getUrlImage(String path) {
    return FirebaseStorage.instance.ref().child(path).getDownloadURL();
  }

  static Future<User> getUser(String id) async {
    print(id);
    DocumentSnapshot snapshot = await usersCollection.doc(id).get();

    return User(
      userID:id,
      email:snapshot.data()['email'],
      name:snapshot.data()['name'],
      phone:snapshot.data()['phone']
    );
  }

  static Future<void> updateUser(User user) async {
    
    return await usersCollection.doc(user.userID).set({
      'email': user.email,
      'name': user.name,
    });
  }

  static Future checkTextFieldUser(String userUID, String chatRoomID) async{
    try {
      // bool test = DatabaseServices().isTest;
      // DocumentReference mintaPertolongan;

      await chatRoomCollection
              .document(chatRoomID)
              .updateData({
            userUID + "_typing":true,
          });
    } catch (e) {
      return false;
    }
  }

  static Future typingFalse(String userUID, String chatRoomID) async{
    try {
      // bool test = DatabaseServices().isTest;
      // DocumentReference mintaPertolongan;

      await chatRoomCollection
              .document(chatRoomID)
              .updateData({
            userUID + "_typing":false,
          });
    } catch (e) {
      return false;
    }
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

  Future togglingGroupJoin(
      String groupId, String groupName, String userName) async {
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

  getcancelPertolongan(String pertolonganID) async {
    return await Firestore.instance
        .collection("cancelPertolongan")
        .document(pertolonganID)
        .snapshots();
  }

  static Future requestcancelPermintaanPertolongan(
      String pertolonganID) async {
    try {
      await pertolonganCancel
              .document(pertolonganID)
              .updateData({
            'isCancel':true,
          });
    } catch (e) {
      return false;
    }
  }

  static Future confirmcancelPermintaanPertolongan(
      String pertolonganID,{String uid}) async {
    try {
      await pertolonganCancel
              .document(pertolonganID)
              .updateData({
            // 'isCancel':false,
            // 'penolong':"",
            'cancelPertolongan.' + uid : FieldValue.delete(),
            'penerima': FieldValue.arrayRemove([uid])
          });
      DocumentReference userProfileRef =
          usersCollection.document(uid);
      DocumentSnapshot userProfileSnap = await userProfileRef.get();
      List riwayatMenolong = userProfileSnap.data()['riwayat_menolong'];
      riwayatMenolong.remove(pertolonganID);
      return await userProfileRef
          .updateData({'riwayat_menolong': riwayatMenolong});
    } catch (e) {
      return false;
    }
  }

  getChatRooms(String userUID) async {
    return await Firestore.instance
        .collection("ChatRoom")
        .where("users", arrayContains: userUID)
        .snapshots();
  }

  // getChatRoomDetail(String chatRoomID) async{
  //   return await Firestore.instance
  //       .collection("ChatRoom")
  //       .where("chatroomid",isEqualTo: chatRoomID)
  //       .getDocuments();
  // }

  getGroups(String userUID, String userName) async {
    return await Firestore.instance
        .collection("groups")
        .where("member", arrayContains: userUID + '_' + userName)
        .snapshots();
  }

  // static Future<String> uploadImage(File imageFile) async {
  //   String fileName = basename(imageFile.path);

  //   Reference ref = FirebaseStorage.instance.ref().child(fileName);
  //   UploadTask task = ref.putFile(imageFile);
  //   TaskSnapshot snapshot = await task.onComplete;

  //   return await snapshot.ref.getDownloadURL();
  // }

  Future groupMember(String chatroomid) async {
    DocumentReference groupDocRef = chatRoomCollection.document(chatroomid);

    // List<dynamic> groups = await userDocSnapshot.data['ChatRoom'];
    await groupDocRef.get();
  }
}
