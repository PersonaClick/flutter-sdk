import 'package:flutter_test/flutter_test.dart';
import 'package:personaclick_sdk/src/multi_instance/personaclick.dart';
import 'package:personaclick_sdk/src/multi_instance/personaclick_config.dart';
import 'package:personaclick_sdk/src/multi_instance/sdk_exceptions.dart';
import 'package:personaclick_sdk/src/personalization_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Records every config the facade asks to build/initialize, and returns a
  // real (but un-initialized-over-native) handle carrying the shop id. Keeps the
  // resolution contract testable without native or a live Pigeon channel.
  late List<String> built;

  PersonaClickConfig cfg(String shopId) => PersonaClickConfig(shopId: shopId);

  setUp(() {
    built = <String>[];
    PersonaClick.debugFactory = (config) {
      built.add(config.shopId);
      return PersonalizationSdk(shopId: config.shopId);
    };
  });

  tearDown(PersonaClick.reset);

  group('initialize', () {
    test('returns a handle bound to the shop and marks it live', () {
      final sdk = PersonaClick.initialize(cfg('a'));

      expect(sdk.shopId, 'a');
      expect(built, ['a']);
      expect(PersonaClick.isInitialized('a'), isTrue);
      expect(PersonaClick.liveShopIds, ['a']);
    });

    test('clears any pending registration for the same shop', () {
      PersonaClick.registerShops([cfg('a')]);
      expect(PersonaClick.pendingShopIds, ['a']);

      PersonaClick.initialize(cfg('a'));

      expect(PersonaClick.pendingShopIds, isEmpty);
      expect(PersonaClick.liveShopIds, ['a']);
    });
  });

  group('registerShops', () {
    test('lazy by default — registers without building', () {
      PersonaClick.registerShops([cfg('a'), cfg('b')]);

      expect(built, isEmpty);
      expect(PersonaClick.pendingShopIds, ['a', 'b']);
      expect(PersonaClick.isInitialized('a'), isFalse);
    });

    test('eagerInit builds every shop up front', () {
      PersonaClick.registerShops([cfg('a'), cfg('b')], eagerInit: true);

      expect(built, ['a', 'b']);
      expect(PersonaClick.liveShopIds, ['a', 'b']);
      expect(PersonaClick.pendingShopIds, isEmpty);
    });
  });

  group('getInstance', () {
    test('no id, single live shop → that instance', () {
      PersonaClick.initialize(cfg('a'));
      expect(PersonaClick.getInstance().shopId, 'a');
    });

    test('explicit id returns the matching live instance', () {
      PersonaClick.initialize(cfg('a'));
      PersonaClick.initialize(cfg('b'));
      expect(PersonaClick.getInstance('b').shopId, 'b');
    });

    test('materializes a pending shop on first use', () {
      PersonaClick.registerShops([cfg('a')]);
      expect(built, isEmpty);

      final sdk = PersonaClick.getInstance('a');

      expect(sdk.shopId, 'a');
      expect(built, ['a']);
      expect(PersonaClick.liveShopIds, ['a']);
      expect(PersonaClick.pendingShopIds, isEmpty);
    });

    test('materializes a pending shop only once', () {
      PersonaClick.registerShops([cfg('a')]);
      final first = PersonaClick.getInstance('a');
      final second = PersonaClick.getInstance('a');

      expect(built, ['a']); // built once
      expect(identical(first, second), isTrue);
    });

    test('no id with several shops → AmbiguousShopException', () {
      PersonaClick.initialize(cfg('a'));
      PersonaClick.registerShops([cfg('b')]);

      expect(
        () => PersonaClick.getInstance(),
        throwsA(
          isA<AmbiguousShopException>().having(
            (e) => e.registeredShopIds,
            'registeredShopIds',
            ['a', 'b'],
          ),
        ),
      );
    });

    test('unknown id → UnknownShopIdException', () {
      PersonaClick.initialize(cfg('a'));
      expect(
        () => PersonaClick.getInstance('nope'),
        throwsA(
          isA<UnknownShopIdException>().having(
            (e) => e.shopId,
            'shopId',
            'nope',
          ),
        ),
      );
    });

    test('no id with nothing registered → UnknownShopIdException', () {
      expect(
        () => PersonaClick.getInstance(),
        throwsA(isA<UnknownShopIdException>()),
      );
    });
  });

  group('isInitialized', () {
    test('null id true only when exactly one live shop', () {
      expect(PersonaClick.isInitialized(), isFalse);
      PersonaClick.initialize(cfg('a'));
      expect(PersonaClick.isInitialized(), isTrue);
      PersonaClick.initialize(cfg('b'));
      expect(PersonaClick.isInitialized(), isFalse); // ambiguous default
    });

    test('pending shop is not counted as initialized', () {
      PersonaClick.registerShops([cfg('a')]);
      expect(PersonaClick.isInitialized('a'), isFalse);
      expect(PersonaClick.isInitialized(), isFalse);
    });
  });
}
