!define VERSION "8.0-dev"
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
    File "CHANGELOG.md"
    File "LICENSE"
    File "README.md"
    File "rudehash.ps1"
    File "rudehash-example.json"

    # workaround; using just "dist" without SetOutPath also copies the config-editor folder altogether
    # because reasons.
    SetOutPath "$INSTDIR\dist"
    File /r "dist\*"

    SetOutPath "$INSTDIR\powershell"
    File /r "powershell\*"

    # CreateShortCut's "start in" depends on "SetOutPath"
    SetOutPath "$INSTDIR"
    CreateDirectory "$SMPROGRAMS\${CNAME}"
    CreateShortCut "$SMPROGRAMS\${CNAME}\${CNAME}.lnk" "$INSTDIR\powershell\pwsh.exe" "-ExecutionPolicy Bypass -File $\"$INSTDIR\rudehash.ps1$\"" "$SYSDIR\setupapi.dll" 13
    CreateShortCut "$SMPROGRAMS\${CNAME}\${CNAME} Config Editor.lnk" "$INSTDIR\dist\rudehash-config-editor.exe"

    WriteUninstaller "$INSTDIR\uninstall.exe"

    WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$SYSDIR\setupapi.dll,13"
    WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "RudeHash"
    WriteRegStr HKLM "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "${UNINST_KEY}" "HelpLink" "https://github.com/gradinkov/rudehash/issues"
    WriteRegStr HKLM "${UNINST_KEY}" "Publisher" "Gradinkov"
    WriteRegStr HKLM "${UNINST_KEY}" "QuietUninstallString" "$INSTDIR\uninstall.exe /S"
    WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "${UNINST_KEY}" "URLInfoAbout" "https://rudehash.org/"
SectionEnd

Section "Uninstall"
    SetRegView 64
    SetShellVarContext all

    # this needs to be first because reasons, so be it
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\CHANGELOG.md"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\rudehash.html"
    Delete "$INSTDIR\rudehash.ps1"
    Delete "$INSTDIR\rudehash-example.json"

    RMDir /r "$INSTDIR\dist"
    RMDir /r "$INSTDIR\powershell"
    RMDir "$INSTDIR"

    Delete "$SMPROGRAMS\${CNAME}\${CNAME}.lnk"
    Delete "$SMPROGRAMS\${CNAME}\${CNAME} Config Editor.lnk"
    RMDir "$SMPROGRAMS\${CNAME}"

    DeleteRegKey HKLM "${UNINST_KEY}"
SectionEnd

Function .onInit
    SetRegView 64
    SetShellVarContext all

    ReadRegStr $R0 HKLM "${UNINST_KEY}" "QuietUninstallString"
    StrCmp $R0 "" done

    MessageBox MB_OKCANCEL|MB_ICONINFORMATION "${CNAME} is already installed. $\n$\nClick $\"OK$\" to remove the previous version or $\"Cancel$\" to cancel this upgrade." IDOK uninst
    Abort

    uninst:
        ClearErrors
        ExecWait $R0
    done:
FunctionEnd
