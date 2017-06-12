library example.field_manipulation;

import 'package:jaguar_serializer/serializer.dart';
import 'package:mongo_dart/mongo_dart.dart' as mgo;

part 'custom_field_processor.g.dart';

@DefineFieldProcessor()
class MongoId implements FieldProcessor<String, mgo.ObjectId> {
  final List<Symbol> fields;

  const MongoId({this.fields});

  String deserialize(mgo.ObjectId input) {
    return input.toHexString();
  }

  mgo.ObjectId serialize(String value) {
    return new mgo.ObjectId.fromHexString(value);
  }
}

@GenSerializer()
@MongoId(fields: const [#id])
@EnDecodeField(#id, asAndFrom: '_id')
class PlayerMongoSerializer extends Serializer<Player>
    with _$PlayerMongoSerializer {
  Player createModel() => new Player();
}

/// Player model for the game
class Player {
  String id;

  /// Name of the player
  String name;

  /// Email of the player
  String email;

  String toString() => 'Player($id, $name, $email)';
}

void main() {
  {
    PlayerMongoSerializer serializer = new PlayerMongoSerializer();
    Player player = serializer.fromMap({
      '_id': new mgo.ObjectId(),
      'name': 'John',
      'email': 'john@noemail.com',
    });
    // Player(581f4dacfda7b4f46b878489, John, john@noemail.com)
    print(player);
  }

  {
    Player player = new Player()
      ..id = '1' * 24
      ..name = 'John'
      ..email = 'john@noemail.com';
    PlayerMongoSerializer serializer = new PlayerMongoSerializer();
    Map map = serializer.toMap(player);
    // {_id: ObjectId("111111111111111111111111"), name: John, email: john@noemail.com}
    print(map);
  }
}
