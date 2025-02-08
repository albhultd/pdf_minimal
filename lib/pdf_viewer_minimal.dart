import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

/// Egy testreszabható PDF megjelenítő widget, amely assetből, fájlból, URL-ről vagy
/// memóriában lévő adatokból jelenít meg PDF-et.
/// Legalább egy forrást (assetPath, filePath, url vagy data) kötelező megadni.
///
/// Példa használatra:
/// ```dart
/// // Keret nélkül:
/// PdfViewerMinimal(
///   assetPath: 'assets/sample.pdf',
/// )
///
/// // Kerettel:
/// PdfViewerMinimal(
///   assetPath: 'assets/sample.pdf',
///   decoration: BoxDecoration(
///     color: Colors.white,
///     border: Border.all(color: Colors.blue, width: 2),
///     borderRadius: BorderRadius.circular(8),
///   ),
/// )
/// ```
class PdfViewerMinimal extends StatefulWidget {
  /// Az asset útvonal, amelyről a PDF betöltése történik.
  final String? assetPath;

  /// A fájlrendszerből történő PDF betöltéshez használt fájl elérési útja.
  final String? filePath;

  /// Az URL, amelyről a PDF letölthető.
  final String? url;

  /// A memóriában lévő PDF adatokat tartalmazó Uint8List.
  final Uint8List? data;

  /// A kezdeti oldal, amelyről a PDF megjelenítése indul. Alapértelmezett: 1.
  final int initialPage;

  /// Opcionális dekoráció a PDF konténer számára.
  /// Ha nem adsz meg értéket, alapértelmezettként nincs látható keret.
  final BoxDecoration? decoration;

  const PdfViewerMinimal({
    Key? key,
    this.assetPath,
    this.filePath,
    this.url,
    this.data,
    this.initialPage = 1,
    this.decoration,
  })  : assert(
          assetPath != null || filePath != null || url != null || data != null,
          'Legalább egy PDF forrást meg kell adni (assetPath, filePath, url vagy data)!',
        ),
        super(key: key);

  @override
  _PdfViewerMinimalState createState() => _PdfViewerMinimalState();
}

class _PdfViewerMinimalState extends State<PdfViewerMinimal> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  /// A PDF dokumentum betöltése a megadott forrás alapján.
  /// A megfelelő forrás (data, asset, file vagy url) kiválasztása után inicializálódik a PdfControllerPinch.
  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      late Future<PdfDocument> pdfDocumentFuture;
      if (widget.data != null) {
        pdfDocumentFuture = PdfDocument.openData(widget.data!);
      } else if (widget.assetPath != null) {
        pdfDocumentFuture = PdfDocument.openAsset(widget.assetPath!);
      } else if (widget.filePath != null) {
        pdfDocumentFuture = PdfDocument.openFile(widget.filePath!);
      } else if (widget.url != null) {
        final response = await http.get(Uri.parse(widget.url!));
        if (response.statusCode == 200) {
          pdfDocumentFuture = PdfDocument.openData(response.bodyBytes);
        } else {
          throw Exception('Hiba a PDF letöltésekor: ${response.statusCode}');
        }
      } else {
        throw Exception('Nincs érvényes PDF forrás megadva!');
      }

      _pdfController = PdfControllerPinch(
        document: pdfDocumentFuture,
        initialPage: widget.initialPage,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Publikus aszinkron függvény a PDF újratöltésére.
  /// Ezt a függvényt például egy külső triggerrel hívhatod meg, ha a PDF-et frissíteni szeretnéd.
  Future<void> reloadPdf() async {
    await _loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Betöltés esetén jelenítünk meg egy indikátort.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Hiba esetén megjelenítünk egy hibaüzenetet és egy "Újrapróbálom" gombot.
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hiba: $_error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPdf,
              child: const Text('Újrapróbálom'),
            ),
          ],
        ),
      );
    }

    if (_pdfController == null) {
      return const SizedBox();
    }

    // A PDF megjelenítése egy testreszabható konténerben.
    // Ha nincs megadva dekoráció, akkor alapértelmezettként nem jelenik meg keret.
    return Container(
      decoration: widget.decoration ??
          const BoxDecoration(
            color: Colors.white,
            // Átlátszó keret: nincs látható border
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
          ),
      child: PdfViewPinch(
        controller: _pdfController!,
      ),
    );
  }
}
