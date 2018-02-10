/// API for listening to the livereload events based on `dart:html`.
///
/// In your `main.dart`:
/// ```
/// import 'package:livereload/client.dart';
///
/// main() {
///   new ReloadListener().listen();
///   // continue with your code...
/// }
/// ```
///
/// Caveat: If the WebSocket URI is customized, the optional parameter [webSocketUri] of [ReloadListener] needs to be specified.
library livereload_client;

import 'dart:html';

import 'src/share.dart';

/// Listener that listens to [webSocketUri] for [reloadSignal].
///
/// Call [listen] to start listening.
class ReloadListener {
  final WebSocket webSocket;
  ReloadListener(
      [String webSocketUri = 'ws://localhost:${defaultWebSocketPort}'])
      : webSocket = new WebSocket(webSocketUri) {}

  /// Reloads the web when receives [reloadSignal].
  void listen() {
    webSocket.onMessage.listen((message) {
      if (message.data == reloadSignal) {
        window.location.reload();
      }
    });
  }
}
