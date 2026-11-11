import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/colors.dart';
import '../../../core/notifications/app_notifier.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/paw_widgets.dart';
import '../../../domain/models/order.dart';
import '../application/receipt_service.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  const ReceiptPreviewScreen({required this.order, super.key});

  final Order order;

  @override
  ConsumerState<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _saving = false;
  bool _printing = false;

  Future<Uint8List> _generatePdfBytes() async {
    try {
      return await ReceiptPdfService.build(widget.order);
    } catch (nativeError, nativeStack) {
      debugPrint('Receipt native PDF generation failed: $nativeError');
      debugPrintStack(stackTrace: nativeStack);
      final fallback = await _captureFallbackPdf();
      debugPrint('Receipt fallback image PDF used successfully.');
      return fallback;
    }
  }

  Future<Uint8List> _captureFallbackPdf() async {
    final context = _receiptKey.currentContext;
    if (context == null) {
      throw StateError('Receipt widget is not mounted.');
    }

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Receipt widget repaint boundary is unavailable.');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to capture receipt image bytes.');
    }

    final pngBytes = byteData.buffer.asUint8List();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(
          child: pw.Image(pw.MemoryImage(pngBytes)),
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _savePdf() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _generatePdfBytes();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'PawPick-Receipt-${widget.order.number}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      AppNotifier.success('Receipt saved', message: 'Open or share the file.');

      final result = await Share.shareXFiles([
        XFile(file.path),
      ]);
      if (result.status == ShareResultStatus.success && mounted) {
        AppNotifier.success('Receipt shared', message: 'Your PDF is ready to send.');
      }
    } catch (error, stackTrace) {
      debugPrint('Receipt save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      AppNotifier.error(
        'Could not create receipt',
        message: 'The PDF could not be generated. Retry, or share a plain-text summary.',
      );
      AppNotifier.success(
        'Share as text',
        message: _textSummary(),
        actionLabel: 'Share',
        onAction: () => _shareText(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareText() async {
    await Share.share(_textSummary());
  }

  String _textSummary() {
    return 'PawPick Receipt ${widget.order.number}\n'
        'Order placed ${widget.order.createdAt.toLocal()}\n'
        'Deliver to ${widget.order.address.fullName}\n'
        'Payment: ${widget.order.paymentMethod}\n\n'
        'Subtotal ${Money.format(widget.order.subtotalMinor)}\n'
        'Shipping ${Money.format(widget.order.shippingMinor)}\n'
        'Total ${Money.format(widget.order.totalMinor)}\n\n'
        'Thank you for bringing home big joy!';
  }

  Future<void> _printPdf() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final bytes = await _generatePdfBytes();
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'PawPick-${widget.order.number}.pdf',
      );
    } catch (error, stackTrace) {
      debugPrint('Receipt print failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      AppNotifier.info(
        'No printer found',
        message: 'Save the receipt as a PDF and print it from your files.',
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt preview'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _receiptKey,
              child: Container(
                color: AppColors.cream,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: ReceiptCard(order: widget.order),
                ),
              ),
            ),
          ),
          _ActionBar(
            order: widget.order,
            saving: _saving,
            printing: _printing,
            onSave: _savePdf,
            onShare: () async {
              try {
                final bytes = await _generatePdfBytes();
                final directory = await getTemporaryDirectory();
                final file = File('${directory.path}/PawPick-${widget.order.number}.pdf');
                await file.writeAsBytes(bytes, flush: true);
                await Share.shareXFiles([XFile(file.path)]);
              } catch (error, stackTrace) {
                debugPrint('Receipt share failed: $error');
                debugPrintStack(stackTrace: stackTrace);
                if (mounted) {
                  AppNotifier.error(
                    'Share failed',
                    message: 'The PDF could not be shared. Try saving it instead.',
                  );
                }
              }
            },
            onPrint: _printPdf,
          ),
        ],
      ),
    );
  }
}

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 42,
                  height: 42,
                  color: AppColors.blue,
                  child: const Center(
                    child: Icon(Icons.pets_rounded, size: 20, color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAWPICK',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Little things. Big joy.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Receipt',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Order ${order.number}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          Text(
            'Placed ${order.createdAt.toLocal().toString().substring(0, 16)}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (order.address.fullName.isNotEmpty) ...[
            Text(
              'Deliver to ${order.address.fullName}',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.ink),
            ),
            Text(
              order.address.label,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(label: order.paymentMethod),
              _MiniChip(label: order.status.name.toUpperCase()),
            ],
          ),
          const SizedBox(height: 18),
          _ItemsTable(order: order),
          const SizedBox(height: 16),
          _TotalsCard(order: order),
          const SizedBox(height: 18),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: QrImageView(
                    data: order.number,
                    size: 82,
                    backgroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Scan to view order ${order.number}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Text(
                  'Thank you for bringing home big joy!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We hope your pet loves it. 🐾',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.order});

  final Order order;

  bool get _isGiftOrder => order.paymentMethod.toLowerCase() == 'gift';

  @override
  Widget build(BuildContext context) {
    final headers = _isGiftOrder ? ['Item', 'Qty'] : ['Item', 'Qty', 'Price', 'Total'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    headers[0],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Qty',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              if (!_isGiftOrder) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Price',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 8),
          ...order.items.map((item) {
            final line = item.name;
            final details = [
              if (item.color != null && item.color!.isNotEmpty) 'Color: ${item.color!}',
              if (item.size != null && item.size!.isNotEmpty) 'Size: ${item.size!}',
            ].join(' · ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                details,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (!_isGiftOrder) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PriceText(
                                amount: item.unitPriceMinor,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PriceText(
                                amount: item.unitPriceMinor * item.quantity,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.line),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final Order order;

  bool get _isGiftOrder => order.paymentMethod.toLowerCase() == 'gift';

  @override
  Widget build(BuildContext context) {
    final rows = <_TotalRowData>[
      _TotalRowData('Subtotal', order.subtotalMinor),
      if (order.shippingMinor > 0) _TotalRowData('Shipping', order.shippingMinor),
      _TotalRowData('Total', order.totalMinor, isTotal: true),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rows[index].label,
                      style: rows[index].isTotal
                          ? Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            )
                          : Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.ink,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: rows[index].isTotal
                        ? PriceText(
                            amount: rows[index].amount,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          )
                        : PriceText(
                            amount: rows[index].amount,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                ),
              ],
            ),
            if (index < rows.length - 1) const SizedBox(height: 8),
          ],
          if (order.shippingMinor == 0 && !_isGiftOrder) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.line),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'FREE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRowData {
  const _TotalRowData(this.label, this.amount, {this.isTotal = false});

  final String label;
  final int amount;
  final bool isTotal;
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.palePink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.order,
    required this.saving,
    required this.printing,
    required this.onSave,
    required this.onShare,
    required this.onPrint,
  });

  final Order order;
  final bool saving;
  final bool printing;
  final Future<void> Function() onSave;
  final Future<void> Function() onShare;
  final Future<void> Function() onPrint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: PawButton(
                labelWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (saving)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    else
                      const Icon(Icons.file_download_rounded, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        saving ? 'Saving...' : 'Save PDF',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
                onPressed: saving ? null : onSave,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PawButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    isOutlined: true,
                    onPressed: onShare,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PawButton(
                    icon: Icons.print_rounded,
                    label: 'Print',
                    isOutlined: true,
                    onPressed: printing ? null : onPrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

