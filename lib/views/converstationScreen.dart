import 'dart:io';

import 'package:flutchat/helper/constants.dart';
import 'package:flutchat/helper/helperfunction.dart';
import 'package:flutchat/services/database.dart';
import 'package:flutchat/widgets/widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConverstationScreen extends StatefulWidget {
  final String chatRoomId;
  final String type;
  ConverstationScreen(this.chatRoomId, this.type);
  @override
  _ConverstationScreenState createState() => _ConverstationScreenState();
}

class _ConverstationScreenState extends State<ConverstationScreen> {
  Future<void> _launched;
  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController messageController = new TextEditingController();
  String appBartext = "";
  String userChat = "";
  String numberPhone = "";
  ScrollController _controllerScrollChat;
  // final db = FirebaseFirestore.instance;
  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  String imagePath;

  Stream chatMessageStream;

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
                        snapshot.data.documents[index].data["content"],
                        snapshot.data.documents[index].data["time"],
                        snapshot.data.documents[index].data["sendBy"] ==
                            Constants.myName,
                        snapshot.data.documents[index].data["sendBy"],
                        snapshot.data.documents[index].data["type"],
                        _controllerScrollChat);
                    // return _buildMessageComposer(snapshot.data.documents[index].data["sendBy"] ==
                    //         Constants.myName);
                  },
                )
              : Container();
        });
  }

  getUserInfo() async {
    String username = widget.chatRoomId
        .toString()
        .replaceAll("_", "")
        .replaceAll(Constants.myName, "");
    Map profilePeminta = await DatabaseMethods.getUserProfile(username);
    setState(() {
      // userChat = profilePeminta['nama'];
      // numberPhone = profilePeminta['phone'];
    });
  }

  getGroupDetail() async {
    Map groupDetail =
        await DatabaseMethods.getChatRoomDetail(widget.chatRoomId);
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

  @override
  void initState() {
    this._controllerScrollChat = ScrollController();
    super.initState();
    print(widget.type);

    widget.type == 'personal' ? getUserInfo() : getGroupDetail();
    databaseMethods.getConverstationMessage(widget.chatRoomId).then((value) {
      setState(() {
        chatMessageStream = value;
      });
    });
    // SchedulerBinding.instance.addPostFrameCallback((_) async {
    //   await Future.delayed(Duration(milliseconds: 300)).then((value) async {
    //     await this._controllerScrollChat.animateTo(this._controllerScrollChat.position.maxScrollExtent, duration: const Duration(milliseconds: 700), curve: Curves.fastOutSlowIn);
    //   });
    // });
  }

  // Future getImage() async {
  //   ImagePicker imagePicker = ImagePicker();
  //   PickedFile pickedFile;

  //   pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
  //   imageFile = File(pickedFile.path);

  //   if (imageFile != null) {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     // uploadFile();
  //     DatabaseMethods.uploadImage(imageFile);
  //   }
  // }

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

  Future uploadFile() async {
    File imageCompressed = await FlutterNativeImage.compressImage(
      imageFile.path,
      quality: 20,
    );
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask task = ref.putFile(imageCompressed);
    StorageTaskSnapshot snapshot = await task.onComplete;

    var imagePath = await snapshot.ref.getPath();
    imageUrl = imagePath.toString();
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
                _launched = _makePhoneCall('tel:+6281515450165');
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
                _launched = _makePhoneCall('tel:+6281515450165');
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
                        "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
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
                    "${DateTime.fromMillisecondsSinceEpoch(time).month.toString()}-${DateTime.fromMillisecondsSinceEpoch(time).day.toString()} | ${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
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
                            "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
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
                            "${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
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
                        left: size.width * 0.04,
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
              margin: EdgeInsets.only(left: 20, bottom: 10),
              child: Row(
                children: <Widget>[
                  Text(
                    "${DateTime.fromMillisecondsSinceEpoch(time).month.toString()}-${DateTime.fromMillisecondsSinceEpoch(time).day.toString()} | ${DateTime.fromMillisecondsSinceEpoch(time).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(time).minute.toString()}",
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

  _buildMessageComposer(ScrollController scrollChatController) {
    return Container(
      constraints: BoxConstraints(minHeight: 100),
      padding: EdgeInsets.symmetric(horizontal: 8),
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
                child: TextField(
                  controller: messageController,
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
            _buildMessageComposer(this._controllerScrollChat),
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
