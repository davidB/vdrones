#! /bin/zsh

mkdir -p target
ln -sf ../packages target/packages

#dart_analyzer --work target/dart-work --package-root=packages/ --metrics --fatal-type-errors --incremental --enable_type_checks --dart-sdk "$DART_SDK" web/index.dart
#dart_analyzer --work target/dart-work --package-root=packages/ --metrics --incremental --enable_type_checks --dart-sdk "$DART_SDK" web/index.dart


cat >filter <<EOF
+ web/packages
+ web/packages/browser
+ web/packages/browser/dart.js
- web/packages/browser/*
- web/packages/*
- packages
- index.dart*
- _lib
- *.xcf
EOF
#rsync -av --copy-links  '--include=packages/browser/dart.js' '--exclude=packages' web target
#rsync -av --delete --copy-links  --filter="merge filter" web target
rsync -av --delete --links web target
#cd web
#dart2js -output-type=js -o../target/web/index.dart.js index.dart
#dart2js --minify --output-type=js -o../target/web/index.dart.js index.dart
#dart2js --minify --output-type=dart -o../target/web/index.dart index.dart
#cd ..
cd target/web
dart --package-root=packages/ packages/web_ui/dwc.dart index0.html
rm index0.html
mv _index0.html.html index0.html

#HACK for web_ui that remove disabled attribute
vim -c '%s#<button class="btn btn-primary" id="_#<button class="btn btn-primary" disabled id="_#ge|x' index0.html

if [ "x$1" = "x--deploy" -o "x$1" = "x--js" ] ; then

  dart2js --package-root=packages/ _index0.html_bootstrap.dart -o_index0.html_bootstrap.dart.js

  if [ "x$1" = "x--deploy" ] ; then
    rm -Rf packages **/packages
    rm **/*.dart **/*.dart.map *.dart *.dart.map
  
    mkdir packages
    cp -R ../../packages/browser packages
  fi

  #TODO copy index0.html into index.html and remove dart reference (**/*.dart + into index.xml)
  cp index0.html index.html
  #vim -c '%s#<script src="packages/browser/dart.js"></script>##ge|x' index.html
  vim -E -s index.html <<EOF
:s#type="application/dart"##g
:s#.dart"#.dart.js"##g
:x
EOF
#TODO insert before last </body>
cat >>index.html <<EOF
  <script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-18659445-4']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

  </script>
EOF

fi

cd ../..

