import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice_v2/features/chat/services/chat_archive_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('archive and restore do not touch conversations or other accounts', () async {
    SharedPreferences.setMockInitialValues({});
    final alice = ChatArchiveStore.of('archive-test-alice');
    final bob = ChatArchiveStore.of('archive-test-bob');
    await alice.load();
    await bob.load();

    expect(alice.contains('group_123'), isFalse);
    await alice.setArchived('group_123', true);
    expect(alice.contains('group_123'), isTrue);
    expect(bob.contains('group_123'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('worldvoice_archived_chats_v1_archive-test-alice'),
        contains('group_123'));
    expect(prefs.getStringList('worldvoice_archived_chats_v1_archive-test-bob'),
        isNull);

    await alice.setArchived('group_123', false);
    expect(alice.contains('group_123'), isFalse);
    expect(prefs.getStringList('worldvoice_archived_chats_v1_archive-test-alice'),
        isEmpty);
  });
}
