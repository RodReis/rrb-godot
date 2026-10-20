; Instalador do Loot Start (F83, ADR-0023). Gerado pelo release.yml (makensis no Linux) a partir do
; pacote de tools/build-package.ps1:
;   makensis -DVERSION=v0.2.0 -DVERSION_NUM=0.2.0.0 -DSRC=<build/package> -DOUT=<Setup.exe> lootstart.nsi
; Instala por usuario em %LOCALAPPDATA%\Programs\Loot Start (sem UAC), atalhos no Menu Iniciar e na
; Area de Trabalho e desinstalador em "Aplicativos instalados". Configuracoes e sessao ficam em
; %APPDATA%\rrb-moba (fora daqui): nem a atualizacao nem a desinstalacao mexem nelas.
; Atualizacao: o Launcher roda "Setup.exe /S /UPDATE" e fecha; o instalador espera o LootStart.exe
; liberar, troca os arquivos e o abre de novo.

Unicode true
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

!define APP "Loot Start"
!define EXE "LootStart.exe"
!define UNINSTALLER "Desinstalar.exe"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootStart"
; Espera o Launcher fechar: ate WAIT_TRIES x WAIT_MS.
!define WAIT_TRIES 40
!define WAIT_MS 500

Name "${APP}"
OutFile "${OUT}"
InstallDir "$LOCALAPPDATA\Programs\${APP}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
BrandingText "${APP} ${VERSION}"

VIProductVersion "${VERSION_NUM}"
VIAddVersionKey "ProductName" "${APP}"
VIAddVersionKey "FileDescription" "Instalador do ${APP}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "FileVersion" "${VERSION_NUM}"
VIAddVersionKey "LegalCopyright" "${APP}"

!define MUI_ICON "${__FILEDIR__}/lootstart.ico"
!define MUI_UNICON "${__FILEDIR__}/lootstart.ico"
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Abrir o ${APP}"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "PortugueseBR"

Var Update

Function .onInit
	${GetParameters} $0
	ClearErrors
	${GetOptions} $0 "/UPDATE" $1
	${IfNot} ${Errors}
		StrCpy $Update 1
	${EndIf}
FunctionEnd

Section "${APP}"
	SetOutPath "$INSTDIR"
	; O Launcher que pediu a atualizacao fecha logo depois de abrir o instalador.
	StrCpy $2 0
	wait_launcher:
	ClearErrors
	${If} ${FileExists} "$INSTDIR\${EXE}"
		Delete "$INSTDIR\${EXE}"
		${If} ${Errors}
			IntOp $2 $2 + 1
			${If} $2 < ${WAIT_TRIES}
				Sleep ${WAIT_MS}
				Goto wait_launcher
			${EndIf}
			Abort "Feche o ${APP} e rode o instalador de novo."
		${EndIf}
	${EndIf}
	File /r /x "LEIA-ME.txt" "${SRC}/*.*"
	WriteUninstaller "$INSTDIR\${UNINSTALLER}"
	CreateShortcut "$SMPROGRAMS\${APP}.lnk" "$INSTDIR\${EXE}"
	; Na atualizacao o atalho da Area de Trabalho nao volta se o jogador o apagou.
	${If} $Update != 1
		CreateShortcut "$DESKTOP\${APP}.lnk" "$INSTDIR\${EXE}"
	${EndIf}
	WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${APP}"
	WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${VERSION}"
	WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\${EXE}"
	WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
	WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\${UNINSTALLER}"'
	WriteRegStr HKCU "${UNINSTALL_KEY}" "QuietUninstallString" '"$INSTDIR\${UNINSTALLER}" /S'
	WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
	WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
	${GetSize} "$INSTDIR" "/S=0K" $3 $4 $5
	WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" $3
	${If} $Update == 1
		Exec '"$INSTDIR\${EXE}"'
	${EndIf}
SectionEnd

Section "Uninstall"
	Delete "$SMPROGRAMS\${APP}.lnk"
	Delete "$DESKTOP\${APP}.lnk"
	RMDir /r "$INSTDIR"
	DeleteRegKey HKCU "${UNINSTALL_KEY}"
SectionEnd
