import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_mesh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new WorldVoice catalog stays lightweight and does not require legacy 3D meshes',
      () async {
    final catalog = await ClassicGiftCatalog.load();
    expect(catalog, hasLength(54));
    expect(catalog.every((gift) => gift.id.startsWith('wv_gift_')), isTrue);
    expect(catalog.every((gift) => !ClassicGiftMesh.supports(gift.id)), isTrue);
  });

  test('unknown gift ids never generate arbitrary 3D assets', () {
    expect(() => ClassicGiftMesh.binary('fake_rose'), throwsArgumentError);
    expect(ClassicGiftMesh.supports('fake_rose'), isFalse);
  });
}
