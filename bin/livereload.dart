import 'dart:async';
import 'dart:io';

import 'package:livereload/livereload.dart';

Future<Null> main(List<String> args) async {
  logger.onRecord.listen(stdIOLogListener);

  final results = liveReloadArgParser.parse(args);
  if (results[CliOption.help] == true) {
    print(liveReloadHelpMessage);
    exit(0);
  }

  final buildRunner = new BuildRunnerServeProcess.fromParsed(results)..start();

  final webSocket =
      new LiveReloadWebSocketServer.fromParsed(results, buildRunner.onBuild)
        ..serve();

  final proxy =
      new LiveReloadProxyServer.fromParsed(results, buildRunner, webSocket)
        ..serve();

  ProcessSignal.SIGINT.watch().take(1).listen((_) {
    buildRunner.kill();
    proxy.forceClose();
    webSocket.forceClose();
  });
}
