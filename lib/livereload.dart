/// API for customizing the livereload server.
///
/// In most case, this is not necessary. Please consider using the [CLI][] instead.
///
/// [CLI]: https://github.com/furrary/livereload
library livereload;

import 'dart:async';
import 'dart:io';

import 'src/build_runner.dart';
import 'src/reloader.dart';

export 'src/reloader.dart';
export 'src/share.dart';

/// Starts a livereload server.
///
/// By default, [buildRunnerOutput] is [stdout.nonBlocking] and [buildRunnerError] is [stderr.nonBlocking].
Future<int> livereload(
  Reloader reloader,
  List<String> buildRunnerArgs, [
  StreamSink<List<int>> buildRunnerOutput,
  StreamSink<List<int>> buildRunnerError,
]) async {
  print((['pub']..addAll(buildRunnerServePubArgs)..addAll(buildRunnerArgs))
      .join(' '));
  Process buildRunner = await buildRunnerServe(buildRunnerArgs);
  buildRunner.stdout
      .transform(branchSucceededBuildTo(reloader))
      .pipe(buildRunnerOutput ?? stdout.nonBlocking);
  buildRunner.stderr.pipe(buildRunnerError ?? stderr.nonBlocking);
  return await buildRunner.exitCode;
}
