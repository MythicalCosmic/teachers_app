import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/features/messaging/messaging_models.dart';

void main() {
  test('attachment previews never expose provider or camera filenames', () {
    const filename = 'IMG_849302_super_long_private_camera_filename.jpeg';
    final image = MessagingMessage(
      id: 'image-1',
      senderId: '1',
      senderName: 'Teacher',
      sentAt: DateTime(2026, 7, 22),
      kind: MessagingKind.image,
      mediaLabel: filename,
    );
    final captioned = MessagingMessage(
      id: 'image-2',
      senderId: '1',
      senderName: 'Teacher',
      sentAt: DateTime(2026, 7, 22),
      body: 'Board notes',
      kind: MessagingKind.image,
      mediaLabel: filename,
    );

    expect(image.preview, contains('Rasm'));
    expect(image.preview, isNot(contains(filename)));
    expect(captioned.preview, contains('Board notes'));
    expect(captioned.preview, isNot(contains(filename)));
  });
}
