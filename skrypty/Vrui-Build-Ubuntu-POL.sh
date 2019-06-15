#!/bin/bash

# Zainstaluj wymagane paczki:
PREREQUISITE_PACKAGES="build-essential g++ libudev-dev libdbus-1-dev libusb-1.0-0-dev zlib1g-dev libpng-dev libjpeg-dev libtiff-dev libasound2-dev libspeex-dev libopenal-dev libv4l-dev libdc1394-22-dev libtheora-dev libbluetooth-dev libxi-dev libxrandr-dev mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev"
echo "Wpisz haslo by zainstalowac wymagane paczki dla Vrui"
sudo apt-get install $PREREQUISITE_PACKAGES
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
	echo "Wystapil problem podczas pobierania paczek; napraw usterke i spróbuj ponownie"
	exit $INSTALL_RESULT
fi

# Stworz folder src:
echo "Tworzenie folderu z kodem $HOME/src"
cd $HOME
mkdir src
cd src
CD_RESULT=$?

if [ $CD_RESULT -ne 0 ]; then
	echo "Nie mozna stworzyc folderu z kodem $HOME/src; napraw usterke i spróbuj ponownie"
	exit $CD_RESULT
fi

# Uzyskaj obecna wersje Vrui:
VRUI_CURRENT_RELEASE=$(wget -q -O - http://idav.ucdavis.edu/~okreylos/ResDev/Vrui/CurrentVruiRelease.txt)
GETVERSION_RESULT=$?
if [ $GETVERSION_RESULT -ne 0 ]; then
	echo "Nie mozna uzyskac obecnej wersji Vrui; sprawdz twoje polaczenie internetowe i spróbuj ponownie"
	exit $GETVERSION_RESULT
fi
read VRUI_VERSION VRUI_RELEASE <<< "$VRUI_CURRENT_RELEASE"

# Pobierz i rozpakuj tarballa z Vrui:
echo "Pobieranie Vrui-$VRUI_VERSION-$VRUI_RELEASE do $HOME/src"
wget -O - http://idav.ucdavis.edu/~okreylos/ResDev/Vrui/Vrui-$VRUI_VERSION-$VRUI_RELEASE.tar.gz | tar xfz -
cd Vrui-$VRUI_VERSION-$VRUI_RELEASE
DOWNLOAD_RESULT=$?

if [ $DOWNLOAD_RESULT -ne 0 ]; then
	echo "Wystapil problem podczas pobierania lub rozpakowywania Vrui; sprawdz twoje polaczenie internetowe i spróbuj ponownie"
	exit $DOWNLOAD_RESULT
fi

# Ustaw folder instalacji Vrui:
VRUI_INSTALLDIR=/usr/local
if [ $# -ge 1 ]; then
	VRUI_INSTALLDIR=$1
fi

# Sprawdz, czy make install wymaga sudo, czyli przykladowo miejsce instalacji nie jest w katalogu home uzytkownika:
INSTALL_NEEDS_SUDO=1
[[ $VRUI_INSTALLDIR = $HOME* ]] && INSTALL_NEEDS_SUDO=0

# Check if make directory path needs Vrui-<version> shim:
# TODO: przetlumacz ten komentarz
VRUI_MAKEDIR=$VRUI_INSTALLDIR/share/Vrui-$VRUI_VERSION/make
[[ $VRUI_INSTALLDIR = *Vrui-$VRUI_VERSION* ]] && VRUI_MAKEDIR=$VRUI_INSTALLDIR/share/make 

# Ustaw ilość rdzeni na komputerze:
NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

# Skompiluj Vrui:
echo "Kompiluje Vrui na $NUM_CPUS rdzeniach"
make -j$NUM_CPUS INSTALLDIR=$VRUI_INSTALLDIR
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
	echo "Kompilacja nie powiodla sie; napraw wszystkie zgloszone bledy i spróbuj ponownie"
	exit $BUILD_RESULT
fi

# Zainstaluj Vrui
echo "Kompilacja zakonczona sukcesem; instalowanie Vrui w $VRUI_INSTALLDIR"
if [ $INSTALL_NEEDS_SUDO -ne 0 ]; then
	echo "Wpisz haslo by zainstalowac Vrui w $VRUI_INSTALLDIR"
	sudo make INSTALLDIR=$VRUI_INSTALLDIR install
else
	make INSTALLDIR=$VRUI_INSTALLDIR install
fi
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
	echo "Nie mozna zainstalowac Vrui w $VRUI_INSTALLDIR; napraw usterke i spróbuj ponownie"
	exit $INSTALL_RESULT
fi

# Zainstaluj reguly dla urządzen
echo "Instalacja w $VRUI_INSTALLDIR zakonczona sukcesem; instalowanie regul dla urządzen w /etc/udev/rules.d"
echo "Jesli pojawi sie monit, wpisz haslo ponownie by zainstalowac reguly dla urządzen"
sudo make INSTALLDIR=$VRUI_INSTALLDIR installudevrules
UDEVRULES_RESULT=$?
if [ $UDEVRULES_RESULT -ne 0 ]; then
	echo "Instalacja regul dla urządzen w /etc/udev/rules.d nie powiodla sie; napraw usterke i spróbuj ponownie"
	exit $UDEVRULES_RESULT
fi

# Skompiluj przykladowe programy Vrui
cd ExamplePrograms
echo "Kompiluje przykladowe programy Vrui na $NUM_CPUS rdzeniach"
make -j$NUM_CPUS VRUI_MAKEDIR=$VRUI_MAKEDIR INSTALLDIR=$VRUI_INSTALLDIR
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
	echo "Kompilacja nie powiodla sie; napraw wszystkie zgloszone bledy i spróbuj ponownie"
	exit $BUILD_RESULT
fi

# Zainstaluj przykladowe programy Vrui
echo "Kompilacja zakonczona sukcesem; instalowanie przykladowych programow Vrui w $VRUI_INSTALLDIR"
if [ $INSTALL_NEEDS_SUDO -ne 0 ]; then
	echo "Jesli pojawi sie monit, wpisz haslo ponownie by zainstalowac przykladowe programy Vrui w $VRUI_INSTALLDIR"
	sudo make VRUI_MAKEDIR=$VRUI_MAKEDIR INSTALLDIR=$VRUI_INSTALLDIR install
else
	make VRUI_MAKEDIR=$VRUI_MAKEDIR INSTALLDIR=$VRUI_INSTALLDIR install
fi
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
	echo "Nie mozna zainstalowac przykladowych programow Vrui w $VRUI_INSTALLDIR; napraw usterke i spróbuj ponownie"
	exit $INSTALL_RESULT
fi

# Uruchom ShowEarthModel
echo "Uruchamiam aplikacje ShowEarthModel. Nacisnij Esc lub zamknij okno by wyjsc."
cd $HOME
$VRUI_INSTALLDIR/bin/ShowEarthModel