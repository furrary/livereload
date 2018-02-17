# Changelog

## 0.4.0

In this release, I want to heavily refactor the code and because no one is actually using the library except for its own CLI, a lot of stuff will be removed without properly deprecated.

### Library

* `buildRunnerServe` function is removed. Use `BuildRunnerServer` instead.
* `startWebSocketServer` function is removed. Use `WebSocketServer` instead.
* `startLiveReloadWebSocketServer` function is removed. Use `LiveReloadWebSocketServer` instead.

## 0.3.0

### Library

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
