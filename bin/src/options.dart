const buildRunnerOptions = const <BuildRunnerOption, String>{
  BuildRunnerOption.lowResourcesMode: 'low-resources-mode',
  BuildRunnerOption.verbose: 'verbose',
  BuildRunnerOption.config: 'config',
  BuildRunnerOption.define: 'define',
  BuildRunnerOption.hostName: 'hostname',
};

const liveReloadOptions = const <LiveReloadOption, String>{
  LiveReloadOption.help: 'help',
  LiveReloadOption.proxyPort: 'proxy-port',
  LiveReloadOption.webSocketPort: 'websocket-port',
  LiveReloadOption.singlePageApplication: 'spa',
};

enum BuildRunnerOption {
  lowResourcesMode,
  verbose,
  config,
  define,
  hostName,
}

enum LiveReloadOption {
  help,
  proxyPort,
  webSocketPort,
  singlePageApplication,
}
