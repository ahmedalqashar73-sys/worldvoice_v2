import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/services/live_session_service.dart';

void main() {
  test('Live uses the WorldVoice profile before Google Auth metadata', () {
    final person = LiveProfileIdentity.fromProfile({
      'name': 'أحمد',
      'avatarUrl': 'https://example.com/worldvoice-photo.jpg',
    }, fallbackName: 'Google User',
       fallbackPhotoUrl: 'https://example.com/google-photo.jpg');
    expect(person.name, 'أحمد');
    expect(person.photoUrl, 'https://example.com/worldvoice-photo.jpg');
  });

  test('Live comments and join notices preserve the public profile identity', () {
    final person = LiveProfileIdentity.fromProfile({
      'displayName': 'Ahmed',
      'photoUrl': 'https://example.com/avatar.png',
    }, fallbackName: 'Old Account');
    expect(person.name, 'Ahmed');
    expect(person.photoUrl, 'https://example.com/avatar.png');
  });

  test('Missing profile falls back without inventing a real photo', () {
    final person = LiveProfileIdentity.fromProfile(
      null, fallbackName: 'Guest', fallbackPhotoUrl: '',
    );
    expect(person.name, 'Guest');
    expect(person.photoUrl, isEmpty);
  });
}
