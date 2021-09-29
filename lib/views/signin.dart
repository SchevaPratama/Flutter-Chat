import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/services/auth.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutchat/views/chatRoom.dart';
import "package:flutter/material.dart";

class SignIn extends StatefulWidget {
  final Function toggle;
  SignIn(this.toggle);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final formKey = GlobalKey<FormState>();
  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController emailTexteditingController =
      new TextEditingController();

  TextEditingController passwordTexteditingController =
      new TextEditingController();

  bool isLoading = false;
  late QuerySnapshot snapshotUserInfo;

  signIn() {
    if (formKey.currentState!.validate()) {
      HelperFunctions.saveUserEmailSharedPreference(
          emailTexteditingController.text);

      setState(() {
        isLoading = true;
      });

      databaseMethods
          .getUserByUserEmail(emailTexteditingController.text)
          .then((val) {
        snapshotUserInfo = val;
        HelperFunctions.saveUserNameSharedPreference(
            (snapshotUserInfo.docs[0].data() as Map<String, dynamic>)['name']);
        HelperFunctions.saveUserEmailSharedPreference(
            (snapshotUserInfo.docs[0].data() as Map<String, dynamic>)['name']);
      });

      authMethods.SignInWithEmailAndPassword(emailTexteditingController.text,
              passwordTexteditingController.text)
          .then((val) {
        if (val != null) {
          HelperFunctions.saveUserLoggedInSharedPreference(true);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ChatRoom()));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMain(context) as PreferredSizeWidget?,
      body: Container(
        height: MediaQuery.of(context).size.height - 50,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Form(
                key: formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      validator: (val) {
                        return RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                .hasMatch(val!)
                            ? null
                            : "Enter correct email";
                      },
                      controller: emailTexteditingController,
                      style: simpleTextFieldStyle(),
                      decoration: textFieldInputDecoration("Email"),
                    ),
                    TextFormField(
                      validator: (val) {
                        return val!.length < 6
                            ? "Enter Password 6+ characters"
                            : null;
                      },
                      obscureText: true,
                      controller: passwordTexteditingController,
                      style: simpleTextFieldStyle(),
                      decoration: textFieldInputDecoration("Password"),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Forgot Pass",
                    style: simpleTextFieldStyle(),
                  ),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              GestureDetector(
                onTap: () {
                  signIn();
                },
                child: Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff007EF4),
                          const Color(0xff2A75BC)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
                child: Text(
                  "Sign In With Google",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Don't have account?",
                    style: simpleTextFieldStyle(),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.toggle();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Register now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
