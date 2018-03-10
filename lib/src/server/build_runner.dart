import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../logging.dart';
import '../parser.dart';

/// An interface to interact with the `build_runner serve` process.
///
/// Call [start] to start the process.
class BuildRunnerServeProcess {
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

  BuildRunnerServeProcess(
    this.uri, [
    this.directory = defaultDirectory,
    this.lowResourcesMode = false,
    this.config,
    this.define,
  ]);

  /// Set up a `build_runner` process with arguments parsed by [liveReloadArgParser].
  factory BuildRunnerServeProcess.fromParsed(ArgResults results) {
    if (results.rest.length > 1) {
      logger.warning(
          '${RecordPrefix.warning} Do not support serving more than one directory. `$defaultDirectory` will be served instead.\n');
    }
    final uri = new Uri(
        scheme: 'http',
        host: results[CliOption.hostName] as String,
        port: int.parse(results[CliOption.buildRunnerPort] as String,
            onError: (input) {
          logger.warning(
              '${RecordPrefix.warning} The port number `$input` must be an integer. Default `build_runner` port `$defaultPort` is used instead.\n');
          return defaultPort;
        }));
    return new BuildRunnerServeProcess(
        uri,
        results.rest.length == 1 ? results.rest.single : defaultDirectory,
        results[CliOption.lowResourcesMode] == true,
        results[CliOption.config] as String,
        results[CliOption.define] as String);
  }

  /// Runs `build_runner serve`.
  ///
  /// *This method must be called only once.*
  Future<Null> start() async {
    if (_startHasBeenCalled)
      throw new StateError(
          'For each instance, `start` must be called only once.');
    _startHasBeenCalled = true;

    /// A logger which records `stdout` and `stderr` of the `build_runner` process.
    ///
    /// The default listener for this logger can resolve the log level based on the prefix, so the log level from this logger doesn't matter much.
    /// However, it should be able to differentiate between level `< SEVERE` and `>= SEVERE` because the default listener would write to `stdout` and `stderr` respectively.

    _proc = await Process.start(_pubBin.path, _args);
    _proc.stdout
        .transform(utf8.decoder)
        .transform(_branchSucceededBuildTo(_onBuildController))
        .transform(_detectServing(_servedCompleter))
        .listen(logger.info);
    _proc.stderr.transform(utf8.decoder).listen(logger.severe);
  }

  /// Kills the process.
  ///
  /// Returns `true` if the signal is successfully delivered to the process.
  /// Otherwise the signal could not be sent, usually meaning that the process is already dead.
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) {
    _onBuildController.close();
    return _proc?.kill(signal) ?? false;
  }

  static final _sdkDir =
      new Directory(path.dirname(path.dirname(Platform.resolvedExecutable)));
  static final _pubBin = new File(
      path.join(_sdkDir.path, 'bin', Platform.isWindows ? 'pub.bat' : 'pub'));
  static const _pubArgs = const ['run', 'build_runner', 'serve'];

  final _servedCompleter = new Completer<Null>();
  final _onBuildController = new StreamController<Null>();

  /// Keeps the ref to the `build_runner` process just for killing.
  Process _proc;

  /// Indicates if [start] has been called.
  bool _startHasBeenCalled = false;

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

  /// Notifies [sink] of each new succeeded build.
  StreamTransformer<String, String> _branchSucceededBuildTo(
    Sink<Null> sink,
  ) =>
      new StreamTransformer.fromHandlers(handleData: (line, originalSink) {
        originalSink.add(line);
        // `build_runner 0.7.13` changes stdout message.
        if (line.startsWith('[INFO] Succeeded') ||
            line.startsWith('[INFO] Build: Succeeded')) {
          sink.add(null);
        }
      });

  /// Completes [completer] when the `build_runner` starts serving.
  StreamTransformer<String, String> _detectServing(Completer<Null> completer) =>
      new StreamTransformer.fromHandlers(handleData: (line, originalSink) {
        if (line.startsWith('Serving') && !completer.isCompleted) {
          completer.complete(null);
          originalSink.add(line.replaceFirst(
              'Serving', '[INFO] `build_runner` starts serving'));
        } else {
          originalSink.add(line);
        }
      });
}
