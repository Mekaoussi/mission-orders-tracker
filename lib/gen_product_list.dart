import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:voyage1/models/models.dart';
import 'package:voyage1/utils/constants.dart';

Future<void> generateProductListPDF({
  required List<ProductEntry> products,
  required int pax,
  required int orderId,
  required DateTime startDate,
  required DateTime endDate,
  required int startYear,
  required int endYear,
  required int productsDIR,
  required bool generateSec,
  required bool generateFrais,
  String? guideName,
  String? cuisinierName,
  String? tourOperateur,
  String? circuitName,
}) async {
  final pdf = pw.Document();
  final imageBytes = await rootBundle.load('assets/icons/logo.png');
  final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

  // Filter and prepare data
  final secs = products.where((p) => p.type == 'sec').toList();
  final frais = products.where((p) => p.type == 'frais').toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        final List<pw.Widget> content = [];
        content.add(_buildHeader(
          image: image,
          title: "LISTE DE NOURRITURE (PAX: $pax)",
          orderId: orderId,
          guideName: guideName,
          cuisinierName: cuisinierName,
          tourOperateur: tourOperateur,
          circuitName: circuitName,
          startDate: startDate,
          endDate: endDate,
        ));
        content.add(pw.SizedBox(height: 10));

        if (generateSec) {
          content.add(_buildSectionTitle("TABLEAU DE PRODUITS SECS"));
          content.add(pw.SizedBox(height: 5));
          content.add(_buildTripleColumnTable(secs, pax, productsDIR));
          content.add(pw.SizedBox(height: 20));
        }

        if (generateFrais) {
          content.add(_buildSectionTitle("TABLEAU DE PRODUITS FRAIS"));
          content.add(pw.SizedBox(height: 5));
          content.add(_buildTripleColumnTable(frais, pax, productsDIR));
        }

        return content;
      },
    ),
  );

  // Save file
  final output = await getApplicationDocumentsDirectory();
  final yearRange = '$startYear-$endYear';
  final month = DateFormat('MMM').format(startDate);
  final folderPath =
      '${output.path}/$kMainFolderName/$yearRange/$month/Order $orderId';
  await Directory(folderPath).create(recursive: true);

  final file = File('$folderPath/LISTE_NOURRITURE.pdf');
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}

pw.Widget _buildHeader({
  required pw.ImageProvider image,
  required String title,
  required int orderId,
  required String? guideName,
  required String? cuisinierName,
  required String? tourOperateur,
  required String? circuitName,
  required DateTime startDate,
  required DateTime endDate,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.5),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 150,
          height: 80, // Adjusted height to vertically center the logo
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(
            border: pw.Border(right: pw.BorderSide(width: 1.5)),
          ),
          child: pw.Center(
            child: pw.Image(image, width: 120, height: 55),
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(5.0),
            child: pw.Column(
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                _buildInfoSection(
                  orderId: orderId,
                  guideName: guideName,
                  cuisinierName: cuisinierName,
                  tourOperateur: tourOperateur,
                  circuitName: circuitName,
                  startDate: startDate,
                  endDate: endDate,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildInfoSection({
  required int orderId,
  required String? guideName,
  required String? cuisinierName,
  required String? tourOperateur,
  required String? circuitName,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final dateFormat = DateFormat('dd/MM/yyyy');
  final dateStr =
      "${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}";

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(children: [
        _buildInfoItem("Order N°", orderId.toString()),
        _buildInfoItem("Dates", dateStr),
      ]),
      pw.SizedBox(height: 4),
      pw.Row(children: [
        _buildInfoItem("Guide", guideName ?? ""),
        _buildInfoItem("Cuisinier", cuisinierName ?? ""),
      ]),
      pw.SizedBox(height: 4),
      pw.Row(children: [
        _buildInfoItem("T.O", tourOperateur ?? ""),
        _buildInfoItem("Circuit", circuitName ?? ""),
      ]),
    ],
  );
}

pw.Widget _buildInfoItem(String label, String value) {
  return pw.Expanded(
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
              text: "$label : ",
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
}

pw.Widget _buildSectionTitle(String title) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(5),
    color: PdfColors.grey300,
    child: pw.Text(
      title,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildTripleColumnTable(
    List<ProductEntry> items, int pax, int productsDIR) {
  // Split items into three columns
  final third = (items.length / 3).ceil();
  final col1 = items.take(third).toList();
  final col2 = items.skip(third).take(third).toList();
  final col3 = items.skip(third * 2).toList();

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: _buildSingleTable(col1, pax, 0, productsDIR)),
      pw.SizedBox(width: 5),
      pw.Expanded(child: _buildSingleTable(col2, pax, third, productsDIR)),
      pw.SizedBox(width: 5),
      pw.Expanded(child: _buildSingleTable(col3, pax, third * 2, productsDIR)),
    ],
  );
}

pw.Widget _buildSingleTable(
    List<ProductEntry> items, int pax, int startIndex, int productsDIR) {
  return pw.Table(
    border: pw.TableBorder.all(),
    columnWidths: {
      0: const pw.FixedColumnWidth(15), // Number (Reduced)
      1: const pw.FlexColumnWidth(1), // Name
      2: const pw.FixedColumnWidth(25), // Quantity (Reduced)
    },
    children: [
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          _cell("N°", isHeader: true),
          _cell("Désignation", isHeader: true),
          _cell("Qté", isHeader: true),
        ],
      ),
      // Rows
      ...List.generate(items.length, (i) {
        final item = items[i];
        final qtyDouble = _calculateQuantity(item, pax, productsDIR);
        String displayQty;
        if (item.isPrecise) {
          // Show detailed double value
          if (qtyDouble == 0) {
            displayQty = '-';
          } else {
            // Format to 2 decimal places and remove unnecessary trailing zeros
            displayQty = qtyDouble
                .toStringAsFixed(2)
                .replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
          }
        } else {
          // Roof the value (ceil) and convert to int (Default behavior)
          final qtyInt = qtyDouble.ceil();
          displayQty = qtyInt == 0 ? '-' : qtyInt.toString();
        }

        return pw.TableRow(
          children: [
            _cell((startIndex + i + 1).toString(), align: pw.TextAlign.center),
            _cell(" ${item.name}", align: pw.TextAlign.left),
            _cell(displayQty, align: pw.TextAlign.center),
          ],
        );
      }),
    ],
  );
}

double _calculateQuantity(ProductEntry product, int pax, int productsDIR) {
  if (pax <= 0) return 0.0;
  // Ensure we have enough data points (expected 7 for ranges 2-3 to 14-15)
  if (product.quantities.length < 7) return 0.0;

  const int maxPaxRange = 15;

  int fullGroups = pax ~/ maxPaxRange;
  int remainder = pax % maxPaxRange;

  double total = 0.0;

  // Index 6 corresponds to 14-15 pax (the max range value)
  double maxRangeQty = product.quantities[6];

  total += fullGroups * maxRangeQty;

  if (remainder > 0) {
    int index = 0;
    if (remainder <= 3)
      index = 0; // Covers 1, 2, 3
    else if (remainder <= 5)
      index = 1; // 4-5
    else if (remainder <= 7)
      index = 2; // 6-7
    else if (remainder <= 9)
      index = 3; // 8-9
    else if (remainder <= 11)
      index = 4; // 10-11
    else if (remainder <= 13)
      index = 5; // 12-13
    else
      index = 6; // 14

    total += product.quantities[index];
  }

  return (total * productsDIR) / 7;
}

pw.Widget _cell(String text,
    {bool isHeader = false, pw.TextAlign align = pw.TextAlign.center}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}
