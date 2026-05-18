import '../domain/template_item.dart';

class CeyizTemplates {
  static const String basic = 'Basic';
  static const String standard = 'Standart';
  static const String premium = 'Premium';

  static final List<TemplateItem> basicItems = [
    // Mutfak
    TemplateItem(categoryName: 'Mutfak', name: 'Tencere seti'),
    TemplateItem(categoryName: 'Mutfak', name: 'Çatal kaşık bıçak seti'),
    TemplateItem(categoryName: 'Mutfak', name: 'Tabak seti'),
    TemplateItem(categoryName: 'Mutfak', name: 'Bardak seti'),
    TemplateItem(categoryName: 'Mutfak', name: 'Çaydanlık'),

    // Yatak Odası
    TemplateItem(categoryName: 'Yatak Odası', name: 'Nevresim takımı'),
    TemplateItem(categoryName: 'Yatak Odası', name: 'Yorgan'),
    TemplateItem(categoryName: 'Yatak Odası', name: 'Yastık'),

    // Banyo
    TemplateItem(categoryName: 'Banyo', name: 'Havlu seti'),
    TemplateItem(categoryName: 'Banyo', name: 'Bornoz seti'),
  ];

  static final List<TemplateItem> standardItems = [
    ...basicItems,

    TemplateItem(categoryName: 'Mutfak', name: 'Blender seti'),
    TemplateItem(categoryName: 'Mutfak', name: 'Kahvaltı takımı'),
    TemplateItem(categoryName: 'Mutfak', name: 'Saklama kabı seti'),

    TemplateItem(categoryName: 'Salon', name: 'Dekoratif yastık'),
    TemplateItem(categoryName: 'Salon', name: 'Halı'),

    TemplateItem(categoryName: 'Banyo', name: 'Çamaşır sepeti'),
  ];

  static final List<TemplateItem> premiumItems = [
    ...standardItems,

    TemplateItem(categoryName: 'Mutfak', name: 'Airfryer'),
    TemplateItem(categoryName: 'Mutfak', name: 'Kahve makinesi'),
    TemplateItem(categoryName: 'Mutfak', name: 'Stand mikser'),

    TemplateItem(categoryName: 'Salon', name: 'Robot süpürge'),
    TemplateItem(categoryName: 'Salon', name: 'Dekoratif ayna'),

    TemplateItem(categoryName: 'Yatak Odası', name: 'Yedek nevresim seti'),

    TemplateItem(categoryName: 'Banyo', name: 'Organizer seti'),
  ];
}
