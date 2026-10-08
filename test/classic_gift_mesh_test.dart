import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_mesh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every approved gift has a real, self-contained glTF 2.0 mesh', () async {
    final catalog = await ClassicGiftCatalog.load();
    expect(catalog, hasLength(30));
    final ids = <String>{};
    for (final gift in catalog) {
      expect(ids.add(gift.id), isTrue);
      expect(ClassicGiftMesh.supports(gift.id), isTrue);
      final glb = ClassicGiftMesh.binary(gift.id);
      expect(glb.length, greaterThan(512));
      final header = ByteData.sublistView(glb);
      expect(header.getUint32(0, Endian.little), 0x46546C67);
      expect(header.getUint32(4, Endian.little), 2);
      expect(header.getUint32(8, Endian.little), glb.length);
      final jsonLength = header.getUint32(12, Endian.little);
      expect(header.getUint32(16, Endian.little), 0x4E4F534A);
      final decoded = jsonDecode(utf8.decode(
          glb.sublist(20, 20 + jsonLength)).trim()) as Map<String, dynamic>;
      expect((decoded['asset'] as Map)['version'], '2.0');
      final scenes = decoded['scenes'] as List;
      final meshes = decoded['meshes'] as List;
      expect(scenes, isNotEmpty);
      expect(meshes, isNotEmpty);
      expect((meshes.first as Map)['primitives'], isNotEmpty);
      final binaryHeaderAt = 20 + jsonLength;
      final bufferSize =
          header.getUint32(binaryHeaderAt, Endian.little);
      expect(header.getUint32(binaryHeaderAt + 4, Endian.little),
          0x004E4942);
      expect(glb.length, binaryHeaderAt + 8 + bufferSize);
      final views = decoded['bufferViews'] as List;
      for (final raw in views) {
        final view = raw as Map;
        final offset = view['byteOffset'] as int;
        final length = view['byteLength'] as int;
        expect(offset % 4, 0);
        expect(offset + length, lessThanOrEqualTo(bufferSize));
      }
      expect(ClassicGiftMesh.dataUri(gift.id),
          startsWith('data:model/gltf-binary;base64,'));
    }
  });

  test('unknown gift ids never generate arbitrary 3D assets', () {
    expect(() => ClassicGiftMesh.binary('fake_rose'), throwsArgumentError);
    expect(ClassicGiftMesh.supports('fake_rose'), isFalse);
  });
}
