import 'dart:io';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';

import 'loggers.dart' as loggers;

const String _warning = '[WARNING] ';
const String _info = '[INFO] ';
const String _severe = '[SEVERE] ';

/// A listener that output log records to `stdout` and `stderr`.
///
/// To be consistent with [`package: build_runner`](https://pub.dartlang.org/packages/build_runner), only *SEVERE* records will be written to `stderr`.
///
/// *This needs some understanding of [`package: logging`](https://pub.dartlang.org/packages/logging).*
void stdIOLogListener(LogRecord rec) {
  switch (rec.loggerName) {
    case loggers.buildRunner:
      _buildRunnerListener(rec);
      break;
    default:
      _defaultListener(rec);
  }
}

void _defaultListener(LogRecord rec) {
  if (rec.level < Level.WARNING) {
    stdout.writeln(rec.message);
  } else if (rec.level < Level.SEVERE) {
    stdout.writeln(yellow.wrap(_warning) + rec.message);
  } else {
    stderr.writeln(red.wrap(_severe) + rec.message);
  }
}

void _buildRunnerListener(LogRecord rec) {
  // `write` instead of `writeln` because messages from `build_runner` always ends with a new line.

  // A message from build_runner tends to start with its level.
  if (rec.message.startsWith(_severe)) {
    stderr.write(rec.message.replaceFirst(_severe, red.wrap(_severe)));
  } else if (rec.message.startsWith(_warning)) {
    stdout.write(rec.message.replaceFirst(_warning, yellow.wrap(_warning)));
  } else if (rec.message.startsWith(_info)) {
    stdout.write(rec.message.replaceFirst(_info, cyan.wrap(_info)));
  } else {
    // A message which is not a starting line won't have the prefix that indicates its level.
    if (rec.level < Level.SEVERE) {
      stdout.write(rec.message);
    } else {
      stderr.write(rec.message);
    }
  }
}
