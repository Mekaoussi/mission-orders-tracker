import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';

/// Saves the PDF to a temporary file and shares it.
/// This allows the user to "Save to Files", "Print", or share via apps.
Future<void> _saveAndSharePdf(Uint8List pdfBytes, String fileName) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(pdfBytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Voici le rapport PDF : $fileName',
    subject: fileName,
  );
}

Future<void> generateMultiSortieReportPdf({
  required Person person,
  required List<Sortie> sorties,
  required DateTime startDate,
  required DateTime endDate,
  required List<Product> allProducts,
  required List<Person> allPeople,
}) async {
  // Sort sorties by departure date ascending (Oldest first)
  sorties.sort((a, b) => a.departureDate.compareTo(b.departureDate));

  final pdf = pw.Document();
  final dateFormat = DateFormat('dd/MM/yyyy');

  // Load logo
  pw.MemoryImage? image;
  try {
    final imageBytes = await rootBundle.load('assets/icons/logo.png');
    image = pw.MemoryImage(imageBytes.buffer.asUint8List());
  } catch (e) {
    // Ignore if logo is missing
  }

  // --- Cover Page ---
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (image != null)
                  pw.SizedBox(width: 120, height: 80, child: pw.Image(image)),
                pw.SizedBox(width: 20),
                pw.Text(
                  "Rapport d'Activité Individuel",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Divider(height: 40, thickness: 2),
            pw.Text(
              "Rapport pour : ${person.name}",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "Rôle : ${person.role}",
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Divider(height: 30),
            pw.Text(
              "Période : ${dateFormat.format(startDate)} au ${dateFormat.format(endDate)}",
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "Nombre total de sorties (comme responsable) : ${sorties.length}",
              style: const pw.TextStyle(fontSize: 16),
            ),
          ],
        );
      },
    ),
  );

  // --- Continuous Pages for Sorties ---
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        final List<pw.Widget> content = [];
        for (int i = 0; i < sorties.length; i++) {
          content.add(
            _buildSortiePage(
              sorties[i],
              allProducts,
              allPeople,
              image,
              dateFormat,
              includeSignatures: false,
            ),
          );

          if (i < sorties.length - 1) {
            content.add(pw.SizedBox(height: 10));
            content.add(pw.Divider(color: PdfColors.grey));
            content.add(pw.SizedBox(height: 10));
          }
        }
        return content;
      },
    ),
  );

  final fileName = "Rapport_${person.name.replaceAll(' ', '_')}.pdf";
  final pdfBytes = await pdf.save();
  await _saveAndSharePdf(pdfBytes, fileName);
}

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
      return 'Inconnu';
    }
  }

  String getProductName(String id) {
    try {
      return products.firstWhere((p) => p.id == id).name;
    } catch (e) {
      return 'Produit Inconnu';
    }
  }

  final dateFormat = DateFormat('dd/MM/yyyy');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return [_buildSortiePage(sortie, products, people, image, dateFormat)];
      },
    ),
  );

  final fileName = "Sortie_${sortie.displayId}.pdf";
  final pdfBytes = await pdf.save();
  await _saveAndSharePdf(pdfBytes, fileName);
}

pw.Widget _buildSortiePage(
  Sortie sortie,
  List<Product> products,
  List<Person> people,
  pw.MemoryImage? image,
  DateFormat dateFormat, {
  bool includeSignatures = true,
}) {
  String getPersonName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    try {
      return people.firstWhere((p) => p.id == id).name;
    } catch (e) {
      return 'Inconnu';
    }
  }

  return pw.Column(
    children: [
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
      _buildItemsTable(sortie, products),
      if (includeSignatures) ...[pw.SizedBox(height: 20), _buildSignatures()],
    ],
  );
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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      sortie.status == 'completed' ? "(COMPLÉTÉ)" : "(ACTIF)",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: sortie.status == 'completed'
                            ? PdfColors.green
                            : PdfColors.orange,
                      ),
                    ),
                  ],
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

pw.Widget _buildItemsTable(Sortie sortie, List<Product> allProducts) {
  final isCompleted = sortie.status == 'completed';

  // Helper to get a product by its ID
  Product? getProductById(String productId) {
    try {
      return allProducts.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Group items by category
  final Map<String, List<SortieItem>> groupedItems = {
    'equipment': [],
    'secs': [],
    'frais': [],
  };

  for (final item in sortie.items) {
    final product = getProductById(item.productId);
    if (product != null) {
      groupedItems[product.type]?.add(item);
    }
  }

  final List<pw.TableRow> tableRows = [];

  // Add header row
  final headers = [
    'Produit',
    'Qté Prise',
    if (isCompleted) 'Qté Retour',
    if (isCompleted) 'Manquant',
    'Note',
  ];
  tableRows.add(
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: headers
          .map(
            (header) => pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );

  // Add items grouped by category
  for (final category in groupedItems.keys) {
    final itemsInCategory = groupedItems[category]!;
    if (itemsInCategory.isNotEmpty) {
      // Add category header row
      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                category.toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            // Fill remaining columns to match header count, creating a visual span
            ...List.generate(headers.length - 1, (index) => pw.Container()),
          ],
        ),
      );

      // Add item rows for this category
      for (final item in itemsInCategory) {
        final product = getProductById(item.productId);
        final missing = item.quantityTaken - item.quantityReturned;

        final rowData = [
          pw.Text(
            product?.name ?? 'Inconnu',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            item.quantityTaken.toString(),
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          if (isCompleted)
            pw.Text(
              item.quantityReturned.toString(),
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          if (isCompleted)
            pw.Text(
              missing > 0 ? missing.toString() : '-',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          pw.Text(item.note ?? '', style: const pw.TextStyle(fontSize: 10)),
        ];

        tableRows.add(
          pw.TableRow(
            children: rowData
                .map(
                  (widget) => pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    alignment: pw.Alignment.centerLeft,
                    child: widget,
                  ),
                )
                .toList(),
          ),
        );
      }
    }
  }

  final Map<int, pw.TableColumnWidth> columnWidths;
  if (isCompleted) {
    columnWidths = {
      0: const pw.FlexColumnWidth(2), // Product Name
      1: const pw.FlexColumnWidth(0.8), // Taken
      2: const pw.FlexColumnWidth(0.8), // Returned
      3: const pw.FlexColumnWidth(0.8), // Missing
      4: const pw.FlexColumnWidth(3.6), // Note
    };
  } else {
    columnWidths = {
      0: const pw.FlexColumnWidth(2.5), // Product Name
      1: const pw.FlexColumnWidth(1), // Taken
      2: const pw.FlexColumnWidth(4.5), // Note
    };
  }

  return pw.Table(
    border: pw.TableBorder.all(),
    columnWidths: columnWidths,
    children: tableRows,
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
        width: 120,
        height: 40,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey),
        ),
      ),
    ],
  );
}
