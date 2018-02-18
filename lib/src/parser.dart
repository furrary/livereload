import 'package:args/args.dart';

import 'server/build_runner.dart';
import 'server/proxy.dart';
import 'server/websocket.dart';

/// Options avaliable in the CLI.
class CliOption {
  static const lowResourcesMode = 'low-resources-mode';
  static const config = 'config';
  static const define = 'define';
  static const singlePageApplication = 'spa';
  static const hostName = 'hostname';
  static const buildRunnerPort = 'buildport';
  static const proxyPort = 'proxyport';
  static const webSocketPort = 'websocketport';
  static const help = 'help';
}

/// The default parser which is used to parse raw arguments given by users.
///
/// By utilizing the builder pattern, you can extends the default CLI options conveniently.
///
/// *This needs some understanding of [`package: args`][].*
///
/// [`package: args`]: https://pub.dartlang.org/packages/args
final liveReloadArgParser = new ArgParser()
  ..addFlag(
    CliOption.lowResourcesMode,
    abbr: 'l',
    defaultsTo: false,
    negatable: false,
    help:
        'Reduces the amount of memory consumed by the build process.\nThis will slow down builds but allow them to progress in resource constrained environments.',
  )
  ..addOption(
    CliOption.config,
    abbr: 'c',
    help: 'Reads `build.<name>.yaml` instead of the default `build.yaml`.',
  )
  ..addOption(
    CliOption.define,
    help: 'Sets the global `options` config for a builder by key.',
  )
  ..addFlag(
    CliOption.singlePageApplication,
    defaultsTo: true,
    help: 'Serves a single page application.',
  )
  ..addOption(
    CliOption.hostName,
    defaultsTo: 'localhost',
    help: 'Specifies the hostname to serve on.',
  )
  ..addOption(
    CliOption.buildRunnerPort,
    abbr: 'b',
    defaultsTo: BuildRunnerServeProcess.defaultPort.toString(),
    help: 'Changes the port number where `build_runner` serves.',
  )
  ..addOption(
    CliOption.proxyPort,
    abbr: 'p',
    defaultsTo: ProxyServer.defaultPort.toString(),
    help: 'Changes the port number of the proxy server.',
  )
  ..addOption(
    CliOption.webSocketPort,
    abbr: 'w',
    defaultsTo: WebSocketServer.defaultPort.toString(),
    help: 'Changes the port number of the websocket.',
  )
  ..addFlag(
    CliOption.help,
    abbr: 'h',
    defaultsTo: false,
    negatable: false,
    help: 'Displays help information for livereload.',
  );

final liveReloadHelpMessage =
    'A simple livereload web development server powered by build_runner.\n'
    '\n'
    'Usage: pub run livereload [directory] [options]\n'
    '       (If [directory] is omitted, `web` will be used.)\n'
    '\n'
    '${liveReloadArgParser.usage}\n'
    '\n'
    'For further customization, please consider using livereload library instead of this CLI.';
