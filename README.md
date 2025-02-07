
```markdown
# pdf_minimal

**pdf_minimal** egy minimalista, multiplatform PDF megjelenítő Flutter csomag, amely kizárólag a PDF dokumentum tartalmát jeleníti meg – további navigációs elemek (pl. toolbar) nélkül. A csomag támogatja az asset-ekből, helyi fájlokból, URL-ekről és memóriában lévő PDF adatokból történő betöltést, így könnyen integrálható különböző projektekbe.

## Jellemzők

- **Minimalista megjelenítés:** Csak a PDF tartalmát rendereli, felesleges UI elemek nélkül.
- **Több forrás támogatása:**  
  - **Asset:** Például az alkalmazáshoz csomagolt PDF-ek.
  - **Fájl:** Helyi fájlrendszerből történő betöltés.
  - **URL:** PDF dokumentum letöltése webről.
  - **Memória:** PDF adatok közvetlen betöltése `Uint8List` formátumban.
- **Multiplatform támogatás:** Android, iOS, Web, Windows, macOS és Linux (a [pdfx](https://pub.dev/packages/pdfx) csomag támogatásának köszönhetően).
- **Pinch-zoom és lapozási funkciók:** A `PdfControllerPinch` vezérlő segítségével.

## Telepítés

Adja hozzá a `pubspec.yaml` fájlod `dependencies` részéhez:

```yaml
dependencies:
  pdf_minimal: ^0.0.1
```

Majd futtasd a következő parancsot a függőségek letöltéséhez:

```bash
flutter pub get
```

## Használat

A csomag fő komponense a `PdfViewerMinimal` widget, amelyet egyszerűen beilleszthetsz az alkalmazásodba. Az alábbi példa bemutatja, hogyan használhatod az asset forrást:

```dart
import 'package:flutter/material.dart';
import 'package:pdf_minimal/pdf_minimal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Minimal Demo',
      home: const PdfViewerExample(),
    );
  }
}

class PdfViewerExample extends StatelessWidget {
  const PdfViewerExample({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Minimal'),
      ),
      body: const PdfViewerMinimal(
        // Példa források:
        // assetPath: 'assets/sample.pdf',
        // filePath: '/path/to/sample.pdf',
        // url: 'https://www.example.com/sample.pdf',
        // data: pdfDataUint8List,
        assetPath: 'assets/sample.pdf',
      ),
    );
  }
}
```

### Források megadása

A `PdfViewerMinimal` widget legalább egy forrást igényel a PDF betöltéséhez. A rendelkezésre álló opciók:

- **assetPath:** Az alkalmazáshoz csomagolt PDF (pl. `assets/sample.pdf`).
- **filePath:** Helyi fájlrendszerből elérhető PDF.
- **url:** URL, ahonnan a PDF letölthető.
- **data:** A PDF adatok `Uint8List` formátumban.

Ne felejtsd el, ha asset-et használsz, deklaráld azt a `pubspec.yaml` fájlodban:

```yaml
flutter:
  assets:
    - assets/sample.pdf
```

## Támogatott platformok

A csomag a [pdfx](https://pub.dev/packages/pdfx) csomag segítségével biztosít multiplatform támogatást, így a következő platformokon használható:

- **Android**
- **iOS**
- **Web**
- **Windows**
- **macOS**
- **Linux**

## Hibák és javaslatok

Ha hibát találsz vagy javaslatod van a csomag fejlesztésére, kérlek nyiss egy issue-t a GitHub repóban:  
[https://github.com/albhultd/pdf_minimal](https://github.com/albhultd/pdf_minimal)

## Licenc

Ez a csomag az MIT licenc alatt érhető el. További információkért lásd a [LICENSE](LICENSE) fájlt.
```

---
