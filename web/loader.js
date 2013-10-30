// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  // TODO:
  // - Support in-browser compilation.
  // - Handle inline Dart scripts.

  // Fall back to compiled JS. Run through all the scripts and
  // replace them if they have a type that indicate that they source
  // in Dart code.
  //
  //   <script type="application/dart" src="..."></script>
  //
  console.log("begin");
  var scripts = document.getElementsByTagName("script");
  var length = scripts.length;
  for (var i = 0; i < length; ++i) {
  console.log(scripts[i]);
  console.log(scripts[i].dataset.dartsrc);
    if (scripts[i].dataset.dartsrc && scripts[i].dataset.dartsrc != '') {
      var src = scripts[i].dataset.dartsrc;
      var type = "application/dart";
      if (!navigator.webkitStartDart) {
        src = src.replace(/\.dart(?=\?|$)/, '.dart.js');
        type = "";
      }
      var script = document.createElement('script');
      script.src = src;
      script.type = type;
      console.log(script);
      var parent = scripts[i].parentNode;
      // TODO(vsm): Find a solution for issue 8455 that works with more
      // than one script.
      document.currentScript = script;
      parent.replaceChild(script, scripts[i]);
    }
  }
  console.log("end");
})();
