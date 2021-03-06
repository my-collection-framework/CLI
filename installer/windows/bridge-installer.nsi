;--------------------------------
;Object.NET's Bridge.NET CLI Installer
  !define CompanyName "Object.NET"
  !define ProductName "Bridge.NET CLI"
  !define ProductSite "https://bridge.net/"
  !define ProductReadmeURL "https://github.com/bridgedotnet/CLI#bridge-cli"
  !define BridgeExec "bridge.exe"
  !define BridgeUninst "bridge-uninstall.exe"
  !define CompanyRegKey "Software\${CompanyName}"
  !define BaseRegKey "${CompanyRegKey}\${ProductName}"
  !define Build "Release"

  !define AssembliesPath "tools"
  !define BridgeLibsPath "lib"
  !define TemplatesPath "Templates"
  !define SrcPath "..\..\Bridge\bin\${Build}"

  !getdllversion "${SrcPath}/${BridgeExec}" ver_fields_
  !define Version "${ver_fields_1}.${ver_fields_2}.${ver_fields_3}"

  !define SysUninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ProductName}"

  ; Whether to install to the current user or for the whole machine
  !ifndef InstallScope
    !define InstallScope "machine"
  !endif

  !if ${InstallScope} == "machine"
    !define RegistryRoot "HKLM"
    !define RegistryPath "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
  !else
    !define RegistryRoot "HKCU"
    !define RegistryPath "Environment"
  !endif
  !define Environ '${RegistryRoot} "${RegistryPath}"'

;--------------------------------
;NSIS Modern User Interface
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;NSIS code not specific to Bridge, extracted from other sources

  !include "external-functions.nsh"

;--------------------------------
;General

  !if ${InstallScope} == "machine"
    ;Name and file
    Name "${ProductName}"
    OutFile "bridge-cli.exe"
    BrandingText "${ProductName} Setup"
    ;Default installation folder
    InstallDir "$PROGRAMFILES\${CompanyName}\${ProductName}"
    ;Request application privileges for Windows Vista and newer
    RequestExecutionLevel admin
  !else
    ;Name and file
    Name "${ProductName}"
    OutFile "bridge-cli-local.exe"
    BrandingText "${ProductName} Setup -- Install for current user account only"
    ;Default installation folder
    InstallDir "$APPDATA\${CompanyName}\${ProductName}"
    RequestExecutionLevel user
  !endif

  ;Get installation folder from registry if available
  InstallDirRegKey "${RegistryRoot}" "${BaseRegKey}" ""

  SetCompressor /solid lzma

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING
  !define MUI_ICON "..\..\Bridge\bridgedotnet-32x32.ico"
  !define MUI_UNICON "..\..\Bridge\bridgedotnet-32x32.ico"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "images\welcome.bmp"
  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "images\top.bmp"

;--------------------------------
;Pages

  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !insertmacro MUI_PAGE_WELCOME

  !insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"

  !define MUI_COMPONENTSPAGE_SMALLDESC
  !insertmacro MUI_PAGE_COMPONENTS

  !define MUI_PAGE_CUSTOMFUNCTION_SHOW AskOrReuseDir
  !insertmacro MUI_PAGE_DIRECTORY

  !insertmacro MUI_PAGE_INSTFILES

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

  !define MUI_FINISHPAGE_NOAUTOCLOSE
  !define MUI_FINISHPAGE_LINK "View ${ProductName} Readme"
  !define MUI_FINISHPAGE_LINK_LOCATION "${ProductReadmeURL}"
  !define MUI_FINISHPAGE_TITLE_3LINES
  !define MUI_WELCOMEFINISHPAGE_CUSTOMFUNCTION_INIT DisableBack
  !insertmacro MUI_PAGE_FINISH

;--------------------------------
;Makes the target directory selection read-only if Bridge has already been
;installed in the system. This will avoid reinstalling in another location
;and losing install/uninstall information.

Function AskOrReuseDir

  ReadRegStr $0 "${RegistryRoot}" "${BaseRegKey}" ""
  IfErrors done

  ; Sets the installation path the same previously used
  StrCpy $INSTDIR $0
  EnableWindow $mui.DirectoryPage.Directory 0
  EnableWindow $mui.DirectoryPage.BrowseButton 0
  MessageBox MB_OK "An installation of ${ProductName} is already registered at '$INSTDIR'. To change destination install directory, you must uninstall it. Proceeding will upgrade/update current installation."

done:

FunctionEnd

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "${ProductName} v${Version}" InstallBridge

  ;Bridge executable file.
  SetOutPath "$INSTDIR"
  File "${SrcPath}\${BridgeExec}"

  ;Copy all files within the asselbies (tools) path, regardless of how many
  ;and their names. Do not recurse thru subdirectories.
  SetOutPath "$INSTDIR\${AssembliesPath}\"
  File "${SrcPath}\${AssembliesPath}\*"

  ;For lib\, just its main folder and lib\pdb
  SetOutPath "$INSTDIR\${BridgeLibsPath}\"
  File "${SrcPath}\${BridgeLibsPath}\Bridge.dll"
  File "${SrcPath}\${BridgeLibsPath}\Bridge.xml"

  SetOutPath "$INSTDIR\${BridgeLibsPath}\pdb\"
  File "${SrcPath}\${BridgeLibsPath}\pdb\Bridge.pdb"

  ;Whole directory and subdirs
  SetOutPath "$INSTDIR\${TemplatesPath}\"
  File /r "${SrcPath}\${TemplatesPath}\*"

  ;Store installation folder
  WriteRegStr "${RegistryRoot}" "${BaseRegKey}" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\${BridgeUninst}"

  ;Windows Add/Remove programs entry
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "DisplayIcon" "$INSTDIR\${BridgeExec}"

  !if ${InstallScope} == "machine"
    WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
      "DisplayName" "${ProductName}"
  !else
    WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
      "DisplayName" "${ProductName} (installed for current user)"
  !endif

  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "DisplayVersion" "${Version}"
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "InstallLocation" "$INSTDIR"
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "Publisher" "${CompanyName}"
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "QuietUninstallString" "$\"$INSTDIR\${BridgeUninst}$\" /S"
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "UninstallString" "$\"$INSTDIR\${BridgeUninst}$\""
  WriteRegStr "${RegistryRoot}" "${SysUninstallKey}" \
    "UrlInfoAbout" "${ProductSite}"

SectionEnd

Section "Add to Path" AddToPath

  DetailPrint "Adding '$INSTDIR' to PATH."
  Push "$INSTDIR"
  Call AddToPath

  ;Store installation folder
  WriteRegDWORD "${RegistryRoot}" "${BaseRegKey}" "AddedToPath" 1

SectionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_InstallBridge ${LANG_ENGLISH} "Installs ${ProductName} v${Version}."
  LangString DESC_AddToPath ${LANG_ENGLISH} "Adds bridge.exe to environment %PATH%."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${InstallBridge} $(DESC_InstallBridge)
    !insertmacro MUI_DESCRIPTION_TEXT ${AddToPath} $(DESC_AddToPath)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section
Section "Uninstall"

  Delete "$INSTDIR\${AssembliesPath}\*"
  RMDir "$INSTDIR\${AssembliesPath}"

  ;libs directory
  Delete "$INSTDIR\${BridgeLibsPath}\pdb\Bridge.pdb"
  Delete "$INSTDIR\${BridgeLibsPath}\Bridge.dll"
  Delete "$INSTDIR\${BridgeLibsPath}\Bridge.xml"
  RMDir "$INSTDIR\${BridgeLibsPath}\pdb"
  RMDir "$INSTDIR\${BridgeLibsPath}"

  RMDir /r "$INSTDIR\${TemplatesPath}"

  Delete "$INSTDIR\${BridgeExec}"
  Delete "$INSTDIR\${BridgeUninst}"
  RMDir "$INSTDIR"

  ;Removes the Object.NET folder if it is left empty
  ;It will actually just remove the directory one level
  ;above installation dir -- provided it was made empty
  ;after uninstallation.
  StrCpy $0 "$INSTDIR\.."
  Call un.DeleteDirIfEmpty

  Call un.AskRemovePathBackup

  ReadRegDWORD $0 "${RegistryRoot}" "${BaseRegKey}" "AddedToPath"
  IfErrors done
  ${If} $0 == 1
   Push "$INSTDIR"
   Call un.RemoveFromPath
  ${EndIf}
  DeleteRegValue "${RegistryRoot}" "${BaseRegKey}" "AddedToPath"

done:
  DeleteRegKey /ifempty "${RegistryRoot}" "${BaseRegKey}"
  DeleteRegKey /ifempty "${RegistryRoot}" "${CompanyRegKey}"

  ;The windows uninstall entry will be removed for good.
  DeleteRegKey "${RegistryRoot}" "${SysUninstallKey}"

SectionEnd
