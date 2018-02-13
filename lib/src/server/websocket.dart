import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants.dart';
import '../logging/loggers.dart' as loggers;

/// Starts a WebSocket server at [uri].
///
/// A stream returned by this function will emit a [WebSocketChannel] everytime a new client connects to the server.
/// Each channel can be used to communicate with its respective client.
Stream<WebSocketChannel> startWebSocketServer(Uri uri) {
  final controller = new StreamController<WebSocketChannel>();
  final handler = webSocketHandler((WebSocketChannel channel) {
    controller.add(channel);
  });
  io.serve(handler, uri.host, uri.port).then((server) {
    new Logger(loggers.webSocket).info(
        'Running WebSocket server at ws://${server.address.host}:${server.port}');
  });
  return controller.stream;
}

/// Starts a WebSocket server which will send a [reloadSignal] to all of its clients when [succeededBuild] emits.
///
/// If you want to take control over the [WebSocketChannel], consider using [startWebSocketServer].
void startLiveReloadWebSocketServer(Uri uri, Stream<Null> succeededBuild) {
  succeededBuild = succeededBuild.asBroadcastStream();
  startWebSocketServer(uri).listen((channel) {
    succeededBuild.first.then((_) {
      channel.sink.add(reloadSignal);
      channel.sink.close();
    });
  });
}
