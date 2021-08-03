import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutchat/model/user.dart';
import 'package:flutchat/services/database.dart';
// import 'package:transporter_dev/models/models.dart';
// import 'package:transporter_dev/services/services.dart';

extension FirebaseUserExtensions on auth.User {
  User convertToUser(
          String name,
          {File profilePicture, bool active = true, bool verified = false}) =>
      User(
        userID:this.uid,
        email:this.email,
        name:name,
      );

  Future<User> fromFireStore() async {
    return await DatabaseMethods.getUser(this.uid);
  }
}
