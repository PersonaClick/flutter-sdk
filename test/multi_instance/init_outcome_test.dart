import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personaclick_sdk/personaclick_sdk.dart';
import 'package:personaclick_sdk/src/pigeon/personalization_api.g.dart' as pigeon;

const _initChannel =
    'dev.flutter.pigeon.personaclick_flutter_sdk.PersonalizationHostApi.initialize';

// `PersonaClick.initialize` hands the shop's handle back at once and the native init goes on. Its
// outcome is the handle's `ready`; a failed init is not left as an unhandled error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answerInit(List<Object?> reply) {
    messenger.setMockMessageHandler(
      _initChannel,
      (_) async =>
          pigeon.PersonalizationHostApi.pigeonChannelCodec.encodeMessage(reply),
    );
  }

  tearDown(() {
    messenger.setMockMessageHandler(_initChannel, null);
    PersonaClick.reset();
  });

  test('a failed native init is not left as an unhandled error', () async {
    answerInit(<Object?>['init_failed', 'shop refused', null]);

    PersonaClick.initialize(const PersonaClickConfig(shopId: 'refused-shop'));
    await pumpEventQueue();
  });

  test('a failed native init reaches ready', () async {
    answerInit(<Object?>['init_failed', 'shop refused', null]);

    final sdk = PersonaClick.initialize(const PersonaClickConfig(shopId: 'refused-shop'));

    await expectLater(
      sdk.ready,
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'init_failed'),
      ),
    );
  });

  test('a native init that succeeds completes ready', () async {
    answerInit(<Object?>[]);

    final sdk = PersonaClick.initialize(const PersonaClickConfig(shopId: 'live-shop'));

    await expectLater(sdk.ready, completes);
  });
}
