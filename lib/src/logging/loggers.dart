/// The name of a logger which records `stdout` and `stderr` of the `build_runner` process.
///
/// *This needs some understanding of [`package: logging`][].*
///
/// [`package: logging`]: https://pub.dartlang.org/packages/logging
const String buildRunner = 'BuildRunner';

/// The name of a logger which records warnings occured during parsing arguments from user.
///
/// *This needs some understanding of [`package: logging`][].*
///
/// [`package: logging`]: https://pub.dartlang.org/packages/logging
const String parser = 'Parser';

/// The name of a logger which records messages from [ProxyServer].
///
/// *This needs some understanding of [`package: logging`][].*
///
/// [`package: logging`]: https://pub.dartlang.org/packages/logging
const String proxy = 'Proxy';

/// The name of a logger which records messages from [WebSocketServer].
///
/// *This needs some understanding of [`package: logging`][].*
///
/// [`package: logging`]: https://pub.dartlang.org/packages/logging
const String webSocket = 'WebSocket';
