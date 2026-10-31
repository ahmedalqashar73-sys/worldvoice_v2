import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/chat/services/group_call_service.dart';

void main() {
  test('group audio call keeps verified membership and connected participants', () {
    final call = GroupCallInfo.fromJson({
      'id': 'group12345678',
      'chatId': 'group12345678',
      'channelId': 'group_group12345678',
      'groupName': 'English speakers',
      'type': 'audio',
      'status': 'active',
      'ownerId': 'owner',
      'memberIds': ['owner', 'friend1', 'friend2'],
      'joinedIds': ['owner', 'friend1'],
      'memberNames': {'owner': 'Ahmed', 'friend1': 'Mimi'},
    });
    expect(call.isActive, isTrue);
    expect(call.isVideo, isFalse);
    expect(call.memberIds, hasLength(3));
    expect(call.joinedIds, ['owner', 'friend1']);
    expect(call.memberNames['friend1'], 'Mimi');
  });

  test('group video call remains a distinct call type', () {
    final call = GroupCallInfo.fromJson({
      'chatId': 'group12345678',
      'type': 'video',
      'status': 'ended',
      'joinedIds': [],
    });
    expect(call.isVideo, isTrue);
    expect(call.isActive, isFalse);
    expect(call.joinedIds, isEmpty);
  });
}
