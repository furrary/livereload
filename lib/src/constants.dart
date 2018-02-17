const String defaultDirectory = 'web';

const defaultPorts = const <String, String>{
  'proxyport': '8000',
  'websocketport': '4242',
};

/// A message send through the WebSocket signaling the browser to reload.
///
/// [Amaki Sally](http://www.asianjunkie.com/2017/10/04/an-introduction-to-the-entertaining-world-of-amaki-sally-a-member-of-227/)
const String reloadSignal = 'AmakiSally';
