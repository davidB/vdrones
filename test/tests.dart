import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import 'utils_test.dart' as utils_test;

main() {
  useHtmlEnhancedConfiguration();
  group('utils_test', () {
    utils_test.main();
  });
  print('tests complete.');
}

