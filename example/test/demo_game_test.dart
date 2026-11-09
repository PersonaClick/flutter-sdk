import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personaclick_sdk/personaclick_sdk.dart';
// ignore: implementation_imports
import 'package:personaclick_sdk/src/v3/personalization_v3.dart';
import 'package:personaclick_sdk_example/demo_app.dart';
import 'package:personaclick_sdk_example/game/game_screen.dart';
import 'package:personaclick_sdk_example/main_shop.dart';
import 'package:personaclick_sdk_example/shop/shop.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  group('the game link', () {
    test('is host game in the scheme of any demo', () {
      for (final url in [
        'personaclick://game',
        'personaclickflutter://game',
        'personaclickrn://game',
        'PersonaClickFLUTTER://GAME',
        'personaclickflutter://game/',
        'personaclickflutter://game/play?level=2',
        ' personaclick://game ',
      ]) {
        expect(isDemoGameLink(url), isTrue, reason: url);
        expect(readDemoGameLink(url)!.page, isNull, reason: url);
      }
    });

    test(
      'with r46_stories is a stories link, and other links are not the game',
      () {
        for (final url in [
          'personaclickflutter://game?r46_stories=c&r46_story=40',
          'personaclickflutter://game/?url=https%3A%2F%2Fa.example&r46_stories=c',
          'personaclickflutter://demo.personaclick.ru/?r46_stories=c&r46_story=40&r46_slide=37',
          'personaclickflutter://shop',
          'personaclickflutter:game',
          'https://game',
          'https://demo.personaclick.ru/game',
          'myapp://game',
          '',
          'not a link',
        ]) {
          expect(isDemoGameLink(url), isFalse, reason: url);
        }
      },
    );

    test('takes an https url as the page of a game of the app', () {
      expect(
        readDemoGameLink(
          'personaclick://game?url=https%3A%2F%2Fgames.example.com%2Fttt%3Flevel%3D2',
        )!.page,
        Uri.parse('https://games.example.com/ttt?level=2'),
      );
      expect(
        readDemoGameLink(
          'personaclickflutter://game?url=https://games.example.com/ttt',
        )!.page,
        Uri.parse('https://games.example.com/ttt'),
      );
    });

    test(
      'opens the built-in game for a url that is not https or is broken',
      () {
        for (final url in [
          'personaclickflutter://game?url=http%3A%2F%2Fgames.example.com',
          'personaclickflutter://game?url=javascript%3Aalert(1)',
          'personaclickflutter://game?url=file%3A%2F%2F%2Fetc%2Fhosts',
          'personaclickflutter://game?url=https%3Agames.example.com',
          'personaclickflutter://game?url=%FF',
          'personaclickflutter://game?url=',
          'personaclickflutter://game?url',
        ]) {
          final link = readDemoGameLink(url);
          expect(link, isNotNull, reason: url);
          expect(link!.page, isNull, reason: url);
        }
      },
    );
  });

  group('the game screen', () {
    late _FakeWebViewPlatform web;

    setUp(() => WebViewPlatform.instance = web = _FakeWebViewPlatform());

    testWidgets('loads the built-in page and gives it the app theme', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(openDemoGameLink('personaclickflutter://game'), isTrue);
      await _settle(tester);

      expect(find.text(DemoGameScreen.title), findsOneWidget);
      final page = web.controllers.single;
      expect(page.asset, demoGameAsset);
      expect(page.request, isNull);
      expect(page.javaScriptMode, JavaScriptMode.unrestricted);
      expect(
        page.background,
        PersonalizationTheme.light.colors.backgroundGeneric,
      );
      // Covered until the page has the theme, so it does not flash in the wrong one.
      expect(find.byType(PersonalizationLoader), findsOneWidget);

      page.finish();
      await tester.pump();
      await tester.pump();
      expect(page.scripts, [
        "window.setGameTheme && window.setGameTheme('light')",
      ]);
      expect(find.byType(PersonalizationLoader), findsNothing);
      await _close(tester);
    });

    testWidgets('gives the page the dark theme of the app', (tester) async {
      await tester.pumpWidget(_app(brightness: Brightness.dark));
      openDemoGameLink('personaclick://game');
      await _settle(tester);

      final page = web.controllers.single;
      expect(
        page.background,
        PersonalizationTheme.dark.colors.backgroundGeneric,
      );
      page.finish();
      await tester.pump();
      expect(page.scripts, [
        "window.setGameTheme && window.setGameTheme('dark')",
      ]);
      await _close(tester);
    });

    testWidgets('loads the https page of the link instead', (tester) async {
      await tester.pumpWidget(_app());
      openDemoGameLink(
        'personaclickrn://game?url=https%3A%2F%2Fgames.example.com%2Fttt',
      );
      await _settle(tester);

      final page = web.controllers.single;
      expect(page.asset, isNull);
      expect(page.request, Uri.parse('https://games.example.com/ttt'));
      // A failed page is not left under the cover.
      page.fail();
      await tester.pump();
      await tester.pump();
      expect(find.byType(PersonalizationLoader), findsNothing);
      await _close(tester);
    });

    testWidgets('is one: a second link while it is open opens nothing', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(openDemoGameLink('personaclickflutter://game'), isTrue);
      await _settle(tester);
      expect(openDemoGameLink('personaclick://game'), isTrue);
      await _settle(tester);
      expect(find.byType(DemoGameScreen), findsOneWidget);
      expect(openDemoGameLink('https://personaclick.com'), isFalse);
      await _close(tester);
    });

    testWidgets('closes with its cross and with back', (tester) async {
      await tester.pumpWidget(_app());
      openDemoGameLink('personaclickflutter://game');
      await _settle(tester);
      await _close(tester);
      expect(find.text('home'), findsOneWidget);

      openDemoGameLink('personaclickflutter://game');
      await _settle(tester);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await _settle(tester);
      expect(find.byType(DemoGameScreen), findsNothing);
    });

    testWidgets('opens from a stories button link of any demo', (tester) async {
      await tester.pumpWidget(_app());
      // The shop is not up here: other links have nothing to open them, and no error.
      demoStoriesLinkClick('no-such-shop')('https://personaclick.com');
      await _settle(tester);
      expect(find.byType(DemoGameScreen), findsNothing);

      demoStoriesLinkClick('no-such-shop')('personaclick://game');
      await _settle(tester);
      expect(find.byType(DemoGameScreen), findsOneWidget);
      await _close(tester);
    });

    testWidgets('a link from outside opens it over the shop-only demo', (
      tester,
    ) async {
      await tester.pumpWidget(const ShopApp());
      await _linkFromOutside(tester, 'personaclickflutter://game');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DemoGameScreen), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('the link the shop-only demo started with opens it', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _links,
        (call) async =>
            call.method == 'getInitialLink' ? 'personaclickflutter://game' : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _links,
          null,
        ),
      );
      await tester.pumpWidget(const ShopApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DemoGameScreen), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('a popup link to it opens it, and the popup goes', (
      tester,
    ) async {
      await tester.pumpWidget(const ShopApp());
      final popups = PersonaClick.getInstance(demoShopId).popups;
      expect(popups.onLink!('https://personaclick.com'), isFalse);
      expect(find.byType(DemoGameScreen), findsNothing);

      expect(popups.onLink!('personaclick://game'), isTrue);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DemoGameScreen), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('the popups of triggers keep off it while it is open', (
      tester,
    ) async {
      await tester.pumpWidget(const ShopApp());
      final sdk = PersonaClick.getInstance(demoShopId);
      expect(sdk.enableAutoPopupPresentation, isTrue);
      expect(openDemoGameLink('personaclick://game'), isTrue);
      await _settle(tester);
      expect(sdk.enableAutoPopupPresentation, isFalse);
      await _close(tester);
      expect(sdk.enableAutoPopupPresentation, isTrue);
      await _unmount(tester);
    });
  });
}

const MethodChannel _links = MethodChannel('personaclick_sdk_example/links');

/// An app on the demos' navigator with a home to come back to.
Widget _app({Brightness brightness = Brightness.light}) => MaterialApp(
  navigatorKey: demoNavigatorKey,
  theme: demoTheme(brightness),
  home: const Scaffold(body: Text('home')),
);

/// Taps the cross of the game's panel.
Future<void> _close(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (widget) => widget is ShopRoundButton && widget.label == 'Закрыть',
    ),
  );
  await _settle(tester);
  expect(find.byType(DemoGameScreen), findsNothing);
}

/// Through a route's transition: the cover's loader keeps animating, so pumps of a
/// set length, not until it settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// A link as MainActivity / AppDelegate hand it over while the app runs.
Future<void> _linkFromOutside(WidgetTester tester, String url) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      _links.name,
      _links.codec.encodeMethodCall(MethodCall('onLink', url)),
      (_) {},
    );

/// Drops the shop and runs out the timeouts of its requests, which have no host here.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(minutes: 1));
}

/// WebViews without a platform: each remembers what it was told to do, and the test
/// finishes its page.
class _FakeWebViewPlatform extends WebViewPlatform {
  final List<_FakeController> controllers = <_FakeController>[];

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = _FakeController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _FakeDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _FakeWidget(params);
}

class _FakeController extends PlatformWebViewController {
  _FakeController(super.params) : super.implementation();

  String? asset;
  Uri? request;
  JavaScriptMode? javaScriptMode;
  Color? background;
  _FakeDelegate? delegate;
  final List<String> scripts = <String>[];

  void finish() => delegate!.onPageFinished!(asset ?? request.toString());

  void fail() => delegate!.onWebResourceError!(
    const WebResourceError(
      errorCode: -2,
      description: 'no network',
      isForMainFrame: true,
    ),
  );

  @override
  Future<void> loadFlutterAsset(String key) async => asset = key;

  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      request = params.uri;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async =>
      this.javaScriptMode = javaScriptMode;

  @override
  Future<void> setBackgroundColor(Color color) async => background = color;

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async => delegate = handler as _FakeDelegate;

  @override
  Future<void> runJavaScript(String javaScript) async =>
      scripts.add(javaScript);
}

class _FakeDelegate extends PlatformNavigationDelegate {
  _FakeDelegate(super.params) : super.implementation();

  PageEventCallback? onPageFinished;
  WebResourceErrorCallback? onWebResourceError;

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async =>
      this.onPageFinished = onPageFinished;

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async => this.onWebResourceError = onWebResourceError;
}

class _FakeWidget extends PlatformWebViewWidget {
  _FakeWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
