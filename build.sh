mkdir -p target
ln -sf ../packages target/packages

#dart_analyzer --work target/dart-work --package-root=packages/ --metrics --fatal-type-errors --incremental --enable_type_checks --dart-sdk "$DART_SDK" web/index.dart
dart_analyzer --work target/dart-work --package-root=packages/ --metrics --enable_type_checks --dart-sdk "$DART_SDK" web/index.dart


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

if [ "x$1" = "x--deploy" ] ; then

  dart2js --package-root=packages/ _index0.html_bootstrap.dart -o_index0.html_bootstrap.dart.js

  rm packages
  rm **/packages
  mkdir packages
  cp -R ../../packages/browser packages

  #TODO copy index0.html into index.html and remove dart reference (**/*.dart + into index.xml)
  cp index0.html index.html
  #vim -c '%s#<script src="packages/browser/dart.js"></script>##ge|x' index.html
  vim -E -s index.html <<EOF
:s#type="application/dart"##g
:s#.dart"#.dart.js"##g
:x
EOF
  rm **/*.dart **/*.dart.map *.dart *.dart.map

fi

cd ../..

