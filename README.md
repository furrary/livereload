# livereload

[![Pub](https://img.shields.io/pub/v/livereload.svg)](https://pub.dartlang.org/packages/livereload)

A simple Dart development server that serves a web app, automatically refreshes when there's a change, and is compatible with single page apllications (SPA) that utilize the [history API][].

_[dartdocs.org][] uses Dart 1.x SDK to generate docs and fails to build, so I need to build the [docs][] myself._

## Installation

The implementation of this package is just a proxy server that passes requests to [`package: build_runner`][]. So, it needs to be installed along with this package.

Edit your `pubspec.yaml`

```yaml
dev_dependencies:
  build_runner:
  build_web_compilers:
  livereload: ^0.2.0
```

and run

```
pub get --no-precompile
```

## Usage

```
pub run livereload
```

Then, browse your web app at [http://localhost:8000](http://localhost:8000).

If you are going to build an SPA, make sure to add a proper [`<base>`][] so that your routing works.

```html
<!DOCTYPE html>
<html lang="en">

<head>
  <!-- <base> is needed. -->
  <base href="/">
  <script defer src="main.dart.js"></script>
  <title>SPA</title>
</head>

<body>
  <!-- AngularDart with angular_router -->
  <my-app>Loading...</my-app>
</body>

</html>
```

## Command Line Options

Since this runs `pub run build_runner serve` under the hood, some options replicate those of [`package: build_runner`][].

```
pub run livereload [directory] [options]
```

By default, the directory is `web`. Please note that this package does _not_ support serving more than one directory at a time, because it would complicate the CLI options. If it is needed, please file an issue. Furthermore, PRs are welcome.

* -l, --low-resources-mode: Reduces the amount of memory consumed by the build process.
* -c, --config: Reads `build.<name>.yaml` instead of the default `build.yaml`. (required: `build_runner >= 0.7.8`)
* --define: Sets the global `options` config for a builder by key. As an example, enabling the dart2js compiler would look like: `--define "build_web_compilers|entrypoint=compiler=dart2js"` (required: `build_runner >= 0.7.9`)
* --hostname: Specifies the hostname to serve on. (defaults to "localhost")
* --buildport: Changes the port number where `build_runner` serves. (defaults to "8080")
* --proxyport: Changes the port number of the proxy server. (defaults to "8000")
* --websocketport: Changes the port number of the websocket. (defaults to "4242")
* --\[no-]spa: Serves a single page application. This allows routes controlled by [history API][] to be working. (defaults to on)

Some of the options from [`package: build_runner`][] are intentionally left out, since it wouldn't match the use case of this package.

[`package: build_runner`]: https://pub.dartlang.org/packages/build_runner
[history api]: https://developer.mozilla.org/en-US/docs/Web/API/History_API
[dartdocs.org]: https://www.dartdocs.org/
[docs]: https://furrary.github.io/livereload/
[`<base>`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
