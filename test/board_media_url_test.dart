import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/board_media_error.dart';
void main() {
  test('compatible video keeps asset identity and non-Cloudinary URLs untouched', () {
    expect(compatibleBoardVideoUrl('https://res.cloudinary.com/demo/video/upload/v123/room/clip.mov'),
      'https://res.cloudinary.com/demo/video/upload/f_mp4,vc_h264,ac_aac/v123/room/clip.mov');
    expect(compatibleBoardVideoUrl('https://example.com/video/upload/private.mp4?sig=abc'), isNull);
    expect(compatibleBoardVideoUrl('https://res.cloudinary.com/demo/raw/upload/book.pdf'), isNull);
  });
}
