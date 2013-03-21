import 'dart:io';
import 'package:web_ui/component_build.dart';

// Ref: http://www.dartlang.org/articles/dart-web-components/tools.html
main() {
  build(new Options().arguments, ['web/tests_web_ui.html', 'web/index.html', 'web/index0.html']);
}
