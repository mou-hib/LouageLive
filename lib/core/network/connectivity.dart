import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the device has a network interface (Wi-Fi, mobile, …).
///
/// This only says whether a network is there, not whether Supabase answers:
/// request failures are still classified by `network_error.dart`. Until the
/// first value, and if the plugin fails, the device is assumed online so
/// the UI never blocks on a broken listener.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);
  try {
    yield online(await connectivity.checkConnectivity());
  } catch (_) {
    // Plugin unavailable (e.g. widget tests): do not subscribe either.
    yield true;
    return;
  }
  yield* connectivity.onConnectivityChanged
      .map(online)
      .handleError((Object _) {});
});

/// [isOnlineProvider] as a plain bool (true while unknown).
extension IsOnline on WidgetRef {
  bool get isOnline => watch(isOnlineProvider).value ?? true;
}
