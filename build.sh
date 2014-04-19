PACKAGE=firefox-roku.zip
mkdir -p bin
rm -f bin/$PACKAGE
pushd app
zip ../bin/$PACKAGE -r .
popd
