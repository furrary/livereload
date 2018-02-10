# livereload

A simple Dart development server that serves a web app, automatically refreshes when there's a change, and is compatible with single page apllications (SPA) that utilize the [history API][].

## Installation
The implementation of this package is just a proxy server that passes requests to [`package: build_runner`][]. So, it needs to be installed along with this package.

```yaml
dependencies:
  livereload:

dev_dependencies:
  build_runner:
  build_web_compilers:
```
## Usage
After running `pub get --no-precompile`, add this to your `main.dart`.

```dart
import 'package:livereload/client.dart';

main() {
  new ReloadListener().listen();
  // continue with your code...
}
```
and run

```
pub run livereload
```

## Command Line Options

Since this runs `pub run build_runner serve` under the hood, most of the options replicates those of [`package: build_runner`][].

```
pub run livereload [<directory>:<port>] [options]
```

By default, the directory is `web` and the port number is `8080`. Please note that this package does *not* support serving more than one directory at a time, because it would complicate the CLI options. If it is needed, please file an issue. Furthermore, PRs are welcome.

* -l, --low-resources-mode: Reduces the amount of memory consumed by the build process.
* -c, --config: Reads `build.<name>.yaml` instead of the default `build.yaml`. (required: `build_runner >= 0.7.8`)
* -v, --verbose: Enables verbose logging.
* --define: Sets the global `options` config for a builder by key. As an example, enabling the dart2js compiler would look like: `--define "build_web_compilers|entrypoint=compiler=dart2js"` (required: `build_runner >= 0.7.9`)
* --hostname: Specifies the hostname to serve on. (defaults to "localhost")
* --proxy-port: Changes the port number of the proxy server. (defaults to "8000")
* --websocket-port: Changes the port number of the websocket. (defaults to "4242")
* --\[no-]spa: Serves a single page application. This allows routes controlled by [history API][] to be working. (defaults to on)

Some of the options from [`package: build_runner`][] are intentionally left out, since it wouldn't match the use case of this package.

[`package: build_runner`]: https://pub.dartlang.org/packages/build_runner
[history API]: https://developer.mozilla.org/en-US/docs/Web/API/History_API
