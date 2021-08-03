import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutchat/helper/constants.dart';
import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/model/user.dart';
import 'package:flutchat/services/auth.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:flutchat/flat_widgets/flat_action_btn.dart';
import 'package:flutchat/flat_widgets/flat_chat_message.dart';
import 'package:flutchat/flat_widgets/flat_message_input_box.dart';
import 'package:flutchat/flat_widgets/flat_page_header.dart';
import 'package:flutchat/flat_widgets/flat_page_wrapper.dart';
import 'package:flutchat/flat_widgets/flat_profile_image.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:firebase_storage/firebase_storage.dart' as storage;

class ConverstationScreen extends StatefulWidget {
  final String chatRoomId;
  final String type;
  final DocumentSnapshot chatroom;
  ConverstationScreen(this.chatRoomId, this.type, {this.chatroom});
  @override
  _ConverstationScreenState createState() => _ConverstationScreenState();
}

class _ConverstationScreenState extends State<ConverstationScreen> {
  StreamController<String> streamController = StreamController();
  firebaseAuth.User _user;
  bool modalShown = false;
  Future<void> _launched;
  Geolocator _geolocator = Geolocator();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController messageController = new TextEditingController();
  String appBartext = "";
  String userChat = "";
  String numberPhone = "";
  ScrollController _controllerScrollChat;
  // final db = FirebaseFirestore.instance;
  File imageFile;
  bool isLoading;
  bool isCancel;
  bool isShowSticker;
  String imageUrl;
  String imagePath;
  List<String> memberList;
  Map markMap;

  Stream chatMessageStream;
  Stream pertolonganStream;

  Widget ChatMessageList() {
    return StreamBuilder(
        stream: chatMessageStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  controller: this._controllerScrollChat,
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    return _chatBubble(
                      snapshot.data.documents[index].data()["content"],
                      snapshot.data.documents[index].data()["time"],
                      snapshot.data.documents[index].data()["sendBy"] ==
                          Constants.myName,
                      snapshot.data.documents[index].data()["sendBy"],
                      snapshot.data.documents[index].data()["type"],
                      _controllerScrollChat,
                    );
                    // return _buildMessageComposer(snapshot.data.documents[index].data["sendBy"] ==
                    //         Constants.myName);
                  },
                )
              : Container();
        });
  }

  Widget cancelPermintaanTolong() {
    return StreamBuilder(
      stream: pertolonganStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data.data()['type'] == 'personal') {
          if (snapshot.data.data()['isCancel'] == true) {
            FutureBuilder<Widget>(
                future: Future.delayed(Duration.zero, () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return confirmCancel(
                            context, snapshot.data.data()['penerima']);
                      });
                }),
                builder:
                    (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                  if (snapshot.hasData) return snapshot.data;
                  return Container();
                });
            this.isCancel = snapshot.data.data()['isCancel'];
            return Container();
          } else {
            return Container();
          }
        } else if (snapshot.hasData &&
            snapshot.data.data()['type'] == 'group') {
          snapshot.data.data()['penerima'].forEach((doc) {
            if (snapshot.data.data()['cancelPertolongan'][doc]
                    ['requestCancel'] ==
                true) {
              print(doc + ' asd');
              FutureBuilder<Widget>(
                  future: Future.delayed(Duration.zero, () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return confirmCancel(context, doc);
                        });
                  }),
                  builder:
                      (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                    if (snapshot.hasData) return snapshot.data;
                    return Container();
                  });
              this.isCancel = snapshot.data.data()['isCancel'];
              return Container();
            } else {
              return Container();
            }
          });
          return Container();
        } else {
          return Container();
        }
      },
    );
  }

  getUserInfo() async {
    _user = await AuthMethods.getCurentUser();
    String username = widget.chatRoomId
        .toString()
        .replaceAll("_", "")
        .replaceAll(Constants.myName, "");
    // Map profilePeminta = await DatabaseMethods.getUserProfile(username);
    // setState(() {
    //   // userChat = profilePeminta['nama'];
    //   // numberPhone = profilePeminta['phone'];
    // });
  }

  getGroupDetail() async {
    DocumentSnapshot groupDetail =
        await DatabaseMethods.getChatRoomDetail(widget.chatRoomId);

    if (groupDetail['raye'].length == 0) {
      String apptext = groupDetail['groupName'];
      setState(() {
        appBartext = groupDetail['groupName'];
      });
    }
    // else if (groupDetail['type'] == 'group' && groupDetail['users'] > 2) {
    //   String apptext = groupDetail['groupName'];
    //   setState(() {
    //     appBartext = groupDetail['groupName'];
    //   });
    // }
    setState(() {
      appBartext = groupDetail['groupName'];
    });
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  getdata() async {
    await FirebaseFirestore.instance
        .collection("ChatRoom")
        .doc(widget.chatRoomId)
        .get()
        .then((value) {
      setState(() {
        memberList = List.from(value.data()['users']);
      });
    });
  }

  @override
  void initState() {
    streamController.stream
        .transform(debounce(Duration(milliseconds: 400)))
        .listen((s) => _validateValues());

    this._controllerScrollChat = ScrollController();
    super.initState();
    print(widget.type);

    widget.type == 'personal' ? getUserInfo() : getGroupDetail();
    databaseMethods.getConverstationMessage(widget.chatRoomId).then((value) {
      setState(() {
        chatMessageStream = value;
      });
    });
    databaseMethods.getcancelPertolongan(widget.chatRoomId).then((value) {
      setState(() {
        pertolonganStream = value;
      });
    });
    getdata();
  }

  //function I am using to perform some logic
  _validateValues() {
    if (messageController.text.length > 0) {
      print("Text active");
    } else {
      print("Text not active");
    }
  }

  Future getImageGallery() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future getImageCamera() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.camera);
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  // Future uploadFile() async {
  //   File imageCompressed = await FlutterNativeImage.compressImage(
  //     imageFile.path,
  //     quality: 20,
  //   );
  //   String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //   StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
  //   StorageUploadTask task = ref.putFile(imageCompressed);
  //   StorageTaskSnapshot snapshot = await task.onComplete;

  //   var imagePath = await snapshot.ref.getPath();
  //   imageUrl = imagePath.toString();
  //   return sendMessage(imageUrl, 1);
  // }

  Future uploadFile() async {
    File imageCompressed = await FlutterNativeImage.compressImage(
      imageFile.path,
      quality: 20,
    );
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    storage.Reference reference = storage.FirebaseStorage.instance
        .ref()
        .child('chatImage')
        .child(widget.chatRoomId)
        .child(fileName);
    storage.UploadTask uploadTask = reference.putFile(imageCompressed);
    var imagePath = await (await uploadTask).ref.fullPath;
    // TaskSnapshot storageTaskSnapshot = await uploadTask.snapshot.ref.fullPath;
    imageUrl = imagePath;
    return sendMessage(imageUrl, 1);
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('Galeri'),
                    onTap: () {
                      getImageGallery();
                      Navigator.of(context).pop();
                    }),
                new ListTile(
                  leading: new Icon(Icons.photo_camera),
                  title: new Text('Kamera'),
                  onTap: () {
                    getImageCamera();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  confirmCancel(BuildContext context, String uid) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: FutureBuilder(
        future: DatabaseMethods.getUserProfile(uid),
        builder: (BuildContext context, AsyncSnapshot snapshotProfile) {
          if (snapshotProfile.connectionState == ConnectionState.done &&
              snapshotProfile.hasData) {
            return Container(
              // color: Color(0xff1391DD),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              height: 250,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ScrollConfiguration(
                    behavior: ScrollBehavior(),
                    child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.down,
                      color: Color(0xff1391DD),
                      child: Padding(
                        padding: EdgeInsets.only(top: 7, bottom: 7),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 7),
                                  child: Text(
                                    snapshotProfile.data['nama'] +
                                        ' membatalkan pertolongan,konfirmasi?',
                                    style: TextStyle(
                                        color: Color(0xff1391DD),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await DatabaseMethods
                                        .confirmcancelPermintaanPertolongan(
                                            widget.chatRoomId,
                                            uid: uid);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(top: 7),
                                    child: Text(
                                      'Konfirmasi',
                                      style: TextStyle(
                                          color: Color(0xff1391DD),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    new AlwaysStoppedAnimation<Color>(Color(0xff1391DD)),
              ),
            );
          }
        },
      ),
    );
  }

  Dialog selectUser(BuildContext context, List<String> dataUser) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
            // color: Color(0xff1391DD),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            height: 250,
            child: Center(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ScrollConfiguration(
                behavior: ScrollBehavior(),
                child: GlowingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    color: Color(0xff1391DD),
                    child: Padding(
                      padding: EdgeInsets.only(top: 7, bottom: 7),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 7),
                                child: Text(
                                  'Member',
                                  style: TextStyle(
                                      color: Color(0xff1391DD),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 15),
                                child: Column(
                                  children: dataUser
                                      .map((data) => Container(
                                            child: FutureBuilder(
                                                future: DatabaseMethods.getUser(
                                                    data),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot
                                                        snapshotMemberGroup) {
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      setState(() {
                                                        String phoneNumber =
                                                            snapshotMemberGroup
                                                                .data.phone
                                                                .toString()
                                                                .replaceAll(
                                                                    "+", "");
                                                        _launched = _makePhoneCall(
                                                            'tel:' +
                                                                snapshotMemberGroup
                                                                    .data
                                                                    .phone);
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                    child: Container(
                                                        margin: EdgeInsets.only(
                                                            left: 27,
                                                            right: 27,
                                                            top: 15),
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 13,
                                                                right: 13,
                                                                top: 11,
                                                                bottom: 11),
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .grey[300],
                                                                offset: Offset(
                                                                    0, 5),
                                                                blurRadius: 5,
                                                              ),
                                                            ]),
                                                        child: Column(
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                      snapshotMemberGroup
                                                                              .hasData
                                                                          ? snapshotMemberGroup
                                                                              .data
                                                                              .name
                                                                          : '',
                                                                      style: TextStyle(
                                                                          color: Color(
                                                                              0xff1391DD),
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              9),
                                                                ),
                                                                Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      snapshotMemberGroup
                                                                              .hasData
                                                                          ? snapshotMemberGroup
                                                                              .data
                                                                              .phone
                                                                          : '',
                                                                      style: TextStyle(
                                                                          color: Color(
                                                                              0xff1391DD),
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ))
                                                              ],
                                                            ),
                                                          ],
                                                        )),
                                                  );
                                                }),
                                          ))
                                      .toList(),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    )),
              ),
            ))));
  }

  Future sendMessage(String content, int type) async {
    if (content.trim() != '') {
      messageController.clear();
      Map<String, dynamic> messageMap = {
        // "id": FieldValue.increment(1),
        "content": content,
        "sendBy": Constants.myName,
        "time": DateTime.now().millisecondsSinceEpoch,
        "type": type,
      };
      databaseMethods.addConverstationMessage(widget.chatRoomId, messageMap);
      // messageController.text = "";
    }
  }

  Widget appBarChat(BuildContext context) {
    String username = widget.chatRoomId
        .toString()
        .replaceAll("_", "")
        .replaceAll(Constants.myName, "");

    if (widget.type == 'personal') {
      return AppBar(
        brightness: Brightness.dark,
        centerTitle: true,
        title: Text(username),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: new EdgeInsets.symmetric(horizontal: 8.0),
            child: new IconButton(
              icon: Icon(Icons.phone),
              onPressed: () {
                // _launched = _makePhoneCall('tel:+6281515450165');
                FirebaseFirestore.instance
                    .collection("ChatRoom")
                    .document(widget.chatRoomId)
                    .updateData({
                  "mapDocument." + Constants.myName + ".name": true,
                });
                memberList.forEach((doc) {
                  print(widget.chatroom.data()['mapDocument'][doc]['email']);
                });
                print(widget.chatroom.data());
                // FlutterNativeCall.makeCall("081515450165");
                // print(numberPhone);
                // FlutterOpenWhatsapp.sendSingleMessage("6281233596037", "Hello");
              },
            ),
          )
        ],
      );
    } else {
      return AppBar(
        brightness: Brightness.dark,
        centerTitle: true,
        title: Text(appBartext),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: new EdgeInsets.symmetric(horizontal: 8.0),
            child: new IconButton(
              icon: Icon(Icons.phone),
              onPressed: () {
                // memberList.asMap().keys.toList().map((index) {
                //   // var item = list[index];
                //   // index is the index of each element.
                //   // return youFunction(index);
                //   print(index.toString() + " asd");
                // });
                memberList.forEach((doc) async {
                  print(doc);
                  DocumentReference docRefUser =
                      Firestore.instance.collection('users').document(doc);
                  DocumentSnapshot purePointDoc = await docRefUser.get();
                  int purePoint = purePointDoc.data()['point'];

                  int point = purePoint + 5;
                  await docRefUser.updateData({'point': point});
                });
                memberList.remove(Constants.myName);
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return selectUser(context, memberList);
                    });
                // _launched = _makePhoneCall('tel:+6281515450165');
                // FlutterNativeCall.makeCall("081515450165");
                // print(numberPhone);
                // FlutterOpenWhatsapp.sendSingleMessage("6281233596037", "Hello");
              },
            ),
          )
        ],
      );
    }
  }

  _chatBubble(String message, int time, bool isMe, String sender, int type,
      ScrollController controller) {
    Size size = MediaQuery.of(context).size;
    // controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.fastOutSlowIn);
    if (isMe) {
      if (type == 0) {
        return Column(
          children: <Widget>[
            Container(
              alignment: Alignment.topRight,
              child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                        DateTimeFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(time),
                            format: 'M j H:i'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )),
            ),
          ],
        );
      } else if (type == 1) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        Size size = MediaQuery.of(context).size;
                        return Dialog(
                          insetPadding: EdgeInsets.only(
                              left: 25,
                              right: 25,
                              top: size.height * .087,
                              bottom: size.height * .087),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            padding: EdgeInsets.only(left: 15, right: 15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin:
                                            EdgeInsets.only(top: 8, bottom: 8),
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: FutureBuilder(
                                                future:
                                                    DatabaseMethods.getUrlImage(
                                                        message),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot snapshot) {
                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.hasData) {
                                                    return CachedNetworkImage(
                                                      imageUrl: snapshot.data,
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(),
                                                      fit: BoxFit.fitWidth,
                                                    );
                                                  } else {
                                                    return Container();
                                                  }
                                                })),
                                      ),
                                    ])
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.2,
                    ),
                    margin: EdgeInsets.only(
                        right: size.width * 0.04,
                        top: size.height * 0.01,
                        bottom: size.height * 0.01),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 6.0,
                          spreadRadius: 0.0,
                          color: Colors.black.withOpacity(.30),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder(
                              future: DatabaseMethods.getUrlImage(
                                message,
                              ),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return CachedNetworkImage(
                                    imageUrl: snapshot.data,
                                    placeholder: (context, url) => Container(),
                                    fit: BoxFit.fitWidth,
                                  );
                                } else {
                                  return Container();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(right: 15, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    // "${DateTime.fromMillisecondsSinceEpoch(time).month.toString()}-${DateTime.fromMillisecondsSinceEpoch(time).day.toString()} | ${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                    DateTimeFormat.format(
                        DateTime.fromMillisecondsSinceEpoch(time),
                        format: 'M j H:i'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
            )
          ],
        );
      }
    } else {
      if (type == 0) {
        return Column(
          children: <Widget>[
            widget.type == 'personal'
                ? Container(
                    alignment: Alignment.topLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.80,
                      ),
                      padding: EdgeInsets.all(10),
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                            DateTimeFormat.format(
                                DateTime.fromMillisecondsSinceEpoch(time),
                                format: 'M j H:i'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.topLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.80,
                      ),
                      padding: EdgeInsets.all(10),
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender,
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                            DateTimeFormat.format(
                                DateTime.fromMillisecondsSinceEpoch(time),
                                format: 'M j H:i'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        );
      } else if (type == 1) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        Size size = MediaQuery.of(context).size;
                        return Dialog(
                          insetPadding: EdgeInsets.only(
                              left: 25,
                              right: 25,
                              top: size.height * .087,
                              bottom: size.height * .087),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            padding: EdgeInsets.only(left: 15, right: 15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                          EdgeInsets.only(top: 8, bottom: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder(
                                          future: DatabaseMethods.getUrlImage(
                                              message),
                                          builder: (BuildContext context,
                                              AsyncSnapshot snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return CachedNetworkImage(
                                                imageUrl: snapshot.data,
                                                placeholder: (context, url) =>
                                                    Container(),
                                                fit: BoxFit.fitWidth,
                                              );
                                            } else {
                                              return Container();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.2,
                    ),
                    margin: EdgeInsets.only(
                        left: size.width * 0.05,
                        top: size.height * 0.01,
                        bottom: size.height * 0.01),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 6.0,
                          spreadRadius: 0.0,
                          color: Colors.black.withOpacity(.30),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder(
                              future: DatabaseMethods.getUrlImage(message),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return CachedNetworkImage(
                                    imageUrl: snapshot.data,
                                    placeholder: (context, url) => Container(),
                                    fit: BoxFit.fitWidth,
                                  );
                                } else {
                                  return Container();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(left: 25, bottom: 10),
              child: Row(
                children: <Widget>[
                  Text(
                    // "${DateTime.fromMillisecondsSinceEpoch(time).month.toString()}-${DateTime.fromMillisecondsSinceEpoch(time).day.toString()} | ${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                    DateTimeFormat.format(
                        DateTime.fromMillisecondsSinceEpoch(time),
                        format: 'M j H:i'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }
  }

  _buildMessage(String message, bool isMe, ScrollController controller) {
    // controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    final Container msg = Container(
      // margin: isMe
      //     ? EdgeInsets.only(
      //         top: 8.0,
      //         bottom: 8.0,
      //         left: 80.0,
      //       )
      //     : EdgeInsets.only(
      //         top: 8.0,
      //         bottom: 8.0,
      //       ),
      // padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      // width: MediaQuery.of(context).size.width * 0.75,
      // decoration: BoxDecoration(
      //   color: isMe ? Theme.of(context).accentColor : Color(0xFFFFEFEE),
      //   borderRadius: isMe
      //       ? BorderRadius.only(
      //           topLeft: Radius.circular(15.0),
      //           bottomLeft: Radius.circular(15.0),
      //         )
      //       : BorderRadius.only(
      //           topRight: Radius.circular(15.0),
      //           bottomRight: Radius.circular(15.0),
      //         ),
      // ),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: <Widget>[
      //     SizedBox(height: 8.0),
      //     Text(
      //       message,
      //       style: TextStyle(
      //         color: Colors.black,
      //         fontSize: 16.0,
      //         fontWeight: FontWeight.w600,
      //       ),
      //     ),
      //   ],
      // ),
      child: isMe
          ? FlatChatMessage(
              message: message,
              messageType: MessageType.sent,
              showTime: false,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            )
          : FlatChatMessage(
              message: message,
              showTime: false,
              backgroundColor: Colors.grey[300],
              textColor: Colors.green,
            ),
    );
    if (isMe) {
      return msg;
    }
    return Row(
      children: <Widget>[msg],
    );
  }

  _sendMessageArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      height: 70,
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 110,
                margin: const EdgeInsets.only(right: 10.0),
                child: ButtonTheme(
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.green)),
                    color: Colors.white,
                    textColor: Colors.green,
                    child: Text(
                      "Saya Tunggu Di TKP",
                      style: TextStyle(
                        fontSize: 13.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      messageController.text = "Saya Tunggu Di TKP";
                    },
                  ),
                ),
              ),
              Container(
                width: 120,
                margin: const EdgeInsets.only(right: 10.0),
                child: ButtonTheme(
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.green)),
                    color: Colors.white,
                    textColor: Colors.green,
                    child: Text(
                      "Terima Kasih",
                      style: TextStyle(
                        fontSize: 13.0,
                      ),
                    ),
                    onPressed: () {
                      messageController.text = "Terima Kasih";
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.photo),
                iconSize: 25,
                color: Theme.of(context).primaryColor,
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration.collapsed(
                    hintText: 'Send a message..',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                iconSize: 25,
                color: Theme.of(context).primaryColor,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  _buildMessageComposer(
      ScrollController scrollChatController, var locationOptions) {
    return Container(
      constraints: BoxConstraints(minHeight: 100),
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white,
      child: Column(
        children: [
          isCancel == true
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10.0),
                        child: ButtonTheme(
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Color(0xff1391DD))),
                            color: Colors.white,
                            textColor: Color(0xff1391DD),
                            child: Text(
                              "Cari Ulang",
                              style: TextStyle(
                                fontSize: 13.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () {
                              messageController.text = "Saya Sedang Ke Sana";
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10.0),
                        child: ButtonTheme(
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Color(0xff1391DD))),
                            color: Colors.white,
                            textColor: Color(0xff1391DD),
                            child: Text(
                              "Saya Sedang Ke Sana",
                              style: TextStyle(
                                fontSize: 13.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () {
                              messageController.text = "Saya Sedang Ke Sana";
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 10.0),
                        child: ButtonTheme(
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Color(0xff1391DD))),
                            color: Colors.white,
                            textColor: Color(0xff1391DD),
                            child: Text(
                              "Terima Kasih",
                              style: TextStyle(
                                fontSize: 13.0,
                              ),
                            ),
                            onPressed: () {
                              messageController.text = "Terima Kasih";
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder(
                  stream: this._geolocator.getPositionStream(locationOptions),
                  builder: (BuildContext context,
                      AsyncSnapshot<Position> snapshotCurrentPosition) {
                    Position positionPenolong;
                    if (snapshotCurrentPosition.data != null ||
                        positionPenolong != null) {
                      positionPenolong =
                          snapshotCurrentPosition.data ?? positionPenolong;
                      positionPenolong =
                          snapshotCurrentPosition.data ?? positionPenolong;
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 10.0),
                            child: ButtonTheme(
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Color(0xff1391DD))),
                                color: Colors.white,
                                textColor: Color(0xff1391DD),
                                child: Text(
                                  "Saya Sedang Ke Sana",
                                  style: TextStyle(
                                    fontSize: 13.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                onPressed: () {
                                  messageController.text =
                                      "Saya Sedang Ke Sana";
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10.0),
                            child: ButtonTheme(
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Color(0xff1391DD))),
                                color: Colors.white,
                                textColor: Color(0xff1391DD),
                                child: Text(
                                  "Terima Kasih",
                                  style: TextStyle(
                                    fontSize: 13.0,
                                  ),
                                ),
                                onPressed: () {
                                  messageController.text = "Terima Kasih";
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10.0),
                            child: ButtonTheme(
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Color(0xff1391DD))),
                                color: Colors.white,
                                textColor: Color(0xff1391DD),
                                child: Text(
                                  "Bagikan Lokasi",
                                  style: TextStyle(
                                    fontSize: 13.0,
                                  ),
                                ),
                                onPressed: () {
                                  messageController.text = "https://www.google.com/maps/place/${positionPenolong.latitude},${positionPenolong.longitude}/@${positionPenolong.latitude},${positionPenolong.longitude},16z";
                                  sendMessage(messageController.text, 0);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.photo),
                iconSize: 25,
                color: Theme.of(context).primaryColor,
                onPressed: () async {
                  _showPicker(context);
                },
              ),
              Expanded(
                child: Focus(
                  child: TextField(
                    onChanged: (val) {
                      streamController.add(val);
                    },
                    controller: messageController,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Send a message..',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                iconSize: 25,
                color: Theme.of(context).primaryColor,
                onPressed: () async {
                  await sendMessage(messageController.text, 0);
                  await scrollChatController.animateTo(
                      scrollChatController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.fastOutSlowIn);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
    return Scaffold(
      backgroundColor: Color(0xff1391DD),
      appBar: appBarChat(context),
      body: GestureDetector(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                    child: ChatMessageList()),
              ),
            ),
            cancelPermintaanTolong(),
            _buildMessageComposer(this._controllerScrollChat, locationOptions),
          ],
        ),
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool isSendByMe;
  MessageTile(this.message, this.isSendByMe);

  @override
  Widget build(BuildContext context) {
    if (isSendByMe == Constants.myName) {
      return Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
