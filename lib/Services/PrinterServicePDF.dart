import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Função que recebe bytes e gera um PDF
Future<void> printPdfFromBytes(List<int> bytes) async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async {
      final pdf = pw.Document();

      // Converte os bytes recebidos em texto (se forem ASCII/UTF8)
      final content = String.fromCharCodes(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                content,
                style: pw.TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      );

      return pdf.save();
    },
  );
}
