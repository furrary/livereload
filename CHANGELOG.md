# Changelog

## 0.4.0

In this release, I want to heavily refactor the code and because no one is actually using the library except for its own CLI, a lot of stuff will be removed without properly deprecated.

### Features

* Change log messages to be less confusing.

### Breaking Changes

* Change CLI option from `--proxyport` to `--port`, which should be less confusing.
* Change the behavior of the default `shouldBeRewritten` to rewrite any request which doesn't have a MIME type _with 404 response_ to `/`.
* `buildRunnerServe` function is removed. Use `BuildRunnerServeProcess` instead.
* `startWebSocketServer` function is removed. Use `WebSocketServer` instead.
* `startLiveReloadWebSocketServer` function is removed. Use `LiveReloadWebSocketServer` instead.
* `startProxyServer` function is removed. Use `ProxyServer` and `LiveReloadProxyServer` instead.

### Bug Fixes

* Properly kill the `build_runner serve` process and force the proxy server and the WebSocket server to close, closes [#5].

## 0.3.0

* `rewriteAs` is now deprecated. Use the newly added `rewriteTo`.
* `startLiveReloadProxyServer` is now deprecated. Use the now exposed `liveReloadPipeline` and `liveReloadSpaPipeline` with `startProxyServer` instead.
* `injectJavaScript` now automatically adds `<script></script>`.

## 0.2.0+1

* Improved the documentation.

## 0.2.0

* A script listening for reload signals is now automatically injected. `client.dart` is not necessary anymore.
* Some command line options have changed, e.g. `directory:port` => `directory --buildport=port`.

## 0.1.0+1

* Adds docs.

## 0.1.0

* Initial version.
