import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:friend_private/backend/database/friend.dart';
import 'package:friend_private/backend/database/memory.dart';
import 'package:friend_private/backend/database/message.dart';
import '../../objectbox.g.dart';

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, "obx-example"));
    return ObjectBox._create(store);
  }
}

class ObjectBoxUtil {
  static final ObjectBoxUtil _instance = ObjectBoxUtil._internal();
  static ObjectBox? _box;

  factory ObjectBoxUtil() {
    return _instance;
  }

  ObjectBoxUtil._internal();

  static Future<void> init() async {
    _box = await ObjectBox.create();
  }

  ObjectBox? get box => _box;

  late final Box<Friend> friendBox;
  late final Box<Memory> memoryBox;
  late final Box<Message> messageBox;

  Future<void> initBoxes() async {
    friendBox = Box<Friend>(_box!.store);
    memoryBox = Box<Memory>(_box!.store);
    messageBox = Box<Message>(_box!.store);
  }
}