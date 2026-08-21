import '../sdk_init_config.dart';

/// Configuration for one SDK instance (one shop), passed to
/// [Personaclick.initialize] / [Personaclick.registerShops].
///
/// Mirrors the native `PersonaclickConfig` (Android/iOS). It is a superset of the
/// legacy [SdkInitConfig]: the same init fields plus an optional [storageKey]
/// for the storage-partition key (defaults to `shopId` natively).
///
/// `storageKey` is **reserved for parity** and not wired end-to-end yet: the
/// Pigeon `InitConfig` has no `storageKey` field, so the native default
/// (partition == `shopId`) applies until the bridge threads it (plan step F2).
class PersonaclickConfig {
  const PersonaclickConfig({
    required this.shopId,
    this.apiDomain,
    this.stream,
    this.enableLogs,
    this.autoSendPushToken,
    this.sendAdvertisingId,
    this.enableAutoPopupPresentation,
    this.needReInitialization,
    this.storageKey,
  });

  final String shopId;
  final String? apiDomain;
  final String? stream;
  final bool? enableLogs;
  final bool? autoSendPushToken;
  final bool? sendAdvertisingId;
  final bool? enableAutoPopupPresentation;
  final bool? needReInitialization;

  /// Storage-partition key. Defaults to [shopId] natively. Reserved — see the
  /// class doc.
  final String? storageKey;

  /// Bridges to the legacy [SdkInitConfig] consumed by the current single-shop
  /// init path. [storageKey] is intentionally dropped here (no wire field yet).
  SdkInitConfig toSdkInitConfig() => SdkInitConfig(
    shopId: shopId,
    apiDomain: apiDomain,
    stream: stream,
    enableLogs: enableLogs,
    autoSendPushToken: autoSendPushToken,
    sendAdvertisingId: sendAdvertisingId,
    enableAutoPopupPresentation: enableAutoPopupPresentation,
    needReInitialization: needReInitialization,
  );

  PersonaclickConfig copyWith({String? shopId, String? storageKey}) => PersonaclickConfig(
    shopId: shopId ?? this.shopId,
    apiDomain: apiDomain,
    stream: stream,
    enableLogs: enableLogs,
    autoSendPushToken: autoSendPushToken,
    sendAdvertisingId: sendAdvertisingId,
    enableAutoPopupPresentation: enableAutoPopupPresentation,
    needReInitialization: needReInitialization,
    storageKey: storageKey ?? this.storageKey,
  );
}
