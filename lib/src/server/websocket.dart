import 'dart:async';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../logging/loggers.dart' as loggers;
import '../parser.dart';
import 'signals.dart';

/// A simple WebSocket server.
///
/// Call [serve] to start the server at [uri].
/// You can interact with the client through [channels].
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

  /// Starts the server at [uri].
  ///
  /// *This method must be called only once.*
  Future<Null> serve() async {
    if (_serveHasBeenCalled)
      throw new StateError(
          'For each instance, `serve` must be called only once.');
    _serveHasBeenCalled = true;

    final log = new Logger(loggers.webSocket);

    final handler = webSocketHandler((WebSocketChannel channel) {
      _channelsController.add(channel);
    });

    io.serve(handler, uri.host, uri.port).then((server) {
      log.info(
          'Running a WebSocket server at ws://${server.address.host}:${server.port}');
    });
  }

  /// Extracts the WebSocket server uri from arguments parsed by [liveReloadArgParser].
  static Uri _getUri(ArgResults results) {
    final log = new Logger(loggers.parser);
    return new Uri(
        scheme: 'ws',
        host: results[CliOption.hostName] as String,
        port: int.parse(results[CliOption.webSocketPort] as String,
            onError: (input) {
          log.warning(
              'The port number `$input` must be an integer. Default WebSocket port `$defaultPort` is used instead.');
          return defaultPort;
        }));
  }

  final _channelsController = new StreamController<WebSocketChannel>();

  /// Indicates if [serve] has been called.
  bool _serveHasBeenCalled = false;
}

/// A WebSocket server which will send [reloadSignal] to all of the connected clients when [onBuild] emits.
///
/// Call [serve] to start the server at [uri].
class LiveReloadWebSocketServer extends WebSocketServer {
  final Stream<Null> onBuild;

  LiveReloadWebSocketServer(Uri uri, Stream<Null> onBuild)
      : onBuild = onBuild.asBroadcastStream(),
        super(uri);

  /// Set up a [LiveReloadWebSocketServer] with arguments parsed by [liveReloadArgParser].
  factory LiveReloadWebSocketServer.fromParsed(
      ArgResults results, Stream<Null> onBuild) {
    return new LiveReloadWebSocketServer(
        WebSocketServer._getUri(results), onBuild);
  }

  @override
  Future<Null> serve() async {
    await super.serve();
    channels.listen((channel) {
      onBuild.first.then((_) {
        channel.sink.add(reloadSignal);
        channel.sink.close(1000);
      });
    });
  }
}
