library vdrones;

import 'dart:math' as math;

class Progress {
  int total = 0;
  int current = 0;
  
  void inc(int v) {
    current = math.min(total, current + v);
  }
  
}

