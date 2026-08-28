// Unit tests for the client trace id generator.

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_app/core/network/client_trace.dart';

void main() {
  test('generates a well-formed id with prefix and uuid + nanos', () {
    final id = ClientTraceId.generate();
    expect(id, startsWith('mobile-chat-'));
    // mobile-chat- + 36-char uuid + - + nanos
    expect(id.length, greaterThan('mobile-chat-'.length + 36));
    expect(id, matches(RegExp(r'^mobile-chat-[0-9a-f-]{36}-\d+$')));
  });

  test('generates unique ids', () {
    final ids = {for (var i = 0; i < 1000; i++) ClientTraceId.generate()};
    expect(ids.length, 1000);
  });

  test('uuid portion is a valid v4 uuid', () {
    final id = ClientTraceId.generate();
    // Strip the "mobile-chat-" prefix and the trailing "-<nanos>".
    final withoutPrefix = id.substring('mobile-chat-'.length);
    final uuid = withoutPrefix.substring(0, withoutPrefix.lastIndexOf('-'));
    expect(uuid.length, 36);
    // version nibble at index 14, variant at index 19
    expect(uuid[14], '4');
    expect('89ab'.contains(uuid[19]), isTrue);
  });
}
