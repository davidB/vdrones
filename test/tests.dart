import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import 'utils_test.dart' as utils_test;
import 'events_test.dart' as events_test;
import 'stats_test.dart' as stats_test;

main() {
  useHtmlEnhancedConfiguration();
  group('utils_test', utils_test.main);
  group('events_test', events_test.main);
  group('stats_test', stats_test.main);
  print('tests complete.');
}

