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

  PersonaclickConfig cfg(String shopId) => PersonaclickConfig(shopId: shopId);

  setUp(() {
    built = <String>[];
    Personaclick.debugFactory = (config) {
      built.add(config.shopId);
      return PersonalizationSdk(shopId: config.shopId);
    };
  });

  tearDown(Personaclick.reset);

  group('initialize', () {
    test('returns a handle bound to the shop and marks it live', () {
      final sdk = Personaclick.initialize(cfg('a'));

      expect(sdk.shopId, 'a');
      expect(built, ['a']);
      expect(Personaclick.isInitialized('a'), isTrue);
      expect(Personaclick.liveShopIds, ['a']);
    });

    test('clears any pending registration for the same shop', () {
      Personaclick.registerShops([cfg('a')]);
      expect(Personaclick.pendingShopIds, ['a']);

      Personaclick.initialize(cfg('a'));

      expect(Personaclick.pendingShopIds, isEmpty);
      expect(Personaclick.liveShopIds, ['a']);
    });
  });

  group('registerShops', () {
    test('lazy by default — registers without building', () {
      Personaclick.registerShops([cfg('a'), cfg('b')]);

      expect(built, isEmpty);
      expect(Personaclick.pendingShopIds, ['a', 'b']);
      expect(Personaclick.isInitialized('a'), isFalse);
    });

    test('eagerInit builds every shop up front', () {
      Personaclick.registerShops([cfg('a'), cfg('b')], eagerInit: true);

      expect(built, ['a', 'b']);
      expect(Personaclick.liveShopIds, ['a', 'b']);
      expect(Personaclick.pendingShopIds, isEmpty);
    });
  });

  group('getInstance', () {
    test('no id, single live shop → that instance', () {
      Personaclick.initialize(cfg('a'));
      expect(Personaclick.getInstance().shopId, 'a');
    });

    test('explicit id returns the matching live instance', () {
      Personaclick.initialize(cfg('a'));
      Personaclick.initialize(cfg('b'));
      expect(Personaclick.getInstance('b').shopId, 'b');
    });

    test('materializes a pending shop on first use', () {
      Personaclick.registerShops([cfg('a')]);
      expect(built, isEmpty);

      final sdk = Personaclick.getInstance('a');

      expect(sdk.shopId, 'a');
      expect(built, ['a']);
      expect(Personaclick.liveShopIds, ['a']);
      expect(Personaclick.pendingShopIds, isEmpty);
    });

    test('materializes a pending shop only once', () {
      Personaclick.registerShops([cfg('a')]);
      final first = Personaclick.getInstance('a');
      final second = Personaclick.getInstance('a');

      expect(built, ['a']); // built once
      expect(identical(first, second), isTrue);
    });

    test('no id with several shops → AmbiguousShopException', () {
      Personaclick.initialize(cfg('a'));
      Personaclick.registerShops([cfg('b')]);

      expect(
        () => Personaclick.getInstance(),
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
      Personaclick.initialize(cfg('a'));
      expect(
        () => Personaclick.getInstance('nope'),
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
        () => Personaclick.getInstance(),
        throwsA(isA<UnknownShopIdException>()),
      );
    });
  });

  group('isInitialized', () {
    test('null id true only when exactly one live shop', () {
      expect(Personaclick.isInitialized(), isFalse);
      Personaclick.initialize(cfg('a'));
      expect(Personaclick.isInitialized(), isTrue);
      Personaclick.initialize(cfg('b'));
      expect(Personaclick.isInitialized(), isFalse); // ambiguous default
    });

    test('pending shop is not counted as initialized', () {
      Personaclick.registerShops([cfg('a')]);
      expect(Personaclick.isInitialized('a'), isFalse);
      expect(Personaclick.isInitialized(), isFalse);
    });
  });
}
