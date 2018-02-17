import 'dart:async';

import 'package:logging/logging.dart';

import 'package:livereload/livereload.dart';

Future<int> main(List<String> args) async {
  Logger.root.onRecord.listen(stdIOLogListener);

  final parser = defaultArgParser();
  final results = parser.parse(args);
  final parsedArgs = new ParsedArgs.from(results);
  if (results[CliOption.help] == true) {
    print(helpMessage(parser));
    return 0;
  }

  final buildRunner = new BuildRunnerServer.fromParsed(results)..serve();
  await buildRunner.served;

  startProxyServer(
      parsedArgs.proxyUri,
      buildRunner.uri,
      parsedArgs.spa
          ? liveReloadSpaPipeline(parsedArgs.webSocketUri)
          : liveReloadPipeline(parsedArgs.webSocketUri));

  new LiveReloadWebSocketServer.fromParsed(results, buildRunner.onBuild)
    ..serve();

  return await buildRunner.exitCode;
}
