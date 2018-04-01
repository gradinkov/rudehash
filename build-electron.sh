set -Ee

export PATH=${PATH}:${ProgramW6432}/nodejs

rm -rf "dist"
npm install electron-packager -g
pushd config-editor
npm install
popd
electron-packager config-editor "RudeHash Config Editor" --platform=win32 --arch=x64 --overwrite --executable-name=rudehash-config-editor
mv "RudeHash Config Editor-win32-x64" "dist"
