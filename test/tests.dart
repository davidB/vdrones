import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import 'vdrone_info_test.dart' as stats_test;
import 'areareader_test.dart' as areareader_test;

main() {
  useHtmlEnhancedConfiguration();
  group('stats_test', stats_test.main);
  group('areareader_test', areareader_test.main);
  print('tests complete.');
}

