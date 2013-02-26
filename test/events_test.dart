library vdrones_test;

import 'package:unittest/unittest.dart';
import '../lib/events.dart';

main() {  
  test("Signal forward request", () {
    var d = new Signal();
    num cntP = 0;
    num cntN = 0;
    d.add((int i) => cntP += i);
    d.add((int i) => cntN -= i);
      
    //d.dispatch(["foo"]);
    d.dispatch([33]);
    expect(cntP, equals(33));  
    expect(cntN, equals(-33));
  });  
}

