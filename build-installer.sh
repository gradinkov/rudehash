set -Ee

PROGX86=$(awk 'BEGIN{print(ENVIRON["ProgramFiles(x86)"])}')
export PATH=${PATH}:${PROGX86}/NSIS

makensis rudehash.nsi

pause
