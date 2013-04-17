library utils_test;

import 'package:unittest/unittest.dart';
import '../lib/utils.dart';
//import 'dart:html';
import 'dart:async';

main() {
  test("LinkedBag", () {
    var d = new LinkedBag();
    d.add(1);
    d.add(2);
    d.add(3);
    d.add(1);
    expect(d.length, equals(4));

    //var lbefore = 0;
    //var lafter = 0;

    d.iterateAndUpdate((v) => (v != 2)? v : null);
    //expect(lafter, equals(lbefore - 1), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(3));

    d.iterateAndUpdate((v) => (v != 1)? v : null);
    //expect(lafter, equals(lbefore - 2), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(1));

    d.iterateAndUpdate((v) => (v != 1)? v : null);
    //expect(lafter, equals(lbefore - 0), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(1));

    d.add(3);
    d.add(1);
    d.add(1);
    expect(d.length, equals(4));

    d.iterateAndUpdate((v) => (v != 3)? v : null);
    //expect(lafter, equals(lbefore - 2), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(2));

    d.iterateAndUpdate((v) => (v != 1)? v : null);
    //expect(lafter, equals(lbefore - 2), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(0));
  });
/*
  test("SimpleLinkedList in async land", () {
    var sut = new SimpleLinkedList();

    var running = true;
    void loop(t) {
      if (running) {
        window.requestAnimationFrame(loop);
      }
      var lbefore =  sut.length;
      var ndeleted = sut.iterateAndRemove((v){
        //longtask
        var u = 0;
        for(var i = 0; i < 1000000; i++) {
          u += i * 2;
        }
        return v % 10 != 0;
      });
      var lafter = sut.length;
      expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    }
    window.requestAnimationFrame(loop);

    var fs = new List<Future>();

    for(var i = 0; i < 100; i++) {
      fs.add(new Future.immediate(i).then((x) => x * 2).then((x) => new Future.of((){ sut.add(x); return x;})));
    }
    var f = Future.wait(fs).then((x){ running = false; return x;}).catchError((e){running = false; print(e);});
    expect(f, completes);
  });
*/  
}


