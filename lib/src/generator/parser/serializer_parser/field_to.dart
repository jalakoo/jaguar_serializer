part of jaguar_serializer.generator.parser.serializer;

class FieldTo {
  PropertyTo property;

  String key;

  String name;

  FieldTo(this.key, this.name, this.property);
}

abstract class PropertyTo {}

class MapPropertyTo implements PropertyTo {
  final PropertyTo key;

  final String keyTypeStr;

  final PropertyTo value;

  final String valueTypeStr;

  const MapPropertyTo(this.key, this.keyTypeStr, this.value, this.valueTypeStr);
}

class ListPropertyTo implements PropertyTo {
  final PropertyTo value;

  final String itemTypeStr;

  const ListPropertyTo(this.value, this.itemTypeStr);
}

class LeafPropertyTo implements PropertyTo {}

class BuiltinLeafPropertyTo implements LeafPropertyTo {
  const BuiltinLeafPropertyTo();
}

class CustomPropertyTo implements LeafPropertyTo {
  final String instantiationString;

  const CustomPropertyTo(this.instantiationString);
}

class SerializedPropertyTo implements LeafPropertyTo {
  final String instantiationString;

  const SerializedPropertyTo(this.instantiationString);
}

PropertyTo _parsePropertyTo(
    SerializerInfo info, String fieldName, DartTypeWrap type) {
  if (type.isDynamic) {
    throw new Exception(
        'Cannot serialize "dynamic" type for property $fieldName!');
  } else if (type.isObject) {
    throw new Exception(
        'Cannot serialize "Object" type for property $fieldName!');
  }

  if (type.isList) {
    List<DartTypeWrap> params = type.typeArguments;
    if (params.length != 1) {
      throw new Exception('List should have exactly one type parameter!');
    }

    DartTypeWrap param = params[0];

    return new ListPropertyTo(
        _parsePropertyTo(info, fieldName, param), param.displayName);
  } else if (type.isMap) {
    List<DartTypeWrap> params = type.typeArguments;

    if (params.length != 2) {
      throw new Exception('Map should have exactly two type parameter!');
    }

    //TODO key should be only builtin?

    DartTypeWrap key = params[0];
    DartTypeWrap value = params[1];

    return new MapPropertyTo(
        _parsePropertyTo(info, fieldName, key),
        key.displayName,
        _parsePropertyTo(info, fieldName, value),
        value.displayName);
  } else if (type.isBuiltin) {
    return new BuiltinLeafPropertyTo();
  } else {
    DartTypeWrap ser;

    info.serializationProviders
        .forEach((DartTypeWrap modelType, DartTypeWrap serializer) {
      if (type.compareNamedElement(modelType)) {
        ser = serializer;
      }
    });

    if (ser == null) {
      throw new Exception(
          "Serializer not found for '${type.displayName} $fieldName'");
    }

    return new SerializedPropertyTo(ser.displayName);
  }
}

FieldTo _parseFieldTo(SerializerInfo info, ModelField field, String key) {
  if (info.customFieldCodecs.containsKey(field.name)) {
    return new FieldTo(key, field.name, new CustomPropertyTo(info.customFieldCodecs[field.name].name));
  } else {
    return new FieldTo(
        key, field.name, _parsePropertyTo(info, field.name, field.type));
  }
}
