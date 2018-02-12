import 'dart:async';
import 'dart:convert' show UTF8;
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../logging/loggers.dart' as loggers;

const _buildRunnerServePubArgs = const ['run', 'build_runner', 'serve'];

/// Runs `pub run build_runner serve` with `args`.
///
/// Returns a future that will resolve with the `exitCode` of the `build_runner` process.
/// `buildSucceededSink` will be notified of each succeeded build.
/// `served` will be completed when the `build_runner` starts serving.
Future<int> buildRunnerServe(List<String> args, Sink<Null> buildSucceededSink,
    Completer<Null> served) async {
  final proc = await Process.start(
      _pubBin.path, new List.from(_buildRunnerServePubArgs)..addAll(args));
  final log = new Logger(loggers.buildRunner);
  // The listener for this logger can resolve the log level based on the prefix,
  // so the log level from this logger doesn't matter much.
  proc.stdout
      .transform(UTF8.decoder)
      .transform(_branchSucceededBuildTo(buildSucceededSink))
      .transform(_detectServing(served))
      .listen(log.info);
  proc.stderr.transform(UTF8.decoder).listen(log.severe);
  return proc.exitCode;
}

/// Pub binary.
final _pubBin = new File(
    path.join(_sdkDir.path, 'bin', Platform.isWindows ? 'pub.bat' : 'pub'));

/// The current Dart SDK directory.
final _sdkDir =
    new Directory(path.dirname(path.dirname(Platform.resolvedExecutable)));

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

/// Completes `completer` when the `build_runner` starts serving.
StreamTransformer<String, String> _detectServing(Completer<Null> completer) =>
    new StreamTransformer.fromHandlers(handleData: (line, originalSink) {
      originalSink.add(line);
      if (line.startsWith('Serving') && !completer.isCompleted) {
        completer.complete(null);
      }
    });
