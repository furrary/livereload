/// API for the livereload server, designed with the need of customization in mind.
///
/// In most case, this is not necessary. Please consider using the [CLI][] instead.
///
/// I will use the implementation of the [CLI][] as an example of how this library is used.
/// ```
/// import 'dart:async';
/// import 'dart:io';
///
/// import 'package:logging/logging.dart';
///
/// import 'package:livereload/livereload.dart';
///
/// Future<Null> main(List<String> args) async {
///   Logger.root.onRecord.listen(stdIOLogListener);
///
///   final results = liveReloadArgParser.parse(args);
///   if (results[CliOption.help] == true) {
///     print(liveReloadHelpMessage);
///     exit(0);
///   }
///
///   final buildRunner = new BuildRunnerServeProcess.fromParsed(results)..start();
///
///   new LiveReloadProxyServer.fromParsed(
///       results,
///       buildRunner,
///       new LiveReloadWebSocketServer.fromParsed(results, buildRunner.onBuild)
///         ..serve())
///     ..serve();
///
///   exit(await buildRunner.exitCode);
/// }
/// ```
///
/// [CLI]: https://github.com/furrary/livereload
library livereload;

export 'src/logging/listeners.dart';
export 'src/parser.dart';
export 'src/server/build_runner.dart';
export 'src/server/proxy.dart';
export 'src/server/signals.dart';
export 'src/server/websocket.dart';
