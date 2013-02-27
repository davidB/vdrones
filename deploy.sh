cd web
dart2js --minify --output-type=js -oindex.dart.js index.dart
cd ..
mkdir -p target
cat >filter <<EOF
+ packages
+ packages/browser
+ packages/browser/dart.js
- packages/*
EOF
#rsync -av --copy-links  '--include=packages/browser/dart.js' '--exclude=packages' web target 
rsync -av --copy-links  --filter="merge filter" web target 
appcfg.sh update target/web

