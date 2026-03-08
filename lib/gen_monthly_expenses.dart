import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:voyage1/helper/helper_function.dart';
import 'package:voyage1/utils/constants.dart';

Future<void> generateMonthlyExpensesPdf({
  required List<Map<String, dynamic>> data,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final pdf = pw.Document();
  final imageBytes = await rootBundle.load('assets/icons/logo.png');
  final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

  const headers = [
    'Mois',
    'Chameaux',
    'Voiture',
    'Guide',
    'Cuisinier',
    'Auberge',
    'Supplements',
    'Total'
  ];

  final dataRows = data.map((row) {
    return <dynamic>[
      _getFrenchMonthShort(row['month']),
      formatNumberWithSpaces(row['chameaux'].toString()),
      formatNumberWithSpaces(row['voiture'].toString()),
      formatNumberWithSpaces(row['guide'].toString()),
      formatNumberWithSpaces(row['cuisinier'].toString()),
      formatNumberWithSpaces(row['auberge'].toString()),
      formatNumberWithSpaces(row['supplements'].toString()),
      formatNumberWithSpaces(row['month_total'].toString()),
    ];
  }).toList();

  final grandTotalPeriod =
      data.fold<num>(0, (sum, row) => sum + (row['month_total'] ?? 0));

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return [
          _buildHeader(image, "RAPPORT DES DÉPENSES MENSUELLES"),
          pw.SizedBox(height: 10),
          pw.Text(
              "Période: ${_getFrenchMonthShort(DateFormat('yyyy-MM').format(startDate))} ${startDate.year} - ${_getFrenchMonthShort(DateFormat('yyyy-MM').format(endDate))} ${endDate.year}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(),
            headerCount: 1,
            headers: headers,
            data: dataRows,
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.all(4),
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // Mois
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
              6: const pw.FlexColumnWidth(1),
              7: const pw.FlexColumnWidth(1), // Total
            },
          ),
          // Footer Table (Grand Total)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('TOTAL GÉNÉRAL EN MRU: ',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(left: pw.BorderSide())),
                      child: pw.Text(
                          formatNumberWithSpaces(grandTotalPeriod.toString()),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20),
            child: pw.Text(
              "Signature du responsable de l'Agence",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontStyle: pw.FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
        ];
      },
    ),
  );

  final output = await getApplicationDocumentsDirectory();

  final folderPath = '${output.path}/$kMainFolderName/Rapports Mensuels';
  await Directory(folderPath).create(recursive: true);

  const frenchMonths = [
    'jan',
    'fev',
    'mar',
    'avr',
    'mai',
    'juin',
    'juil',
    'aout',
    'sep',
    'oct',
    'nov',
    'dec'
  ];

  final startStr = "${startDate.year}_${frenchMonths[startDate.month - 1]}";
  final endStr = "${endDate.year}_${frenchMonths[endDate.month - 1]}";
  final fileName = "Rapport_Depenses_${startStr}--${endStr}.pdf";
  final file = File('$folderPath/$fileName');

  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}

String _getFrenchMonthShort(String yyyyMM) {
  try {
    final parts = yyyyMM.split('-');
    final month = int.parse(parts[1]);
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
  } catch (e) {
    return yyyyMM;
  }
}

pw.Widget _buildHeader(pw.ImageProvider image, String title) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.5),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
                flex: 1,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Container(
                        height: 60,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              right: pw.BorderSide(
                                  color: PdfColors.black,
                                  style: pw.BorderStyle(paint: false))),
                        ),
                        child: pw.Center(
                          child: pw.Image(image, width: 100, height: 55),
                        ),
                      ),
                      pw.Container(
                          padding: const pw.EdgeInsets.all(0),
                          color: PdfColor(0, 0, 0),
                          height: 50,
                          width: 1),
                    ])),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                height: 60,
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


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
