import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:flutchat/model/user.dart';

class AuthMethods {
  final FirebaseAuth.FirebaseAuth _auth = FirebaseAuth.FirebaseAuth.instance;

  User? _userFromFirebaseUser(FirebaseAuth.User? user) {
    return user != null ? User(userID: user.uid) : null;
  }

  Future SignInWithEmailAndPassword(String email, String password) async {
    try {
      FirebaseAuth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      FirebaseAuth.User? firebaseUser = result.user;
      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
    }
  }

  Future SignUpWithEmailAndPassword(String email, String password) async {
    try {
      FirebaseAuth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      FirebaseAuth.User? firebaseUser = result.user;
      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
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
