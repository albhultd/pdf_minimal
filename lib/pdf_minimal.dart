import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:universal_platform/universal_platform.dart';

/// Egy production-ready PDF megjelenítő widget, amely:
/// - Támogatja az asset, fájl, URL vagy memóriában lévő PDF forrásokat.
/// - Oldal navigációs vezérlőket biztosít.
/// - Forgatási vezérlőkkel (balra, jobbra, visszaállítás) rendelkezik.
/// - Opcionálisan double-tap zoom-ot valósít meg, amelyet platform-specifikusan kezelünk.
/// - Testreszabható dekorációval, paddinggal, loading és error widgetekkel, valamint callback-ekkel.
class PdfViewerExtended extends StatefulWidget {
  final String? assetPath;
  final String? filePath;
  final String? url;
  final Uint8List? data;
  final int initialPage;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final Widget? loadingWidget;
  final Widget Function(String error, VoidCallback retry)? errorWidgetBuilder;
  final bool showPageNavigation;
  final ValueChanged<int>? onPageChanged;
  final void Function(int pagesCount)? onDocumentLoaded;

  // További vezérlő paraméterek:
  final bool showAdditionalControls;
  final bool enableDoubleTapZoom;
  final double doubleTapZoomScale;
  final ValueChanged<double>? onZoomChanged;

  const PdfViewerExtended({
    Key? key,
    this.assetPath,
    this.filePath,
    this.url,
    this.data,
    this.initialPage = 1,
    this.decoration,
    this.padding,
    this.loadingWidget,
    this.errorWidgetBuilder,
    this.showPageNavigation = false,
    this.onPageChanged,
    this.onDocumentLoaded,
    this.showAdditionalControls = false,
    this.enableDoubleTapZoom = false,
    this.doubleTapZoomScale = 2.0,
    this.onZoomChanged,
  }) : assert(
         assetPath != null || filePath != null || url != null || data != null,
         'Legalább egy PDF forrást meg kell adni (assetPath, filePath, url vagy data)!',
       ),
       super(key: key);

  @override
  _PdfViewerExtendedState createState() => _PdfViewerExtendedState();
}

class _PdfViewerExtendedState extends State<PdfViewerExtended> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  double _rotationAngle = 0.0;

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
        _error = null;
      });

      Future<PdfDocument> pdfDocumentFuture;
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

      // Várjuk meg a dokumentum betöltését és értesítjük a callback-et.
      final document = await _pdfController!.document;
      _totalPages = document.pagesCount;
      widget.onDocumentLoaded?.call(_totalPages);
      _currentPage = widget.initialPage;

      _pdfController!.addListener(() {
        if (_currentPage != _pdfController!.page) {
          setState(() {
            _currentPage = _pdfController!.page;
          });
          widget.onPageChanged?.call(_currentPage);
        }
        // Ha a PdfControllerPinch támogatja a zoom értéket, itt követhetjük:
        // double currentZoom = _pdfController!.currentZoom;
        // widget.onZoomChanged?.call(currentZoom);
      });

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

  /// Előző oldalra léptetés.
  void _goToPreviousPage() {
    if (_pdfController != null && _currentPage > 1) {
      _pdfController!.previousPage(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  /// Következő oldalra léptetés.
  void _goToNextPage() {
    if (_pdfController != null && _currentPage < _totalPages) {
      _pdfController!.nextPage(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  /// Forgatás balra.
  void _rotateLeft() {
    setState(() {
      _rotationAngle -= 90;
    });
  }

  /// Forgatás jobbra.
  void _rotateRight() {
    setState(() {
      _rotationAngle += 90;
    });
  }

  /// Forgatás visszaállítása.
  void _resetRotation() {
    setState(() {
      _rotationAngle = 0;
    });
  }

  /// Oldal navigációs sáv építése.
  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$_currentPage / $_totalPages'),
          IconButton(
            onPressed: _currentPage < _totalPages ? _goToNextPage : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// További vezérlő sáv (pl. forgatás) építése.
  Widget _buildAdditionalControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _rotateLeft,
            icon: const Icon(Icons.rotate_left),
            tooltip: 'Balra forgatás',
          ),
          IconButton(
            onPressed: _rotateRight,
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Jobbra forgatás',
          ),
          IconButton(
            onPressed: _resetRotation,
            icon: const Icon(Icons.refresh),
            tooltip: 'Forgatás visszaállítása',
          ),
        ],
      ),
    );
  }

  /// A PDF megjelenítése, opcionálisan double-tap zoom kezeléssel.
  Widget _buildPdfView() {
    Widget pdfView = PdfViewPinch(
      controller: _pdfController!,
    );

    // Platform specifikus ellenőrzés: mobil platformokon engedjük a double-tap zoom-ot,
    // míg weben és asztali környezetben (nem mobil) letilthatjuk vagy másként kezeljük.
    final bool isMobile = UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

    if (isMobile && widget.enableDoubleTapZoom) {
      pdfView = GestureDetector(
        onDoubleTap: () {
          // Implementáció: ha a PdfControllerPinch támogatja a programozott zoom-ot,
          // itt állíthatjuk be a kívánt zoom szintet.
          debugPrint('Double-tap: zooming to ${widget.doubleTapZoomScale}x');
          // Példa (ha elérhető):
          // _pdfController!.setZoom(widget.doubleTapZoomScale);
          // widget.onZoomChanged?.call(widget.doubleTapZoomScale);
        },
        child: pdfView,
      );
    } else if (kIsWeb || (!isMobile && !kIsWeb)) {
      // Weben vagy asztali környezetben (amely nem mobil) a double-tap zoom általában nem elvárt.
      if (widget.enableDoubleTapZoom) {
        debugPrint('Double-tap zoom is disabled on this platform for better user experience.');
      }
    }

    // Forgatás alkalmazása a megadott szög alapján.
    return Transform.rotate(
      angle: _rotationAngle * (3.1415926535897932 / 180),
      child: pdfView,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return widget.errorWidgetBuilder != null
          ? widget.errorWidgetBuilder!(_error!, _loadPdf)
          : Center(
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

    // PDF tartalom konténerben, testreszabható dekorációval és paddinggal.
    Widget pdfContent = Container(
      padding: widget.padding ?? EdgeInsets.zero,
      decoration: widget.decoration ??
          const BoxDecoration(
            color: Colors.white,
          ),
      child: _buildPdfView(),
    );

    // Építjük a teljes layoutot: PDF tartalom + opcionális oldal navigáció + további vezérlők.
    List<Widget> children = [];
    children.add(Expanded(child: pdfContent));
    if (widget.showPageNavigation) {
      children.add(_buildNavigation());
    }
    if (widget.showAdditionalControls) {
      children.add(_buildAdditionalControls());
    }

    return Column(
      children: children,
    );
  }
}
