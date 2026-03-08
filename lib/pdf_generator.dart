import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';

Future<void> generateSortiePdf(
  Sortie sortie,
  List<Product> products,
  List<Person> people,
) async {
  final pdf = pw.Document();

  // Load logo (Handle case where asset might be missing)
  pw.MemoryImage? image;
  try {
    final imageBytes = await rootBundle.load('assets/icons/logo.png');
    image = pw.MemoryImage(imageBytes.buffer.asUint8List());
  } catch (e) {
    // Ignore if logo is missing
  }

  // Helper to find names
  String getPersonName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    try {
      return people.firstWhere((p) => p.id == id).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  String getProductName(String id) {
    try {
      return products.firstWhere((p) => p.id == id).name;
    } catch (e) {
      return 'Unknown Product';
    }
  }

  final dateFormat = DateFormat('dd/MM/yyyy');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return [
          _buildHeader(
            image: image,
            title: "BON DE SORTIE / RETOUR",
            sortie: sortie,
            guideName: getPersonName(sortie.guideId),
            cuisinierName: getPersonName(sortie.cuisinierId),
            responsibleName: getPersonName(sortie.responsibleId),
            dateFormat: dateFormat,
          ),
          pw.SizedBox(height: 20),
          _buildItemsTable(sortie, getProductName),
          pw.SizedBox(height: 20),
          _buildSignatures(),
        ];
      },
    ),
  );

  final output = await getApplicationDocumentsDirectory();
  final fileName = "Sortie_${sortie.displayId}.pdf";
  final file = File('${output.path}/$fileName');
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}

pw.Widget _buildHeader({
  required pw.ImageProvider? image,
  required String title,
  required Sortie sortie,
  required String guideName,
  required String cuisinierName,
  required String responsibleName,
  required DateFormat dateFormat,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.5),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo Section
        pw.Container(
          width: 120,
          height: 80,
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(
            border: pw.Border(right: pw.BorderSide(width: 1.5)),
          ),
          child: image != null
              ? pw.Center(child: pw.Image(image, width: 100, height: 55))
              : pw.Center(
                  child: pw.Text(
                    "LOGO",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
        ),
        // Info Section
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(8.0),
            child: pw.Column(
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn("Sortie N°", sortie.displayId),
                    _buildInfoColumn(
                      "Date Départ",
                      dateFormat.format(sortie.departureDate),
                    ),
                    _buildInfoColumn(
                      "Date Retour",
                      dateFormat.format(sortie.returnDate),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Divider(),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn("Responsable", responsibleName),
                    _buildInfoColumn("Guide", guideName),
                    _buildInfoColumn("Cuisinier", cuisinierName),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildInfoColumn(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
    ],
  );
}

pw.Widget _buildItemsTable(
  Sortie sortie,
  String Function(String) getProductName,
) {
  final isCompleted = sortie.status == 'completed';

  final headers = [
    'Produit',
    'Qté Prise',
    if (isCompleted) 'Qté Retour',
    if (isCompleted) 'Manquant',
    'Note',
  ];

  final data = sortie.items.map((item) {
    final missing = item.quantityTaken - item.quantityReturned;
    return [
      getProductName(item.productId),
      item.quantityTaken.toString(),
      if (isCompleted) item.quantityReturned.toString(),
      if (isCompleted) (missing > 0 ? missing.toString() : '-'),
      item.note ?? '',
    ];
  }).toList();

  return pw.Table.fromTextArray(
    headers: headers,
    data: data,
    border: pw.TableBorder.all(),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    cellStyle: const pw.TextStyle(fontSize: 10),
    cellAlignment: pw.Alignment.centerLeft,
    headerAlignment: pw.Alignment.centerLeft,
    columnWidths: {
      0: const pw.FlexColumnWidth(3), // Product Name
      1: const pw.FlexColumnWidth(1), // Taken
      if (isCompleted) 2: const pw.FlexColumnWidth(1), // Returned
      if (isCompleted) 3: const pw.FlexColumnWidth(1), // Missing
      4: const pw.FlexColumnWidth(2), // Note
    },
  );
}

pw.Widget _buildSignatures() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _buildSignatureBox("Signature Responsable"),
      _buildSignatureBox("Signature Guide/Cuisinier"),
    ],
  );
}

pw.Widget _buildSignatureBox(String title) {
  return pw.Column(
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 5),
      pw.Container(
        width: 150,
        height: 60,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey),
        ),
      ),
    ],
  );
}
