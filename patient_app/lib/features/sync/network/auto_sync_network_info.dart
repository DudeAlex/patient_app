import 'package:connectivity_plus/connectivity_plus.dart';

/// Buckets network connectivity into the simplified classes auto sync cares
/// about (Wi-Fi/ethernet, cellular, offline, or everything else).
enum AutoSyncConnectionType { wifiLike, cellular, offline, other }

/// Provides the current connectivity snapshot so auto sync can decide whether
/// a background Drive backup should run.
abstract class AutoSyncNetworkInfo {
  Future<AutoSyncConnectionType> connectionType();
}

/// Default implementation backed by `connectivity_plus`. This keeps the plugin
/// dependency at the framework layer while allowing tests to inject fakes.
class ConnectivityAutoSyncNetworkInfo implements AutoSyncNetworkInfo {
  ConnectivityAutoSyncNetworkInfo({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<AutoSyncConnectionType> connectionType() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    bool contains(ConnectivityResult target) => results.contains(target);

    if (contains(ConnectivityResult.wifi) ||
        contains(ConnectivityResult.ethernet)) {
      return AutoSyncConnectionType.wifiLike;
    }
    if (contains(ConnectivityResult.mobile) ||
        contains(ConnectivityResult.vpn)) {
      return AutoSyncConnectionType.cellular;
    }
    if (contains(ConnectivityResult.none)) {
      return AutoSyncConnectionType.offline;
    }
    return AutoSyncConnectionType.other;
  }
}
