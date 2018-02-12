const String defaultDirectory = 'web';

const defaultPorts = const <String, String>{
  CliOption.buildRunnerPort: '8080',
  CliOption.proxyPort: '8000',
  CliOption.webSocketPort: '4242',
};

/// Options avaliable in the CLI.
class CliOption {
  static const lowResourcesMode = 'low-resources-mode';
  static const config = 'config';
  static const define = 'define';
  static const singlePageApplication = 'spa';
  static const hostName = 'hostname';
  static const buildRunnerPort = 'buildport';
  static const proxyPort = 'proxyport';
  static const webSocketPort = 'websocketport';
  static const help = 'help';
}

/// A message send through the WebSocket signaling the browser to reload.
///
/// [Amaki Sally](http://www.asianjunkie.com/2017/10/04/an-introduction-to-the-entertaining-world-of-amaki-sally-a-member-of-227/)
const String reloadSignal = 'AmakiSally';
