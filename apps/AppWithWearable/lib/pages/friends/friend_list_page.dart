import 'package:flutter/material.dart';
import 'package:friend_private/backend/database/friend.dart';
import 'package:friend_private/backend/database/box.dart';

class FriendListPage extends StatefulWidget {
  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final _friendBox = ObjectBoxUtil().friendBox;
  List<Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() {
    setState(() {
      _friends = _friendBox.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Friends')),
      body: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return ListTile(
            title: Text(friend.name ?? friend.email),
            subtitle: Text(friend.email),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddFriendDialog() {
    String email = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Friend'),
        content: TextField(
          onChanged: (value) => email = value,
          decoration: InputDecoration(hintText: "Enter friend's email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final friend = Friend(email, email); // You might want to get the UID from a server
                _friendBox.put(friend);
                Navigator.pop(context);
                _loadFriends();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Friend added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text('Add Friend'),
          ),
        ],
      ),
    );
  }
}