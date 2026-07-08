import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Génère un certificat de compétence (PDF simple) et le partage via les
/// applications installées sur l'appareil.
///
/// Le fichier est généré à la volée dans le répertoire temporaire de
/// l'application : il n'est pas conservé en base (voir dossier de
/// conception technique, section 3.3).
class CertificateService {
  static Future<void> genererEtPartager({
    required String nomUtilisateur,
    required String nomLangage,
    required String nomNiveau,
    required DateTime dateObtention,
  }) async {
    final document = pw.Document();

    final dateFormatee =
        '${dateObtention.day.toString().padLeft(2, '0')}/${dateObtention.month.toString().padLeft(2, '0')}/${dateObtention.year}';

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(40),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2, color: PdfColors.indigo),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'CERTIFICAT DE COMPÉTENCE',
                    style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('CodeQuiz atteste que', style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    nomUtilisateur,
                    style: const pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'a validé le niveau $nomNiveau en $nomLangage',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('Obtenu le $dateFormatee', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
          );
        },
      ),
    );

    final repertoire = await getTemporaryDirectory();
    final fichier = File('${repertoire.path}/certificat_${nomLangage}_$nomNiveau.pdf');
    await fichier.writeAsBytes(await document.save());

    await Share.shareXFiles(
      [XFile(fichier.path)],
      text: 'Mon certificat $nomLangage — $nomNiveau sur CodeQuiz !',
    );
  }
}
