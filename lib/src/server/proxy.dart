import 'dart:async';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';

import '../logging/loggers.dart' as loggers;
import '../parser.dart';
import 'build_runner.dart';
import 'signals.dart';
import 'websocket.dart';

/// A simple `shelf` server which will proxy requests to [to].
///
/// Call [serve] to start the server at [uri].
/// A [pipeline] can be added to customize the behavior of the server.
///
/// *This needs some understanding of [`package: shelf`][].*
///
/// [`package: shelf`]: https://pub.dartlang.org/packages/shelf
class ProxyServer {
  static const defaultPort = 8000;

  final Uri uri;
  final Uri to;
  final Pipeline pipeline;

  ProxyServer(this.uri, this.to, [this.pipeline = const Pipeline()]);

  /// Set up a [ProxyServer] with arguments parsed by [liveReloadArgParser].
  factory ProxyServer.fromParsed(ArgResults results, Uri to,
      [Pipeline pipeline = const Pipeline()]) {
    return new ProxyServer(_getUri(results), to, pipeline);
  }

  /// Starts the server at [uri].
  ///
  /// *This method must be called only once.*
  Future<Null> serve() async {
    if (_serveHasBeenCalled)
      throw new StateError(
          'For each instance, `serve` must be called only once.');
    _serveHasBeenCalled = true;

    final log = new Logger(loggers.proxy);

    final server = await io.serve(
        pipeline.addHandler(proxyHandler(to)), uri.host, uri.port);
    log.info(
        'Running Proxy server at http://${server.address.host}:${server.port}');
  }

  /// Extracts the proxy server uri from arguments parsed by [liveReloadArgParser].
  static Uri _getUri(ArgResults results) {
    final log = new Logger(loggers.parser);
    return new Uri(
        scheme: 'http',
        host: results[CliOption.hostName] as String,
        port:
            int.parse(results[CliOption.proxyPort] as String, onError: (input) {
          log.warning(
              'The port number `$input` must be an integer. Default proxy port `$defaultPort` is used instead.');
          return defaultPort;
        }));
  }

  /// Indicates if [serve] has been called.
  bool _serveHasBeenCalled = false;
}

/// A livereload proxy server.
///
/// This server proxies requests to `build_runner serve` and injects a script that will reload the browser on [reloadSignal]. (See [injectJavaScript] and [reloadOn].)
/// If this serves a single page application, it will rewrite any 404 response whose path doesn't have a MIME type to the root path of `build_runner serve`. (See [rewriteTo] and [shouldBeRewritten].)
///
/// If this heuristic doesn't work well for you, please file an issue. Furthermore, PRs are welcome.
///
/// Call [serve] to start the server at [uri].
/// A [pipeline] can be added to customize the behavior of the server.
///
/// This should be used together with [LiveReloadWebSocketServer].
///
/// *This needs some understanding of [`package: shelf`][].*
///
/// [`package: shelf`]: https://pub.dartlang.org/packages/shelf
class LiveReloadProxyServer extends ProxyServer {
  /// Returns `true` for any 404 response whose path doesn't have a MIME type.
  static bool shouldBeRewritten(Request request, Response response) {
    return response.statusCode == 404 &&
        request.url.pathSegments.isNotEmpty &&
        lookupMimeType(request.url.pathSegments.last) == null &&
        // .map doesn't have a MIME type, a workaround is needed
        !request.url.path.endsWith('.map');
  }

  /// A future which will resolve when `build_runner` starts serving.
  ///
  /// This expects [BuildRunnerServeProcess.served].
  final Future<Null> buildRunnerServed;
  final Uri buildRunnerUri;
  final Uri webSocketUri;

  LiveReloadProxyServer(Uri uri, this.buildRunnerUri, this.webSocketUri,
      this.buildRunnerServed, bool isSinglePageApplication,
      [Pipeline pipeline = const Pipeline()])
      : super(
            uri,
            buildRunnerUri,
            isSinglePageApplication
                ? pipeline
                    .addMiddleware(
                        injectJavaScript(reloadOn(webSocketUri, reloadSignal)))
                    .addMiddleware(rewriteTo('/', shouldBeRewritten))
                : pipeline.addMiddleware(
                    injectJavaScript(reloadOn(webSocketUri, reloadSignal))));

  /// Set up a [LiveReloadProxyServer] with arguments parsed by [liveReloadArgParser].
  factory LiveReloadProxyServer.fromParsed(
      ArgResults results,
      BuildRunnerServeProcess buildRunner,
      LiveReloadWebSocketServer webSocketServer,
      [Pipeline pipeline = const Pipeline()]) {
    return new LiveReloadProxyServer(
        ProxyServer._getUri(results),
        buildRunner.uri,
        webSocketServer.uri,
        buildRunner.served,
        results[CliOption.singlePageApplication] == true,
        pipeline);
  }

  @override
  Future<Null> serve() async {
    await buildRunnerServed;
    await super.serve();
  }
}

/// Creates a [Middleware] that injects a [script] into every html response.
///
/// *This needs some understanding of [`package: shelf`][].*
///
/// [`package: shelf`]: https://pub.dartlang.org/packages/shelf
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
/// *This needs some understanding of [`package: shelf`][].*
///
/// [`package: shelf`]: https://pub.dartlang.org/packages/shelf
Middleware rewriteTo(String absolutePath,
        bool shouldBeRewritten(Request request, Response response)) =>
    (innerHandler) => (request) async {
          var requestBody = await request.readAsString(request.encoding);
          var response = await innerHandler(request.change(body: requestBody));
          return shouldBeRewritten(request, response)
              ? await innerHandler(new Request(request.method,
                  request.requestedUri.replace(path: absolutePath),
                  body: requestBody,
                  context: request.context,
                  encoding: request.encoding,
                  headers: request.headers,
                  protocolVersion: request.protocolVersion))
              : response;
        };

/// Generates a JavaScript which will reload the browser on receiving a [message] from [webSocketUri].
String reloadOn(Uri webSocketUri, String message) =>
    "new WebSocket('$webSocketUri').onmessage=function(e){if(e.data==='$message')window.location.reload()};";

const _contentType = 'Content-Type';
const _textHtml = 'text/html';
