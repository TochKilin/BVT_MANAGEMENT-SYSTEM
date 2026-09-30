import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/cart_item.dart';

const _green = Color(0xFF008575);
const _ink = Color(0xFF17213D);

class InvoiceScreen extends StatelessWidget {
  final List<CartItem> items;
  final Map<String, dynamic> sale;
  final double paid;
  final String paymentMethod;
  const InvoiceScreen({
    super.key,
    required this.items,
    required this.sale,
    required this.paid,
    required this.paymentMethod,
  });

  Future<Uint8List> _buildPdfBytes() async {
    final total =
        (sale['total'] as num?)?.toDouble() ??
        items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final date =
        DateTime.tryParse(sale['created_at']?.toString() ?? '') ??
        DateTime.now();
    final number =
        sale['sale_number']?.toString() ?? 'SO-${sale['_id'] ?? '00001'}';
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'VETCARE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Veterinary Clinic & Pharmacy - Sales Invoice'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Invoice: $number'),
          pw.Text('Date: ${date.toLocal()}'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Batch', 'Qty', 'Unit price', 'Amount'],
            data: items
                .map(
                  (item) => [
                    _pdfText(item.name),
                    _pdfText(item.batchNumber),
                    '${item.quantity}',
                    '\$${item.unitPrice.toStringAsFixed(2)}',
                    '\$${item.lineTotal.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Subtotal: \$${((sale['subtotal'] as num?)?.toDouble() ?? total).toStringAsFixed(2)}',
                ),
                pw.Text(
                  'Tax: \$${((sale['tax'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                ),
                pw.Text(
                  'Discount: \$${((sale['discount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                ),
                pw.Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.Text('Paid by $paymentMethod: \$${paid.toStringAsFixed(2)}'),
                pw.Text(
                  'Change: \$${(paid > total ? paid - total : 0).toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Center(child: pw.Text('Thank you for your purchase')),
        ],
      ),
    );
    return document.save();
  }

  Future<void> _printInvoice(BuildContext context) async {
    final number = sale['sale_number']?.toString() ?? 'sale';
    try {
      final bytes = await _buildPdfBytes();
      final printed = await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Invoice-$number.pdf',
        format: PdfPageFormat.a4,
      );
      if (!context.mounted) return;
      if (printed) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ការបោះពុម្ពត្រូវបានបោះបង់')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('មិនអាចបោះពុម្ពវិក្កយបត្របាន៖ $error')),
      );
    }
  }

  String _money(num value) => '\$${value.toStringAsFixed(2)}';

  String _pdfText(String value) {
    // The PDF package's built-in fonts do not include Khmer glyphs.
    final printable = value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    return printable.isEmpty ? 'Medicine' : printable;
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (sale['total'] as num?)?.toDouble() ??
        items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final date =
        DateTime.tryParse(sale['created_at']?.toString() ?? '') ??
        DateTime.now();
    final number =
        sale['sale_number']?.toString() ?? 'SO-${sale['_id'] ?? '00001'}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'វិក្កយបត្រ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Chip(
              avatar: const Icon(Icons.circle, color: _green, size: 13),
              label: const Text('បានបង់'),
              backgroundColor: const Color(0xFFE7F4F1),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                children: [
                  const Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Color(0xFFD9D9D9),
                          child: Icon(Icons.pets, color: _ink, size: 42),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'VETCARE',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'មន្ទីរសត្វ និងឱសថស្ថាន • វិក្កយបត្រលក់',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD8D8D8)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: Text(
                            'No. #$number',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text('•'),
                        Text(
                          '${_month(date.month)} ${date.day}, ${date.year}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ទំនិញ / ការពិពណ៌នា',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        'តម្លៃ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...items.map(_itemCard),
                  const SizedBox(height: 18),
                  const Divider(),
                  _summaryRow(
                    'តម្លៃទំនិញសរុប',
                    _money((sale['subtotal'] as num?) ?? total),
                  ),
                  _summaryRow(
                    'ពន្ធ / ការបញ្ចុះតម្លៃ (0%)',
                    _money(
                      ((sale['tax'] as num?) ?? 0) -
                          ((sale['discount'] as num?) ?? 0),
                    ),
                  ),
                  _summaryRow('តម្លៃត្រូវបង់', _money(total), bold: true),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD8D8D8)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: _green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'បង់ប្រាក់: $paymentMethod',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              _money(paid),
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('ប្រាក់អាប់ត្រូវប្រគល់'),
                            ),
                            Text(
                              _money(paid > total ? paid - total : 0),
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '|||| |||| |||| |||| ||||',
                          style: TextStyle(
                            fontSize: 24,
                            letterSpacing: 2,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TXN-${number.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async => Printing.sharePdf(
                        bytes: await _buildPdfBytes(),
                        filename:
                            'Invoice-${sale['sale_number'] ?? 'sale'}.pdf',
                      ),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('ចែករំលែក'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        backgroundColor: const Color(0xFFD9D9D9),
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _printInvoice(context),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('បោះពុម្ពវិក្កយបត្រ'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(CartItem item) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD8D8D8)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medication_outlined, color: _ink, size: 27),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'x${item.quantity} at ${_money(item.unitPrice)} / unit',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        Text(
          _money(item.lineTotal),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    ),
  );

  Widget _summaryRow(String title, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 18 : 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                fontSize: bold ? 21 : 17,
              ),
            ),
          ],
        ),
      );

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
