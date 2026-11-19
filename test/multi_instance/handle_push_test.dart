import 'package:flutter_test/flutter_test.dart';
import 'package:personaclick_sdk/src/multi_instance/push_event.dart';
import 'package:personaclick_sdk/src/multi_instance/personaclick.dart';
import 'package:personaclick_sdk/src/multi_instance/personaclick_config.dart';
import 'package:personaclick_sdk/src/personalization_sdk.dart';
import 'package:personaclick_sdk/src/pigeon/personalization_api.g.dart' as pigeon;

/// F4 contract: [PersonaClick.handlePush] resolves the target shop from the payload's
/// `shop_id` (drop on unknown/ambiguous), tracks natively, and fires that shop's
/// callbacks — mirror of the native `PersonaClick.handlePush` routing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const handlePushChannel =
      'dev.flutter.pigeon.personaclick_flutter_sdk.PersonalizationHostApi.handlePush';

  late List<List<Object?>> nativeCalls;
  late Map<String, PersonalizationSdk> handles;

  PersonaClickConfig cfg(String shopId) => PersonaClickConfig(shopId: shopId);

  Map<String, String> push(String? shopId) => {
    'shop_id': ?shopId,
    'type': 'bulk',
    'id': 'mi-demo',
    'title': 't',
    'body': 'b',
  };

  setUp(() {
    nativeCalls = [];
    handles = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(handlePushChannel, (message) async {
          nativeCalls.add(
            pigeon.PersonalizationHostApi.pigeonChannelCodec.decodeMessage(
                  message,
                )
                as List<Object?>,
          );
          return pigeon.PersonalizationHostApi.pigeonChannelCodec.encodeMessage(
            <Object?>[],
          );
        });
    PersonaClick.debugFactory = (config) {
      final sdk = PersonalizationSdk(shopId: config.shopId);
      handles[config.shopId] = sdk;
      return sdk;
    };
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(handlePushChannel, null);
    PersonaClick.reset();
  });

  test('routes to the shop named by shop_id and tracks natively', () async {
    PersonaClick.initialize(cfg('A'));
    PersonaClick.initialize(cfg('B'));

    final routed = await PersonaClick.handlePush(push('B'), PushEvent.delivered);

    expect(routed, 'B');
    expect(nativeCalls, hasLength(1));
    expect(nativeCalls.single[1], 'delivered'); // the event's name
  });

  test('unknown shop is dropped — no native call', () async {
    PersonaClick.initialize(cfg('A'));

    final routed = await PersonaClick.handlePush(push('zzz'), PushEvent.delivered);

    expect(routed, isNull);
    expect(nativeCalls, isEmpty);
  });

  test('no shop_id with a single live shop falls back to it', () async {
    PersonaClick.initialize(cfg('A'));

    final routed = await PersonaClick.handlePush(push(null), PushEvent.delivered);

    expect(routed, 'A');
    expect(nativeCalls, hasLength(1));
  });

  test('no shop_id with two live shops is ambiguous and dropped', () async {
    PersonaClick.initialize(cfg('A'));
    PersonaClick.initialize(cfg('B'));

    final routed = await PersonaClick.handlePush(push(null), PushEvent.delivered);

    expect(routed, isNull);
    expect(nativeCalls, isEmpty);
  });

  test('materializes a pending shop and routes to it', () async {
    PersonaClick.registerShops([cfg('A')]);
    expect(PersonaClick.liveShopIds, isEmpty);

    final routed = await PersonaClick.handlePush(push('A'), PushEvent.delivered);

    expect(routed, 'A');
    expect(PersonaClick.liveShopIds, ['A']); // materialized on the push
  });

  test('fires only the target shop callbacks', () async {
    PersonaClick.initialize(cfg('A'));
    PersonaClick.initialize(cfg('B'));
    Map<String, String?>? gotA;
    Map<String, String?>? gotB;
    handles['A']!.setPushNotificationCallbacks(onReceived: (p) => gotA = p);
    handles['B']!.setPushNotificationCallbacks(onReceived: (p) => gotB = p);

    await PersonaClick.handlePush(push('B'), PushEvent.delivered);

    expect(gotB, isNotNull);
    expect(gotB!['shop_id'], 'B');
    expect(gotA, isNull);
  });

  test('the events reach native by name, and the released callbacks hear them '
      'as in 1.6.4', () async {
    PersonaClick.initialize(cfg('A'));
    final heard = <String>[];
    handles['A']!.setPushNotificationCallbacks(
      onReceived: (_) => heard.add('onReceived'),
      onDelivered: (_) => heard.add('onDelivered'),
      onClicked: (_) => heard.add('onClicked'),
    );

    for (final event in PushEvent.values) {
      await PersonaClick.handlePush(push('A'), event);
    }

    expect(nativeCalls.map((c) => c[1]), [
      'delivered',
      'opened',
      'clicked',
      'closed',
    ]);
    expect(heard, ['onReceived', 'onDelivered', 'onClicked']);
  });
}
