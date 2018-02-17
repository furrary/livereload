import 'package:args/args.dart';
import 'package:logging/logging.dart';

import 'constants.dart';
import 'logging/loggers.dart' as loggers;
import 'server/build_runner.dart';
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

/// Returns the default parser which is used to parse raw arguments given by users.
///
/// By utilizing the builder pattern, you can extends the default CLI options conveniently.
///
/// *This needs some understanding of [`package: args`](https://pub.dartlang.org/packages/args).*
ArgParser defaultArgParser() => new ArgParser()
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
    defaultsTo: BuildRunnerServer.defaultPort.toString(),
    help: 'Changes the port number where `build_runner` serves.',
  )
  ..addOption(
    CliOption.proxyPort,
    abbr: 'p',
    defaultsTo: defaultPorts[CliOption.proxyPort],
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

/// Returns a usage information of the CLI wrapped around [parser].usage.
String helpMessage(ArgParser parser) =>
    'A simple livereload web development server powered by build_runner.\n'
    '\n'
    'Usage: pub run livereload [directory] [options]\n'
    '       (If [directory] is omitted, `web` will be used.)\n'
    '\n'
    '${parser.usage}\n'
    '\n'
    'For further customization, please consider using livereload library instead of this CLI.';

/// An object which represents the parsed arguments of the [defaultArgParser].
class ParsedArgs {
  final String hostName;
  final int proxyPort;
  final bool spa;

  ParsedArgs(this.hostName, this.proxyPort, this.spa);

  factory ParsedArgs.from(ArgResults results) => new ParsedArgs(
      _parseString(results, CliOption.hostName),
      _parsePort(results, CliOption.proxyPort),
      _parseBool(results, CliOption.singlePageApplication));

  /// Uri for proxy server.
  Uri get proxyUri => new Uri(scheme: 'http', host: hostName, port: proxyPort);
}

bool _parseBool(ArgResults results, String option) {
  return results[option] == true ? true : false;
}

int _parsePort(ArgResults results, String option) {
  var port = int.parse(results[option].toString(), onError: (_) => null);
  if (port == null) {
    new Logger(loggers.parser).warning(
        'The port number must be an integer. `${defaultPorts[option]}` is used instead.');
    port = int.parse(defaultPorts[option]);
  }
  return port;
}

String _parseString(ArgResults results, String option) {
  return results[option] == null ? null : results[option].toString();
}
