; GeniusTrader.nsi
;
; It will install GeniusTrader into a directory that the user selects,

;--------------------------------
Var /GLOBAL configdir

; The name of the installer
Name "GeniusTrader"

; The file to write
OutFile "GeniusTrader.exe"

; The default installation directory
InstallDir $PROGRAMFILES\GeniusTrader

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\GeniusTrader" "Install_Dir"

;--------------------------------

; Pages

Page license
LicenseData gpl.txt
Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "GeniusTrader (required)"

  ExecWait '"perl.exe" "require v5.8.0;print 1"' $0
  IfErrors no_perl perl_ok
  no_perl:
  MessageBox MB_OK "This installer requires perl v5.8 or later in order for GeniusTrader to function properly. You can get perl from http://www.activestate.org/"
  abort "Perl not found. Please download it from http://www.activestate.org/ ."

  perl_ok:

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  ; Put file there
  File /r modules
  File /r ..\GT
  File /r ..\Scripts

  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\GeniusTrader "Install_Dir" "$INSTDIR"

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GeniusTrader" "DisplayName" "GeniusTrader"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GeniusTrader" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GeniusTrader" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GeniusTrader" "NoRepair" 1
  WriteUninstaller "uninstall.exe"


  Push $INSTDIR\Scripts
  Call AddToPath

  Push $INSTDIR
  Call AddToperl5lib


  Call GetHomePath
  strcpy $configdir "$0\.gt"
  CreateDirectory $configdir

  ClearErrors
  FileOpen $0 $configdir\options w
  IfErrors done
  FileWrite $0 "Brokers::module SelfTrade"

  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"

  FileWrite $0 "Path::Font::Arial $%WINDIR%\fonts\arial.ttf"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWrite $0 "Path::Font::Courier $%WINDIR%\fonts\couri.ttf"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWrite $0 "Path::Font::Times $%WINDIR%\fonts\times.ttf"

  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"

  FileWrite $0 "Analysis::ReferenceTimeFrame year"

  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"

  FileWrite $0 "Aliases::Global::TFS    SY:TFS 50 10|CS:SY:TFS"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWrite $0 "Aliases::Global::TFS[]  SY:TFS #1 #2|CS:SY:TFS #1|CS:Stop:Fixed #3"

  FileClose $0
  done:

SectionEnd


; Optional section (can be disabled by the user)

Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\GeniusTrader"
  CreateShortCut "$SMPROGRAMS\GeniusTrader\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
SectionEnd

Section "Date::Calc module"
  ClearErrors
  ExecWait '"perl.exe" -MCarp::Clan -e "print $$Carp::Clan::VERSION"' $0
  DetailPrint "Carp::Clan check returned $0"
;  IfErrors Carp_Clan_bad Carp_Clan_done
  Carp_Clan_bad:
  ExecWait '"ppm.bat" install $INSTDIR/modules/Carp-Clan.ppd' $0
  DetailPrint "Carp_Clan returned $0"
  Carp_Clan_done:

  ClearErrors
  ExecWait '"perl.exe" -MBit::Vector -e "print $$Bit::Vector::VERSION"' $0
  DetailPrint "Bit::Vector check returned $0"
;  IfErrors Bit_Vector_bad Bit_Vector_done
  Bit_Vector_bad:
  ExecWait '"ppm.bat" install $INSTDIR/modules/Bit-Vector.ppd' $0
  DetailPrint "Bit::Vector returned $0"
  Bit_Vector_done:

  ClearErrors
  ExecWait '"perl.exe" -MDate::Calc -e "print $$Date::Calc::VERSION"' $0
  DetailPrint "Date::Calc check returned $0"
;  IfErrors Date_Calc_bad Date_Calc_done
  Date_Calc_bad:
  ExecWait '"ppm.bat" install $INSTDIR/modules/Date-Calc.ppd' $0
  DetailPrint "Date::Calc returned $0"
  Date_Calc_done:

SectionEnd

Section "XML::LibXML module"
  File libxml2.dll
  CopyFiles $INSTDIR\libxml2.dll $INSTDIR\Scripts
  Delete $INSTDIR\libxml2.dll
  ClearErrors
  ExecWait '"perl.exe" -MXML::LibXML::Common -e "print $$XML::LibXML::Common::VERSION"' $0
  DetailPrint "XML::LibXML::Common check returned $0"
;  IfErrors XML_LibXML_Common_bad XML_LibXML_Common_done
  XML_LibXML_Common_bad:
  ExecWait '"ppm.bat" install $INSTDIR/modules/XML-LibXML-Common.ppd' $0
  DetailPrint "XML::LibXML::Common returned $0"
  XML_LibXML_Common_done:

  ClearErrors
  ExecWait '"perl.exe" -MXML::LibXML -e "print $$XML::LibXML::VERSION"' $0
  DetailPrint "XML::LibXML check returned $0"
;  IfErrors XML_LibXML_bad XML_LibXML_done
  XML_LibXML_bad:
  ExecWait '"ppm.bat" install $INSTDIR/modules/XML-LibXML.ppd' $0
  DetailPrint "XML::LibXML returned $0"
  XML_LibXML_done:
SectionEnd

Section "GD module"
  ClearErrors
  ExecWait '"perl.exe" -MGD -e "print $$GD::VERSION"' $0
  DetailPrint "GD check returned $0"
;  IfErrors GD_bad GD_done
  GD_bad:
  ExecWait '"ppm.bat" install $INSTDIR/modules/GD.ppd' $0
  DetailPrint "GD returned $0"
  GD_done:
SectionEnd

Section "Sample text data files" DATA_TEXT
  SectionSetText DATA_TEXT teste

  File /r data
  ClearErrors
  FileOpen $0 $configdir\options a
  IfErrors done
  FileSeek $0 0 END
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"

  FileWrite $0 "DB::module Text"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"

  FileWrite $0 "DB::text::directory $INSTDIR\data"
  FileWriteByte $0 "13"
  FileWriteByte $0 "10"

  FileWrite $0 "DB::text::options ( '	' , 0 , '.txt' , ('date' => 5, 'open' => 0, 'high' => 1, 'low' => 2, 'close' => 3, 'volume' => 4, 'Adj. Close*' => 3) )"
  FileClose $0
  done:
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

  Push $INSTDIR
  Call un.RemoveFromperl5lib

  Push $INSTDIR\Scripts
  Call un.RemoveFromPath

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GeniusTrader"
  DeleteRegKey HKLM SOFTWARE\GeniusTrader

  ; Remove files and uninstaller
  RMDir /r $INSTDIR\GT
  RMDir /r $INSTDIR\Scripts
  RMDir /r $INSTDIR\data
  RMDir /r $INSTDIR\modules

  Call un.GetHomePath
  strcpy $configdir "$0\.gt"
  RMDir /r $configdir
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\GeniusTrader\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\GeniusTrader"
  RMDir "$INSTDIR"

SectionEnd



















Function GetHomePath
  ReadEnvStr $1 HOMEDRIVE
  ReadEnvStr $2 HOMEPATH

  StrCpy $0 "$1$2"
FunctionEnd


Function un.GetHomePath
  ReadEnvStr $1 HOMEDRIVE
  ReadEnvStr $2 HOMEPATH

  StrCpy $0 "$1$2"
FunctionEnd








!ifndef _AddToPath_nsh
!define _AddToPath_nsh
 
!verbose 3
!include "WinMessages.NSH"
!verbose 4
 
!ifndef WriteEnvStr_RegKey
  !ifdef ALL_USERS
    !define WriteEnvStr_RegKey \
       'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !else
    !define WriteEnvStr_RegKey 'HKCU "Environment"'
  !endif
!endif
 
; AddToPath - Adds the given dir to the search path.
;        Input - head of the stack
;        Note - Win9x systems requires reboot
 
Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3
 
  # don't add if the path doesn't exist
  IfFileExists "$0\*.*" "" AddToPath_done
 
  ReadEnvStr $1 PATH
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  Push "$1;"
  Push "$0\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  GetFullPathName /SHORT $3 $0
  Push "$1;"
  Push "$3;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  Push "$1;"
  Push "$3\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
 
  Call IsNT
  Pop $1
  StrCmp $1 1 AddToPath_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" a
    FileSeek $1 -1 END
    FileReadByte $1 $2
    IntCmp $2 26 0 +2 +2 # DOS EOF
      FileSeek $1 -1 END # write over EOF
    FileWrite $1 "$\r$\nSET PATH=%PATH%;$3$\r$\n"
    FileClose $1
    SetRebootFlag true
    Goto AddToPath_done
 
  AddToPath_NT:
    ReadRegStr $1 ${WriteEnvStr_RegKey} "PATH"
    StrCpy $2 $1 1 -1 # copy last char
    StrCmp $2 ";" 0 +2 # if last char == ;
      StrCpy $1 $1 -1 # remove last char
    StrCmp $1 "" AddToPath_NTdoIt
      StrCpy $0 "$1;$0"
    AddToPath_NTdoIt:
      WriteRegExpandStr ${WriteEnvStr_RegKey} "PATH" $0
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
 
  AddToPath_done:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
 
; RemoveFromPath - Remove a given dir from the path
;     Input: head of the stack
 
Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6
 
  IntFmt $6 "%c" 26 # DOS EOF
 
  Call un.IsNT
  Pop $1
  StrCmp $1 1 unRemoveFromPath_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" r
    GetTempFileName $4
    FileOpen $2 $4 w
    GetFullPathName /SHORT $0 $0
    StrCpy $0 "SET PATH=%PATH%;$0"
    Goto unRemoveFromPath_dosLoop
 
    unRemoveFromPath_dosLoop:
      FileRead $1 $3
      StrCpy $5 $3 1 -1 # read last char
      StrCmp $5 $6 0 +2 # if DOS EOF
        StrCpy $3 $3 -1 # remove DOS EOF so we can compare
      StrCmp $3 "$0$\r$\n" unRemoveFromPath_dosLoopRemoveLine
      StrCmp $3 "$0$\n" unRemoveFromPath_dosLoopRemoveLine
      StrCmp $3 "$0" unRemoveFromPath_dosLoopRemoveLine
      StrCmp $3 "" unRemoveFromPath_dosLoopEnd
      FileWrite $2 $3
      Goto unRemoveFromPath_dosLoop
      unRemoveFromPath_dosLoopRemoveLine:
        SetRebootFlag true
        Goto unRemoveFromPath_dosLoop
 
    unRemoveFromPath_dosLoopEnd:
      FileClose $2
      FileClose $1
      StrCpy $1 $WINDIR 2
      Delete "$1\autoexec.bat"
      CopyFiles /SILENT $4 "$1\autoexec.bat"
      Delete $4
      Goto unRemoveFromPath_done
 
  unRemoveFromPath_NT:
    ReadRegStr $1 ${WriteEnvStr_RegKey} "PATH"
    StrCpy $5 $1 1 -1 # copy last char
    StrCmp $5 ";" +2 # if last char != ;
      StrCpy $1 "$1;" # append ;
    Push $1
    Push "$0;"
    Call un.StrStr ; Find `$0;` in $1
    Pop $2 ; pos of our dir
    StrCmp $2 "" unRemoveFromPath_done
      ; else, it is in path
      # $0 - path to add
      # $1 - path var
      StrLen $3 "$0;"
      StrLen $4 $2
      StrCpy $5 $1 -$4 # $5 is now the part before the path to remove
      StrCpy $6 $2 "" $3 # $6 is now the part after the path to remove
      StrCpy $3 $5$6
 
      StrCpy $5 $3 1 -1 # copy last char
      StrCmp $5 ";" 0 +2 # if last char == ;
        StrCpy $3 $3 -1 # remove last char
 
      WriteRegExpandStr ${WriteEnvStr_RegKey} "PATH" $3
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
 
  unRemoveFromPath_done:
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
 
!ifndef IsNT_KiCHiK
!define IsNT_KiCHiK
 
###########################################
#            Utility Functions            #
###########################################
 
; IsNT
; no input
; output, top of the stack = 1 if NT or 0 if not
;
; Usage:
;   Call IsNT
;   Pop $R0
;  ($R0 at this point is 1 or 0)
 
!macro IsNT un
Function ${un}IsNT
  Push $0
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  StrCmp $0 "" 0 IsNT_yes
  ; we are not NT.
  Pop $0
  Push 0
  Return
 
  IsNT_yes:
    ; NT!!!
    Pop $0
    Push 1
FunctionEnd
!macroend
!insertmacro IsNT ""
!insertmacro IsNT "un."
 
!endif ; IsNT_KiCHiK
 
; StrStr
; input, top of stack = string to search for
;        top of stack-1 = string to search in
; output, top of stack (replaces with the portion of the string remaining)
; modifies no other variables.
;
; Usage:
;   Push "this is a long ass string"
;   Push "ass"
;   Call StrStr
;   Pop $R0
;  ($R0 at this point is "ass string")
 
!macro StrStr un
Function ${un}StrStr
Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd
!macroend
!insertmacro StrStr ""
!insertmacro StrStr "un."
 
!endif ; _AddToPath_nsh 







!ifndef _AddToperl5lib_nsh
!define _AddToperl5lib_nsh
 
!verbose 3
!include "WinMessages.NSH"
!verbose 4
 
!ifndef WriteEnvStr_RegKey
  !ifdef ALL_USERS
    !define WriteEnvStr_RegKey \
       'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !else
    !define WriteEnvStr_RegKey 'HKCU "Environment"'
  !endif
!endif
 
; AddToperl5lib - Adds the given dir to the search perl5lib.
;        Input - head of the stack
;        Note - Win9x systems requires reboot
 
Function AddToperl5lib
  Exch $0
  Push $1
  Push $2
  Push $3
 
  # don't add if the perl5lib doesn't exist
  IfFileExists "$0\*.*" "" AddToperl5lib_done
 
  ReadEnvStr $1 PERL5LIB
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToperl5lib_done
  Push "$1;"
  Push "$0\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToperl5lib_done
  GetFullPathName /SHORT $3 $0
  Push "$1;"
  Push "$3;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToperl5lib_done
  Push "$1;"
  Push "$3\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToperl5lib_done
 
  Call IsNT
  Pop $1
  StrCmp $1 1 AddToperl5lib_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" a
    FileSeek $1 -1 END
    FileReadByte $1 $2
    IntCmp $2 26 0 +2 +2 # DOS EOF
      FileSeek $1 -1 END # write over EOF
    FileWrite $1 "$\r$\nSET PERL5LIB=%PERL5LIB%;$3$\r$\n"
    FileClose $1
    SetRebootFlag true
    Goto AddToperl5lib_done
 
  AddToperl5lib_NT:
    ReadRegStr $1 ${WriteEnvStr_RegKey} "PERL5LIB"
    StrCpy $2 $1 1 -1 # copy last char
    StrCmp $2 ";" 0 +2 # if last char == ;
      StrCpy $1 $1 -1 # remove last char
    StrCmp $1 "" AddToperl5lib_NTdoIt
      StrCpy $0 "$1;$0"
    AddToperl5lib_NTdoIt:
      WriteRegExpandStr ${WriteEnvStr_RegKey} "PERL5LIB" $0
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
 
  AddToperl5lib_done:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
 
; RemoveFromperl5lib - Remove a given dir from the perl5lib
;     Input: head of the stack
 
Function un.RemoveFromperl5lib
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6
 
  IntFmt $6 "%c" 26 # DOS EOF
 
  Call un.IsNT
  Pop $1
  StrCmp $1 1 unRemoveFromperl5lib_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" r
    GetTempFileName $4
    FileOpen $2 $4 w
    GetFullPathName /SHORT $0 $0
    StrCpy $0 "SET PERL5LIB=%PERL5LIB%;$0"
    Goto unRemoveFromperl5lib_dosLoop
 
    unRemoveFromperl5lib_dosLoop:
      FileRead $1 $3
      StrCpy $5 $3 1 -1 # read last char
      StrCmp $5 $6 0 +2 # if DOS EOF
        StrCpy $3 $3 -1 # remove DOS EOF so we can compare
      StrCmp $3 "$0$\r$\n" unRemoveFromperl5lib_dosLoopRemoveLine
      StrCmp $3 "$0$\n" unRemoveFromperl5lib_dosLoopRemoveLine
      StrCmp $3 "$0" unRemoveFromperl5lib_dosLoopRemoveLine
      StrCmp $3 "" unRemoveFromperl5lib_dosLoopEnd
      FileWrite $2 $3
      Goto unRemoveFromperl5lib_dosLoop
      unRemoveFromperl5lib_dosLoopRemoveLine:
        SetRebootFlag true
        Goto unRemoveFromperl5lib_dosLoop
 
    unRemoveFromperl5lib_dosLoopEnd:
      FileClose $2
      FileClose $1
      StrCpy $1 $WINDIR 2
      Delete "$1\autoexec.bat"
      CopyFiles /SILENT $4 "$1\autoexec.bat"
      Delete $4
      Goto unRemoveFromperl5lib_done
 
  unRemoveFromperl5lib_NT:
    ReadRegStr $1 ${WriteEnvStr_RegKey} "PERL5LIB"
    StrCpy $5 $1 1 -1 # copy last char
    StrCmp $5 ";" +2 # if last char != ;
      StrCpy $1 "$1;" # append ;
    Push $1
    Push "$0;"
    Call un.StrStr ; Find `$0;` in $1
    Pop $2 ; pos of our dir
    StrCmp $2 "" unRemoveFromperl5lib_done
      ; else, it is in perl5lib
      # $0 - perl5lib to add
      # $1 - perl5lib var
      StrLen $3 "$0;"
      StrLen $4 $2
      StrCpy $5 $1 -$4 # $5 is now the part before the perl5lib to remove
      StrCpy $6 $2 "" $3 # $6 is now the part after the perl5lib to remove
      StrCpy $3 $5$6
 
      StrCpy $5 $3 1 -1 # copy last char
      StrCmp $5 ";" 0 +2 # if last char == ;
        StrCpy $3 $3 -1 # remove last char
 
      WriteRegExpandStr ${WriteEnvStr_RegKey} "PERL5LIB" $3
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
 
  unRemoveFromperl5lib_done:
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
 
!ifndef IsNT_KiCHiK
!define IsNT_KiCHiK
 
###########################################
#            Utility Functions            #
###########################################
 
; IsNT
; no input
; output, top of the stack = 1 if NT or 0 if not
;
; Usage:
;   Call IsNT
;   Pop $R0
;  ($R0 at this point is 1 or 0)
 
!macro IsNT un
Function ${un}IsNT
  Push $0
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  StrCmp $0 "" 0 IsNT_yes
  ; we are not NT.
  Pop $0
  Push 0
  Return
 
  IsNT_yes:
    ; NT!!!
    Pop $0
    Push 1
FunctionEnd
!macroend
!insertmacro IsNT ""
!insertmacro IsNT "un."
 
!endif ; IsNT_KiCHiK
 
 
!endif ; _AddToperl5lib_nsh 

