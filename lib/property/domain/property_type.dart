
enum PropertyType { sfm, multifamily, commercial }

String mapPropertyType(PropertyType t) {
  switch (t) {
    case PropertyType.sfm:
      return "single_family";
    case PropertyType.multifamily:
      return "multi_family";
    case PropertyType.commercial:
      return "commercial";
  }
}
