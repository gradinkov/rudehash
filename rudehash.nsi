!define VERSION "8.0"
!define CNAME "RudeHash"
!define FNAME "rudehash"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${CNAME}"

Name "${CNAME} ${VERSION}"
OutFile "${FNAME}-${VERSION}.exe"
InstallDir $PROGRAMFILES64\${CNAME}
RequestExecutionLevel admin
SetCompressor /SOLID lzma
LicenseText "License"
LicenseData "LICENSE"

Section
    !include "x64.nsh"
    ${Unless} ${RunningX64}
        MessageBox MB_OK|MB_ICONSTOP "${CNAME} only runs on 64-bit Windows."
        Quit
    ${EndUnless}

    SetRegView 64
    SetShellVarContext all

    SetOutPath "$INSTDIR"
    File /r "powershell"
    File "CHANGELOG.md"
    File "LICENSE"
    File "README.md"
    File "rudehash.html"
    File "rudehash.ps1"
    File "rudehash-example.json"

    SetOutPath "$INSTDIR\dist"
    File "dist\bootstrap.min.css"
    File "dist\bootstrap.min.css.map"
    File "dist\foundation-icons.css"
    File "dist\foundation-icons.woff"
    File "dist\jsoneditor.min.js"
    File "dist\jsoneditor.min.js.map"

    # SetOutPath determines "start in" property for CreateShortCut
    SetOutPath "$INSTDIR"
    CreateDirectory "$SMPROGRAMS\${CNAME}"
    CreateShortCut "$SMPROGRAMS\${CNAME}\${CNAME}.lnk" "$INSTDIR\powershell\pwsh.exe" "-ExecutionPolicy Bypass -File $\"$INSTDIR\rudehash.ps1$\"" "$SYSDIR\setupapi.dll" 13
    CreateShortCut "$SMPROGRAMS\${CNAME}\${CNAME} Config Editor.lnk" "$INSTDIR\rudehash.html" "" "$SYSDIR\setupapi.dll" 15

    WriteUninstaller "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "RudeHash"
    WriteRegStr HKLM "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$SYSDIR\setupapi.dll,13"
    WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "${UNINST_KEY}" "QuietUninstallString" "$INSTDIR\uninstall.exe /S"
SectionEnd

Section "Uninstall"
    SetRegView 64
    SetShellVarContext all

    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\CHANGELOG.md"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\rudehash.html"
    Delete "$INSTDIR\rudehash.ps1"
    Delete "$INSTDIR\rudehash-example.json"

    Delete "$INSTDIR\dist\bootstrap.min.css"
    Delete "$INSTDIR\dist\bootstrap.min.css.map"
    Delete "$INSTDIR\dist\foundation-icons.css"
    Delete "$INSTDIR\dist\foundation-icons.woff"
    Delete "$INSTDIR\dist\jsoneditor.min.js"
    Delete "$INSTDIR\dist\jsoneditor.min.js.map"

    RMDir "$INSTDIR\dist"
    RMDir /r "$INSTDIR\powershell"
    RMDir "$INSTDIR"

    Delete "$SMPROGRAMS\${CNAME}\${CNAME}.lnk"
    Delete "$SMPROGRAMS\${CNAME}\${CNAME} Config Editor.lnk"
    RMDir "$SMPROGRAMS\${CNAME}"

    DeleteRegKey HKLM "${UNINST_KEY}"
SectionEnd
