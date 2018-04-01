set -Ee

sh ./build-electron.sh

# alternatively: printenv 'ProgramFiles(x86)'
PROGX86=$(awk 'BEGIN{print(ENVIRON["ProgramFiles(x86)"])}')
export PATH=${PATH}:${PROGX86}/NSIS

VERSION=$(grep "^\!define VERSION" rudehash.nsi | awk -F'"' '{ print $2 }')
DATESTR=$(date +%Y%m%d)

if [[ $VERSION == *-dev ]]
then
    makensis /X"OutFile 'rudehash-${VERSION}-${DATESTR}.exe'" rudehash.nsi
else
    makensis /X"OutFile 'rudehash-${VERSION}.exe'" rudehash.nsi
fi
