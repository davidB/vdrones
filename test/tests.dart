import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import 'stats_test.dart' as stats_test;

main() {
  useHtmlEnhancedConfiguration();
  group('stats_test', stats_test.main);
  print('tests complete.');
}

