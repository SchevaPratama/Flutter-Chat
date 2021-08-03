import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutchat/model/user.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/extensions/firebase_user_extensions.dart';

class AuthMethods {
  static auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  User _userFromFirebaseUser(auth.User user) {
    return user != null ? User(userID: user.uid) : null;
  }

  static Future getCurentUser() async {
    auth.User user = await auth.FirebaseAuth.instance.currentUser;
    return user;
  }

  Future SignInWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      auth.User firebaseUser = result.user;
      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
    }
  }

  Future SignUpWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      auth.User firebaseUser = result.user;
      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<SignInSignUpResult> signUp(
      String email, String password, String name) async {
    try {
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Map<String, String> userInfoMap = {
          "name": email,
          "email": password,
        };

      // phone = UserServices.convertValidPhone(phone);
      User user = result.user.convertToUser(
          name,);
      // DatabaseMethods().uploadUserInfo(userInfoMap);
      await DatabaseMethods.updateUser(user);
      // await MailServices.requestEmailCustomerSignUp(user);
      // Customer customerUser =
      //     Customer(user, user.id, DateTime.now(), DateTime.now());
      // await CustomerServices.updateCustomer(customerUser);
      await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // await _auth.signOut().then((value) async {
      //   await auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      // });
      return SignInSignUpResult(user: user);
    } catch (e) {
      return SignInSignUpResult(message: e.toString());
    }
  }

  static Future<SignInSignUpResult> signInEmail(
      String email, String password) async {
    try {
      List<QueryDocumentSnapshot> listUser = (await DatabaseMethods.usersCollection
              .where('email', isEqualTo: email)
              .get())
          .docs;
      if (listUser.length != 0) {
        auth.UserCredential result = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        print(result.user.uid + " asd");
        User user = await result.user.fromFireStore();
        return SignInSignUpResult(user: user);
      } else {
        return SignInSignUpResult(message: 'user not used email provider');
      }
    } catch (e) {
      return SignInSignUpResult(message: e.toString());
    }
  }

  Future resetPass(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }

  Future SignOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }
}

class SignInSignUpResult {
  final User user;
  final String message;

  SignInSignUpResult({this.user, this.message});
}
