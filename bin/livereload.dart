import 'dart:async';

import 'package:logging/logging.dart';

import 'package:livereload/livereload.dart';

Future<int> main(List<String> args) async {
  Logger.root.onRecord.listen(stdIOLogListener);

  final parser = defaultArgParser();
  final parsedArgs = new ParsedArgs.from(parser.parse(args));
  if (parsedArgs.help) {
    print(helpMessage(parser));
    return 0;
  }

  final succeededBuildNotifier = new StreamController<Null>(sync: true);
  final buildRunnerServed = new Completer<Null>();
  final exitCode = buildRunnerServe(parsedArgs.buildRunnerServeArgs,
      succeededBuildNotifier, buildRunnerServed);
  await buildRunnerServed.future;

  startLiveReloadProxyServer(parsedArgs.proxyUri, parsedArgs.directory,
      parsedArgs.buildRunnerUri, parsedArgs.webSocketUri, parsedArgs.spa);

  startLiveReloadWebSocketServer(
      parsedArgs.webSocketUri, succeededBuildNotifier.stream);

  return await exitCode;
}
