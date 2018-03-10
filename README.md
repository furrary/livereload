# livereload

[![Pub](https://img.shields.io/pub/v/livereload.svg)](https://pub.dartlang.org/packages/livereload)

A simple Dart development server that serves a web app, automatically refreshes on changes, and is compatible with single page apllications (SPA) that utilize the [history API][].

_[dartdocs.org][] uses Dart 1.x SDK to generate docs and fails to build, so I need to build the [docs][] myself._

## Installation

This package runs `pub run build_runner serve` under the hood. So, [`package: build_runner`][] needs to be installed along with this package.

Edit your `pubspec.yaml`

```yaml
dev_dependencies:
  build_runner: ^0.7.13
  build_web_compilers: ^0.3.0
  livereload: ^0.4.0
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

Most of the options replicate those of [`package: build_runner`][]. You can config your build through `build.yaml`, the same way as you would do with [`package: build_runner`][].

```
pub run livereload [directory] [options]
```

* If the directory is omitted, `web` will be served.
* -l, --low-resources-mode: Reduces the amount of memory consumed by the build process.
* -c, --config: Reads `build.<name>.yaml` instead of the default `build.yaml`.
* --define: Sets the global `options` config for a builder by key. As an example, enabling the dart2js compiler would look like: `--define "build_web_compilers|entrypoint=compiler=dart2js"`
* --hostname: Specifies the hostname to serve on. (defaults to "localhost")
* --port: Changes the port number of the livereload server. (defaults to "8000")
* --buildport: Changes the port number where `build_runner` serves. (defaults to "8080")
* --websocketport: Changes the port number of the underlying websocket. (defaults to "4242")
* --\[no-]spa: Serves a single page application. This allows routes controlled by [history API][] to be working. (defaults to on)

## Further Configuration

This package is a [`shelf`][] proxy server, so you can write your own `.dart` file which imports this library ([docs][]) and add more middlewares to your heart's content.

[`package: build_runner`]: https://pub.dartlang.org/packages/build_runner
[history api]: https://developer.mozilla.org/en-US/docs/Web/API/History_API
[dartdocs.org]: https://www.dartdocs.org/
[docs]: https://furrary.github.io/livereload/
[`<base>`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
[`shelf`]: https://pub.dartlang.org/packages/shelf
