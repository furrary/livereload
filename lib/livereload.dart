/// API for the livereload server, designed with the need of customization in mind.
///
/// In most case, this is not necessary. Please consider using the [CLI][] instead.
///
/// I will use the implementation of the [CLI][] as an example of how this API is used.
/// ```
/// import 'dart:async';
///
/// import 'package:logging/logging.dart';
///
/// import 'package:livereload/livereload.dart';
///
/// Future<int> main(List<String> args) async {
///  Logger.root.onRecord.listen(stdIOLogListener);
///
///  final parser = defaultArgParser();
///  final parsedArgs = new ParsedArgs.from(parser.parse(args));
///  if (parsedArgs.help) {
///    print(helpMessage(parser));
///    return 0;
///  }
///
///  final succeededBuildNotifier = new StreamController<Null>(sync: true);
///  final buildRunnerServed = new Completer<Null>();
///  final exitCode = buildRunnerServe(parsedArgs.buildRunnerServeArgs,
///      succeededBuildNotifier, buildRunnerServed);
///  await buildRunnerServed.future;
///
///  startLiveReloadProxyServer(parsedArgs.proxyUri, parsedArgs.directory,
///      parsedArgs.buildRunnerUri, parsedArgs.webSocketUri, parsedArgs.spa);
///
///  startLiveReloadWebSocketServer(
///      parsedArgs.webSocketUri, succeededBuildNotifier.stream);
///
///  return await exitCode;
/// }
/// ```
///
/// [CLI]: https://github.com/furrary/livereload
library livereload;

export 'src/constants.dart';
export 'src/logging/listeners.dart';
export 'src/parser.dart';
export 'src/server/build_runner.dart';
export 'src/server/proxy.dart';
export 'src/server/websocket.dart';
