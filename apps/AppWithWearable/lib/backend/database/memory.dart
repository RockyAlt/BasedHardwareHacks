import 'dart:convert';
import 'dart:math';
import 'package:friend_private/backend/database/geolocation.dart';
import 'package:friend_private/backend/database/transcript_segment.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/backend/friend_service.dart';
import 'package:objectbox/objectbox.dart';

enum MemoryType { audio, image }

@Entity()
class Memory {
  @Id()
  int id = 0;

  @Index()
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime? startedAt;

  @Property(type: PropertyType.date)
  DateTime? finishedAt;

  @Property(type: PropertyType.date)
  DateTime? sharedAt;

  String? sharedByUid;

  final sharedWithFriends = ToMany<Friend>();

  String transcript;
  final transcriptSegments = ToMany<TranscriptSegment>();
  final photos = ToMany<MemoryPhoto>();

  String? recordingFilePath;

  final structured = ToOne<Structured>();

  @Backlink('memory')
  final pluginsResponse = ToMany<PluginResponse>();

  @Index()
  bool discarded;

  final geolocation = ToOne<Geolocation>();

  Memory(
    this.createdAt,
    this.transcript,
    this.discarded, {
    this.id = 0,
    this.recordingFilePath,
    this.startedAt,
    this.finishedAt,
  });

  MemoryType get type => transcript.isNotEmpty ? MemoryType.audio : MemoryType.image;

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
    if (json['pluginsResponse'] != null) {
      for (dynamic response in json['pluginsResponse']) {
        if (response.isEmpty) continue;
        if (response is String) {
          memory.pluginsResponse.add(PluginResponse(response));
        } else {
          memory.pluginsResponse.add(PluginResponse.fromJson(response));
        }
      }
    }

    if (json['transcriptSegments'] != null) {
      for (dynamic segment in json['transcriptSegments']) {
        if (segment.isEmpty) continue;
        memory.transcriptSegments.add(TranscriptSegment.fromJson(segment));
      }
    }

    if (json['photos'] != null) {
      for (dynamic photo in json['photos']) {
        if (photo.isEmpty) continue;
        memory.photos.add(MemoryPhoto.fromJson(photo));
      }
    }

    memory.sharedAt = json['sharedAt'] != null ? DateTime.parse(json['sharedAt']) : null;
    memory.sharedByUid = json['sharedByUid'];
    
    if (json['sharedWithFriends'] != null) {
      FriendService friendService = FriendService();
      for (String friendUid in json['sharedWithFriends']) {
        Friend? friend = friendService.getFriendByUid(friendUid);
        if (friend != null) {
          memory.sharedWithFriends.add(friend);
        }
      }
    }

    return memory;
  }

  String getTranscript({int? maxCount, bool generate = false}) {
    try {
      var transcript = generate && transcriptSegments.isNotEmpty
          ? TranscriptSegment.segmentsAsString(transcriptSegments, includeTimestamps: true)
          : this.transcript;
      var decoded = utf8.decode(transcript.codeUnits);
      if (maxCount != null) return decoded.substring(0, min(maxCount, decoded.length));
      return decoded;
    } catch (e) {
      return transcript;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'transcript': transcript,
      'recordingFilePath': recordingFilePath,
      'structured': structured.target!.toJson(),
      'pluginsResponse': pluginsResponse.map<Map<String, String?>>((response) => response.toJson()).toList(),
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
class Event {
  @Id()
  int id = 0;

  String title;
  DateTime startsAt;
  int duration;

  String description;
  bool created = false;
  bool isConfirmed = false;

  final structured = ToOne<Structured>();
  final invitedFriends = ToMany<Friend>();

  Event(this.title, this.startsAt, this.duration, {this.description = '', this.created = false, this.id = 0});

  void inviteFriend(Friend friend) {
    invitedFriends.add(friend);
  }

  void confirmEvent() {
    isConfirmed = true;
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

  static Event fromJson(Map<String, dynamic> json) {
    var event = Event(
      json['title'],
      DateTime.parse(json['startsAt']),
      json['duration'],
      description: json['description'] ?? '',
      created: json['created'] ?? false,
      id: json['id'],
    );
    event.isConfirmed = json['isConfirmed'] ?? false;
    
    if (json['invitedFriends'] != null) {
      FriendService friendService = FriendService();
      for (String friendUid in json['invitedFriends']) {
        Friend? friend = friendService.getFriendByUid(friendUid);
        if (friend != null) {
          event.invitedFriends.add(friend);
        }
      }
    }
    
    return event;
  }
}