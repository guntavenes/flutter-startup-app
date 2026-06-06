import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

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

    final directory = await getTemporaryDirectory();

    final fileName =
        'ceyiz_listesi_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final tempFile = File('${directory.path}/$fileName');

    await tempFile.writeAsBytes(bytes);

    final mediaStore = MediaStore();

    final saveInfo = await mediaStore.saveFile(
      tempFilePath: tempFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    return saveInfo?.uri.toString();
  }
}
