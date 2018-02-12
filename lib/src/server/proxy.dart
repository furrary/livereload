import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart' as shelfProxy;

import '../constants.dart';
import '../logging/loggers.dart' as loggers;

/// Starts a server at `uri` proxying requests to `buildRunnerUri`.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
Future<Null> startProxyServer(Uri uri, Uri buildRunnerUri,
    [Pipeline pipeline = const Pipeline()]) async {
  final handler = shelfProxy.proxyHandler(buildRunnerUri);
  final server =
      await io.serve(pipeline.addHandler(handler), uri.host, uri.port);
  new Logger(loggers.proxy).info(
      'Running Proxy server at http://${server.address.host}:${server.port}');
}

/// Starts a proxy server at `uri` proxying requests to `buildRunnerUri` and injects a script listening for a [reloadSignal].
///
/// If `spa` is `true`, this server will utilize the [rewriteAs] middleware.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
void startLiveReloadProxyServer(
    Uri uri, String directory, Uri buildRunnerUri, Uri webSocketUri, bool spa,
    [Pipeline pipeline = const Pipeline()]) {
  final indexHtml =
      new File.fromUri(new Uri.directory(directory).resolve('index.html'))
          .readAsStringSync();
  final listenForReload =
      "<script>new WebSocket('$webSocketUri').onmessage=function(e){if(e.data==='$reloadSignal')window.location.reload()};</script>";
  startProxyServer(
      uri,
      buildRunnerUri,
      spa
          ? pipeline
              .addMiddleware(injectJavaScript(listenForReload))
              .addMiddleware(rewriteAs(indexHtml))
          : pipeline.addMiddleware(injectJavaScript(listenForReload)));
}

/// Creates a `Middleware` that returns a `html` response with `responseBody` if the `requestedUri` doesn't have a MIME type.
///
/// If this heuristic doesn't work well for you, please file an issue. Furthermore, PRs are welcome.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
Middleware rewriteAs(String responseBody) =>
    createMiddleware(requestHandler: (req) {
      return _shouldBeRewritten(req.requestedUri)
          ? new Response.ok(responseBody, headers: {_contentType: _textHtml})
          : null;
    });

/// Creates a `Middleware` that injects a `script` into every html response.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
Middleware injectJavaScript(String script) =>
    createMiddleware(responseHandler: (res) async {
      if (res.headers[_contentType] == _textHtml) {
        final body = await res.readAsString();
        return res.change(body: body.replaceFirst('</body>', '$script</body>'));
      }
      return res;
    });

bool _shouldBeRewritten(Uri uri) {
  return uri.pathSegments.isNotEmpty &&
      lookupMimeType(uri.pathSegments.last) == null &&
      // .map doesn't have a MIME type, a workaround is needed
      !uri.path.endsWith('.map');
}

const _contentType = 'Content-Type';
const _textHtml = 'text/html';
