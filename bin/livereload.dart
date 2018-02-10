import 'dart:async';

import 'package:args/args.dart';
import 'package:livereload/livereload.dart';

import 'src/options.dart';

Future<int> main(List<String> args) async {
  var parser = liveReloadArgParser();
  var results = parser.parse(args);

  if (results['help'] == true) {
    print(liveReloadHelpMessage(parser));
    return 0;
  }

  if (results.rest.length > 1) {
    throw new UnsupportedError(
      'Serving more than one directory at a time is not supported.',
    );
  }

  /// A list that represents `[<directory>, <port>]`.
  var directoryAndPort = (results.rest.isEmpty
          ? 'web:$defaultBuildRunnerPort'
          : results.rest.single)
      .split(':');

  if (directoryAndPort.length != 2) {
    throw new ArgumentError(
      'Please run `pub run livereload --help` to see usage information.',
    );
  }

  return livereload(
    new LiveReloader(
      new Uri(
        scheme: 'http',
        host: results[buildRunnerOptions[BuildRunnerOption.hostName]] as String,
        port: int.parse(directoryAndPort.last),
      ),
      new Uri(
        scheme: 'http',
        host: results[buildRunnerOptions[BuildRunnerOption.hostName]] as String,
        port: int.parse(
            results[liveReloadOptions[LiveReloadOption.proxyPort]] as String),
      ),
      new Uri(
        scheme: 'ws',
        host: results[buildRunnerOptions[BuildRunnerOption.hostName]] as String,
        port: int.parse(
            results[liveReloadOptions[LiveReloadOption.webSocketPort]]
                as String),
      ),
      spa: results['spa'] == true,
    ),
    [directoryAndPort.join(':')]..addAll(results.options
        .where((option) => buildRunnerOptions.containsValue(option))
        .expand(
          (option) => results[option] == true
              ? ['--$option']
              : results[option] == false
                  ? []
                  : ['--$option', results[option] as String],
        )),
  );
}

ArgParser liveReloadArgParser() => new ArgParser()
  ..addFlag(
    liveReloadOptions[LiveReloadOption.help],
    abbr: 'h',
    negatable: false,
    help: 'Displays help information for livereload.',
  )
  ..addFlag(
    buildRunnerOptions[BuildRunnerOption.lowResourcesMode],
    abbr: 'l',
    negatable: false,
    help:
        'Reduces the amount of memory consumed by the build process.\nThis will slow down builds but allow them to progress in resource constrained environments.',
  )
  ..addOption(
    buildRunnerOptions[BuildRunnerOption.config],
    abbr: 'c',
    help: 'Reads `build.<name>.yaml` instead of the default `build.yaml`.',
  )
  ..addFlag(
    buildRunnerOptions[BuildRunnerOption.verbose],
    abbr: 'v',
    negatable: false,
    help: 'Enables verbose logging.',
  )
  ..addOption(
    buildRunnerOptions[BuildRunnerOption.define],
    help: 'Sets the global `options` config for a builder by key.',
  )
  ..addOption(
    buildRunnerOptions[BuildRunnerOption.hostName],
    defaultsTo: 'localhost',
    help: 'Specifies the hostname to serve on.',
  )
  ..addOption(
    liveReloadOptions[LiveReloadOption.proxyPort],
    defaultsTo: defaultProxyPort,
    help: 'Changes the port number of the proxy server.',
  )
  ..addOption(
    liveReloadOptions[LiveReloadOption.webSocketPort],
    defaultsTo: defaultWebSocketPort,
    help: 'Changes the port number of the websocket.',
  )
  ..addFlag(
    liveReloadOptions[LiveReloadOption.singlePageApplication],
    defaultsTo: true,
    help: 'Serves a single page application.',
  );

String liveReloadHelpMessage(ArgParser parser) =>
    'A simple livereload web development server powered by build_runner.\n'
    '\n'
    'Usage: pub run livereload [<directory>:<port>] [options]\n'
    '       (defaults to `pub run livereload web:$defaultBuildRunnerPort`)\n'
    '\n'
    '${parser.usage}\n'
    '\n'
    'For further customization, please consider using livereload library instead of this CLI.';
