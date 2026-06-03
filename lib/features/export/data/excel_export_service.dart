import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';

class ExcelExportService {
  ExcelExportService._();

  static Future<String?> exportItems({required List<Item> items}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Ceyiz Listesi'];

    sheet.appendRow([
      TextCellValue('Ürün'),
      TextCellValue('Durum'),
      TextCellValue('Marka'),
      TextCellValue('Model'),
      TextCellValue('Fiyat'),
      TextCellValue('Alınma Tarihi'),
      TextCellValue('Hedef Alınma Tarihi'),
      TextCellValue('Link'),
      TextCellValue('Not'),
    ]);

    for (final item in items) {
      sheet.appendRow([
        TextCellValue(item.name),
        TextCellValue(item.isPurchased ? 'Alındı' : 'Alınmadı'),
        TextCellValue(item.brand ?? ''),
        TextCellValue(item.model ?? ''),
        TextCellValue(
          item.isPurchased ? (item.purchasedPrice ?? 0).toCurrency() : '',
        ),
        TextCellValue(
          item.isPurchased ? item.purchaseDate.toShortDateText() : '',
        ),
        TextCellValue(
          !item.isPurchased && item.estimatedPurchaseDate != null
              ? item.estimatedPurchaseDate.toShortDateText()
              : '',
        ),
        TextCellValue(item.link ?? ''),
        TextCellValue(item.note ?? ''),
      ]);
    }

    excel.delete('Sheet1');

    final bytes = excel.save();

    if (bytes == null) {
      return null;
    }

    final fileName = 'ceyiz_listesi_${DateTime.now().millisecondsSinceEpoch}';

    return FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
