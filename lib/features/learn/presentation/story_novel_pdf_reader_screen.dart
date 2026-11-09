import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../domain/models/story_library_models.dart';

/// Displays the original PDF pages for WorldVoice Library novels.
/// When a book is not yet bundled, the owner can import its PDF from Downloads.
/// The older JSON reader remains untouched for future AI and learning features.
class StoryNovelPdfReaderScreen extends StatefulWidget {
  const StoryNovelPdfReaderScreen({super.key, required this.entry});

  final StoryLibraryEntry entry;

  @override
  State<StoryNovelPdfReaderScreen> createState() =>
      _StoryNovelPdfReaderScreenState();
}

/// A stable asset convention for published novels. Packages containing the
/// official PDFs will open automatically without any import step.
String novelPdfAssetPath(String id) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
    throw ArgumentError.value(id, 'id', 'Invalid WorldVoice novel id');
  }
  return 'assets/stories/en/A1/books/' + id + '.pdf';
}

/// Resolves a published novel's PDF using its language and CEFR level.
/// For example: Spanish A2 -> assets/stories/es/A2/books/<id>.pdf.
String novelPdfAssetPathForEntry(StoryLibraryEntry entry) {
  final code = entry.language.trim().toLowerCase();
  final level = entry.level.trim().toUpperCase();
  if (!RegExp(r'^[a-z]{2,3}
  const _PdfLocation.asset(this.path) : isAsset = true;
  const _PdfLocation.file(this.path) : isAsset = false;

  final String path;
  final bool isAsset;
}

class _StoryNovelPdfReaderScreenState
    extends State<StoryNovelPdfReaderScreen> {
  late Future<_PdfLocation?> _location = _findPdf();
  bool _importing = false;

  Future<String> _localPath() async {
    final home = await getApplicationDocumentsDirectory();
    final folder = Directory(
      home.path + Platform.pathSeparator + 'worldvoice_library_pdfs',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path + Platform.pathSeparator + widget.entry.id + '.pdf';
  }

  Future<_PdfLocation?> _findPdf() async {
    final bundled = novelPdfAssetPathForEntry(widget.entry);
    try {
      await rootBundle.load(bundled);
      return _PdfLocation.asset(bundled);
    } catch (_) {
      // A missing bundled asset is expected during the import-only transition.
    }
    final local = File(await _localPath());
    if (await local.exists() && await _validPdf(local)) {
      return _PdfLocation.file(local.path);
    }
    return null;
  }

  Future<bool> _validPdf(File file) async {
    if (!await file.exists() || await file.length() < 128) return false;
    final bytes = await file.openRead(0, 5).expand((part) => part).toList();
    return bytes.length == 5 &&
        String.fromCharCodes(bytes) == '%PDF-';
  }

  Future<void> _importPdf() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      // file_picker 13.x: use the single-file static picker.
      final PlatformFile? chosen = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || chosen == null) return;
      final String? selectedPath = chosen.path;
      final target = File(await _localPath());
      final temp = File(target.path + '.part');
      if (selectedPath != null) {
        await File(selectedPath).copy(temp.path);
      } else {
        final Uint8List bytes = await chosen.readAsBytes();
        await temp.writeAsBytes(bytes, flush: true);
      }
      if (!await _validPdf(temp)) {
        await temp.delete();
        throw const FormatException('Please select a valid PDF book.');
      }
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      if (mounted) setState(() => _location = _findPdf());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr),
        actions: [
          IconButton(
            tooltip: ar ? 'اختيار ملف PDF' : 'Import PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _importing ? null : _importPdf,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE7E5E2),
      body: FutureBuilder<_PdfLocation?>(
        future: _location,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final source = snapshot.data;
          if (source == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                      size: 58, color: Color(0xFF254E42)),
                    const SizedBox(height: 16),
                    Text(ar ? 'افتح الكتاب بصيغة PDF الأصلية'
                            : 'Open the original PDF book',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      ar
                        ? 'اختر نسخة PDF الخاصة بهذه الرواية من ملفات جوالك مرة واحدة. سيحفظها WorldVoice ويعرض صفحاتها الأصلية مع التكبير والتصغير.'
                        : 'Choose this novel’s original PDF from your phone once. WorldVoice will keep the file and display the original pages, with pinch zoom.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const ValueKey('worldvoice-novel-import-pdf'),
                      onPressed: _importing ? null : _importPdf,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(ar ? 'اختيار PDF من الجوال'
                                     : 'Choose a PDF file'),
                    ),
                  ],
                ),
              ),
            );
          }
          return KeyedSubtree(
            key: ValueKey(source.path),
            child: source.isAsset
              ? PdfViewer.asset(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                )
              : PdfViewer.file(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                ),
          );
        },
      ),
    );
  }
}
).hasMatch(code) ||
      !RegExp(r'^(A1|A2|B1|B2|C1|C2)
  const _PdfLocation.asset(this.path) : isAsset = true;
  const _PdfLocation.file(this.path) : isAsset = false;

  final String path;
  final bool isAsset;
}

class _StoryNovelPdfReaderScreenState
    extends State<StoryNovelPdfReaderScreen> {
  late Future<_PdfLocation?> _location = _findPdf();
  bool _importing = false;

  Future<String> _localPath() async {
    final home = await getApplicationDocumentsDirectory();
    final folder = Directory(
      home.path + Platform.pathSeparator + 'worldvoice_library_pdfs',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path + Platform.pathSeparator + widget.entry.id + '.pdf';
  }

  Future<_PdfLocation?> _findPdf() async {
    final bundled = novelPdfAssetPath(widget.entry.id);
    try {
      await rootBundle.load(bundled);
      return _PdfLocation.asset(bundled);
    } catch (_) {
      // A missing bundled asset is expected during the import-only transition.
    }
    final local = File(await _localPath());
    if (await local.exists() && await _validPdf(local)) {
      return _PdfLocation.file(local.path);
    }
    return null;
  }

  Future<bool> _validPdf(File file) async {
    if (!await file.exists() || await file.length() < 128) return false;
    final bytes = await file.openRead(0, 5).expand((part) => part).toList();
    return bytes.length == 5 &&
        String.fromCharCodes(bytes) == '%PDF-';
  }

  Future<void> _importPdf() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      // file_picker 13.x: use the single-file static picker.
      final PlatformFile? chosen = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || chosen == null) return;
      final String? selectedPath = chosen.path;
      final target = File(await _localPath());
      final temp = File(target.path + '.part');
      if (selectedPath != null) {
        await File(selectedPath).copy(temp.path);
      } else {
        final Uint8List bytes = await chosen.readAsBytes();
        await temp.writeAsBytes(bytes, flush: true);
      }
      if (!await _validPdf(temp)) {
        await temp.delete();
        throw const FormatException('Please select a valid PDF book.');
      }
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      if (mounted) setState(() => _location = _findPdf());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr),
        actions: [
          IconButton(
            tooltip: ar ? 'اختيار ملف PDF' : 'Import PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _importing ? null : _importPdf,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE7E5E2),
      body: FutureBuilder<_PdfLocation?>(
        future: _location,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final source = snapshot.data;
          if (source == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                      size: 58, color: Color(0xFF254E42)),
                    const SizedBox(height: 16),
                    Text(ar ? 'افتح الكتاب بصيغة PDF الأصلية'
                            : 'Open the original PDF book',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      ar
                        ? 'اختر نسخة PDF الخاصة بهذه الرواية من ملفات جوالك مرة واحدة. سيحفظها WorldVoice ويعرض صفحاتها الأصلية مع التكبير والتصغير.'
                        : 'Choose this novel’s original PDF from your phone once. WorldVoice will keep the file and display the original pages, with pinch zoom.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const ValueKey('worldvoice-novel-import-pdf'),
                      onPressed: _importing ? null : _importPdf,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(ar ? 'اختيار PDF من الجوال'
                                     : 'Choose a PDF file'),
                    ),
                  ],
                ),
              ),
            );
          }
          return KeyedSubtree(
            key: ValueKey(source.path),
            child: source.isAsset
              ? PdfViewer.asset(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                )
              : PdfViewer.file(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                ),
          );
        },
      ),
    );
  }
}
).hasMatch(level) ||
      !RegExp(r'^[a-z][a-z0-9_]*
  const _PdfLocation.asset(this.path) : isAsset = true;
  const _PdfLocation.file(this.path) : isAsset = false;

  final String path;
  final bool isAsset;
}

class _StoryNovelPdfReaderScreenState
    extends State<StoryNovelPdfReaderScreen> {
  late Future<_PdfLocation?> _location = _findPdf();
  bool _importing = false;

  Future<String> _localPath() async {
    final home = await getApplicationDocumentsDirectory();
    final folder = Directory(
      home.path + Platform.pathSeparator + 'worldvoice_library_pdfs',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path + Platform.pathSeparator + widget.entry.id + '.pdf';
  }

  Future<_PdfLocation?> _findPdf() async {
    final bundled = novelPdfAssetPath(widget.entry.id);
    try {
      await rootBundle.load(bundled);
      return _PdfLocation.asset(bundled);
    } catch (_) {
      // A missing bundled asset is expected during the import-only transition.
    }
    final local = File(await _localPath());
    if (await local.exists() && await _validPdf(local)) {
      return _PdfLocation.file(local.path);
    }
    return null;
  }

  Future<bool> _validPdf(File file) async {
    if (!await file.exists() || await file.length() < 128) return false;
    final bytes = await file.openRead(0, 5).expand((part) => part).toList();
    return bytes.length == 5 &&
        String.fromCharCodes(bytes) == '%PDF-';
  }

  Future<void> _importPdf() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      // file_picker 13.x: use the single-file static picker.
      final PlatformFile? chosen = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || chosen == null) return;
      final String? selectedPath = chosen.path;
      final target = File(await _localPath());
      final temp = File(target.path + '.part');
      if (selectedPath != null) {
        await File(selectedPath).copy(temp.path);
      } else {
        final Uint8List bytes = await chosen.readAsBytes();
        await temp.writeAsBytes(bytes, flush: true);
      }
      if (!await _validPdf(temp)) {
        await temp.delete();
        throw const FormatException('Please select a valid PDF book.');
      }
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      if (mounted) setState(() => _location = _findPdf());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr),
        actions: [
          IconButton(
            tooltip: ar ? 'اختيار ملف PDF' : 'Import PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _importing ? null : _importPdf,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE7E5E2),
      body: FutureBuilder<_PdfLocation?>(
        future: _location,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final source = snapshot.data;
          if (source == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                      size: 58, color: Color(0xFF254E42)),
                    const SizedBox(height: 16),
                    Text(ar ? 'افتح الكتاب بصيغة PDF الأصلية'
                            : 'Open the original PDF book',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      ar
                        ? 'اختر نسخة PDF الخاصة بهذه الرواية من ملفات جوالك مرة واحدة. سيحفظها WorldVoice ويعرض صفحاتها الأصلية مع التكبير والتصغير.'
                        : 'Choose this novel’s original PDF from your phone once. WorldVoice will keep the file and display the original pages, with pinch zoom.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const ValueKey('worldvoice-novel-import-pdf'),
                      onPressed: _importing ? null : _importPdf,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(ar ? 'اختيار PDF من الجوال'
                                     : 'Choose a PDF file'),
                    ),
                  ],
                ),
              ),
            );
          }
          return KeyedSubtree(
            key: ValueKey(source.path),
            child: source.isAsset
              ? PdfViewer.asset(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                )
              : PdfViewer.file(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                ),
          );
        },
      ),
    );
  }
}
).hasMatch(entry.id)) {
    throw ArgumentError('Invalid WorldVoice novel language, level or id');
  }
  final root = 'assets/stories/' + code + '/' + level + '/';
  if (!entry.asset.startsWith(root) || !entry.asset.endsWith('.json')) {
    throw ArgumentError('WorldVoice novel index does not match its asset path');
  }
  return root + 'books/' + entry.id + '.pdf';
}

class _PdfLocation {
  const _PdfLocation.asset(this.path) : isAsset = true;
  const _PdfLocation.file(this.path) : isAsset = false;

  final String path;
  final bool isAsset;
}

class _StoryNovelPdfReaderScreenState
    extends State<StoryNovelPdfReaderScreen> {
  late Future<_PdfLocation?> _location = _findPdf();
  bool _importing = false;

  Future<String> _localPath() async {
    final home = await getApplicationDocumentsDirectory();
    final folder = Directory(
      home.path + Platform.pathSeparator + 'worldvoice_library_pdfs',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path + Platform.pathSeparator + widget.entry.id + '.pdf';
  }

  Future<_PdfLocation?> _findPdf() async {
    final bundled = novelPdfAssetPath(widget.entry.id);
    try {
      await rootBundle.load(bundled);
      return _PdfLocation.asset(bundled);
    } catch (_) {
      // A missing bundled asset is expected during the import-only transition.
    }
    final local = File(await _localPath());
    if (await local.exists() && await _validPdf(local)) {
      return _PdfLocation.file(local.path);
    }
    return null;
  }

  Future<bool> _validPdf(File file) async {
    if (!await file.exists() || await file.length() < 128) return false;
    final bytes = await file.openRead(0, 5).expand((part) => part).toList();
    return bytes.length == 5 &&
        String.fromCharCodes(bytes) == '%PDF-';
  }

  Future<void> _importPdf() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      // file_picker 13.x: use the single-file static picker.
      final PlatformFile? chosen = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || chosen == null) return;
      final String? selectedPath = chosen.path;
      final target = File(await _localPath());
      final temp = File(target.path + '.part');
      if (selectedPath != null) {
        await File(selectedPath).copy(temp.path);
      } else {
        final Uint8List bytes = await chosen.readAsBytes();
        await temp.writeAsBytes(bytes, flush: true);
      }
      if (!await _validPdf(temp)) {
        await temp.delete();
        throw const FormatException('Please select a valid PDF book.');
      }
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      if (mounted) setState(() => _location = _findPdf());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr),
        actions: [
          IconButton(
            tooltip: ar ? 'اختيار ملف PDF' : 'Import PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _importing ? null : _importPdf,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE7E5E2),
      body: FutureBuilder<_PdfLocation?>(
        future: _location,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final source = snapshot.data;
          if (source == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                      size: 58, color: Color(0xFF254E42)),
                    const SizedBox(height: 16),
                    Text(ar ? 'افتح الكتاب بصيغة PDF الأصلية'
                            : 'Open the original PDF book',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      ar
                        ? 'اختر نسخة PDF الخاصة بهذه الرواية من ملفات جوالك مرة واحدة. سيحفظها WorldVoice ويعرض صفحاتها الأصلية مع التكبير والتصغير.'
                        : 'Choose this novel’s original PDF from your phone once. WorldVoice will keep the file and display the original pages, with pinch zoom.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const ValueKey('worldvoice-novel-import-pdf'),
                      onPressed: _importing ? null : _importPdf,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(ar ? 'اختيار PDF من الجوال'
                                     : 'Choose a PDF file'),
                    ),
                  ],
                ),
              ),
            );
          }
          return KeyedSubtree(
            key: ValueKey(source.path),
            child: source.isAsset
              ? PdfViewer.asset(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                )
              : PdfViewer.file(
                  source.path,
                  params: const PdfViewerParams(
                    margin: 2.0,
                    backgroundColor: Colors.white,
                    scaleEnabled: true,
                    panEnabled: true,
                  ),
                ),
          );
        },
      ),
    );
  }
}
