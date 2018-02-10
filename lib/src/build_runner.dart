import 'dart:async';
import 'dart:convert' show UTF8;
import 'dart:io';

import 'package:path/path.dart' as path;

/// Pub binary.
final pubBin = new File(
    path.join(sdkDir.path, 'bin', Platform.isWindows ? 'pub.bat' : 'pub'));

/// The current Dart SDK directory.
final sdkDir =
    new Directory(path.dirname(path.dirname(Platform.resolvedExecutable)));

/// Notifies [sink] of each new succeeded build.
StreamTransformer<List<int>, List<int>> branchSucceededBuildTo(
  Sink<Null> sink,
) =>
    new StreamTransformer.fromHandlers(handleData: (codeUnits, originalSink) {
      String line = UTF8.decode(codeUnits);
      if (line.startsWith('[INFO] Build: Succeeded')) {
        sink.add(null);
      }
      originalSink.add(codeUnits);
    });

const buildRunnerServePubArgs = const ['run', 'build_runner', 'serve'];

/// Runs `pub run build_runner serve` with [args].
Future<Process> buildRunnerServe(List<String> args) async {
  return Process.start(
    pubBin.path,
    new List.from(buildRunnerServePubArgs)..addAll(args),
  );
}
