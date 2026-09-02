import 'dart:typed_data';

import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  PdfReportService._();

  static Future<void> createAndShare({
    required List<Item> items,
    required List<Category> categories,
    double? budget,
  }) async {
    final bytes = await buildReport(
      items: items,
      categories: categories,
      budget: budget,
    );
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(bytes: bytes, filename: 'ceyizim_raporu_$date.pdf');
  }

  static Future<Uint8List> buildReport({
    required List<Item> items,
    required List<Category> categories,
    double? budget,
  }) async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    final purchased = items.where((item) => item.isPurchased).toList();
    final remaining = items.where((item) => !item.isPurchased).toList();
    final spent = purchased.fold<double>(
      0,
      (sum, item) => sum + (item.purchasedPrice ?? 0),
    );
    final planned = remaining.fold<double>(
      0,
      (sum, item) => sum + (item.plannedPrice ?? 0),
    );
    final completion = items.isEmpty ? 0.0 : purchased.length / items.length;
    final money = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    final categoryById = {
      for (final category in categories) category.id: category,
    };

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFD95F9F)),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Çeyizim+ Raporu',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 20,
                  color: const PdfColor.fromInt(0xFF8E244E),
                ),
              ),
              pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now())),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${context.pageNumber} / ${context.pagesCount}'),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('Toplam ürün', '${items.length}', bold),
              _metric('Alınan', '${purchased.length}', bold),
              _metric('Kalan', '${remaining.length}', bold),
              _metric('Toplam harcama', money.format(spent), bold),
              if (budget != null) _metric('Bütçe', money.format(budget), bold),
              _metric('Planlanan', money.format(planned), bold),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Tamamlanma', style: pw.TextStyle(font: bold, fontSize: 15)),
          pw.SizedBox(height: 6),
          pw.Container(
            width: 500,
            height: 14,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFE4F0),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: 500 * completion,
                height: 14,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFD95F9F),
                  borderRadius: pw.BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('%${(completion * 100).round()} tamamlandı'),
          pw.SizedBox(height: 24),
          pw.Text(
            'Kategori Özeti',
            style: pw.TextStyle(font: bold, fontSize: 17),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Kategori', 'Toplam', 'Alınan', 'Kalan', 'Harcama'],
            data: categories.map((category) {
              final categoryItems = items
                  .where((item) => item.categoryId == category.id)
                  .toList();
              final categoryPurchased = categoryItems
                  .where((item) => item.isPurchased)
                  .toList();
              final categorySpent = categoryPurchased.fold<double>(
                0,
                (sum, item) => sum + (item.purchasedPrice ?? 0),
              );
              return [
                category.name,
                '${categoryItems.length}',
                '${categoryPurchased.length}',
                '${categoryItems.length - categoryPurchased.length}',
                money.format(categorySpent),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFA9447A),
            ),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Ürün Listesi',
            style: pw.TextStyle(font: bold, fontSize: 17),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Ürün', 'Kategori', 'Durum', 'Fiyat'],
            data: items.map((item) {
              final price = item.isPurchased
                  ? item.purchasedPrice
                  : item.plannedPrice;
              return [
                item.name,
                categoryById[item.categoryId]?.name ?? 'Kategori',
                item.isPurchased ? 'Alındı' : 'Bekliyor',
                price == null ? '-' : money.format(price),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFD95F9F),
            ),
            cellPadding: const pw.EdgeInsets.all(5),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _metric(String label, String value, pw.Font bold) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF2F7),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 13)),
        ],
      ),
    );
  }
}
