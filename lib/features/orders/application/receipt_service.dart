import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/money.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/order.dart';

class ReceiptPdfException implements Exception {
  const ReceiptPdfException(this.message, [this.error, this.stackTrace]);

  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

class _ReceiptAssets {
  static ByteData? _regular;
  static ByteData? _bold;
  static ByteData? _logo;

  static Future<ByteData> regular() async => _regular ??= await _load('assets/fonts/NotoSans-Regular.ttf');

  static Future<ByteData> bold() async => _bold ??= await _load('assets/fonts/NotoSans-Bold.ttf');

  static Future<ByteData> logo() async => _logo ??= await _load('assets/branding/logo.png');

  static Future<ByteData> _load(String asset) async => rootBundle.load(asset);
}

class ReceiptPdfService {
  ReceiptPdfService._();

  static Future<Uint8List> build(Order order) async {
    try {
      debugPrint('ReceiptPdfService.build: step 1/6 loading regular font');
      final regular = await _ReceiptAssets.regular();

      debugPrint('ReceiptPdfService.build: step 2/6 loading bold font');
      final bold = await _ReceiptAssets.bold();

      debugPrint('ReceiptPdfService.build: step 3/6 loading logo');
      final logo = await _ReceiptAssets.logo();

      debugPrint('ReceiptPdfService.build: step 4/6 building QR');
      final document = await _buildDocument(order, regular, bold, logo);

      debugPrint('ReceiptPdfService.build: step 5/6 saving PDF');
      final bytes = await document.save();
      debugPrint('ReceiptPdfService.build: step 6/6 complete');
      return bytes;
    } catch (error, stackTrace) {
      debugPrint('ReceiptPdfService.build failed with error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw ReceiptPdfException(
        'We could not generate your receipt. Please try again.',
        error,
        stackTrace,
      );
    }
  }

  static Future<void> print(Order order) async {
    final bytes = await build(order);
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'PawPick-${order.number}.pdf',
    );
  }

  static Future<void> sharePdfBytes(Uint8List bytes, String number) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'PawPick-$number.pdf',
    );
  }

  static Future<pw.Document> _buildDocument(
    Order order,
    ByteData regular,
    ByteData bold,
    ByteData logo,
  ) async {
    final baseFont = pw.Font.ttf(regular);
    final boldFont = pw.Font.ttf(bold);
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final isGiftOrder = order.paymentMethod.toLowerCase() == 'gift';
    final document = pw.Document(theme: theme);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) => <pw.Widget>[
          pw.Row(
            children: [
              pw.Image(
                pw.MemoryImage(logo.buffer.asUint8List()),
                height: 36,
                width: 36,
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAWPICK',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Little things. Big joy.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Order ${order.number}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            'Placed ${order.createdAt.toLocal().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 16),
          if (order.address.fullName.isNotEmpty) ...[
            pw.Text('Deliver to ${order.address.fullName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(order.address.label),
          ],
          pw.Text('Payment: ${order.paymentMethod}'),
          pw.SizedBox(height: 18),
          _itemsTable(order, isGiftOrder),
          pw.SizedBox(height: 18),
          _totalsTable(order, isGiftOrder),
          pw.SizedBox(height: 22),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: order.number,
              width: 90,
              height: 90,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'Scan to view order ${order.number}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'Thank you for bringing home big joy!',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'We hope your pet loves it. 🐾',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
    return document;
  }

  static pw.Widget _itemsTable(Order order, bool isGiftOrder) {
    final rows = <List<String>>[];
    for (final item in order.items) {
      final details = _variantLabel(item);
      final label = details.isEmpty ? item.name : '$item.name\n$details';
      rows.add(
        isGiftOrder
            ? [label, '${item.quantity}']
            : [
                label,
                '${item.quantity}',
                Money.format(item.unitPriceMinor),
                Money.format(item.unitPriceMinor * item.quantity),
              ],
      );
    }

    return pw.Table(
      columnWidths: isGiftOrder
          ? {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FixedColumnWidth(36),
            }
          : {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FixedColumnWidth(36),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(1.6),
            },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text(
                'Item',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text(
                'Qty',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
            if (!isGiftOrder) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  'Price',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  'Total',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        ...rows.map((row) {
          final itemCell = pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(
              row[0],
              softWrap: true,
              maxLines: 2,
              style: const pw.TextStyle(fontSize: 10),
            ),
          );

          final qtyCell = pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(
              row[1],
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10),
            ),
          );

          if (isGiftOrder) {
            return pw.TableRow(children: [itemCell, qtyCell]);
          }

          return pw.TableRow(
            children: [
              itemCell,
              qtyCell,
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  row[2],
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  row[3],
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _totalsTable(Order order, bool isGiftOrder) {
    final rows = <List<String>>[
      ['Subtotal', Money.format(order.subtotalMinor)],
      if (!isGiftOrder && order.shippingMinor > 0) ['Shipping', Money.format(order.shippingMinor)],
      ['Total', Money.format(order.totalMinor)],
    ];

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  rows[i][0],
                  style: rows[i][0] == 'Total'
                      ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                      : pw.TextStyle(),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  rows[i][1],
                  textAlign: pw.TextAlign.right,
                  style: rows[i][0] == 'Total'
                      ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                      : pw.TextStyle(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _variantLabel(CartItem item) {
    final parts = <String>[];
    if (item.color != null && item.color!.isNotEmpty) parts.add(item.color!);
    if (item.size != null && item.size!.isNotEmpty) parts.add(item.size!);
    return parts.join(' · ');
  }
}
