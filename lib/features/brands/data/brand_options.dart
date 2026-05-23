class BrandOptions {
  static const String other = 'Diğer';

  static const Map<String, List<String>> byCategory = {
    'Mutfak': [
      'Karaca',
      'Korkmaz',
      'Emsan',
      'Schafer',
      'Arzum',
      'Philips',
      'Tefal',
      other,
    ],
    'Banyo': [
      'English Home',
      'Madame Coco',
      'Özdilek',
      'Taç',
      'Karaca Home',
      other,
    ],
    'Yatak Odası': [
      'Taç',
      'Karaca Home',
      'English Home',
      'Madame Coco',
      'Yataş',
      other,
    ],
    'Elektronik': [
      'Philips',
      'Arçelik',
      'Bosch',
      'Samsung',
      'Xiaomi',
      'Dyson',
      other,
    ],
    'Salon': ['IKEA', 'English Home', 'Madame Coco', 'Karaca Home', other],
  };

  static List<String> getBrands(String categoryName) {
    return byCategory[categoryName] ?? [other];
  }
}
