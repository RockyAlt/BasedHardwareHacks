import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import 'package:friend_private/backend/database/geolocation.dart';
import 'package:friend_private/backend/preferences.dart';

@Entity()
class Memory {
  @Id()
  int id = 0;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime? startedAt;

  @Property(type: PropertyType.date)
  DateTime? finishedAt;

  String transcript;
  final transcriptSegments = ToMany<TranscriptSegment>();
  final photos = ToMany<MemoryPhoto>();

  String? recordingFilePath;
  String? recordingFileBase64;

  final structured = ToOne<Structured>();

  final pluginsResponse = ToMany<PluginResponse>();

  bool discarded;

  final geolocation = ToOne<Geolocation>();

  @Property(type: PropertyType.date)
  DateTime? sharedAt;

  String? sharedByUid;

  final sharedWithFriends = ToMany<Friend>();

  Memory(
    this.createdAt,
    this.transcript,
    this.discarded, {
    this.id = 0,
    this.recordingFilePath,
    this.startedAt,
    this.finishedAt,
  });

  static String memoriesToString(List<Memory> memories, {bool includeTranscript = false}) => memories
      .map((e) => '''
      ${e.createdAt.toIso8601String().split('.')[0]}
      Title: ${e.structured.target!.title}
      Summary: ${e.structured.target!.overview}
      ${e.structured.target!.actionItems.isNotEmpty ? 'Action Items:' : ''}
      ${e.structured.target!.actionItems.map((item) => '  - ${item.description}').join('\n')}
      Category: ${e.structured.target!.category}
      ${includeTranscript ? 'Transcript:\n${e.transcript}' : ''}
      '''
          .replaceAll('      ', '')
          .trim())
      .join('\n\n');

  static Memory fromJson(Map<String, dynamic> json) {
    var memory = Memory(
      DateTime.parse(json['createdAt']),
      json['transcript'],
      json['discarded'],
      recordingFilePath: json['recordingFilePath'],
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt']) : null,
    );
    memory.structured.target = Structured.fromJson(json['structured']);
    memory.recordingFileBase64 = json['recordingFileBase64'];
    
    if (json['pluginsResponse'] != null) {
      for (var response in json['pluginsResponse']) {
        memory.pluginsResponse.add(PluginResponse.fromJson(response));
      }
    }

    if (json['transcriptSegments'] != null) {
      for (var segment in json['transcriptSegments']) {
        memory.transcriptSegments.add(TranscriptSegment.fromJson(segment));
      }
    }

    if (json['photos'] != null) {
      for (var photo in json['photos']) {
        memory.photos.add(MemoryPhoto.fromJson(photo));
      }
    }

    memory.sharedAt = json['sharedAt'] != null ? DateTime.parse(json['sharedAt']) : null;
    memory.sharedByUid = json['sharedByUid'];
    
    return memory;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'transcript': transcript,
      'recordingFilePath': recordingFilePath,
      'recordingFileBase64': recordingFileBase64,
      'structured': structured.target!.toJson(),
      'pluginsResponse': pluginsResponse.map((response) => response.toJson()).toList(),
      'discarded': discarded,
      'transcriptSegments': transcriptSegments.map((segment) => segment.toJson()).toList(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'sharedAt': sharedAt?.toIso8601String(),
      'sharedByUid': sharedByUid,
      'sharedWithFriends': sharedWithFriends.map((friend) => friend.uid).toList(),
    };
  }

  bool isShared() {
    return sharedAt != null && sharedByUid != null;
  }

  void shareWithFriend(Friend friend) {
    sharedWithFriends.add(friend);
    sharedAt = DateTime.now();
    sharedByUid = SharedPreferencesUtil().uid;
  }
}

@Entity()
class Structured {
  @Id()
  int id = 0;

  String title;
  String overview;
  String emoji;
  String category;

  final actionItems = ToMany<ActionItem>();
  final events = ToMany<Event>();

  Structured(this.title, this.overview, {this.id = 0, this.emoji = '', this.category = 'other'});

  static Structured fromJson(Map<String, dynamic> json) {
    var structured = Structured(
      json['title'],
      json['overview'],
      emoji: json['emoji'],
      category: json['category'],
    );
    
    if (json['actionItems'] != null) {
      for (var item in json['actionItems']) {
        structured.actionItems.add(ActionItem(item));
      }
    }

    if (json['events'] != null) {
      for (var event in json['events']) {
        structured.events.add(Event.fromJson(event));
      }
    }
    
    return structured;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'overview': overview,
      'emoji': emoji,
      'category': category,
      'actionItems': actionItems.map((item) => item.description).toList(),
      'events': events.map((event) => event.toJson()).toList(),
    };
  }
}

@Entity()
class ActionItem {
  @Id()
  int id = 0;

  String description;

  ActionItem(this.description, {this.id = 0});
}

@Entity()
class Event {
  @Id()
  int id = 0;

  String title;
  @Property(type: PropertyType.date)
  DateTime startsAt;
  int duration;
  String description;
  bool created;
  bool isConfirmed;

  final invitedFriends = ToMany<Friend>();

  Event(this.title, this.startsAt, this.duration, {this.description = '', this.created = false, this.isConfirmed = false, this.id = 0});

  void inviteFriend(Friend friend) {
    invitedFriends.add(friend);
  }

  void confirmEvent() {
    isConfirmed = true;
  }

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      json['title'],
      DateTime.parse(json['startsAt']),
      json['duration'],
      description: json['description'] ?? '',
      created: json['created'] ?? false,
      isConfirmed: json['isConfirmed'] ?? false,
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startsAt': startsAt.toIso8601String(),
      'duration': duration,
      'description': description,
      'created': created,
      'isConfirmed': isConfirmed,
      'invitedFriends': invitedFriends.map((friend) => friend.uid).toList(),
    };
  }
}

@Entity()
class MemoryPhoto {
  @Id()
  int id = 0;

  String base64;
  String description;

  MemoryPhoto(this.base64, this.description, {this.id = 0});

  static MemoryPhoto fromJson(Map<String, dynamic> json) {
    return MemoryPhoto(json['base64'], json['description'], id: json['id']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'base64': base64,
      'description': description,
    };
  }
}

@Entity()
class PluginResponse {
  @Id()
  int id = 0;

  String? pluginId;
  String content;

  PluginResponse(this.content, {this.id = 0, this.pluginId});

  static PluginResponse fromJson(Map<String, dynamic> json) {
    return PluginResponse(json['content'], id: json['id'], pluginId: json['pluginId']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pluginId': pluginId,
      'content': content,
    };
  }
}

@Entity()
class TranscriptSegment {
  @Id()
  int id = 0;

  String text;
  String speaker;
  int speakerId;
  bool isUser;
  double start;
  double end;

  TranscriptSegment(this.text, this.speaker, this.speakerId, this.isUser, this.start, this.end, {this.id = 0});

  static TranscriptSegment fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      json['text'],
      json['speaker'],
      json['speaker_id'],
      json['is_user'],
      json['start'],
      json['end'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'speaker': speaker,
      'speaker_id': speakerId,
      'is_user': isUser,
      'start': start,
      'end': end,
    };
  }
}

@Entity()
class Friend {
  @Id()
  int id = 0;

  @Unique()
  String uid;
  String email;
  String? name;

  Friend(this.uid, this.email, {this.name, this.id = 0});

  static Friend fromJson(Map<String, dynamic> json) {
    return Friend(json['uid'], json['email'], name: json['name'], id: json['id']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
    };
  }
}