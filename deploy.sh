mkdir -p target
cat >filter <<EOF
+ web/packages
+ web/packages/browser
+ web/packages/browser/dart.js
- web/packages/browser/*
- web/packages/*
- packages
- index.dart*
- _lib
EOF
#rsync -av --copy-links  '--include=packages/browser/dart.js' '--exclude=packages' web target
rsync -av --copy-links  --filter="merge filter" web target
cd web
dart2js --minify --output-type=js -o../target/web/index.dart.js index.dart
#dart2js --minify --output-type=dart -o../target/web/index.dart index.dart
cd ..

appcfg.sh  --use_java7 update target/web

