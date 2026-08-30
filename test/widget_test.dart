import 'package:ceyizim_plus/core/database/entity_id_generator.dart';
import 'package:ceyizim_plus/core/extensions/date_extensions.dart';
import 'package:ceyizim_plus/core/formatters/title_case_text_formatter.dart';
import 'package:ceyizim_plus/core/formatters/turkish_currency_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('üretilen kimlikler pozitif, güvenli aralıkta ve benzersizdir', () {
    final ids = List.generate(1000, (_) => EntityIdGenerator.next());

    expect(ids.every((id) => id > 0 && id < (1 << 52)), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('tarih uzantısı boş ve dolu değerleri biçimlendirir', () {
    int? emptyDate;
    final date = DateTime(2026, 8, 30).millisecondsSinceEpoch;

    expect(emptyDate.toShortDateText(), '-');
    expect(date.toShortDateText(), '30.08.2026');
  });

  test('başlık biçimlendirici kelimelerin ilk harfini büyütür', () {
    final result = TitleCaseTextFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'hello WORLD'),
    );

    expect(result.text, 'Hello World');
  });

  test('para biçimlendirici binlik ayırıcı ekler', () {
    final result = TurkishCurrencyInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1234567'),
    );

    expect(result.text, '1.234.567');
  });
}
