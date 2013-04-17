library utils;
import 'dart:async';

class LinkedBag<E> {
  LinkedEntry _head = new LinkedEntry();

  get length {
    int i = 0;
    for(var a = _head; a != null; a = a._next) {
      if (a._obj != null) i++;
    }
    return i;
  }

  void clear() {
    for(var a = _head; a != null; a = a._next) {
      a._obj = null;
    }
  }

  void add(E obj) {
    var a = _head;
    while(a != null) {
      if (a._obj == null) {
        a._obj = obj;
        return;
      }
      if (a._next == null) {
        var e = new LinkedEntry();
        e._obj = obj;
        a._next = e;
        return;
      }
      a = a._next;
    }
  }

  /**
   * Iterate over the entries (!= null) in the bag.
   * [f] update the entry in the bag (return null => free the entry)
   */
  void iterateAndUpdate(E f(E)) {
    int i = 0;
    for(var current = _head; current != null; current = current._next) {
      if (current._obj != null) {
        current._obj = f(current._obj);
      }
    }
  }
}

class LinkedEntry {
  LinkedEntry _next = null;
  var _obj;
}

class SimpleLinkedEntry {
  SimpleLinkedEntry _next = null;
  var _obj;
}

class SimpleLinkedList<E> {
  SimpleLinkedEntry _head = null;
  bool iterating = false;
  bool dump = false;
  get length {
    int i = 0;
    for(var a = _head; a != null; a = a._next, i++);
    return i;
  }

  void add(E obj) {
    if (iterating) {
      dump = true;
      throw new StateError("iterating");
    }
    SimpleLinkedEntry e = new SimpleLinkedEntry();
    e._next = _head;
    e._obj = obj;
    _head = e;
  }

  num iterateAndRemove(bool f(E)) {
    iterating = true;
    int i = 0;
    try {
      var current = _head;
      var prev = null;
      var head = null;
      bool c = false;
      while(current != null) {
        var cont = f(current._obj);
        if (!cont) {
          i++;
          if (prev != null) {
            prev._next = null;
          }
        } else {
          if (head == null) {
            head = current;
          }
          if (prev != null) {
            prev._next = current;
          }
          prev = current;
        }
        current = current._next;
      }
      _head = head;
      if (dump) {
        dump = false;
        throw new Exception("dump on iterating");
      }
    } finally {
      iterating = false;
    }
    return i;
  }
}
