import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutchat/helper/constants.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/services.dart';
import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutter/material.dart';

class ConverstationScreen extends StatefulWidget {
  final String? chatRoomId;
  ConverstationScreen(this.chatRoomId);
  @override
  _ConverstationScreenState createState() => _ConverstationScreenState();
}

class _ConverstationScreenState extends State<ConverstationScreen> {
  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController messageController = new TextEditingController();
  String? username;
  File? imageFile;
  bool? isLoading;
  String? imageUrl;

  Stream? chatMessageStream;

  Widget ChatMessageList() {
    return StreamBuilder(
        stream: chatMessageStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: (snapshot.data! as QuerySnapshot).docs.length,
                  itemBuilder: (context, index) {
                    return _chatBubble(
                      context,
                      ((snapshot.data! as QuerySnapshot).docs[index].data()
                          as Map<String, dynamic>)["message"],
                      ((snapshot.data! as QuerySnapshot).docs[index].data()
                              as Map<String, dynamic>)["sendBy"] ==
                          Constants.myName,
                      ((snapshot.data! as QuerySnapshot).docs[index].data()
                          as Map<String, dynamic>)["sendBy"],
                      ((snapshot.data! as QuerySnapshot).docs[index].data()
                          as Map<String, dynamic>)["type"],
                      ((snapshot.data! as QuerySnapshot).docs[index].data()
                          as Map<String, dynamic>)["time"],
                    );
                  },
                )
              : Container();
        });
  }

  Future getImageGallery() async {
    ImagePicker imagePicker = ImagePicker();
    final pickedFile;

    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    imageFile = File(pickedFile!.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future getImageCamera() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.camera);
    imageFile = File(pickedFile!.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
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
                    leading: new Icon(
                      Icons.photo_library,
                      color: Color(0XFF0D7FCC),
                    ),
                    title: new Text(
                      'Galeri',
                      style: TextStyle(
                        color: Color(0XFF0D7FCC),
                      ),
                    ),
                    onTap: () {
                      getImageGallery();
                      Navigator.of(context).pop();
                    }),
                new ListTile(
                  leading: new Icon(
                    Icons.photo_camera,
                    color: Color(0XFF0D7FCC),
                  ),
                  title: new Text(
                    'Kamera',
                    style: TextStyle(
                      color: Color(0XFF0D7FCC),
                    ),
                  ),
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

  Future uploadFile() async {
    File imageCompressed = await FlutterNativeImage.compressImage(
      imageFile!.path,
      quality: 20,
    );
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    storage.Reference reference = storage.FirebaseStorage.instance
        .ref()
        .child('chatImage')
        .child(widget.chatRoomId!)
        .child(fileName);
    storage.UploadTask uploadTask = reference.putFile(imageCompressed);
    var imagePath = await (await uploadTask).ref.fullPath;
    // TaskSnapshot storageTaskSnapshot = await uploadTask.snapshot.ref.fullPath;
    imageUrl = imagePath;
    return sendMessage(imageUrl!, 1);
  }

  sendMessage(String content, int type) {
    if (content.trim() != '') {
      messageController.clear();
      Map<String, dynamic> messageMap = {
        "message": content,
        "sendBy": Constants.myName,
        "time": DateTime.now().toUtc(),
        "type": type
      };
      databaseMethods.addConverstationMessage(widget.chatRoomId, messageMap);
    }
  }

  @override
  void initState() {
    databaseMethods.getConverstationMessage(widget.chatRoomId).then((value) {
      setState(() {
        chatMessageStream = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0XFF0D7FCC),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            BackButton(),
            // CircleAvatar(
            //   backgroundImage: AssetImage("assets/images/user_2.png"),
            // ),
            SizedBox(width: 20.0 * 0.75),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoomId
                      .toString()
                      .replaceAll("_", "")
                      .replaceAll(Constants.myName as String, ""),
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Toko Tokoan",
                  style: TextStyle(fontSize: 12),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.local_phone),
            onPressed: () {},
          ),
          SizedBox(width: 20.0 / 2),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ChatMessageList(),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 5.0,
                vertical: 15.0,
              ),
              decoration: BoxDecoration(
                // color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 4),
                    blurRadius: 32,
                    color: Color(0xFF087949).withOpacity(0.08),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF1B80D3).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showPicker(context);
                              },
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF1B80D3),
                              ),
                            ),
                            SizedBox(width: 15.0),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Type message",
                                  hintStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                sendMessage(messageController.text, 0);
                              },
                              child: Icon(
                                Icons.send,
                                color: Color(0xFF1B80D3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_chatBubble(context, String? message, bool isSendByMe, String? sender,
    int? type, Timestamp time) {
  if (isSendByMe) {
    if (type == 0) {
      return Container(
        margin: EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.only(left: 0, right: 12),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  width: 300,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0 * 0.75,
                      vertical: 20.0 / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1BA0E2).withOpacity(1),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                          bottomLeft: Radius.circular(23)),
                    ),
                    child: Text(
                      message!,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Text(
                    // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                    DateTimeFormat.format(time.toDate(), format: 'j M Y H:i'),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (type == 1) {
      return Container(
        margin: EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: FutureBuilder(
                                              future:
                                                  DatabaseMethods.getUrlImage(
                                                      message!),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot snapshot) {
                                                if (snapshot.connectionState ==
                                                        ConnectionState.done &&
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
                      padding: EdgeInsets.only(left: 0, right: 12),
                      margin: EdgeInsets.symmetric(vertical: 6),
                      width: 300,
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 300, // 45% of total width
                        child: AspectRatio(
                          aspectRatio: 1.6,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder(
                                  future: DatabaseMethods.getUrlImage(message!),
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
                                      return Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                new AlwaysStoppedAnimation<
                                                    Color>(Color(0xFF1BA0E2)),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ),
                Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Text(
                    // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                    DateTimeFormat.format(time.toDate(), format: 'j M Y H:i'),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }
  } else {
    if (type == 0) {
      return Container(
        margin: EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 10, top: 10),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Color(0xFF023e8a),
                  borderRadius: BorderRadius.circular(40)),
              child: Text(
                "${sender!.substring(0, 1)}",
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(left: 5, right: 0),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  width: 300,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0 * 0.75,
                      vertical: 20.0 / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF023e8a),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                          bottomRight: Radius.circular(23)),
                    ),
                    child: Text(
                      message!,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 12),
                  child: Text(
                    // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                    DateTimeFormat.format(time.toDate(), format: 'j M Y H:i'),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    } else if (type == 1) {
      return Container(
        margin: EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 10, top: 10),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Color(0xFF023e8a),
                  borderRadius: BorderRadius.circular(40)),
              child: Text(
                "${sender!.substring(0, 1)}",
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: FutureBuilder(
                                              future:
                                                  DatabaseMethods.getUrlImage(
                                                      message!),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot snapshot) {
                                                if (snapshot.connectionState ==
                                                        ConnectionState.done &&
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
                    padding: EdgeInsets.only(left: 5, right: 0),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    width: 300,
                    alignment: Alignment.bottomLeft,
                    child: SizedBox(
                      width: 300, // 45% of total width
                      child: AspectRatio(
                        aspectRatio: 1.6,
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder(
                                  future: DatabaseMethods.getUrlImage(message!),
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
                                      return Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                new AlwaysStoppedAnimation<
                                                    Color>(Color(0xFF023e8a)),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 12),
                  child: Text(
                    // "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
                    DateTimeFormat.format(time.toDate(), format: 'j M Y H:i'),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }
  }
}

class MessageTile extends StatelessWidget {
  final String? message;
  final bool isSendByMe;
  final String? sender;
  final int? type;
  MessageTile(this.message, this.isSendByMe, this.sender, this.type);

  @override
  Widget build(BuildContext context) {
    return isSendByMe
        ? Container(
            margin: EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(left: 0, right: 12),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  width: 300,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0 * 0.75,
                      vertical: 20.0 / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1BA0E2).withOpacity(1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      message!,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            margin: EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 10, top: 10),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40)),
                  child: Text(
                    "${sender!.substring(0, 1)}",
                    style: TextStyle(
                        color: Color(0xFF1494C6),
                        fontFamily: 'Poppins',
                        fontSize: 14),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 5, right: 0),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  width: 300,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0 * 0.75,
                      vertical: 20.0 / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1494C6).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      message!,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          );
  }
}
