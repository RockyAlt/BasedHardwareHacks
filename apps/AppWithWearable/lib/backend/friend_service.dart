import 'package:friend_private/backend/database/box.dart';
import 'package:friend_private/backend/database/friend.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/backend/api_requests/api/server.dart';

class FriendService {
  final _friendBox = ObjectBoxUtil().box!.store.box<Friend>();

  Future<void> addFriend(String email) async {
    var response = await makeApiCall(
      // Just email here idk how the real thing would work, device ID?
      url: '${Env.apiBaseUrl}v1/user?email=$email',
      headers: {},
      method: 'GET',
      body: '',
    );

    if (response?.statusCode == 200) {
      var userData = jsonDecode(response!.body);
      final friend = Friend(userData['uid'], email, name: userData['name']);
      _friendBox.put(friend);
    } else {
      throw Exception('User not found');
    }
  }

  List<Friend> getFriends() {
    return _friendBox.getAll();
  }

  Future<void> removeFriend(int friendId) async {
    _friendBox.remove(friendId);
  }
}