import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:livereload/livereload.dart';

Future<Null> main(List<String> args) async {
  Logger.root.onRecord.listen(stdIOLogListener);

  final results = liveReloadArgParser.parse(args);
  if (results[CliOption.help] == true) {
    print(liveReloadHelpMessage);
    exit(0);
  }

  final buildRunner = new BuildRunnerServeProcess.fromParsed(results)..start();

  new LiveReloadProxyServer.fromParsed(
      results,
      buildRunner,
      new LiveReloadWebSocketServer.fromParsed(results, buildRunner.onBuild)
        ..serve())
    ..serve();

  exit(await buildRunner.exitCode);
}
