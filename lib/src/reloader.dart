import 'dart:async';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'share.dart';

/// A default [Reloader].
class LiveReloader extends Reloader {
  /// True if the server serves a Single Page Application (SPA).
  final bool spa;

  WebSocketChannel _channel;
  final StreamController<Null> _controller = new StreamController();

  bool _isFirstBuild = true;

  /// Creates a new LiveReloader.
  ///
  /// Set [spa] to `true` to rewrite requests to [buildRunnerUri].
  LiveReloader(Uri buildRunnerUri, Uri httpUri, Uri webSocketUri,
      {this.spa = true})
      : super(buildRunnerUri, httpUri, webSocketUri) {
    _controller.stream.listen((_) {
      if (!_isFirstBuild) {
        handleIncrementalBuild();
      } else {
        _isFirstBuild = false;
        handleFirstBuild();
      }
    });
  }

  /// Channel to communicate via [webSocketUri].
  ///
  /// This is only available after [startWebSocketServer].
  WebSocketChannel get channel => _channel;

  @override
  void add(_) {
    _controller.add(_);
  }

  @override
  void close() {
    _controller.close();
  }

  /// Handles the first succeeded build.
  ///
  /// By default, it [startHttpServer] and [startWebSocketServer].
  /// This method may be overridden to add more functionalities.
  void handleFirstBuild() {
    startHttpServer();
    startWebSocketServer();
  }

  /// Handles any succeeded build other than the first one.
  ///
  /// By default, it sends [reloadSignal] to notify the web to reload.
  /// This method may be overridden to add more functionalities.
  void handleIncrementalBuild() {
    _reload();
  }

  /// Decides if [uri] should be rewritten to [buildRunnerUri].
  ///
  /// By default, it determines if the [uri] doesn't have a MIME type.
  /// This method may be overridden.
  bool shouldBeRewritten(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty
        ? lookupMimeType(uri.pathSegments.last) == null
        : false;
  }

  /// Starts a server that passes every request to `build_runner serve`.
  ///
  /// If [spa] is `true`, the server will pass every request that [shouldBeRewritten] to [buildRunnerUri].
  void startHttpServer() {
    final handler = (Request request) =>
        spa && shouldBeRewritten(request.requestedUri)
            ? proxyHandler(buildRunnerUri)(_changePath(request, '/'))
            : proxyHandler(buildRunnerUri)(request);

    shelf_io.serve(handler, proxyUri.host, proxyUri.port).then((server) {
      print('Proxying at http://${server.address.host}:${server.port}');
    });
  }

  /// Starts WebSocket server at [webSocketUri] and set up [channel].
  void startWebSocketServer() {
    final handler = webSocketHandler((WebSocketChannel channel) {
      _channel = channel;
    });

    shelf_io
        .serve(handler, webSocketUri.host, webSocketUri.port)
        .then((server) {
      // TODO: check the compatibility with the current API of `livereload.client`
      print(
        'Please add `new ReloadListener(\'ws://${server.address.host}:${server.port}\').listen();` to your `main.dart`.',
      );
    });
  }

  /// Copies a request and changes its path.
  Request _changePath(Request request, String path) =>
      new Request(request.method, request.requestedUri.replace(path: path),
          protocolVersion: request.protocolVersion,
          headers: request.headers,
          handlerPath: request.handlerPath,
          body: request.read(),
          encoding: request.encoding,
          context: request.context);

  void _reload() {
    channel?.sink?.add(reloadSignal);
  }
}

/// A [Reloader] will be notified of each succeeded build.
///
/// This class must be extended to be functional.
abstract class Reloader implements Sink<Null> {
  final Uri buildRunnerUri;
  final Uri proxyUri;
  final Uri webSocketUri;

  Reloader(this.buildRunnerUri, this.proxyUri, this.webSocketUri) {
    if (!buildRunnerUri.isScheme('http'))
      throw new UnsupportedError(
          'Only `http` scheme is supported for buildRunnerUri.');
    if (!proxyUri.isScheme('http'))
      throw new UnsupportedError(
          'Only `http` scheme is supported for proxyUri.');
    if (!webSocketUri.isScheme('ws'))
      throw new UnsupportedError(
          'Only `ws` scheme is supported for webSocketUri.');
  }
}
