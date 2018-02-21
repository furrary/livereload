import 'dart:io';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';

/// A set of prefixes for indicating the level of each log record.
///
/// These prefixes are not necessarily used, but [stdIOLogListener] will read them and assign respective color to each log record.
class RecordPrefix {
  static const String warning = '[WARNING]';
  static const String info = '[INFO]';
  static const String severe = '[SEVERE]';
}

/// A listener that output log records to [stdout] and [stderr].
///
/// To be consistent with [`package: build_runner`][], only *SEVERE* records will be written to `stderr`.
///
/// *This needs some understanding of [`package: logging`][].*
///
/// [`package: build_runner`]: https://pub.dartlang.org/packages/build_runner
/// [`package: logging`]: https://pub.dartlang.org/packages/logging
void stdIOLogListener(LogRecord rec) {
  if (rec.message.contains(RecordPrefix.severe)) {
    stderr.write(rec.message
        .replaceFirst(RecordPrefix.severe, red.wrap(RecordPrefix.severe)));
  } else if (rec.message.contains(RecordPrefix.warning)) {
    stdout.write(rec.message
        .replaceFirst(RecordPrefix.warning, yellow.wrap(RecordPrefix.warning)));
  } else if (rec.message.contains(RecordPrefix.info)) {
    stdout.write(rec.message
        .replaceFirst(RecordPrefix.info, cyan.wrap(RecordPrefix.info)));
  } else {
    // A message which is not a starting line won't have the prefix that indicates its level.
    if (rec.level < Level.SEVERE) {
      stdout.write(rec.message);
    } else {
      stderr.write(rec.message);
    }
  }
}

/// A global logger for the livereload package.
///
/// *This needs some understanding of [`package: logging`][].*
///
/// [`package: logging`]: https://pub.dartlang.org/packages/logging
final logger = new Logger('livereload');
