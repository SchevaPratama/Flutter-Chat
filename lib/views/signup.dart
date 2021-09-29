import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/services/auth.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/views/chatRoom.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  final Function toggle;
  SignUp(this.toggle);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool isLoading = false;

  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods databaseMethods = new DatabaseMethods();

  final formKey = GlobalKey<FormState>();

  TextEditingController usernameTexteditingController =
      new TextEditingController();

  TextEditingController emailTexteditingController =
      new TextEditingController();

  TextEditingController passwordTexteditingController =
      new TextEditingController();

  signMeUp() {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      authMethods.SignUpWithEmailAndPassword(emailTexteditingController.text,
              passwordTexteditingController.text)
          .then((val) {
        // print("${val.uid}");

        Map<String, String> userInfoMap = {
          "name": usernameTexteditingController.text,
          "email": emailTexteditingController.text
        };

        HelperFunctions.saveUserNameSharedPreference(
            usernameTexteditingController.text);
        HelperFunctions.saveUserEmailSharedPreference(
            emailTexteditingController.text);

        databaseMethods.uploadUserInfo(userInfoMap);
        HelperFunctions.saveUserLoggedInSharedPreference(true);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ChatRoom()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMain(context) as PreferredSizeWidget?,
      body: isLoading
          ? Container(
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Container(
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
                                return val!.isEmpty || val.length < 2
                                    ? "Please Enter Username Correctly"
                                    : null;
                              },
                              controller: usernameTexteditingController,
                              style: simpleTextFieldStyle(),
                              decoration: textFieldInputDecoration("Username"),
                            ),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          signMeUp();
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
                            "Sign Up",
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
                          "Sign Up With Google",
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
                            "Already have account?",
                            style: simpleTextFieldStyle(),
                          ),
                          GestureDetector(
                            onTap: () {
                              widget.toggle();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Sign in now",
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
            ),
    );
  }
}
