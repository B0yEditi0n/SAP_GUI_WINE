#!/bin/bash

#
# OBS: ao iniciar o comando rode o comando
# export SAPGUI_WINEPREFIX="caminho ser instalado"
#

set -e
######################################
# DEPENDENCIAS
######################################

echo "######################################
#  Instalando Dependencias de Sistema
######################################"

command -v winetricks >/dev/null || sudo apt install -y winetricks 
command -v unzip >/dev/null || sudo apt install -y unzip
command -v ntlm_auth >/dev/null || sudo apt install -y winbind
command -v cabextract >/dev/null || sudo apt install -y cabextract

######################################
# WINE
######################################

# baixando o wine especifico




if [ -n $SAPGUI_WINEPREFIX ]; then
    ROOT_PREFIX=$SAPGUI_WINEPREFIX 
else
    ROOT_PREFIX=$WINEPREFIX 
fi

WINE_MAJOR=$(wine --version | cut -d'.' -f1 | sed 's/wine-//')
if [[ "$WINE_MAJOR" -lt 11 ]]; then
    if [[ ! -d "$ROOT_PREFIX/.wine/wine-11.0-amd64-wow64" ]]; then
        echo "Instalando Wine 11"
        mkdir -p "$ROOT_PREFIX/.wine"
        wget https://github.com/Kron4ek/Wine-Builds/releases/download/11.0/wine-11.0-amd64-wow64.tar.xz
        tar -xf wine-11.0-amd64-wow64.tar.xz -C "$ROOT_PREFIX/.wine/"

    fi
    export PATH="$ROOT_PREFIX/.wine/wine-11.0-amd64-wow64/bin:$PATH"
    export LD_LIBRARY_PATH="$ROOT_PREFIX/.wine/wine-11.0-amd64-wow64/lib:$LD_LIBRARY_PATH"
    echo "Wine version: $(wine --version)" 
fi
 
if [[ ! -d "$ROOT_PREFIX/prefix" ]]; then
    mkdir -p "$ROOT_PREFIX/prefix"
fi
export WINEPREFIX="$ROOT_PREFIX/prefix/SAP_GUI_WIME"
export WINEARCH=win64
# export WINEDEBUG=-all para melhor ver logs de erro


#########################################
#  MENU DE AUXILIO DE CONFIGURAÇÃO
#########################################

echo "1) Instalar"
echo "2) Abrir o CFG"
echo "3) Abrir o Winetricks"
echo "0) Sair"

read -p "Escolha: " opcao

case $opcao in
  1)
    echo "Instalando..."
    ;;
  2)
    echo "Abrindo CFG..."
    winecfg
    exit 
    ;;
  3)
    echo "Abrindo Winetricks..."
    winetricks
    exit 
    ;;
  0)
    echo "Saindo..."
    exit
    ;;
  *)
    echo "Opção inválida"
    ;;
esac

#########################################
#  INSTALÇÃO DE SCRIPT
#########################################
# Confirma o Prefixo Usado
echo "Usando prefix: $WINEPREFIX"
read -p "Deseja continuar? (s/n): " resposta

if [[ "$resposta" == "s" ]]; then
    mkdir -p "$ROOT_PREFIX/prefix"
    echo "Continuando..."
else
    echo "Cancelado"
    exit 1
fi


wineboot -i

echo "######################################
#   Instalando Dependencias Wine
######################################"

# # instalação de Dependencias
sudo winetricks --self-update
# winetricks -q win10 # windows padrão é o 10
winetricks -q corefonts

winetricks -q d3dx11_42
winetricks -q d3dx11_43
winetricks -q dxvk     # A Renderição do Aplicação Exige
winetricks -q vkd3d
winetricks -q msxml6
winetricks -q mfc140 
winetricks -q vb6run
winetricks -q vcrun6

# Teste para integrar o edge
winetricks -q atmlib
winetricks -q gdiplus
winetricks -q msxml3
winetricks -q riched20
winetricks -q riched30
# fim do teste 

set +e
winetricks -q ie8
set -e

# INICIO: Teste de integração Chromium
# FIM: Teste de integração Chromium
#wine msiexec /i setup/wine-mono-11.0.0-x86.msi
#wine msiexec /i setup/wine-gecko-2.47.4-x86_64.msi
echo "instalação do Dotnet48"
winetricks -q dotnet48

echo "instalação do Webview2"
winetricks -q webview2

echo "instalação do pactoes VisualStudio"
winetricks -q vcrun2012
winetricks -q vcrun2015
winetricks -q vcrun2022

wine winecfg -v win10

# instalação dos arquivos SAP
echo "######################################
#   Instalação SAP
######################################"
if [[ ! -d "./BD_NW_7.0_Presentation_7.70_Comp._1_/" ]]; then
    unzip -q -o sap_gui_main.zip
fi
echo "${PWD}/BD_NW_7.0_Presentation_7.70_Comp._1_/PRES1/GUI/Windows/Win32"
sap_prefix="${PWD}/BD_NW_7.0_Presentation_7.70_Comp._1_/PRES1/GUI/Windows/Win32"


# Tenta Instalar o VC na pasta do SAP
set +e
wine "${sap_prefix}/System/VC12/vc12redist_x64.exe"
wine "${sap_prefix}/System/VC15/vc15redist_x64.exe"
wine "${sap_prefix}/SetupAll.exe"
set -e

#
#   VARIAVEIS DE AMBIENTE
#

# Impede decoração do sistema
wine reg add "HKCU\Software\Wine\X11 Driver" /v Decorated /t REG_SZ /d N /f
# Força o Tema (Belize Theme) 
# https://help.sap.com/docs/sap_gui_for_windows/dfad9ecd79db404eba46fdd709013a78/e7d961683653451397a67607caafb9ad.html?locale=en-US
wine reg add "HKCU\Software\SAP\General\Appearance" \
/v SelectedTheme /t REG_DWORD /d 1 /f

#######################################
# Criar um lançador simples
#######################################
echo "######################################
#   Criando Lançadores de Sistema
######################################"
cat << 'EOF' > "$ROOT_PREFIX/launcher.sh"
#!/usr/bin/env bash

export PATH="$PWD/.wine/wine-11.0-amd64-wow64/bin:$PATH"
export LD_LIBRARY_PATH="$PWD/.wine/wine-11.0-amd64-wow64/lib:$LD_LIBRARY_PATH"
export WINEPREFIX="$PWD/prefix/SAP_GUI_WIME"
export WINEARCH=win64
# export WINEDEBUG=-all
# export WINEESYNC=1

WINE="$PWD/.wine/wine-11.0-amd64-wow64/bin/wine"

wineserver -p

"$WINE" "$WINEPREFIX/drive_c/SAP/SAPgui/saplogon.exe"
EOF
chmod +x "$ROOT_PREFIX/launcher.sh"

echo '...'

prefix="$WINEPREFIX"
cat <<EOF > ~/.local/share/applications/sap-gui.desktop
[Desktop Entry]
Name=SAP GUI
Comment=Acessar o SAP via Wine

Exec=env WINEPREFIX="$WINEPREFIX" PATH="$ROOT_PREFIX/.wine/wine-11.0-amd64-wow64/bin:\$PATH" LD_LIBRARY_PATH="$ROOT_PREFIX/.wine/wine-11.0-amd64-wow64/lib:\$LD_LIBRARY_PATH" WINEARCH=win64 wine "C:\\SAP\\SAPgui\\saplogon.exe"

Icon=11CB_saplogon.0
Terminal=false
Type=Office
Type=Application;

EOF
chmod +x ~/.local/share/applications/sap-gui.desktop

echo 'instalação concluida'