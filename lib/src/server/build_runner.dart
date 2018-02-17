import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../logging/loggers.dart' as loggers;
import '../parser.dart';

/// An interface to interact with the `build_runner serve` process.
///
/// Call [serve] to start the process.
class BuildRunnerServer {
  static const defaultDirectory = 'web';
  static const defaultPort = 8080;

  final Uri uri;
  final String directory;
  final bool lowResourcesMode;
  final String config;
  final String define;

  /// A future that will resolve after the `build_runner` starts serving.
  Future<Null> get served => _servedCompleter.future;

  /// A stream that will be notified of each succeeded build of the `build_runner`.
  Stream<Null> get onBuild => _onBuildController.stream;

  /// A future that will resolve with the `exitCode` of the `build_runner` process.
  Future<int> get exitCode => _exitCodeCompleter.future;

  /// Set up a `build_runner` process with selected arguments.
  BuildRunnerServer(this.uri, this.lowResourcesMode, this.config, this.define,
      [this.directory = defaultDirectory]);

  /// Set up a `build_runner` process with arguments parsed by [defaultArgParser].
  factory BuildRunnerServer.fromParsed(ArgResults results) {
    final log = new Logger(loggers.parser);
    final uri = new Uri(
        scheme: 'http',
        host: results[CliOption.hostName] as String,
        port: int.parse(results[CliOption.buildRunnerPort] as String,
            onError: (input) {
          log.warning(
              'The port number `$input` must be an integer. Default `build_runner` port `$defaultPort` is used instead.');
          return defaultPort;
        }));
    if (results.rest.length > 1) {
      log.warning(
          'Do not support serving more than one directory. `$defaultDirectory` will be served instead.');
    }
    return new BuildRunnerServer(
        uri,
        results[CliOption.lowResourcesMode] == true,
        results[CliOption.config] as String,
        results[CliOption.define] as String,
        results.rest.length == 1 ? results.rest.single : defaultDirectory);
  }

  static final _sdkDir =
      new Directory(path.dirname(path.dirname(Platform.resolvedExecutable)));
  static final _pubBin = new File(
      path.join(_sdkDir.path, 'bin', Platform.isWindows ? 'pub.bat' : 'pub'));
  static const _pubArgs = const ['run', 'build_runner', 'serve'];

  /// A logger which records `stdout` and `stderr` of the `build_runner` process.
  ///
  /// The default listener for this logger can resolve the log level based on the prefix, so the log level from this logger doesn't matter much.
  /// However, it should be able to differentiate between level `< SEVERE` and `>= SEVERE` because the default listener would write to `stdout` and `stderr` respectively.
  static final _log = new Logger(loggers.buildRunner);

  final _exitCodeCompleter = new Completer<int>();
  final _servedCompleter = new Completer<Null>();
  final _onBuildController = new StreamController<Null>(sync: true);

  bool _isRunning = false;

  /// Runs `build_runner serve`.
  ///
  /// This method must be called only *once*.
  Future<Null> serve() async {
    if (_isRunning) throw new StateError('`build_runner serve` is running.');
    _isRunning = true;
    final proc = await Process.start(_pubBin.path, _args);
    proc.stdout
        .transform(UTF8.decoder)
        .transform(_branchSucceededBuildTo(_onBuildController))
        .transform(_detectServing(_servedCompleter))
        .listen(_log.info);
    proc.stderr.transform(UTF8.decoder).listen(_log.severe);
    _exitCodeCompleter.complete(await proc.exitCode);
  }

  /// Notifies [sink] of each new succeeded build.
  StreamTransformer<String, String> _branchSucceededBuildTo(
    Sink<Null> sink,
  ) =>
      new StreamTransformer.fromHandlers(handleData: (line, originalSink) {
        originalSink.add(line);
        if (line.startsWith('[INFO] Build: Succeeded')) {
          sink.add(null);
        }
      });

  /// Completes [completer] when the `build_runner` starts serving.
  StreamTransformer<String, String> _detectServing(Completer<Null> completer) =>
      new StreamTransformer.fromHandlers(handleData: (line, originalSink) {
        originalSink.add(line);
        if (line.startsWith('Serving') && !completer.isCompleted) {
          completer.complete(null);
        }
      });

  /// Arguments used to start a `build_runner` process.
  List<String> get _args {
    final list = new List<String>.from(_pubArgs)..add('$directory:${uri.port}');
    if (lowResourcesMode) {
      list.add('--${CliOption.lowResourcesMode}');
    }
    if (config != null) {
      list.addAll(['--${CliOption.config}', config]);
    }
    if (define != null) {
      list.addAll(['--${CliOption.define}', define]);
    }
    list.addAll(['--${CliOption.hostName}', uri.host]);
    return list;
  }
}
