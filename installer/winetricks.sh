tt#!/bin/sh
# Quick and dirty script to download and install various 
# redistributable runtime libraries
#
# Copyright 2007, 2008 Google (Dan Kegel, dank@kegel.com)
# Thanks to Detlef Riekenberg for lots of updates
# Thanks to Saulius Krasuckas for corrections and suggestions

# Default values for important settings if not already in environment.
# These settings should not need editing here.
WINE=${WINE:-wine}
WINEPREFIX=${WINEPREFIX:-$HOME/.wine}

# Internal variables; these locations are not too important
WINETRICKS_CACHE=$HOME/winetrickscache
# Default to hiding the directory, by popular demand
test -d "$WINETRICKS_CACHE" || WINETRICKS_CACHE=$HOME/.winetrickscache
WINETRICKS_TMP="$WINEPREFIX"/drive_c/winetrickstmp
mkdir -p "$WINETRICKS_TMP"
WINETRICKS_TMP_WIN='c:\winetrickstmp'

WINDIR="$WINEPREFIX/drive_c/windows"

# Which sourceforge mirror to use.  Rotate based on time, since 
# their mirror picker sometimes persistantly sends you to a broken
# mirror.
case `date +%S` in
*[01]) SOURCEFORGE=http://internap.dl.sourceforge.net/sourceforge ;;
*[23]) SOURCEFORGE=http://easynews.dl.sourceforge.net/sourceforge ;;
*)     SOURCEFORGE=http://downloads.sourceforge.net;;
esac

case "$1" in
-V|--version) 
  echo "Winetricks version 20090121.  (C) Dan Kegel.  LGPL."
  exit 0
  ;;
esac

die() {
  echo "$@"

  case x"$GUI" in
  x1) xmessage -center "               Winetricks error: $@                 " ;;
  *) ;;
  esac

  exit 1
}

if [ ! -x "`which "$WINE"`" ]
then
  die "Cannot find wine ($WINE)"
fi

#----------------------------------------------------------------

usage() {
    set +x
    echo "Usage: $0 [options] package [package] ..."
    echo "This script can help you prepare your system for Windows applications"
    echo "that mistakenly assume all users' systems have all the needed"
    echo "redistributable runtime libraries or fonts."
    echo "Some options require the Linux 'cabextract' program."
    echo ""
    echo "Options:"
    echo " -q         quiet.  You must have already agreed to the EULAs."
    echo " -v         verbose"
    echo " -V         display Version"
    echo "Packages:"    
    echo " art2kmin      MS Access 2000 runtime.  License required!"
    echo " colorprofile  Standard RGB color profile"
    echo " comctl32      MS common controls 5.80"
    echo " comctl32.ocx  MS comctl32.ocx and mscomctl.ocx, comctl32 wrappers for VB6"
    echo " controlpad    MS ActiveX Control Pad"
    echo " corefonts     MS Arial, Courier, Times fonts"
    echo " dcom98        MS DCOM, override the Wine implementation"
    echo " dirac0.8      the obsolete Dirac 0.8 directshow filter"
    echo " directx9      MS DirectX 9 user redistributable"
    echo " divx          divx video codec"
    echo " dotnet11      MS .NET 1.1 (requires Windows license)"
    echo " dotnet20      MS .NET 2.0 (requires Windows license)"
    echo " ffdshow       ffdshow video codecs"
    echo " flash         Adobe Flash Player ActiveX and firefox plugins"
    echo " fm20          MS Forms 2.0 Object Library"
    echo " fontfix       Fix bad fonts which cause crash in some apps (e.g. .net)."
    echo " gdiplus       MS gdiplus.dll (from powerpoint viewer)"
    echo " gecko         The HTML rendering Engine (Mozilla)"
    echo " hosts         Adds empty C:\windows\system32\drivers\etc\{hosts,services} files"
    echo " icodecs       Intel Codecs (Indeo)"
    echo " jet40         MS Jet 4.0 Service Pack 8"
    echo " liberation    Red Hat Liberation fonts (Sans, Serif, Mono)"
    echo " mdac25        MS MDAC 2.5: Microsoft ODBC drivers, etc."
    echo " mdac27        MS MDAC 2.7"
    echo " mdac28        MS MDAC 2.8"
    echo " mfc40         MS mfc40 (Microsoft Foundation Classes from Visual C++ 4)"
    echo " mfc42         MS mfc42 (see vcrun6 below)"
    echo " mono20        mono-2.0.1"
    echo " mono22        mono-2.2"
    echo " msi2          MS Installer 2.0"
    echo " mshflxgd      MS Hierarchical Flex Grid Control"
    echo " msls31        MS Line Services 3.1 (needed by native riched?)"
    echo " msmask        MS Masked Edit Control"
    echo " msscript      MS Script Control"
    echo " msxml3        MS XML version 3"
    echo " msxml4        MS XML version 4"
    echo " msxml6        MS XML version 6" 
    echo " ogg           ogg filters/codecs: flac, theora, speex, vorbis, schroedinger"
    echo " ole2          MS 16 bit OLE"
    echo " pdh           MS pdh.dll (Performance Data Helper)"
    echo " quicktime72   Apple Quicktime 7.2"
    echo " riched20      MS riched20 and riched32"
    echo " riched30      MS riched30"
    echo " tahoma        MS Tahoma font (not part of corefonts)"
    echo " urlmon        MS urlmon.dll"
    echo " vb3run        MS Visual Basic 3 runtime"
    echo " vb4run        MS Visual Basic 4 runtime"
    echo " vb5run        MS Visual Basic 5 runtime"
    echo " vb6run        MS Visual Basic 6 runtime"
    echo " vcrun6        MS Visual C++ 6 sp4 libraries (mfc42, msvcp60, msvcrt)"
    echo " vcrun2003     MS Visual C++ 2003 libraries (mfc71,msvcp71,msvcr71)"
    echo " vcrun2005     MS Visual C++ 2005 libraries (mfc80,msvcp80,msvcr80)"
    echo " vcrun2005sp1  MS Visual C++ 2005 sp1 libraries"
    echo " vcrun2008     MS Visual C++ 2008 libraries (mfc90,msvcp90,msvcr90)"
    echo " vjrun20       MS Visual J# 2.0 libraries (requires dotnet20)"
    echo " wininet       MS wininet.dll (requires Windows license)"
    echo " wmp9          MS Windows Media Player 9 (requires Windows license)"
    echo " wmp10         MS Windows Media Player 10 (requires Windows license)"
    echo " sapi51        MS Windows Text to Speech engine 5.1 and free voices"
    echo " sapi4         MS Windows Text to speech engine 4 without voices"
    echo " sapi4_us_voices L&H US English voices SAPI4"
    echo " sapi4_uk_voices L&H UK English voices SAPI4"
    echo " wsh56         MS Windows Scripting Host 5.6"
    echo " wsh56js       MS Windows scripting 5.6, jscript only, no cscript"
    echo " wsh56vb       MS Windows scripting 5.6, vbscript only, no cscript"
    echo " xvid          xvid video codec"
    echo "Apps:"
    echo " autohotkey    Autohotkey (open source gui scripting language)"
    echo " firefox3      Firefox Version 3"
    echo " ie6           Microsoft Internet Explorer 6.0"
    echo " kde           KDE for Windows installer"
    echo " mpc           Media Player Classic"
    echo " vlc           VLC media player"
    echo "Pseudopackages:"
    echo " allfonts      All listed fonts (corefonts, tahoma, liberation)"
    echo " allcodecs     All listed codecs (xvid, ffdshow, icodecs)"
    echo " fakeie6       Set registry to claim IE6sp1 is installed"
    echo " native_mdac   Override odbc32 and odbccp32"
    echo " native_oleaut32 Override oleaut32"
    echo " nt40          Set windows version to nt40"
    echo " win98         Set windows version to Windows 98"
    echo " win2k         Set windows version to Windows 2000"
    echo " winxp         Set windows version to Windows XP"
    echo " vista         Set windows version to Windows Vista"
    echo " winver=       Set windows version to default (winxp)"
    echo " volnum        Rename drive_c to harddiskvolume0 (needed by some installers)"
}

#----------------------------------------------------------------
# Trivial GUI just to handle case where user tries running without commandline

# Checks for known desktop environments
# set variable DE to the desktop environments name, lowercase

detectDE() {
    if [ x"$KDE_FULL_SESSION" = x"true" ]
    then 
        DE=kde
    elif [ x"$GNOME_DESKTOP_SESSION_ID" != x"" ]
    then
        DE=gnome
    elif [ x"$DISPLAY" != x"" ]
    then
        DE=x
    else 
        DE=none
    fi
}

kde_showmenu() {
    title="$1"
    shift
    text="$1"
    shift
    col1name="$1"
    shift
    col2name="$1"
    shift
    while test $# -gt 0
    do
        args="$args $1 $1 off"
        shift
    done
    kdialog --title "$title" --separate-output --checklist "$text" $args
}

x_showmenu() {
    title="$1"
    shift
    text="$1"
    shift
    col1name="$1"
    shift
    col2name="$1"
    shift
    if test $# -gt 0
    then
        args="$1"
        shift
    fi
    while test $# -gt 0
    do
        args="$args,$1"
        shift
    done
    (echo "$title"; echo ""; echo "$text") | \
    xmessage -print -file - -buttons "Cancel,$args" | sed 's/Cancel//'
}

showmenu()
{
    detectDE
    case $DE in
    kde) kde_showmenu "$@" ;;
    gnome|x) x_showmenu "$@" ;;
    none) usage 1>&2; exit 1;;
    esac
}
 
dogui()
{
  detectDE
  if [ $DE = gnome ]
  then
    echo "zenity --title 'Select a package to install' --text 'Install?' --list --checklist --column '' --column Package --column Description --height 440 --width 600 \\" > "$WINETRICKS_TMP"/zenity.sh
    usage | grep '^ [a-z]' | sed 's/^ \([^ ]*\) *\(.*\)/FALSE "\1" '"'\2'/" | sed 's/$/ \\/' >> $WINETRICKS_TMP/zenity.sh
    export todo="`sh "$WINETRICKS_TMP"/zenity.sh | tr '|' ' '`"
  else
    packages=`usage | awk '/^ [a-z]/ {print $1}'`
    export todo="`showmenu "winetricks" "Select a package to install" "Install?" "Package" $packages`"
  fi

  if test "$todo"x = x
  then
     exit 0
  fi
}

#----------------------------------------------------------------

GUI=0
case x"$1" in
x) GUI=1; dogui ; set $todo ;;
x-h|x--help|xhelp) usage ; exit 1 ;;
esac
test -d "$WINEPREFIX" || $WINE cmd /c echo yes > /dev/null 2>&1
mkdir -p "$WINETRICKS_CACHE"
olddir=`pwd`
# Clean up after failed runs, if needed
rm -rf "$WINETRICKS_TMP"/*

# The folder-name is localized!
programfilesdir_win="`unset WINEDEBUG; $WINE cmd.exe /c echo "%ProgramFiles%"`"
test x"$programfilesdir_win" != x || die "$WINE cmd.exe /c echo '%ProgramFiles%' returned empty string"
programfilesdir_unix="`unset WINEDEBUG; $WINE winepath -u "$programfilesdir_win"`"
test x"$programfilesdir_unix" != x || die "winepath -u $programfilesdir_win returned empty string"

# (Fixme: get fonts path from SHGetFolderPath
# See also http://blogs.msdn.com/oldnewthing/archive/2003/11/03/55532.aspx)
#
# Did the user rename Fonts to fonts?
if test ! -d "$WINDIR"/Fonts && test -d "$WINDIR"/fonts 
then
    winefontsdir="$WINDIR"/fonts
else
    winefontsdir="$WINDIR"/Fonts
fi

# Mac folks tend to not have sha1sum, but we can make do with openssl
if [ -x "`which sha1sum`" ]
then
   SHA1SUM="sha1sum"
else
   SHA1SUM="openssl dgst -sha1"
fi

if [ ! -x "`which "cabextract"`" ]
then
  echo "Cannot find cabextract.  Please install it (e.g. 'sudo apt-get install cabextract' or 'sudo yum install cabextract')."
fi

#-----  Helpers  ------------------------------------------------

# Execute with error checking
try() {
    # "VAR=foo try cmd" fails to put VAR in the environment
    # with some versions of bash if try is a shell function?!
    # Adding this explicit export works around it.
    export WINEDLLOVERRIDES
    echo Executing "$@"
    "$@"
    status=$?
    if test $status -ne 0
    then
        die "Note: command '$@' returned status $status.  Aborting."
    fi
}

# verify an sha1sum
verify_sha1sum() {
    wantsum=$1
    file=$2
   
    gotsum=`$SHA1SUM < $file | sed 's/ .*//'`
    if [ "$gotsum"x != "$wantsum"x ]
    then
       die "sha1sum mismatch!  Rename $file and try again."
    fi
}

# Download a file
# Usage: package url [sha1sum [filename]]
# Caches downloads in winetrickscache/$package
download() {
    if [ "$4"x != ""x ]
    then
        file="$4"
    else
        file=`basename "$2"`
    fi
    cache="$WINETRICKS_CACHE/$1"
    mkdir -p "$cache"
    if test ! -f "$cache/$file"
    then
        cd "$cache"
        # Mac folks tend to have curl rather than wget
        # On Mac, 'which' doesn't return good exit status
        # Need to jam in --header "Accept-Encoding: gzip,deflate" else
        # redhat.com decompresses liberation-fonts.tar.gz!
        if [ -x "`which wget`" ]
        then
           # Use -nd to insulate ourselves from people who set -x in WGETRC
           # [*] --retry-connrefused works around the broken sf.net mirroring
           # system when downloading corefonts
           # [*] --read-timeout is useful on the adobe server that doesn't
           # close the connection unless you tell it to (control-C or closing
           # the socket)
           try wget -nd -c --read-timeout=300 --retry-connrefused --header "Accept-Encoding: gzip,deflate" "$2"
        else
           # curl doesn't get filename from the location given by the server!
           # fortunately, we know it
           try curl -L -o "$file" -C - --header "Accept-Encoding: gzip,deflate" "$2"
        fi
        cd "$olddir"
    fi
    if [ "$3"x != ""x ]
    then
	verify_sha1sum $3  "$cache/$file"
    fi
}

set_winver() {
    echo "Setting Windows version to $1"
    cat > "$WINETRICKS_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine]
"Version"="$1"

_EOF_
    try $WINE regedit "$WINETRICKS_TMP"/set-winver.reg
}

unset_winver() {
    echo "Clearing Windows version back to default"
    cat > "$WINETRICKS_TMP"/unset-winver.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine]
"Version"=-

_EOF_
    try $WINE regedit "$WINETRICKS_TMP"/unset-winver.reg
}

override_dlls() {
    mode=$1
    shift
    echo Using $mode override for following DLLs: $@
    cat > "$WINETRICKS_TMP"/override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
_EOF_
    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$WINDIR"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac
        echo "\"$1\"=\"$mode\"" >> "$WINETRICKS_TMP"/override-dll.reg
	shift
    done

    try $WINE regedit "$WINETRICKS_TMP"/override-dll.reg
    rm "$WINETRICKS_TMP"/override-dll.reg
}

override_app_dlls() {
    app=$1
    shift
    mode=$1
    shift
    echo Using $mode override for following DLLs when running $app: $@
    ( 
    echo REGEDIT4 
    echo "" 
    echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$app\\DllOverrides]" 
    ) > "$WINETRICKS_TMP"/override-dll.reg 

    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$WINDIR"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac
        echo "\"$1\"=\"$mode\"" >> "$WINETRICKS_TMP"/override-dll.reg
	shift
    done

    try $WINE regedit "$WINETRICKS_TMP"/override-dll.reg
    rm "$WINETRICKS_TMP"/override-dll.reg
}

register_font() {
    file=$1
    shift
    font=$1
    #echo "Registering $file as $font"
    cat > "$WINETRICKS_TMP"/register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
"$font"="$file"
_EOF_
    # too verbose
    #try $WINE regedit "$WINETRICKS_TMP"/register-font.reg
    $WINE regedit "$WINETRICKS_TMP"/register-font.reg
}

#----- One function per package, in alphabetical order ----------

load_art2kmin() {
    download . http://download.microsoft.com/download/office2000dev/art2kmin/1/win98/en-us/art2kmin.exe 73be2622254d1f857a204a03f068787542b985e9
    try $WINE "$WINETRICKS_CACHE"/art2kmin.exe
    cd "$WINEPREFIX/drive_c/ART2KMin Setup"
    try $WINE Setup.exe INSTALLPFILES=1 /wait $WINETRICKS_QUIET
    cd "$olddir"
}

#----------------------------------------------------------------

load_autohotkey() {
    download . http://www.autohotkey.net/programs/AutoHotkey104706_Install.exe 3d3d8845473dea477d6983d063f0afc9999d880f
    try $WINE "$WINETRICKS_CACHE"/AutoHotkey104706_Install.exe $WINETRICKS_S
}

#----------------------------------------------------------------

load_cc580() {
    # http://www.microsoft.com/downloads/details.aspx?familyid=6f94d31a-d1e0-4658-a566-93af0d8d4a1e
    download . http://download.microsoft.com/download/platformsdk/redist/5.80.2614.3600/w9xnt4/en-us/cc32inst.exe 94c3c494258cc54bd65d2f0153815737644bffde

    try $WINE "$WINETRICKS_CACHE"/cc32inst.exe "/T:`$WINE winepath -w "$WINETRICKS_TMP"`" /c $WINETRICKS_QUIET
    try $WINE "$WINETRICKS_TMP"/comctl32.exe
    try $WINE "$WINDIR"/temp/x86/50ComUpd.Exe "/T:`$WINE winepath -w "$WINETRICKS_TMP"`" /c $WINETRICKS_QUIET
    cp "$WINETRICKS_TMP"/comcnt.dll "$WINDIR"/system32/comctl32.dll

    override_dlls native,builtin comctl32
}

#----------------------------------------------------------------

load_comctl32ocx() {
    # http://www.microsoft.com/downloads/details.aspx?FamilyID=25437D98-51D0-41C1-BB14-64662F5F62FE
    download . http://download.microsoft.com/download/3/a/5/3a5925ac-e779-4b1c-bb01-af67dc2f96fc/VisualBasic6-KB896559-v1-ENU.exe f52cf2034488235b37a1da837d1c40eb2a1bad84

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/VisualBasic6-KB896559-v1-ENU.exe
    cp "$WINETRICKS_TMP"/mscomctl.ocx "$WINDIR"/system32/mscomctl.ocx
    cp "$WINETRICKS_TMP"/comctl32.ocx "$WINDIR"/system32/comctl32.ocx
    try $WINE regsvr32 comctl32.ocx
    try $WINE regsvr32 mscomctl.ocx
}

#----------------------------------------------------------------

load_colorprofile() {
    download . http://download.microsoft.com/download/whistler/hwdev1/1.0/wxp/en-us/ColorProfile.exe 6b72836b32b343c82d0760dff5cb51c2f47170eb
    try unzip -o $WINETRICKS_UNIXQUIET -d "$WINETRICKS_TMP" "$WINETRICKS_CACHE"/ColorProfile.exe
    mkdir -p "$WINDIR"/system32/spool/drivers/color
    cp -f "$WINETRICKS_TMP/sRGB Color Space Profile.icm" "$WINDIR"/system32/spool/drivers/color
}

#----------------------------------------------------------------

load_controlpad() {
    # http://msdn.microsoft.com/en-us/library/ms968493.aspx
    # Fixes error "Failed to load UniText..."
    download . http://download.microsoft.com/download/activexcontrolpad/install/4.0.0.950/win98mexp/en-us/setuppad.exe 8921e0f52507ca6a373c94d222777c750fb48af7
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/setuppad.exe
    echo "If setup says 'Unable to start DDE ...', press Ignore"
    echo "If setup says 'Requires IE 3.0', run 'winetricks wsh56'"
    try $WINE "$WINETRICKS_TMP"/setup $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_corefonts() {
    # See http://corefonts.sf.net
    # TODO: let user pick mirror,
    # see http://corefonts.sourceforge.net/msttcorefonts-2.0-1.spec for how
    # TODO: add more fonts
    
    # Added More Fonts (see msttcorefonts)
    # [*] Pointed download locations to sites that actually contained the
    # fonts to download (as of 04-03-2008)			    
    #download . $SOURCEFORGE/corefonts/andale32.exe c4db8cbe42c566d12468f5fdad38c43721844c69
    download . $SOURCEFORGE/corefonts/arial32.exe 6d75f8436f39ab2da5c31ce651b7443b4ad2916e
    download . $SOURCEFORGE/corefonts/arialb32.exe d45cdab84b7f4c1efd6d1b369f50ed0390e3d344
    download . $SOURCEFORGE/corefonts/comic32.exe 2371d0327683dcc5ec1684fe7c275a8de1ef9a51
    download . $SOURCEFORGE/corefonts/courie32.exe 06a745023c034f88b4135f5e294fece1a3c1b057
    download . $SOURCEFORGE/corefonts/georgi32.exe 90e4070cb356f1d811acb943080bf97e419a8f1e
    download . $SOURCEFORGE/corefonts/impact32.exe 86b34d650cfbbe5d3512d49d2545f7509a55aad2
    download . $SOURCEFORGE/corefonts/times32.exe 20b79e65cdef4e2d7195f84da202499e3aa83060
    download . $SOURCEFORGE/corefonts/trebuc32.exe 50aab0988423efcc9cf21fac7d64d534d6d0a34a
    download . $SOURCEFORGE/corefonts/verdan32.exe f5b93cedf500edc67502f116578123618c64a42a
    download . $SOURCEFORGE/corefonts/webdin32.exe 2fb4a42c53e50bc70707a7b3c57baf62ba58398f

    # Natively installed versions of these fonts will cause the installers
    # to exit silently. Because there are apps out there that depend on the
    # files being present in the Windows font directory we use cabextract
    # to obtain the files and register the fonts by hand.

    # Andale needs a FontSubstitutes entry
    # try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/andale32.exe

    # Display EULA
    test x"$WINETRICKS_QUIET" = x"" || try $WINE "$WINETRICKS_CACHE"/arial32.exe $WINETRICKS_QUIET

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/arial32.exe
    try cp -f "$WINETRICKS_TMP"/Arial*.TTF "$winefontsdir"
    register_font Arial.TTF "Arial (TrueType)"
    register_font Arialbd.TTF "Arial Bold (TrueType)"
    register_font Arialbi.TTF "Arial Bold Italic (TrueType)"
    register_font Ariali.TTF "Arial Italic (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/arialb32.exe
    try cp -f "$WINETRICKS_TMP"/AriBlk.TTF "$winefontsdir"
    register_font AriBlk.TTF "Arial Black (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/comic32.exe
    try cp -f "$WINETRICKS_TMP"/Comic*.TTF "$winefontsdir"
    register_font Comic.TTF "Comic Sans MS (TrueType)"
    register_font Comicbd.TTF "Comic Sans MS Bold (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/courie32.exe
    try cp -f "$WINETRICKS_TMP"/cour*.ttf "$winefontsdir"
    register_font Cour.TTF "Courier New (TrueType)"
    register_font CourBD.TTF "Courier New Bold (TrueType)"
    register_font CourBI.TTF "Courier New Bold Italic (TrueType)"
    register_font Couri.TTF "Courier New Italic (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/georgi32.exe
    try cp -f "$WINETRICKS_TMP"/Georgia*.TTF "$winefontsdir"
    register_font Georgia.TTF "Georgia (TrueType)"
    register_font Georgiab.TTF "Georgia Bold (TrueType)"
    register_font Georgiaz.TTF "Georgia Bold Italic (TrueType)"
    register_font Georgiai.TTF "Georgia Italic (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/impact32.exe
    try cp -f "$WINETRICKS_TMP"/Impact.TTF "$winefontsdir"
    register_font Impact.TTF "Impact (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/times32.exe
    try cp -f "$WINETRICKS_TMP"/Times*.TTF "$winefontsdir"
    register_font Times.TTF "Times New Roman (TrueType)"
    register_font Timesbd.TTF "Times New Roman Bold (TrueType)"
    register_font Timesbi.TTF "Times New Roman Bold Italic (TrueType)"
    register_font Timesi.TTF "Times New Roman Italic (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/trebuc32.exe
    try cp -f "$WINETRICKS_TMP"/trebuc*.ttf "$winefontsdir"
    register_font Trebuc.TTF "Trebucet MS (TrueType)"
    register_font Trebucbd.TTF "Trebucet MS Bold (TrueType)"
    register_font Trebucbi.TTF "Trebucet MS Bold Italic (TrueType)"
    register_font Trebucit.TTF "Trebucet MS Italic (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/verdan32.exe
    try cp -f "$WINETRICKS_TMP"/Verdana*.TTF "$winefontsdir"
    register_font Verdana.TTF "Verdana (TrueType)"
    register_font Verdanab.TTF "Verdana Bold (TrueType)"
    register_font Verdanaz.TTF "Verdana Bold Italic (TrueType)"
    register_font Verdanai.TTF "Verdana Italic (TrueType)"

    try cabextract -q --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/webdin32.exe
    try cp -f "$WINETRICKS_TMP"/Webdings.TTF "$winefontsdir"
    register_font Webdings.TTF "Webdings (TrueType)"
}

#----------------------------------------------------------------

load_dirac08() {
    download . http://codecpack.nl/dirac_dsfilter_080.exe aacfcddf6b2636de5f0a50422ba9155e395318af
    try $WINE "$WINETRICKS_CACHE"/dirac_dsfilter_080.exe $WINETRICKS_SILENT
}

#----------------------------------------------------------------
load_sapi51() {
    download . https://raw.githubusercontent.com/NicklasMCHD/OpenSAPI/master/installer/sapi.msi
    set_winver win2k
    try $WINE msiexec /i $WINETRICKS_CACHE/sapi.msi
    unset_winver
}
#----------------------------------------------------------------
load_sapi4() {
    download . https://raw.githubusercontent.com/NicklasMCHD/OpenSAPI/master/installer/sapi4.exe
    set_winver win2k
    try $WINE "$WINETRICKS_CACHE"/sapi4.exe $WINETRICKS_SILENT
    unset_winver
}
#----------------------------------------------------------------
load_sapi4_uk_voices() {
    download . https://raw.githubusercontent.com/NicklasMCHD/OpenSAPI/master/voices/uk_eng_sapi4_voices.exe 
    set_winver win2k
    try $WINE "$WINETRICKS_CACHE"/uk_eng_sapi4_voices.exe  $WINETRICKS_SILENT
    unset_winver
}
#----------------------------------------------------------------
load_sapi4_us_voices() {
    download . https://raw.githubusercontent.com/NicklasMCHD/OpenSAPI/master/voices/us_eng_sapi4_voices.exe 
    set_winver win2k
    try $WINE "$WINETRICKS_CACHE"/us_eng_sapi4_voices.exe  $WINETRICKS_SILENT
    unset_winver
}
#----------------------------------------------------------------

load_directx9() {
    # Aug 2008 DirectX 9c User Redistributable
    # http://www.microsoft.com/downloads/details.aspx?familyid=886ACB56-C91A-4A8E-8BB8-9F20F1244A8E&displaylang=en
    download . http://download.microsoft.com/download/0/d/3/0d307649-9967-49fa-ab27-61f11024e97f/directx_nov2008_redist.exe 0cbe95cacd413208a9f38e31b602015408025019
    # Stefan suggested that, when installing, one should override as follows:
    # 1) use builtin wintrust (we don't run native properly somehow?)
    # 2) disable mscoree (else if it's present some module misbehaves?)
    # 3) override native any directx DLL whose Wine version doesn't register itself well yet
    # For #3, I have no idea which DLLs don't register themselves well yet,
    # so I'm just listing a few of the basic ones.  Let's whittle that
    # list down as soon as we can.  
    set_winver win2k
    WINEDLLOVERRIDES="wintrust=b,mscoree=,ddraw,d3d8,d3d9,dsound,dinput=n" \
       try $WINE "$WINETRICKS_CACHE"/directx_nov2008_redist.exe /t:"$WINETRICKS_TMP_WIN" $WINETRICKS_QUIET

    # How many of these do we really need?
    # We should probably remove most of these...?
    override_dlls native d3dim d3drm d3dx8 d3dx9_24 d3dx9_25 d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29
    override_dlls native d3dx9_30 d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 d3dx9_36 d3dxof
    override_dlls native dciman32 ddrawex devenum dmband dmcompos dmime dmloader dmscript dmstyle 
    override_dlls native dmsynth dmusic dmusic32 dnsapi dplay dplayx dpnaddr dpnet dpnhpast dpnlobby 
    override_dlls native dswave dxdiagn mscoree msdmo qcap quartz streamci
    override_dlls builtin d3d8 d3d9 dinput dinput8 dsound
    
    try $WINE "$WINETRICKS_TMP_WIN"/DXSETUP.exe

    unset_winver
}

#----------------------------------------------------------------

load_divx() {
    # 6.8.2: 02203fdc4dddd13e789c39b22902837da31d2a1d ?
    # 6.8.2: e36bf87c1675d0cf9169839bc0cd8f866b9db026 as of 4 jun 2008 as http://download.divx.com/divx/DivXInstaller.exe
    # 6.8.3: f4f4387ef89316aea440a29f3e24c1f1945e14af as of 20 jun 2008 as http://download.divx.com/divx/abt/b1/DivXInstaller.exe
    # 6.8.4: c5fcb1465a1bb24d1c104c2588fdb6706d1e1476 as of 10 Jul 2008 as http://download.divx.com/divx/abt/b1/DivXInstaller.exe
    # 6.8.4: d28a2b041f4af45d22c4dedfe7608f2958cf997d as of 23 Aug 2008 as http://download.divx.com/divx/DivXInstaller.exe
    download divx-6.8.4-1 http://download.divx.com/divx/DivXInstaller.exe d28a2b041f4af45d22c4dedfe7608f2958cf997d

    try $WINE "$WINETRICKS_CACHE"/divx-6.8.4-1/DivXInstaller $WINETRICKS_SILENT
}

#----------------------------------------------------------------

load_dcom98() {
    # Install native dcom per http://wiki.winehq.org/NativeDcom
    # to avoid http://bugs.winehq.org/show_bug.cgi?id=4228
    download . http://download.microsoft.com/download/d/1/3/d13cd456-f0cf-4fb2-a17f-20afc79f8a51/DCOM98.EXE aff002bd03f17340b2bef2e6b9ea8e3798e9ccc1

    # Pick win98 so we can install native dcom
    set_winver win98

    # Avoid "err:setupapi:SetupDefaultQueueCallbackA copy error 5 ..."
    # Those messages are suspect, probably shouldn't be err's.
    rm -f "$WINDIR"/system32/ole32.dll
    rm -f "$WINDIR"/system32/olepro32.dll
    rm -f "$WINDIR"/system32/oleaut32.dll
    rm -f "$WINDIR"/system32/rpcrt4.dll

    # Normally only need to override ole32, but overriding advpack
    # as well gets us the correct exit status.
    WINEDLLOVERRIDES="ole32,advpack=n" try $WINE "$WINETRICKS_CACHE"/DCOM98.EXE $WINETRICKS_QUIET

    # Set native DCOM by default for all apps (ok, this might be overkill)
    override_dlls native,builtin ole32 oleaut32 rpcrt4

    # but not for a few builtin apps that don't like it
    override_app_dlls services.exe builtin ole32 oleaut32 rpcrt4
    override_app_dlls wineboot.exe builtin ole32 oleaut32 rpcrt4
    override_app_dlls winedevice.exe builtin ole32 oleaut32 rpcrt4

    # and undo version win98
    unset_winver
}

#----------------------------------------------------------------

load_dotnet11() {
    DOTNET_INSTALL_DIR="$WINDIR/Microsoft.NET/Framework/v1.1.4322" 

    # need corefonts, else installer crashes
    load_corefonts

    # http://www.microsoft.com/downloads/details.aspx?FamilyId=262D25E3-F589-4842-8157-034D1E7CF3A3
    download dotnet11 http://download.microsoft.com/download/a/a/c/aac39226-8825-44ce-90e3-bf8203e74006/dotnetfx.exe 16a354a2207c4c8846b617cbc78f7b7c1856340e
    try $WINE "$WINETRICKS_CACHE"/dotnet11/dotnetfx.exe $WINETRICKS_QUIET
} 

#----------------------------------------------------------------

load_dotnet20() {
    # Recipe from http://bugs.winehq.org/show_bug.cgi?id=10467#c57
    test -d "$WINDIR/gecko" || load_gecko
    set_winver win2k
    # See http://kegel.com/wine/l_intl-sh.txt for how l_intl.nls was generated
    download dotnet20 http://kegel.com/wine/l_intl.nls
    try cp -f "$WINETRICKS_CACHE"/dotnet20/l_intl.nls "$WINDIR/system32/"

    # http://www.microsoft.com/downloads/details.aspx?FamilyID=0856eacb-4362-4b0d-8edd-aab15c5e04f5
    download dotnet20 http://download.microsoft.com/download/5/6/7/567758a3-759e-473e-bf8f-52154438565a/dotnetfx.exe a3625c59d7a2995fb60877b5f5324892a1693b2a
    if [ "$WINETRICKS_QUIET"x = ""x ]
    then
       try $WINE "$WINETRICKS_CACHE"/dotnet20/dotnetfx.exe 
    else
       try $WINE "$WINETRICKS_CACHE"/dotnet20/dotnetfx.exe /q /c:"install.exe /q"
    fi
    unset_winver
} 

#----------------------------------------------------------------

# Fake IE per workaround in http://bugs.winehq.org/show_bug.cgi?id=3453
# Just the first registry key works for most apps.
# The App Paths part is required by a few apps, like Quickbooks Pro;
# see http://windowsxp.mvps.org/ie/qbooks.htm
set_fakeie6() {

    cat > "$WINETRICKS_TMP"/fakeie6.reg <<"_EOF_"
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer]
"Version"="6.0.2900.2180"

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\App Paths\IEXPLORE.EXE]
_EOF_

    echo -n '@="' >>"$WINETRICKS_TMP"/fakeie6.reg
    echo -n "${programfilesdir_win}" | sed "s/\\\\/\\\\\\\\/" >>"$WINETRICKS_TMP"/fakeie6.reg
    echo '\\\\Internet Explorer\\\\iexplore.exe"' >>"$WINETRICKS_TMP"/fakeie6.reg

    echo -n '"PATH"="' >>"$WINETRICKS_TMP"/fakeie6.reg
    echo -n "${programfilesdir_win}" | sed "s/\\\\/\\\\\\\\/" >>"$WINETRICKS_TMP"/fakeie6.reg
    echo '\\\\Internet Explorer"' >>"$WINETRICKS_TMP"/fakeie6.reg

    try $WINE regedit "$WINETRICKS_TMP"/fakeie6.reg

    # On old wineprefixes iexplore.exe is not created. Create a fake dll using
    # shdocvw.dll that should have similar VERSIONINFO.
    if [ ! -f "$programfilesdir_unix/Internet Explorer/iexplore.exe" ]; then
        echo "You have an old wineprefix without iexplore.exe. Will create a fake now"
        if [ ! -d "$programfilesdir_unix/Internet Explorer/iexplore.exe" ]; then
            try mkdir "$programfilesdir_unix/Internet Explorer";
        fi
        try cp -f "$WINDIR/system32/shdocvw.dll" "$programfilesdir_unix/Internet Explorer/iexplore.exe"
    fi
}

#----------------------------------------------------------------

load_firefox3() {
    # Firefox 3
    download . "http://releases.mozilla.org/pub/mozilla.org/firefox/releases/3.0.5/win32/en-US/Firefox%20Setup%203.0.5.exe" a3bc99e32fa07fc5db3d2dfcddbfdc05400ec3a0 "Firefox Setup 3.0.5.exe"
    if [ "$WINETRICKS_QUIET"x = ""x ]
    then
       try $WINE "$WINETRICKS_CACHE"/"Firefox Setup 3.0.5.exe" 
    else
       try $WINE "$WINETRICKS_CACHE"/"Firefox Setup 3.0.5.exe" -ms
    fi
}

#----------------------------------------------------------------

load_ffdshow() {
    # ffdshow
    download . $SOURCEFORGE/ffdshow-tryout/ffdshow_beta5_rev2033_20080705_clsid.exe 6da6837e2f400923ff5294a6591a88a3eee5ee40
    try $WINE "$WINETRICKS_CACHE"/ffdshow_beta5_rev2033_20080705_clsid.exe $WINETRICKS_SILENT
}

#----------------------------------------------------------------

load_flash() {
    # www.adobe.com/products/flashplayer/

    # Active X plugin
    # http://blogs.adobe.com/psirt/2008/03/preparing_for_april_flash_play.html
    # http://fpdownload.macromedia.com/get/flashplayer/current/licensing/win/install_flash_player_active_x.msi 
    # 2008-04-01: old version sha1sum f4dd1c0c715b791db2c972aeba90d3b78372996a
    # 2008-04-18: new version sha1sum 04ac79c4f1eb1e1ca689f27fa71f12bb5cd11cc2
    # Version 10 http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_ax.exe
    # 2008-11-27: 10 sha1sum 7f6850ae815e953311bb94a8aa9d226f97a646dd  

    download . http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_ax.exe 7f6850ae815e953311bb94a8aa9d226f97a646dd
    try $WINE "$WINETRICKS_CACHE"/install_flash_player_ax.exe $WINETRICKS_S

    # Mozilla / Firefox plugin
    # 2008-07-22: sha1sum 1e6f7627784a5b791e99ae9ad63133dc11c7940b
    # 2008-11-27: sha1sum 20ec0300a8cae19105c903a7ec6c0801e016beb0
    download . http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player.exe 20ec0300a8cae19105c903a7ec6c0801e016beb0
    try $WINE "$WINETRICKS_CACHE"/install_flash_player.exe $WINETRICKS_S
}

#----------------------------------------------------------------

load_fontfix() {
    # some versions of ukai.ttf and uming.ttf crash .net and picasa
    # See http://bugs.winehq.org/show_bug.cgi?id=7098#c9
    # Could fix globally, but that needs root, so just fix for wine
    if test -f /usr/share/fonts/truetype/arphic/ukai.ttf 
    then
        gotsum=`$SHA1SUM < /usr/share/fonts/truetype/arphic/ukai.ttf | sed 's/ .*//'`
        # FIXME: do all affected versions of the font have same sha1sum as Gutsy?  Seems unlikely.
        if [ "$gotsum"x = "96e1121f89953e5169d3e2e7811569148f573985"x ]
        then
            download . http://apt.debian.org.tw/pool/t/ttf-arphic-ukai/ttf-arphic-ukai_0.1.20060108.orig.tar.gz 46cc7b67b6117a7e161c1a573502c0bf2b09cbdc  
            cd "$WINETRICKS_TMP/"
	    tar -xzf "$WINETRICKS_CACHE/ttf-arphic-ukai_0.1.20060108.orig.tar.gz"
	    try mv ttf-arphic-ukai-0.1.20060108/*.ttf "$winefontsdir"
            cd "$olddir"
        fi
    fi

    if test -f /usr/share/fonts/truetype/arphic/uming.ttf 
    then
        gotsum=`$SHA1SUM < /usr/share/fonts/truetype/arphic/uming.ttf | sed 's/ .*//'`
        if [ "$gotsum"x = "2a4f4a69e343c21c24d044b2cb19fd4f0decc82c"x ]
        then
            download . http://apt.debian.org.tw/pool/t/ttf-arphic-uming/ttf-arphic-uming_0.1.20060108.orig.tar.gz ec34aeb240fcce09d25fce2fbe5e5b6f358c2f24  
            cd "$WINETRICKS_TMP/"
	    tar -xzf "$WINETRICKS_CACHE/ttf-arphic-uming_0.1.20060108.orig.tar.gz"
	    try mv ttf-arphic-uming-0.1.20060108/*.ttf "$winefontsdir"
            cd "$olddir"
        fi
    fi
}

#----------------------------------------------------------------

load_gecko() {
    # Load the HTML rendering Engine (Gecko)
    # FIXME: shouldn't this code be in some script installed 
    # as part of Wine instead of in winetricks?
    # (e.g. we hardcode gecko's url here, but it's normally
    # only hardcoded in wine.inf, and fetched from the registry thereafter,
    # so we're adding a maintenance burden here.)
    case `$WINE --version` in
    wine-0*|wine-1.0*|wine-1.1|wine-1.1.?|wine-1.1.11)
        GECKO_VERSION=0.1.0 
        GECKO_SHA1SUM=c16f1072dc6b0ced20935662138dcf019a38cd56 
        ;;
    *)
        GECKO_VERSION=0.9.0 
        GECKO_SHA1SUM=5cf410ff7fdd3f9d625f481f9d409968728d3d09
        ;;
    esac

    if test ! -f "$WINETRICKS_CACHE"/wine_gecko-$GECKO_VERSION.cab
    then
       # FIXME: busted if using curl!
       download . "http://source.winehq.org/winegecko.php?v=$GECKO_VERSION" $GECKO_SHA1SUM wine_gecko-$GECKO_VERSION.cab
    fi

    cat > "$WINETRICKS_TMP"/geckopath.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\MSHTML\\$GECKO_VERSION]
_EOF_

    #The registry-entry does not support an environment-variable
    # note: echo's behavior with backslashes and options is nonportable,
    # see http://www.opengroup.org/onlinepubs/009695399/utilities/echo.html
    echo -n '"GeckoPath"="' >>"$WINETRICKS_TMP"/geckopath.reg
    echo -n 'c:\\windows\\gecko\\'$GECKO_VERSION | sed "s/\\\\/\\\\\\\\/g" >>"$WINETRICKS_TMP"/geckopath.reg
    echo '\\\\wine_gecko"' >>"$WINETRICKS_TMP"/geckopath.reg

    # extract the files
    mkdir -p "$WINDIR"/gecko/$GECKO_VERSION
    cd "$WINDIR"/gecko/$GECKO_VERSION
    try cabextract $WINETRICKS_UNIXQUIET "$WINETRICKS_CACHE"/wine_gecko-$GECKO_VERSION.cab
    cd "$olddir"

    # set install-path
    try $WINE regedit "$WINETRICKS_TMP"/geckopath.reg
}

#----------------------------------------------------------------

load_gdiplus() {
    # gdiplus is documented here as a redistributable:
    # http://msdn.microsoft.com/library/en-us/gdicpp/GDIPlus/GDIPlus.asp
    # however, there's no standalone installer.  So install a random
    # app that happens to bundle it.
    download . http://download.microsoft.com/download/a/1/a/a1adc39b-9827-4c7a-890b-91396aed2b86/ppviewer.exe 4d13ca85d1d366167b6247ac7340b7736b1bff87
    try $WINE "$WINETRICKS_CACHE"/ppviewer.exe $WINETRICKS_QUIET
    # And then make it globally available.
    try cp "$programfilesdir_unix/Microsoft Office/PowerPoint Viewer/GDIPLUS.DLL" "$WINDIR"/system32/

    # For some reason, native,builtin isn't good enough...?
    override_dlls native gdiplus
}

#----------------------------------------------------------------

load_hosts() {
    # Create fake system32\drivers\etc\hosts and system32\drivers\etc\services files.
    # The hosts file is used to map network names to IP addresses without DNS.
    # The services file is used map service names to network ports.
    # Some apps depend on these files, but they're not implemented in wine.
    # Fortunately, empty files in the correct location satisfy those apps. 
    # See http://bugs.winehq.org/show_bug.cgi?id=12076
    mkdir -p "$WINDIR"/system32/drivers/etc
    touch "$WINDIR"/system32/drivers/etc/hosts
    touch "$WINDIR"/system32/drivers/etc/services
}

#----------------------------------------------------------------
load_icodecs() {
    # http://downloadcenter.intel.com/Detail_Desc.aspx?strState=LIVE&ProductID=355&DwnldID=2846
    download . http://downloadmirror.intel.com/2846/eng/codinstl.exe 2c5d64f472abe3f601ce352dcca75b4f02996f8a
    try $WINE "$WINETRICKS_CACHE"/codinstl.exe
    # Work around bug in codec's installer?
    # http://support.britannica.com/other/touchthesky/win/issues/TSTUw_150.htm
    # http://appdb.winehq.org/objectManager.php?sClass=version&iId=7091
    try $WINE regsvr32 ir50_32.dll
}

load_ie6() {
    load_msls31

    # Unregister Wine IE
    try $WINE iexplore -unregserver

    # Change the override to the native so we are sure we use and register them
    override_dlls native,builtin iexplore.exe itircl itss jscript mlang mshtml msimtf shdoclc shdocvw shlwapi urlmon

    # Remove the fake dlls from the existing WINEPREFIX 
    mv "$WINEPREFIX"/drive_c/"$programfilesdir_unix"/"Internet Explorer"/iexplore.exe "$WINEPREFIX"/drive_c/"$programfilesdir_unix"/"Internet Explorer"/iexplore.exe.bak
    for dll in itircl itss jscript mlang mshtml msimtf shdoclc shdocvw shlwapi urlmon
    do
        test -f "$WINDIR"/system32/$dll.dll && 
          mv "$WINDIR"/system32/$dll.dll "$WINDIR"/system32/$dll.dll.bak
    done

    # fixes rendering issues in IE
    #set_winver win2k

    # Workaround a IE6 Installer bug, not Wine's fault
    # See http://bugs.winehq.org/show_bug.cgi?id=5409
    # Actual value downloaded doesn't matter
    rm -f "$WINETRICKS_CACHE"/ie6sites.dat
    download . http://www.microsoft.com/windows/ie/ie6sp1/download/rtw/x86/ie6sites.dat

    # Install
    download . http://download.microsoft.com/download/ie6sp1/finrel/6_sp1/W98NT42KMeXP/EN-US/ie6setup.exe f3ab61a785eb9611fa583612e83f3b69377f2cef
    $WINE "$WINETRICKS_CACHE"/ie6setup.exe

    # Work around DLL registration bug until ierunonce/RunOnce/wineboot is fixed
    # FIXME: whittle down this list 
    cd "$WINDIR"/system32/
    for i in actxprxy.dll browseui.dll browsewm.dll cdfview.dll ddraw.dll \
      dispex.dll dsound.dll iedkcs32.dll iepeers.dll iesetup.dll \
      imgutil.dll inetcomm.dll inseng.dll isetup.dll jscript.dll laprxy.dll \
      mlang.dll mshtml.dll mshtmled.dll msi.dll msident.dll \
      msoeacct.dll msrating.dll mstime.dll msxml3.dll occache.dll \
      ole32.dll oleaut32.dll olepro32.dll pngfilt.dll quartz.dll \
      rpcrt4.dll rsabase.dll rsaenh.dll scrobj.dll scrrun.dll \
      shdocvw.dll shell32.dll urlmon.dll vbscript.dll webcheck.dll \
      wshcon.dll wshext.dll asctrls.ocx hhctrl.ocx mscomct2.ocx \
      plugin.ocx proctexe.ocx tdc.ocx webcheck.dll wshom.ocx
    do
        $WINE regsvr32 /i $i > /dev/null 2>&1
    done

    # try $WINE "$programfilesdir_unix"/"Internet Explorer"/IEXPLORE.EXE http://www.winehq.org
}

#----------------------------------------------------------------

load_jet40() {
    # http://support.microsoft.com/kb/239114
    # See also http://bugs.winehq.org/show_bug.cgi?id=6085
    download . http://download.microsoft.com/download/4/3/9/4393c9ac-e69e-458d-9f6d-2fe191c51469/jet40sp8_9xnt.exe 8cd25342030857969ede2d8fcc34f3f7bcc2d6d4
    try $WINE "$WINETRICKS_CACHE"/jet40sp8_9xnt.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_kde() {
    download . http://winkde.org/pub/kde/ports/win32/installer/kdewin-installer-gui-0.9.3-1.exe 618f1c4987aa0725640ff331b14ff9a0d3e84f3a
    mkdir -p "$programfilesdir_unix/kde"
    cp "$WINETRICKS_CACHE"/kdewin-installer-gui-0.9.3-1.exe "$programfilesdir_unix/kde"
    cd "$programfilesdir_unix/kde"
    try $WINE "$programfilesdir_win\\kde\\kdewin-installer-gui-0.9.3-1.exe"
    cd "$olddir"
}

#----------------------------------------------------------------

load_liberation() {
    # http://www.redhat.com/promo/fonts/ 				
    download . https://fedorahosted.org/releases/l/i/liberation-fonts/liberation-fonts-1.04.tar.gz 097882c92e3260742a3dc3bf033792120d8635a3
    tar --strip 1 --wildcards -C "$winefontsdir" -xvzf "$WINETRICKS_CACHE"/liberation-fonts-1.04.tar.gz '*.ttf'
}

#----------------------------------------------------------------

set_native_mdac() {
    # Set those overrides globally so user programs get MDAC's odbc
    # instead of wine's unixodbc
    override_dlls native,builtin odbc32 odbccp32
}

#----------------------------------------------------------------

load_mdac25() {
    download mdac25 http://download.microsoft.com/download/e/e/4/ee4fe9ee-6fa1-4ab6-ab8c-fe1769f4edcf/mdac_typ.exe 09e974a5dbebaaa08c7985a4a1126886dc05fd87
    set_native_mdac
    set_winver nt40
    try $WINE "$WINETRICKS_CACHE"/mdac25/mdac_typ.exe
    unset_winver
}

#----------------------------------------------------------------

load_mdac27() {
    download mdac27 http://download.microsoft.com/download/3/b/f/3bf74b01-16ba-472d-9a8c-42b2b4fa0d76/mdac_typ.exe f68594d1f578c3b47bf0639c46c11c5da161feee
    set_native_mdac
    set_winver win2k
    try $WINE "$WINETRICKS_CACHE"/mdac27/mdac_typ.exe
    unset_winver
}

#----------------------------------------------------------------

load_mdac28() {
    download mdac28 http://download.microsoft.com/download/c/d/f/cdfd58f1-3973-4c51-8851-49ae3777586f/MDAC_TYP.EXE 91bd59f0b02b67f3845105b15a0f3502b9a2216a
    set_native_mdac
    set_winver win98
    try $WINE "$WINETRICKS_CACHE"/mdac28/MDAC_TYP.EXE
    unset_winver
}

#----------------------------------------------------------------

load_mfc40() {
    # See http://support.microsoft.com/kb/122244
    download . http://download.microsoft.com/download/ole/ole2v/3.5/w351/en-us/ole2v.exe c6cac71f32405ccb09c6f375e0738e6e13f073e4
    try unzip -o $WINETRICKS_UNIXQUIET -d "$WINETRICKS_TMP" "$WINETRICKS_CACHE"/ole2v.exe
    try cp -f "$WINETRICKS_TMP"/MFC40.DLL "$WINDIR"/system32/

    rm -rf "$WINETRICKS_TMP"/*
}

#----------------------------------------------------------------

load_mono20() {
    # Load Mono, have it handle all .net requests
    download .  ftp://ftp.novell.com/pub/mono/archive/2.0.1/windows-installer/1/mono-2.0.1-gtksharp-2.10.4-win32-1.exe ccb67ac41b59522846e47d0c423836b9d334c088
    # Anyone know how to get it to do a silent install?
    try $WINE "$WINETRICKS_CACHE"/mono-2.0.1-gtksharp-2.10.4-win32-1.exe

    cat > "$WINETRICKS_TMP"/mono_2.0.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727]
"Install"=dword:00000001
"SP"=dword:00000001

[HKEY_LOCAL_MACHINE\Software\Microsoft\.NETFramework\policy\v2.0]
"4322"="3706-4322"
_EOF_
    try $WINE regedit "$WINETRICKS_TMP"/mono_2.0.reg
    rm -f "$WINETRICKS_TMP"/mono_2.0.reg
}

#----------------------------------------------------------------

load_mono22() {
    # Load Mono, have it handle all .net requests
    download .  ftp://ftp.novell.com/pub/mono/archive/2.2/windows-installer/5/mono-2.2-gtksharp-2.12.7-win32-5.exe be977dfa9c49deea1be02ba4a2228e343f1e5840
    # Anyone know how to get it to do a silent install?
    try $WINE "$WINETRICKS_CACHE"/mono-2.2-gtksharp-2.12.7-win32-5.exe

    # FIXME: what should this be for mono 2.2?
    cat > "$WINETRICKS_TMP"/mono_2.0.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727]
"Install"=dword:00000001
"SP"=dword:00000001

[HKEY_LOCAL_MACHINE\Software\Microsoft\.NETFramework\policy\v2.0]
"4322"="3706-4322"
_EOF_
    try $WINE regedit "$WINETRICKS_TMP"/mono_2.0.reg
    rm -f "$WINETRICKS_TMP"/mono_2.0.reg
}

#----------------------------------------------------------------

load_mpc() {
    download . $SOURCEFORGE/guliverkli2/mplayerc_20080414.zip bc9f922d7151e7cc7fef429b085cf208ef989bab
    cd "$WINEPREFIX"/drive_c 
    try unzip "$WINETRICKS_CACHE"/mplayerc_20080414.zip
    cd "$olddir"
    echo MPC now available as c:/mplayerc.exe
}

#----------------------------------------------------------------

load_msi2() {
    # Install native msi per http://wiki.winehq.org/NativeMsi
    # http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=CEBBACD8-C094-4255-B702-DE3BB768148F
    download . http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366

    # Pick win98 so we can install native msi
    set_winver win98

    # Avoid "err:setupapi:SetupDefaultQueueCallbackA copy error 5 ..."
    rm -f "$WINDIR"/system32/msi.dll
    rm -f "$WINDIR"/system32/msiexec.exe

    WINEDLLOVERRIDES="msi,msiexec.exe=n" try $WINE "$WINETRICKS_CACHE"/InstMSIA.exe $WINETRICKS_QUIET

    override_dlls native,builtin msi msiexec.exe

    # and undo version win98
    unset_winver
}

#----------------------------------------------------------------

load_mshflxgd() {
    # http://msdn.microsoft.com/en-us/library/aa240864(VS.60).aspx
    # orig: 5f9c7a81022949bfe39b50f2bbd799c448bb7377
    # Jan 2009: 7ad74e589d5eefcee67fa14e65417281d237a6b6
    download .  http://activex.microsoft.com/controls/vb6/MSHFLXGD.CAB 7ad74e589d5eefcee67fa14e65417281d237a6b6
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/MSHFLXGD.CAB
    #try cp -f "$WINETRICKS_TMP"/MSHFLXGD.OCX "$WINDIR"/system32
    try cp -f "$WINETRICKS_TMP"/mshflxgd.ocx "$WINDIR"/system32
}

#----------------------------------------------------------------

load_msls31() {
    # Install native Microsoft Line Services (needed by e-Sword, possibly only when using native riched20)
    download . http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/InstMsiA.exe
    try cp -f "$WINETRICKS_TMP"/msls31.dll "$WINDIR"/system32
}

#----------------------------------------------------------------

load_msmask() {
    # http://msdn.microsoft.com/en-us/library/11405hcf(VS.71).aspx
    # http://bugs.winehq.org/show_bug.cgi?id=2934
    download .  http://activex.microsoft.com/controls/vb6/MSMASK32.CAB bdd2bb3a32d18926a048f302aff18b1e6d250d9d
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/MSMASK32.CAB
    try cp -f "$WINETRICKS_TMP"/MSMASK32.OCX "$WINDIR"/system32
    try $WINE regsvr32 msmask32.ocx
}

#----------------------------------------------------------------

load_msscript() {
    # http://msdn.microsoft.com/scripting/scriptcontrol/x86/sct10en.exe
    # http://www.microsoft.com/downloads/details.aspx?familyid=d7e31492-2595-49e6-8c02-1426fec693ac
    download .  http://download.microsoft.com/download/d/2/a/d2a7430c-6d5b-48e9-96c4-3c751be7bffe/sct10en.exe fd9f2f23357ab11ae70682d6864f7e9f188adf2a
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/sct10en.exe
    try cp -f "$WINETRICKS_TMP"/msscript.ocx "$WINDIR"/system32
    try $WINE regsvr32 msscript.ocx
}

#----------------------------------------------------------------

load_msxml3() {
    # Service Pack 5
    #download http://download.microsoft.com/download/a/5/e/a5e03798-2454-4d4b-89a3-4a47579891d8/msxml3.msi
    # Service Pack 7
    download . http://download.microsoft.com/download/8/8/8/888f34b7-4f54-4f06-8dac-fa29b19f33dd/msxml3.msi d4c2178dfb807e1a0267fce0fd06b8d51106d913
    # http://bugs.winehq.org/show_bug.cgi?id=7849 fixed since 0.9.37
    override_dlls native,builtin msxml3
    try $WINE msiexec /i "$WINETRICKS_CACHE"/msxml3.msi $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_msxml4() {
    # http://www.microsoft.com/downloads/details.aspx?familyid=24B7D141-6CDF-4FC4-A91B-6F18FE6921D4
    if test ! -f "$WINETRICKS_CACHE"/msxml4.msi
    then
       download . http://download.microsoft.com/download/e/2/e/e2e92e52-210b-4774-8cd9-3a7a0130141d/msxml4-KB927978-enu.exe d364f9fe80c3965e79f6f64609fc253dfeb69c25
       rm -rf "$WINETRICKS_TMP"/*

       try $WINE "$WINETRICKS_CACHE"/msxml4-KB927978-enu.exe "/x:`$WINE winepath -w "$WINETRICKS_TMP"`" $WINETRICKS_QUIET
       if test ! -f "$WINETRICKS_TMP"/msxml.msi
       then
          die msxml.msi not found
       fi
       mv "$WINETRICKS_TMP"/msxml.msi "$WINETRICKS_CACHE"/msxml4.msi
    fi

    try $WINE msiexec /i "$WINETRICKS_CACHE"/msxml4.msi $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_msxml6() {
    # http://www.microsoft.com/downloads/details.aspx?FamilyID=993c0bcf-3bcf-4009-be21-27e85e1857b1
    download . http://download.microsoft.com/download/2/e/0/2e01308a-e17f-4bf9-bf48-161356cf9c81/msxml6.msi 2308743ddb4cb56ae910e461eeb3eab0a9e58058

    try $WINE msiexec /i "$WINETRICKS_CACHE"/msxml6.msi $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_ogg() {
    # flac, ogg, speex, vorbis, ogm source, ogg source
    download . http://cross-lfs.org/~mlankhorst/oggcodecs_0.81.2.exe c9d10a8f1b65b9f3824e227333d66247e14fad4c
    #try $WINE "$WINETRICKS_CACHE"/oggcodecs_0.81.2.exe $WINETRICKS_QUIET
    # oh, and the new schroedinger direct show filter, too
    # see following URLs for more info
    # http://www.diracvideo.org/
    # http://cross-lfs.org/~mlankhorst/direct-schro.txt
    # http://www.diracvideo.org/git?p=direct-schro.git;a=summary
    # Requires wine-1.1.1
    download . http://cross-lfs.org/~mlankhorst/direct-schro.dll
    cp "$WINETRICKS_CACHE"/direct-schro.dll "$WINDIR"/system32/direct-schro.dll
    try $WINE regsvr32 direct-schro.dll
}

#----------------------------------------------------------------

load_ole2() {
    # http://support.microsoft.com/kb/123087/EN-US/
    download . http://download.microsoft.com/download/win31/update/2.03/win/en-us/ww1116.exe b803991c40f387464b61f606536b7c98a88245d2
    try unzip -o $WINETRICKS_UNIXQUIET -d "$WINETRICKS_TMP" "$WINETRICKS_CACHE"/ww1116.exe
    set_winver win31
    cd "$WINETRICKS_TMP"
    try $WINE setup.exe $WINETRICKS_QUIET
    cd "$olddir"
    unset_winver 
    # TODO: Need to set native overrides for some dlls, like ole2disp?
}

#----------------------------------------------------------------

load_pdh() {
    # http://support.microsoft.com/kb/284996
    download . http://download.microsoft.com/download/platformsdk/Redist/5.0.2195.2668/NT4/EN-US/pdhinst.exe f42448660def8cd7f42b34aa7bc7264745f4425e
    try $WINE "$WINETRICKS_CACHE"/pdhinst.exe
    try cp -f "$WINDIR"/temp/x86/Pdh.Dll "$WINDIR"/system32/pdh.dll
}

#----------------------------------------------------------------

load_quicktime72() {
    # http://www.apple.com/support/downloads/quicktime72forwindows.html
    download quicktime72 'http://wsidecar.apple.com/cgi-bin/nph-reg3rdpty2.pl/product=14402&cat=59&platform=osx&method=sa/QuickTimeInstaller.exe' bb89981f10cf21de57b9453e53cf81b9194271a9
    unset QUICKTIME_QUIET
    if test "$WINETRICKS_QUIET"x != x
    then
       QUICKTIME_QUIET="/qn"  # ISSETUPDRIVEN=0
    fi
    # set vista mode to inhibit directdraw overlay use that blacks the screen
    set_winver vista
    try $WINE "$WINETRICKS_CACHE"/quicktime72/QuickTimeInstaller.exe ALLUSERS=1 DESKTOP_SHORTCUTS=0 QTTaskRunFlags=0 QTINFO.BISQTPRO=1 SCHEDULE_ASUW=0 REBOOT_REQUIRED=No $QUICKTIME_QUIET
    if test "$WINETRICKS_QUIET"x = x
    then
        echo "You probably want to select Advanced / Safe Mode in the Quicktime control panel"
        try $WINE control ${programfilesdir_win}'\QuickTime\QTSystem\QuickTime.cpl'
    fi
    
    unset_winver 
    # user might want to set vista mode himself, or run
    #  wine control ".wine/drive_c/Program Files/QuickTime/QTSystem/QuickTime.cpl"
    # and pick Advanced / Safe Mode (gdi only).
    # We could probably force that by overwriting QuickTime.qtp
    # (probably in Program Files/QuickTime/QTSystem/QuickTime.qtp)
    # but the format isn't known, so we'd have to override all other settings, too.
}

#----------------------------------------------------------------

volnum() {
    # Recent Microsoft installers are often based on "windows package manager", see
    # http://support.microsoft.com/kb/262841 and
    # http://www.microsoft.com/technet/prodtechnol/windowsserver2003/deployment/winupdte.mspx
    # These installers check the drive name, and if it doesn't start with 'harddisk',
    # they complain "Unable to find a volume for file extraction", see
    # http://bugs.winehq.org/show_bug.cgi?id=5351 
    # You may be able to work around this by using the installer's /x or /extract switch,
    # but renaming drive_c to "harddiskvolume0" lets you just run the installer as normal.

    if test ! -d "$WINEPREFIX"/harddiskvolume0/
    then
	ln -s drive_c "$WINEPREFIX"/harddiskvolume0
	rm "$WINEPREFIX"/dosdevices/c:
	ln -s ../harddiskvolume0 "$WINEPREFIX"/dosdevices/c: 
        echo "Renamed drive_c to harddiskvolume0"
    else
        echo "drive_c already named harddiskvolume0"
    fi
}

#----------------------------------------------------------------

load_riched20() {
    # http://support.microsoft.com/?kbid=249973
    download . http://download.microsoft.com/download/winntsp/Patch/RTF/NT4/EN-US/Q249973i.EXE f0b7663f15dbd31410435483ba832318c7a70470
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/Q249973i.EXE
    try cp -f "$WINETRICKS_TMP"/riched??.dll "$WINDIR"/system32
    override_dlls native,builtin riched20 riched32
    
    rm -rf "$WINETRICKS_TMP"/*
}

#----------------------------------------------------------------

load_riched30() {
    # http://www.novell.com/documentation/nm1/readmeen_web/readmeen_web.html#Akx3j64
    # claims that Groupwise Messenger's View / Text Size command
    # only works with riched30, and recommends getting it by installing 
    # msi 2, which just happens to come with riched30 version of riched20
    # (though not with a corresponding riched32, which might be a problem)
    # http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=CEBBACD8-C094-4255-B702-DE3BB768148F
    download . http://download.microsoft.com/download/WindowsInstaller/Install/2.0/W9XMe/EN-US/InstMsiA.exe e739c40d747e7c27aacdb07b50925b1635ee7366
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/InstMsiA.exe
    try cp -f "$WINETRICKS_TMP"/riched20.dll "$WINDIR"/system32
    override_dlls native,builtin riched20 
    
    rm -rf "$WINETRICKS_TMP"/*
}

#----------------------------------------------------------------

load_tahoma() {
    # The tahoma and tahomabd fonts are needed by e.g. Steam
    
    download . http://download.microsoft.com/download/office97pro/fonts/1/w95/en-us/tahoma32.exe 888ce7b7ab5fd41f9802f3a65fd0622eb651a068
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE"/tahoma32.exe
    try cp -f "$WINETRICKS_TMP"/Tahoma.TTF "$winefontsdir"/tahoma.ttf
    try cp -f "$WINETRICKS_TMP"/Tahomabd.TTF "$winefontsdir"/tahomabd.ttf
    chmod +w "$winefontsdir"/tahoma*.ttf
    rm -rf "$WINETRICKS_TMP"/*
}

#----------------------------------------------------------------

load_urlmon() {
    # This is an updated urlmon from IE 6.0
    # See http://www.microsoft.com/downloads/details.aspx?familyid=85BB441A-5BB1-4A82-86EC-A249AF287513
    # (Works for Dolphin Smalltalk, see http://bugs.winehq.org/show_bug.cgi?id=8258)
    download . http://download.microsoft.com/download/8/2/0/820faffc-3ea0-4914-bca3-584235964ded/Q837251.exe bcc79b92ac3c06c4de3692672c3d70bdd36be892
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE/Q837251.exe"
    try cp -f "$WINETRICKS_TMP"/URLMON.DLL "$WINDIR"/system32/urlmon.dll
    override_dlls native,builtin urlmon
}

#----------------------------------------------------------------

load_vb3run() {
    # See http://support.microsoft.com/kb/196285
    download . http://download.microsoft.com/download/vb30/utility/1/w9xnt4/en-us/vb3run.exe 518fcfefde9bf680695cadd06512efadc5ac2aa7
    try unzip -o $WINETRICKS_UNIXQUIET -d "$WINETRICKS_TMP" "$WINETRICKS_CACHE"/vb3run.exe
    try cp -f "$WINETRICKS_TMP/Vbrun300.dll" "$WINDIR"/system32/

}

#----------------------------------------------------------------

load_vb4run() {
    # See http://support.microsoft.com/kb/196286
    download . http://download.microsoft.com/download/vb40ent/sample27/1/w9xnt4/en-us/vb4run.exe 83e968063272e97bfffd628a73bf0ff5f8e1023b
    try unzip -o $WINETRICKS_UNIXQUIET -d "$WINETRICKS_TMP" "$WINETRICKS_CACHE"/vb4run.exe
    try cp -f "$WINETRICKS_TMP/Vb40032.dll" "$WINDIR"/system32/
    try cp -f "$WINETRICKS_TMP/Vb40016.dll" "$WINDIR"/system32/

}

#----------------------------------------------------------------

load_vbvm50() {
    download . http://download.microsoft.com/download/vb50pro/utility/1/win98/en-us/msvbvm50.exe 28bfaf09b8ac32cf5ffa81252f3e2fadcb3a8f27
    try $WINE "$WINETRICKS_CACHE"/msvbvm50.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_vbrun60() {
    download . http://download.microsoft.com/download/vb60pro/install/6/win98me/en-us/vbrun60.exe 2dc00e5fc701492bcba7ac58f057ee43751e18e5
    # Exits with status 43 for some reason?
    $WINE "$WINETRICKS_CACHE"/vbrun60.exe $WINETRICKS_QUIET || true
}

#----------------------------------------------------------------

load_vcrun6() {
    # Load the Visual C++ 6 runtime libraries, including the elusive mfc42u.dll
    if test -f "$WINDIR"/system32/mfc42u.dll
    then
        echo "vcrun6 already installed, skipping"
        return
    fi

    if test ! -f "$WINETRICKS_CACHE"/vcredist.exe
    then
       download . http://download.microsoft.com/download/vc60pro/update/1/w9xnt4/en-us/vc6redistsetup_enu.exe 382c8f5a7f41189af8d4165cf441f274b7e2a457
       rm -rf "$WINETRICKS_TMP"/*
       
       try $WINE "$WINETRICKS_CACHE"/vc6redistsetup_enu.exe "/T:`$WINE winepath -w "$WINETRICKS_TMP"`" /c $WINETRICKS_QUIET
       if test ! -f "$WINETRICKS_TMP"/vcredist.exe
       then
          die vcredist.exe not found
       fi
       mv "$WINETRICKS_TMP"/vcredist.exe "$WINETRICKS_CACHE"
    fi
    # Delete some fake dlls to avoid vcredist installer warnings
    rm -f "$WINDIR"/system32/msvcrt.dll
    rm -f "$WINDIR"/system32/oleaut32.dll
    rm -f "$WINDIR"/system32/olepro32.dll
    # vcredist still exits with status 43.  Anyone know why?
    $WINE "$WINETRICKS_CACHE"/vcredist.exe || true

    # And then some apps need mfc42u.dll, dunno what right way
    # is to get it, vcredist doesn't install it by default?
    cd "$WINETRICKS_TMP"/
    rm -rf "$WINETRICKS_TMP"/*
    try cabextract "$WINETRICKS_CACHE"/vcredist.exe
    mv mfc42u.dll "$WINDIR"/system32/
    cd "$olddir"
}

#----------------------------------------------------------------

load_vcrun2003() {
    # Load the Visual C++ 2003 runtime libraries
    # Sadly, I know of no Microsoft URL for these
    echo "Installing BZFlag (which comes with the Visual C++ 2003 runtimes)"
    download . $SOURCEFORGE/bzflag/BZEditW32_1.6.5_Installer.exe bdd1b32c4202fd77e6513fd507c8236888b09121
    try $WINE "$WINETRICKS_CACHE"/BZEditW32_1.6.5_Installer.exe $WINETRICKS_S
    cp "$programfilesdir_unix/BZEdit1.6.5"/m*71* "$WINDIR"/system32/
}

#----------------------------------------------------------------

load_vcrun2005() {
    # Load the Visual C++ 2005 runtime libraries
    # See http://www.microsoft.com/downloads/details.aspx?familyid=32BC1BEE-A3F9-4C13-9C99-220B62A191EE
    download vcrun2005 http://download.microsoft.com/download/d/3/4/d342efa6-3266-4157-a2ec-5174867be706/vcredist_x86.exe 47fba37de95fa0e2328cf2e5c8ebb954c4b7b93c
    try $WINE "$WINETRICKS_CACHE"/vcrun2005/vcredist_x86.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_vcrun2005sp1() {
    # Load the Visual C++ 2005 SP1 runtime libraries
    # See http://www.microsoft.com/downloads/details.aspx?familyid=200b2fd9-ae1a-4a14-984d-389c36f85647
    download vcrun2005sp1 http://download.microsoft.com/download/e/1/c/e1c773de-73ba-494a-a5ba-f24906ecf088/vcredist_x86.exe 7dfa98be78249921dd0eedb9a3dd809e7d215c8d 
    try $WINE "$WINETRICKS_CACHE"/vcrun2005sp1/vcredist_x86.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_vcrun2008() {
    # Otherwise it complains...
    volnum

    # Load the Visual C++ 2008 runtime libraries
    # See http://www.microsoft.com/downloads/details.aspx?familyid=9b2da534-3e03-4391-8a4d-074b9f2bc1bf
    download vcrun2008 http://download.microsoft.com/download/1/1/1/1116b75a-9ec3-481a-a3c8-1777b5381140/vcredist_x86.exe 56719288ab6514c07ac2088119d8a87056eeb94a 
    try $WINE "$WINETRICKS_CACHE"/vcrun2008/vcredist_x86.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_vjrun20() {
    download vjrun20 http://download.microsoft.com/download/9/2/3/92338cd0-759f-4815-8981-24b437be74ef/vjredist.exe 80a098e36b90d159da915aebfbfbacf35f302bd8
    try $WINE "$WINETRICKS_CACHE"/vjrun20/vjredist.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_vlc() {
    # want http://www.videolan.org/mirror.php?file=vlc/0.8.6f/win32/vlc-0.8.6f-win32.exe but it doesn't redirect?
    download . http://mirrors.optralan.com/videolan/vlc/0.8.6f/win32/vlc-0.8.6f-win32.exe b83558e4232c47a385dbc93ebdc2e6b942fbcfbf
    try $WINE "$WINETRICKS_CACHE"/vlc-0.8.6f-win32.exe $WINETRICKS_S
}

#----------------------------------------------------------------

load_wininet() {
    # This is an updated wininet from IE 5.0.1.   
    # (Good enough for Active Worlds browser.  Also helps "Avatar - Legends of the Arena" get to login screen.)
    # See http://www.microsoft.com/downloads/details.aspx?familyid=6DEE32AB-B618-4FB3-9A45-CDD08162E167
    download . http://download.microsoft.com/download/ie5/Update/1/WIN98/EN-US/3725.exe b048e0b4e303298de3317b16f7008c43ca71ddfe
    try cabextract --directory="$WINETRICKS_TMP" "$WINETRICKS_CACHE/3725.exe"
    try cp -f "$WINETRICKS_TMP"/Wininet.dll "$WINDIR"/system32/wininet.dll
    override_dlls native,builtin wininet
}

#----------------------------------------------------------------

load_wmp9() {
    # Not really expected to work well yet; see
    # http://appdb.winehq.org/appview.php?versionId=1449

    set_winver win2k

    # See also http://www.microsoft.com/windows/windowsmedia/player/9series/default.aspx
    download wmp9 http://download.microsoft.com/download/1/b/c/1bc0b1a3-c839-4b36-8f3c-19847ba09299/MPSetup.exe 580536d10657fa3868de2869a3902d31a0de791b

    # Have to run twice; see http://bugs.winehq.org/show_bug.cgi?id=1886
    try $WINE "$WINETRICKS_CACHE"/wmp9/MPSetup.exe $WINETRICKS_QUIET
    try $WINE "$WINETRICKS_CACHE"/wmp9/MPSetup.exe $WINETRICKS_QUIET

    # Also install the codecs
    # See http://www.microsoft.com/downloads/details.aspx?FamilyID=06fcaab7-dcc9-466b-b0c4-04db144bb601
    download . http://download.microsoft.com/download/5/c/2/5c29d825-61eb-4b16-8eb8-58367d0464d5/WM9Codecs9x.exe 8b76bdcbea0057eb12b7966edab4b942ddacc253
    try $WINE "$WINETRICKS_CACHE"/WM9Codecs9x.exe $WINETRICKS_QUIET

    unset_winver
}

#----------------------------------------------------------------

load_wmp10() {
    # See http://appdb.winehq.org/appview.php?iVersionId=3212

    # See also http://www.microsoft.com/windows/windowsmedia/player/10
    download . http://download.microsoft.com/download/1/2/A/12A31F29-2FA9-4F50-B95D-E45EF7013F87/MP10Setup.exe 69862273a5d9d97b4a2e5a3bd93898d259e86657

    # Crashes on exit, but otherwise ok; see http://bugs.winehq.org/show_bug.cgi?id=12633
    echo Executing $WINE "$WINETRICKS_CACHE"/MP10Setup.exe $WINETRICKS_QUIET
    $WINE "$WINETRICKS_CACHE"/MP10Setup.exe $WINETRICKS_QUIET || true

    # Also install the codecs
    # See http://www.microsoft.com/downloads/details.aspx?FamilyID=06fcaab7-dcc9-466b-b0c4-04db144bb601
    download . http://download.microsoft.com/download/5/c/2/5c29d825-61eb-4b16-8eb8-58367d0464d5/WM9Codecs9x.exe 8b76bdcbea0057eb12b7966edab4b942ddacc253
    set_winver win2k
    try $WINE "$WINETRICKS_CACHE"/WM9Codecs9x.exe $WINETRICKS_QUIET
    unset_winver
}

#----------------------------------------------------------------

load_wsh56() {
    # See also http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=C717D943-7E4B-4622-86EB-95A22B832CAA
    # FIXME: depends on vcrun6, should we install that automatically?
    download . http://download.microsoft.com/download/2/8/a/28a5a346-1be1-4049-b554-3bc5f3174353/WindowsXP-Windows2000-Script56-KB917344-x86-enu.exe f4692766caa3ee9b38d4166845486c6199a33457

    try $WINE "$WINETRICKS_CACHE"/WindowsXP-Windows2000-Script56-KB917344-x86-enu.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_wsh56js() {
    # This installs jscript 5.6 (but not vbscript)
    # See also http://www.microsoft.com/downloads/details.aspx?FamilyID=16dd21a1-c4ee-4eca-8b80-7bd1dfefb4f8&DisplayLang=en
    download . http://download.microsoft.com/download/b/c/3/bc3a0c36-fada-497d-a3de-8b0139766f3b/Windows2000-KB917344-56-x86-enu.exe add5f74c5bd4da6cfae47f8306de213ec6ed52c8

    try $WINE "$WINETRICKS_CACHE"/Windows2000-KB917344-56-x86-enu.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_wsh56vb() {
    # This installs vbscript 5.6 (but not jscript)
    # See also http://www.microsoft.com/downloads/details.aspx?familyid=4F728263-83A3-464B-BCC0-54E63714BC75
    download . http://download.microsoft.com/download/IE60/Patch/Q318089/W9XNT4Me/EN-US/vbs56men.exe 48f14a93db33caff271da0c93f334971f9d7cb22

    try $WINE "$WINETRICKS_CACHE"/vbs56men.exe $WINETRICKS_QUIET
}

#----------------------------------------------------------------

load_xvid() {
    # xvid
    test -f "$WINDIR"/system32/[Mm][Ff][Cc]42.[Dd][Ll][Ll] || load_vcrun6
    download . http://download2.videohelp.com/download/Xvid-1.1.3-27042008.exe f1008a11037c0b9368aa4979e62d0963d05d8007
    try $WINE "$WINETRICKS_CACHE"/Xvid-1.1.3-27042008.exe $WINETRICKS_SILENT
}

#----------------------------------------------------------------


while test "$1" != ""
do
    PACKAGE=$1
    case $1 in
    -q) WINETRICKS_QUIET="/q"
        WINETRICKS_UNIXQUIET="-q"
        WINETRICKS_SILENT="/silent"
        WINETRICKS_S="/S"                 # for NSIS installers
        WINEDEBUG=${WINEDEBUG:-"fixme-all"}
        export WINEDEBUG
        ;;
    -v) set -x;;
    art2kmin) load_art2kmin;;
    autohotkey) load_autohotkey;;
    cc580|comctl32) load_cc580;;
    sapi51) load_sapi51;;
    sapi4) load_sapi4;;
    sapi4_us_voices) load_sapi4_us_voices;;
    sapi4_uk_voices) load_sapi4_uk_voices;;
    comctl32.ocx) load_comctl32ocx;;
    colorprofile) load_colorprofile;;
    corefonts) load_corefonts;;
    controlpad|fm20) load_controlpad;;
    dcom98) load_dcom98;;
    dirac|dirac0.8) load_dirac08;;
    directx9) load_directx9;;
    divx) load_divx;;
    dotnet11) load_dotnet11; load_fontfix;;
    dotnet20) load_dotnet20; load_fontfix;;
    firefox|firefox3) load_firefox3;;
    ffdshow) load_ffdshow;;
    flash) load_flash;;
    fontfix) load_fontfix;;
    gdiplus) load_gdiplus;;
    gecko) load_gecko;;
    hosts) load_hosts;;
    icodecs) load_icodecs;;
    ie6) load_ie6;;
    jet40) load_jet40;;
    kde) load_kde;;
    liberation) load_liberation;;
    mdac25) load_mdac25;;
    mdac27) load_mdac27;;
    mdac28) load_mdac28;;
    mfc40) load_mfc40;;
    mono19|mono20) load_mono20;;
    mono22) load_mono22;;
    mpc) load_mpc;;
    msi2) load_msi2;;
    mshflxgd) load_mshflxgd;;
    msls31) load_msls31;;
    msmask) load_msmask;;
    msscript) load_msscript;;
    msxml3) load_msxml3;;
    msxml4) load_msxml4;;
    msxml6) load_msxml6;;
    ogg) load_ogg;;
    ole2) load_ole2;;
    pdh) load_pdh;;
    quicktime72) load_gdiplus; load_quicktime72;;  # needs e.g. gdiplus.dll.GdipCloneImage
    riched20) load_riched20;;
    riched30) load_riched30;;
    tahoma) load_tahoma;;
    urlmon) load_urlmon;;
    vb3run) load_vb3run;;
    vb4run) load_vb4run;;
    vbvm50|vb5run) load_vbvm50;;
    vbrun60|vb6run) load_vbrun60;;
    vcrun6|mfc42) load_vcrun6;;
    vcrun2003) load_vcrun2003;;
    vcrun2005) load_vcrun2005;;
    vcrun2005sp1) load_vcrun2005sp1;;
    vcrun2008) load_vcrun2008;;
    vjrun20) load_vjrun20;;
    vlc) load_vlc;;
    wininet) load_wininet;;
    wmp9) load_vcrun6; load_wsh56; load_wmp9;;
    wmp10) load_vcrun6; load_wsh56; load_wmp10;;
    wsh56) load_vcrun6; load_wsh56;;
    wsh56js) load_wsh56js;;
    wsh56vb) load_wsh56vb;;
    xvid) load_xvid;;

    fakeie6) set_fakeie6;;
    allfonts) load_corefonts; load_tahoma; load_liberation;;
    allvcodecs|allcodecs) load_vcrun6; load_ffdshow; load_xvid; load_icodecs;;
    nt40|winver=nt40) set_winver nt40;;
    win98|winver=win98) set_winver win98;;
    win2k|winver=win2k) set_winver win2k;;
    winxp|winver=winxp) set_winver winxp;;
    vista|winver=vista) set_winver vista;;
    winver=) unset_winver;;
    native_mdac) set_native_mdac;;
    native_oleaut32) override_dlls native,builtin oleaut32;;
    volnum) volnum;;
    *) echo Unknown arg $1; usage ; exit 1;;
    esac
    # Provide a bit of feedback
    test "$WINETRICKS_QUIET" = "" && case $1 in 
    -q) echo Setting quiet mode;;
    -v) echo Setting verbose mode;;
    *) echo "Install of $1 done" ;;
    esac
    shift
    # cleanup
    rm -rf "$WINETRICKS_TMP"/*
done

test "$WINETRICKS_QUIET" = "" && echo winetricks done. || true

