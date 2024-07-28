import 'package:friend_private/backend/database/memory.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:objectbox/objectbox.dart';

import '../schema/plugin.dart';

enum MessageSender { ai, human }

enum MessageType { text, daySummary }

@Entity()
class Message {
  @Id()
  int id = 0;

  @Index()
  @Property(type: PropertyType.date)
  DateTime createdAt;

  String text;
  String sender;

  String? pluginId;
  bool fromIntegration;

  String type;

  final memories = ToMany<Memory>();

  Message(
    this.createdAt,
    this.text,
    MessageSender senderEnum, {
    this.id = 0,
    MessageType typeEnum = MessageType.text,
    this.pluginId,
    this.fromIntegration = false,
  })  : sender = senderEnum.toString().split('.').last,
        type = typeEnum.toString().split('.').last;

  MessageSender get senderEnum => MessageSender.values.firstWhere((e) => e.toString().split('.').last == sender);
  set senderEnum(MessageSender value) => sender = value.toString().split('.').last;

  MessageType get typeEnum => MessageType.values.firstWhere((e) => e.toString().split('.').last == type);
  set typeEnum(MessageType value) => type = value.toString().split('.').last;

  static String getMessagesAsString(
    List<Message> messages, {
    bool useUserNameIfAvailable = false,
    bool usePluginNameIfAvailable = false,
  }) {
    var sortedMessages = messages.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    List<Plugin> plugins = SharedPreferencesUtil().pluginsList;

    return sortedMessages.map((e) {
      var sender = e.sender == 'human'
          ? SharedPreferencesUtil().givenName.isNotEmpty && useUserNameIfAvailable
              ? SharedPreferencesUtil().givenName
              : 'User'
          : usePluginNameIfAvailable && e.pluginId != null
              ? plugins.firstWhere((p) => p.id == e.pluginId).name
              : e.sender.toString().toUpperCase();
      return '(${e.createdAt.toIso8601String().split('.')[0]}) $sender: ${e.text}';
    }).join('\n');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'text': text,
      'sender': sender,
      'type': type,
      'pluginId': pluginId,
      'fromIntegration': fromIntegration,
    };
  }

  static Message fromJson(Map<String, dynamic> json) {
    return Message(
      DateTime.parse(json['createdAt']),
      json['text'],
      MessageSender.values.firstWhere((e) => e.toString().split('.').last == json['sender']),
      id: json['id'],
      typeEnum: MessageType.values.firstWhere((e) => e.toString().split('.').last == json['type']),
      pluginId: json['pluginId'],
      fromIntegration: json['fromIntegration'] ?? false,
    );
  }
}