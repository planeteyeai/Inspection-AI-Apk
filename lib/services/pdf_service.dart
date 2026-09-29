import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/inspection_models.dart';
import '../ui/app_brand.dart';

class PdfService {
  static Future<void> generateAndDownloadSingleReport(Report report) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppBrand.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    AppBrand.subtitle,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Text(
                DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.orange700, thickness: 1.5),
          pw.SizedBox(height: 8),

          // Bridge Form Info
          if (report.bridgeData != null) ...[
            pw.Text(
              'BRIDGE SITE DETAILS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Chainages: ${report.bridgeData!.chainages.isEmpty ? "N/A" : report.bridgeData!.chainages}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  if (report.bridgeData!.projectName.isNotEmpty)
                    pw.Text(
                      'Project: ${report.bridgeData!.projectName}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (report.bridgeData!.bridgeId != null)
                    pw.Text(
                      'Bridge ID: ${report.bridgeData!.bridgeId}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.Text(
                    'Span: ${report.bridgeData!.span}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Superstructure: ${report.bridgeData!.typeOfSuperstructure}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Summary & Metrics
          pw.Text(
            'EXECUTIVE SUMMARY',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(report.description, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),

          // Metrics table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _headerCell('Total Issues'),
                  _headerCell('Total Area (m²)'),
                  _headerCell('Total Length (m)'),
                  _headerCell('Max Depth (m)'),
                  _headerCell('Max Width (m)'),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell('${report.metrics.issueCount}'),
                  _cell(report.metrics.totalArea.toStringAsFixed(3)),
                  _cell(report.metrics.totalLength.toStringAsFixed(2)),
                  _cell(report.metrics.maxDepth.toStringAsFixed(3)),
                  _cell(report.metrics.maxWidth.toStringAsFixed(3)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Distress Issues List
          if (report.issues.isNotEmpty) ...[
            pw.Text(
              'DISTRESS DEFECT BREAKDOWN',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ...report.issues.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final issue = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Distress #$idx: ${issue.type.toUpperCase()}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.orange900,
                          ),
                        ),
                        pw.Text(
                          '${(issue.confidence * 100).toStringAsFixed(0)}% Confidence',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                    if (issue.elementName != null &&
                        issue.elementName!.isNotEmpty)
                      pw.Text(
                        'Element: ${issue.elementName}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.blue800,
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Depth: ${issue.depth}m | Width: ${issue.width ?? "-"}m | Length: ${issue.length ?? "-"}m | Area: ${issue.area?.toStringAsFixed(3) ?? "-"}m²',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Description: ${issue.description}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 10),
          ],

          // Recommendations
          if (report.recommendations.isNotEmpty) ...[
            pw.Text(
              'RECOMMENDATIONS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...report.recommendations.asMap().entries.map(
              (e) => pw.Bullet(
                text: '${e.key + 1}. ${e.value}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Element rating / measurements / scaffolding / testing
          if (report.bridgeResults != null &&
              report.bridgeResults!.isNotEmpty) ...[
            pw.Text(
              'STRUCTURAL ELEMENT RESULTS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ...report.bridgeResults!.map((res) {
              final tests = kPdfTestKeys
                  .where((k) => res.testingOptions[k] == true)
                  .join(', ');
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      res.elementName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Rating: ${res.conditionRating} | Severity: ${res.levelOfSeverity}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Distress L/W/T: ${res.distressLength ?? "-"} / ${res.distressWidth ?? "-"} / ${res.distressThickness ?? "-"} | Nos: ${res.distressNos ?? "-"} | ${res.distressUnit} ${res.distressValue}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Scaffolding L/W/H: ${res.scaffoldingLength ?? "-"} / ${res.scaffoldingWidth ?? "-"} / ${res.scaffoldingHeight ?? "-"} | Cum: ${res.scaffoldingCum.toStringAsFixed(2)} m³',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Suggested RnR: ${res.suggestedRnR}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Testing Yes/No: ${res.testingRecommendation ? "Yes" : "No"} | Selected: ${tests.isEmpty ? "None" : tests}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Inspection_${report.id}.pdf',
    );
  }

  static const List<String> kPdfTestKeys = [
    'UPV',
    'RHT',
    'HCP',
    'CD',
    'Core',
    'Profoscope',
    'Chemical Test',
    'GPR',
  ];

  static pw.Widget _headerCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    ),
  );

  static pw.Widget _cell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 9),
    ),
  );
}
