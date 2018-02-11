import 'dart:html';

import 'package:livereload/client.dart';

void main() {
  new ReloadListener().listen();
  querySelector('#output').text = 'Your Dart app is running.';
}
