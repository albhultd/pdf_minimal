import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

/// Egy egyszerű PDF megjelenítő widget, amely assetből, fájlból, URL-ről vagy
/// memóriában lévő adatokból jelenít meg PDF-et.
/// Legalább az [assetPath], [filePath], [url] vagy [data] paraméterek egyét kell megadni.
class PdfViewerMinimal extends StatefulWidget {
  final String? assetPath;
  final String? filePath;
  final String? url;
  final Uint8List? data;
  final int initialPage;

  const PdfViewerMinimal({
    Key? key,
    this.assetPath,
    this.filePath,
    this.url,
    this.data,
    this.initialPage = 1,
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
  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Future<PdfDocument> documentFuture;

      if (widget.data != null) {
        // Memóriában lévő adatból nyitjuk meg a PDF-et
        documentFuture = PdfDocument.openData(widget.data!);
      } else if (widget.assetPath != null) {
        // Assetből töltjük be
        documentFuture = PdfDocument.openAsset(widget.assetPath!);
      } else if (widget.filePath != null) {
        // Fájlrendszerből nyitjuk meg
        documentFuture = PdfDocument.openFile(widget.filePath!);
      } else if (widget.url != null) {
        // Hálózatról töltjük le a PDF-et
        final response = await http.get(Uri.parse(widget.url!));
        if (response.statusCode == 200) {
          documentFuture = PdfDocument.openData(response.bodyBytes);
        } else {
          throw Exception('Hiba a PDF letöltésekor: ${response.statusCode}');
        }
      } else {
        throw Exception('Nincs érvényes PDF forrás megadva!');
      }

      _pdfController = PdfControllerPinch(
        document: documentFuture,
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

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Hiba: $_error'));
    }
    if (_pdfController == null) {
      return const SizedBox();
    }
    return PdfViewPinch(
      controller: _pdfController!,
    );
  }
}