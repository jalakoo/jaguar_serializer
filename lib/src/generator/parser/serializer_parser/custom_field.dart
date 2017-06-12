part of jaguar_serializer.generator.parser.serializer;

class CustomFieldCodecInfo {
  final String name;
  final String type;
  final NodeListImpl arguments;

  String get instantiationString {
    var args = arguments
        .where((node) => node is! NamedExpression)
        .map((node) => node.toString())
    .toList();

    arguments
        .where((node) => node is NamedExpression)
        .map((node) => node as NamedExpression)
        .forEach((node) {
      print("[${node.name.beginToken}]");
    });

    args.addAll(arguments
        .where((node) => node is NamedExpression)
        .map((node) => node as NamedExpression)
        .where((NamedExpression node) => node.name.beginToken.toString() != "fields")
        .map((NamedExpression node) => node.toString()));



    String str = "$type(${args.join(", ")})";

    return str;
  }

  CustomFieldCodecInfo(this.type, this.name, this.arguments);
}

void _parseCustomField(
    SerializerInfo ret, AnnotationElementWrap annot, int idx) {
  if (annot.element is! ConstructorElement) {
    return null;
  }

  if (annot.element.enclosingElement is! ClassElement) {
    return null;
  }

  ClassElementWrap clazz = new ClassElementWrap(annot.element.enclosingElement);

  DefineFieldProcessor defFieldProc = clazz.metadata
      .map((AnnotationElementWrap annotDef) => annotDef.instantiated)
      .firstWhere((annotDef) => annotDef is DefineFieldProcessor,
          orElse: () => null);

  if (defFieldProc is! DefineFieldProcessor) {
    return null;
  }

  InterfaceTypeWrap fieldPross = clazz.allSupertypes.firstWhere(
      (InterfaceTypeWrap interface) =>
          interface.compareNamedElement(kFieldProcessor),
      orElse: () => null);

  if (fieldPross is! InterfaceTypeWrap) {
    return null;
  }

  annot.constantValue
      .getField('fields')
      .toListValue()
      .map((DartObject obj) => obj?.toSymbolValue())
      .where((String v) => v != null)
      .forEach((String key) {
    ret.customFieldCodecs[key] = new CustomFieldCodecInfo(
        annot.name, "_$idx${annot.name}", annot.argumentAst);
  });
}

void _collectCustomFields(SerializerInfo ret, ClassElementWrap clazz) {
  int idx = 1;
  clazz.metadata.forEach((annot) => _parseCustomField(ret, annot, idx++));
}
