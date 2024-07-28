import 'package:objectbox/objectbox.dart';

@Entity()
class Friend {
  @Id()
  int id = 0;

  @Unique()
  String uid;
  String email;
  String? name;

  Friend(this.uid, this.email, {this.name});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
    };
  }

  static Friend fromJson(Map<String, dynamic> json) {
    return Friend(
      json['uid'],
      json['email'],
      name: json['name'],
    )..id = json['id'] ?? 0;
  }
}