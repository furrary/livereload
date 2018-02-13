import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart' as shelfProxy;

import '../constants.dart';
import '../logging/loggers.dart' as loggers;

const _contentType = 'Content-Type';
const _textHtml = 'text/html';

/// Starts a server at [uri] proxying requests to [buildRunnerUri].
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

Pipeline liveReloadPipeline(Uri webSocketUri) => const Pipeline()
    .addMiddleware(injectJavaScript(reloadOn(webSocketUri, reloadSignal)));

Pipeline liveReloadSpaPipeline(Uri webSocketUri) =>
    liveReloadPipeline(webSocketUri).addMiddleware(rewriteTo('/'));

/// Creates a [Middleware] that injects a [script] into every html response.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
Middleware injectJavaScript(String script) =>
    createMiddleware(responseHandler: (response) async {
      if (response.headers[_contentType] == _textHtml) {
        return response.change(
            body: (await response.readAsString())
                .replaceFirst('</body>', '<script>$script</script></body>'));
      }
      return response;
    });

/// Creates a [Middleware] that will replace the path of `requestedUri` with [absolutePath] if the `request` [shouldBeRewritten].
///
/// By default, the `request` that [shouldBeRewritten] is the one whose url doesn't have a MIME type.
/// If this heuristic doesn't work well for you, please file an issue. Furthermore, PRs are welcome.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
Middleware rewriteTo(String absolutePath,
        [bool shouldBeRewritten(Request request) = _hasNoMimeType]) =>
    (innerHandler) => (request) => shouldBeRewritten(request)
        ? innerHandler(new Request(
            request.method, request.requestedUri.replace(path: absolutePath),
            body: request.read(),
            context: request.context,
            encoding: request.encoding,
            headers: request.headers,
            protocolVersion: request.protocolVersion))
        : innerHandler(request);

/// Generates a JavaScript which will reload the browser on receving a [message] from [webSocketUri].
String reloadOn(Uri webSocketUri, String message) =>
    "new WebSocket('$webSocketUri').onmessage=function(e){if(e.data==='$message')window.location.reload()};";

/// Checks if the [request].url doesn't have a MIME type.
bool _hasNoMimeType(Request request) {
  return request.url.pathSegments.isNotEmpty &&
      lookupMimeType(request.url.pathSegments.last) == null &&
      // .map doesn't have a MIME type, a workaround is needed
      !request.url.path.endsWith('.map');
}

/// Creates a [Middleware] that returns a `html` response with [responseBody] if the [Request.requestedUri] doesn't have a MIME type.
///
/// **DEPRECATED!** Use [rewriteTo] instead.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
@deprecated
Middleware rewriteAs(String responseBody) =>
    createMiddleware(requestHandler: (request) {
      return _hasNoMimeType(request)
          ? new Response.ok(responseBody, headers: {_contentType: _textHtml})
          : null;
    });

/// Starts a proxy server at [uri] proxying requests to [buildRunnerUri] and injects a script listening for a [reloadSignal].
///
/// **DEPRECATED!** Use the [liveReloadPipeline] and [liveReloadSpaPipeline] with [startProxyServer] instead.
///
/// *This needs some understanding of [`package: shelf`](https://pub.dartlang.org/packages/shelf).*
@deprecated
void startLiveReloadProxyServer(
    Uri uri, String directory, Uri buildRunnerUri, Uri webSocketUri, bool spa,
    [Pipeline pipeline = const Pipeline()]) {
  final indexHtml =
      new File.fromUri(new Uri.directory(directory).resolve('index.html'))
          .readAsStringSync();
  final listenForReload =
      "new WebSocket('$webSocketUri').onmessage=function(e){if(e.data==='$reloadSignal')window.location.reload()};";
  startProxyServer(
      uri,
      buildRunnerUri,
      spa
          ? pipeline
              .addMiddleware(injectJavaScript(listenForReload))
              .addMiddleware(rewriteAs(indexHtml))
          : pipeline.addMiddleware(injectJavaScript(listenForReload)));
}
