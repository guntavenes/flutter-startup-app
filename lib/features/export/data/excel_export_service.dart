import 'dart:io';

import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/core/extensions/currency_extensions.dart';
import 'package:ceyizim_plus/core/extensions/date_extensions.dart';
import 'package:excel/excel.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  ExcelExportService._();

  static Future<String?> exportItems({required List<Item> items}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Ceyiz Listesi'];

    excel.delete('Sheet1');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 18,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#D96BA7'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#A9447A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final normalStyle = CellStyle(
      fontSize: 11,
      verticalAlign: VerticalAlign.Center,
    );

    final purchasedStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#E6F7EC'),
      fontColorHex: ExcelColor.fromHexString('#1F7A3A'),
      verticalAlign: VerticalAlign.Center,
    );

    final overdueStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FDECEC'),
      fontColorHex: ExcelColor.fromHexString('#B42318'),
      verticalAlign: VerticalAlign.Center,
    );

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('I1'));

    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Çeyiz Takip Listesi');
    titleCell.cellStyle = titleStyle;

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

    for (var column = 0; column < 9; column++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 1),
              )
              .cellStyle =
          headerStyle;
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    for (final item in items) {
      final isOverdue =
          !item.isPurchased &&
          item.estimatedPurchaseDate != null &&
          DateTime.fromMillisecondsSinceEpoch(
            item.estimatedPurchaseDate!,
          ).isBefore(todayStart);

      final rowStyle = item.isPurchased
          ? purchasedStyle
          : isOverdue
          ? overdueStyle
          : normalStyle;

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

      final rowIndex = sheet.maxRows - 1;

      for (var column = 0; column < 9; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            rowStyle;
      }
    }

    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 22);
    sheet.setColumnWidth(7, 30);
    sheet.setColumnWidth(8, 35);

    final bytes = excel.save();

    if (bytes == null) {
      return null;
    }

    final directory = await getTemporaryDirectory();

    final fileName =
        'ceyiz_listesi_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final tempFile = File('${directory.path}/$fileName');

    await tempFile.writeAsBytes(bytes);

    if (Platform.isAndroid) {
      MediaStore.ensureInitialized();
      MediaStore.appFolder = 'Ceyiz Takip';

      final mediaStore = MediaStore();

      final saveInfo = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      return saveInfo?.uri.toString();
    }

    if (Platform.isIOS) {
      final params = ShareParams(files: [XFile(tempFile.path)]);

      await SharePlus.instance.share(params);

      return tempFile.path;
    }

    return tempFile.path;
  }
}
