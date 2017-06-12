///@nodoc
library jaguar_serializer.generator.writer;

import 'package:jaguar_serializer/src/generator/parser/serializer_parser/serializer_parser.dart';

part 'to_item.dart';

part 'from_item.dart';

class SerializerWriter {
  final SerializerWriteInfo info;
  List<String> _providersTo = [];
  List<String> _providersFrom = [];
  List<String> _customsProcessors = [];

  StringBuffer _w = new StringBuffer();

  SerializerWriter(this.info);

  String toString() => _w.toString();

  void generate() {
    _w.writeln('abstract class _\$' +
        info.name +
        ' implements Serializer<${info.className}> {');
    _w.writeln();

    _providerWriter();

    _toWriter();

    _fromWriter();

    _w.writeln('String modelString() => "${info.modelName}";');

    _w.writeln('}');
  }

  void _serializedPropertyToWriter(PropertyTo to) {
    if (to is SerializedPropertyTo) {
      if (_providersTo.contains(to.instantiationString)) {
        return;
      }
      _providersTo.add(to.instantiationString);
      _w.writeln(
          'final ${to.instantiationString} to${to.instantiationString} = new ${to.instantiationString}();');
    } else if (to is ListPropertyTo) {
      _serializedPropertyToWriter(to.value);
    } else if (to is MapPropertyTo) {
      _serializedPropertyToWriter(to.key);
      _serializedPropertyToWriter(to.value);
    }
  }

  void _serializedPropertyFromWriter(PropertyFrom from) {
    if (from is SerializedPropertyFrom) {
      if (_providersFrom.contains(from.instantiationString)) {
        return;
      }
      _providersFrom.add(from.instantiationString);
      _w.writeln('final ${from.instantiationString} from${from
              .instantiationString} = new ${from.instantiationString}();');
    } else if (from is ListPropertyFrom) {
      _serializedPropertyFromWriter(from.value);
    } else if (from is MapPropertyFrom) {
      _serializedPropertyFromWriter(from.key);
      _serializedPropertyFromWriter(from.value);
    }
  }

  void _serializedPropertyCustomWriter(
      String key, CustomFieldCodecInfo customProcessor) {
    if (!_customsProcessors.contains("${customProcessor.name}")) {
      _customsProcessors.add("${customProcessor.name}");
      _w.writeln(
          'final ${customProcessor.type} ${customProcessor.name} = const ${customProcessor.instantiationString};');
    }
  }

  void _providerWriter() {
    info.customFieldCodecs.forEach(_serializedPropertyCustomWriter);
    info.to.forEach((FieldTo item) {
      _serializedPropertyToWriter(item.property);
    });
    info.from.forEach((FieldFrom item) {
      _serializedPropertyFromWriter(item.property);
    });
    _w.writeln("");
  }

  void _toWriter() {
    _w.writeln(
        'Map toMap(${info.className} model, {bool withType: false, String typeKey}) {');
    _w.writeln(r'Map ret = new Map();');

    _w.writeln('if(model != null) {');

    for (FieldTo item in info.to) {
      _toItemWriter(item);
    }

    if (info.typeInfo) {
      _typeKey();
    }

    _w.writeln('}');

    _w.writeln(r'return ret;');
    _w.writeln(r'}');
  }

  void _typeKey() {
    _w.writeln('if(modelString() != null && withType) {');

    _w.write('ret[typeKey ?? defaultTypeInfoKey] = modelString();');

    _w.writeln('}');
  }

  void _toItemWriter(FieldTo item) {
    final String itemStr = 'model.${item.name}';

    _w.writeln('if($itemStr != null) {');

    _w.write('ret["${item.key}"] = ');
    ToItemWriter writer = new ToItemWriter(item.property);
    _w.write(writer.generate('model.${item.name}'));
    _w.write(';');

    _w.writeln('}');
  }

  void _fromWriter() {
    _w.writeln(
        '${info.className} fromMap(Map map, {${info.className} model, String typeKey}) {');
    _w.writeln(r'if(map is! Map) {');
    _w.writeln(r'return null;');
    _w.writeln(r'}');

    _w.writeln('if(model is! ${info.className}) {');
    _w.writeln(r'model = createModel();');
    _w.writeln(r'}');

    for (FieldFrom item in info.from) {
      _fromItemWriter(item);
    }

    _w.writeln(r'return model;');
    _w.writeln(r'}');
  }

  void _fromItemWriter(FieldFrom item) {
    _w.write('model.${item.name} = ');
    FromItemWriter writer = new FromItemWriter(item.property);
    _w.write(writer.generate('map["${item.key}"]'));
    _w.write(';');
  }
}
