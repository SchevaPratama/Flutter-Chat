import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String userID;
  final String email;
  final String name;
  final String phone;
  User({this.userID, this.email, this.name,this.phone});

  @override
  // TODO: implement props
  @override
  List<Object> get props => [
        userID,
        email,
        name,
        phone
      ];
}
