/// Exceptions raised by [PersonaClick] shop resolution.
///
/// They mirror the native contract so the same failure modes surface
/// identically on every platform:
///   * Android — `PersonaClickError`: `UnknownShopIdException` / `AmbiguousShopException`
///   * iOS     — `PersonaClickError.unknownShopId` / `.ambiguousShop`
///
/// The Flutter SDK is a thin bridge over the native SDKs, so these are raised by
/// the Dart facade's own resolver (a mirror of the registered shop-ids) — the
/// resolution rules are identical, only the throw site is in Dart.
library;

/// The error of the facade (contract `PersonaClickError`): the app's code asked for a
/// shop the facade cannot resolve. A mistake in the app's code, not a failure of
/// the SDK's work — so it is not an [SdkException]. Thrown at once by
/// [PersonaClick.getInstance].
///
/// Its two cases are the released [UnknownShopIdException] (`unknownShop`) and
/// [AmbiguousShopException] (`ambiguousShop`): code that catches either of them
/// keeps working.
sealed class PersonaClickException implements Exception {
  const PersonaClickException();

  /// The case of the contract: `unknownShop` or `ambiguousShop`.
  PersonaClickErrorType get type;

  /// A human-readable message in English.
  String get message;
}

/// The cases of [PersonaClickException].
enum PersonaClickErrorType {
  /// No shop is registered for the requested id.
  unknownShop,

  /// No shop id was given while several shops are registered.
  ambiguousShop,
}

/// Thrown when an instance is requested for a shop that is neither initialized
/// nor registered — nothing registered at all, or no such shop id.
class UnknownShopIdException extends PersonaClickException {
  const UnknownShopIdException(this.shopId, [this.customMessage]);

  @override
  PersonaClickErrorType get type => PersonaClickErrorType.unknownShop;

  /// The requested shop id, or `null` when [PersonaClick.getInstance] was called with
  /// no id while nothing at all is registered.
  final String? shopId;

  /// Optional override for the default human-readable message.
  final String? customMessage;

  @override
  String get message =>
      customMessage ??
      (shopId != null
          ? 'No shop is registered for shopId=$shopId. '
                'Call PersonaClick.initialize(...) or PersonaClick.registerShops(...) first.'
          : 'No shop has been registered. '
                'Call PersonaClick.initialize(...) or PersonaClick.registerShops(...) first.');

  @override
  String toString() => 'UnknownShopIdException: $message';
}

/// Thrown when [PersonaClick.getInstance] is called with no shop id while more than
/// one shop is registered — the default instance is ambiguous.
class AmbiguousShopException extends PersonaClickException {
  const AmbiguousShopException(this.registeredShopIds, [this.customMessage]);

  @override
  PersonaClickErrorType get type => PersonaClickErrorType.ambiguousShop;

  /// The shops (live + pending) that made the default ambiguous, sorted.
  final List<String> registeredShopIds;

  /// Optional override for the default human-readable message.
  final String? customMessage;

  @override
  String get message =>
      customMessage ??
      'More than one shop is registered — call PersonaClick.getInstance(shopId) with '
          'an explicit id. Registered: $registeredShopIds.';

  @override
  String toString() => 'AmbiguousShopException: $message';
}
