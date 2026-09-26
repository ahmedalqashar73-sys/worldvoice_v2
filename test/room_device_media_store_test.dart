import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/room_device_media_store.dart';

void main() {
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('worldvoice_pdf_test_');
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('PDF header detection rejects HTML error pages', () async {
    final pdf = File(sandbox.path + Platform.pathSeparator + 'valid.pdf');
    await pdf.writeAsBytes(<int>[37, 80, 68, 70, 45, 49, 46, 55]);
    expect(await RoomDeviceMediaStore.isPdf(pdf), isTrue);

    final html = File(sandbox.path + Platform.pathSeparator + 'invalid.pdf');
    await html.writeAsString('<html>Forbidden</html>');
    expect(await RoomDeviceMediaStore.isPdf(html), isFalse);
  });

  test('PDF header detection rejects missing and empty files', () async {
    final missing = File(sandbox.path + Platform.pathSeparator + 'missing.pdf');
    expect(await RoomDeviceMediaStore.isPdf(missing), isFalse);

    final empty = File(sandbox.path + Platform.pathSeparator + 'empty.pdf');
    await empty.writeAsBytes(<int>[]);
    expect(await RoomDeviceMediaStore.isPdf(empty), isFalse);
  });
}
