import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../logging.dart';
import '../parser.dart';
import 'signals.dart';

/// A simple WebSocket server.
///
/// Call [serve] to start the server at [uri].
/// You can interact with the client through [channels].
///
/// Caveat: You will need to close each channel *manually*.
class WebSocketServer {
  static const defaultPort = 4242;

  final Uri uri;

  /// A stream which will emit a [WebSocketChannel] everytime a new client connects to the server.
  ///
  /// A [WebSocketChannel] has a `sink` which can be used to push messages to the client and a `stream` which receives messages from the client.
  Stream<WebSocketChannel> get channels => _channelsController.stream;

  WebSocketServer(this.uri);

  /// Set up a [WebSocketServer] with arguments parsed by [liveReloadArgParser].
  factory WebSocketServer.fromParsed(ArgResults results) {
    return new WebSocketServer(_getUri(results));
  }

  /// Starts this server at [uri] and will log a message returned from [logMessage] when this server is successfully started.
  ///
  /// *This method must be called only once.*
  Future<Null> serve(String logMessage(HttpServer server)) async {
    if (_serveHasBeenCalled)
      throw new StateError(
          'For each instance, `serve` must be called only once.');
    _serveHasBeenCalled = true;

    final handler = webSocketHandler((WebSocketChannel channel) {
      _channelsController.add(channel);
    });

    _server = await io.serve(handler, uri.host, uri.port);
    logger.info(logMessage(_server));
  }

  /// Forces the server to close.
  Future<dynamic> forceClose() {
    _channelsController.close();
    return Future
        .wait<dynamic>([_channelsController.done, _server.close(force: true)]);
  }

  /// Extracts the WebSocket server uri from arguments parsed by [liveReloadArgParser].
  static Uri _getUri(ArgResults results) {
    return new Uri(
        scheme: 'ws',
        host: results[CliOption.hostName] as String,
        port: int.parse(results[CliOption.webSocketPort] as String,
            onError: (input) {
          logger.warning(
              '${RecordPrefix.warning} The port number `$input` must be an integer. Default WebSocket port `$defaultPort` is used instead.\n');
          return defaultPort;
        }));
  }

  /// Keeps ref to the server just for closing.
  HttpServer _server;

  final _channelsController = new StreamController<WebSocketChannel>();

  /// Indicates if [serve] has been called.
  bool _serveHasBeenCalled = false;
}

/// A WebSocket server which will send [reloadSignal] to all of the connected clients when [onBuild] emits.
///
/// Call [serve] to start the server at [uri].
class LiveReloadWebSocketServer extends WebSocketServer {
  final Stream<Null> onBuild;

  LiveReloadWebSocketServer(Uri uri, this.onBuild) : super(uri);

  /// Set up a [LiveReloadWebSocketServer] with arguments parsed by [liveReloadArgParser].
  factory LiveReloadWebSocketServer.fromParsed(
      ArgResults results, Stream<Null> onBuild) {
    return new LiveReloadWebSocketServer(
        WebSocketServer._getUri(results), onBuild);
  }

  @override
  Future<Null> serve([logMessage = _defaultMessage]) async {
    await super.serve(logMessage);
    channels.listen((channel) {
      _activeChannels.add(channel);
      channel.stream.where((dynamic data) => data == disconnectSignal).listen(
          (dynamic _) {
        channel.sink.close(1001);
      }, onDone: () {
        _activeChannels.remove(channel);
      });
    });
    onBuild.listen((_) {
      _activeChannels
          .forEach((activeChannel) => activeChannel.sink.add(reloadSignal));
    });
  }

  @override
  Future<dynamic> forceClose() {
    return Future.wait<dynamic>(_activeChannels.map((activeChannel) {
      activeChannel.sink.close(1001);
      return activeChannel.sink.done;
    }).toList()
      ..add(super.forceClose()));
  }

  static String _defaultMessage(HttpServer server) =>
      '${RecordPrefix.info} Serving a WebSocket server at ws://${server.address.host}:${server.port}\n';

  final _activeChannels = <WebSocketChannel>[];
}
