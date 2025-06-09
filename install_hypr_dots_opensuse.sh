#!/bin/bash

# Skrypt instalacyjny konfiguracji Hyprlanda end-4/dots-hyprland
# PRZEZNACZONY DLA ŚWIEŻEJ, MINIMALNEJ INSTALACJI openSUSE Tumbleweed (np. Server/Minimal X).
#
# PRZECZYTAJ UWAŻNIE KAŻDY KROK PRZED URUCHOMIENIEM!
# Wymaga połączenia z internetem.

# --- Zmienne globalne ---
DOTS_REPO="https://github.com/end-4/dots-hyprland.git"
DOTS_DIR="$HOME/dots-hyprland-temp"
CONFIG_DIR="$HOME/.config"
LOCAL_SHARE_FONTS="$HOME/.local/share/fonts"
HYPRLAND_SESSION_FILE="/usr/share/xsessions/hyprland.desktop" # Najbardziej prawdopodobna lokalizacja dla SDDM/GDM

# --- Funkcje pomocnicze ---
print_header() {
    echo -e "\n\033[1;34m--- $1 ---\033[0m"
}

print_info() {
    echo -e "\033[0;32m$1\033[0m"
}

print_warning() {
    echo -e "\033[0;33m$1\033[0m"
}

print_error() {
    echo -e "\033[0;31m$1\033[0m"
}

confirm_action() {
    read -p "$1 (y/N): " choice
    [[ "$choice" =~ ^[yY]$ ]]
}

# Funkcja do instalacji opi, jeśli nie jest zainstalowany
install_opi() {
    if ! command -v opi &> /dev/null; then
        print_info "Nie znaleziono 'opi'. Próbuję zainstalować 'opi'..."
        sudo zypper install --no-confirm opi
        if ! command -v opi &> /dev/null; then
            print_error "Nie udało się zainstalować 'opi'. Proszę zainstaluj je ręcznie: 'sudo zypper install opi' i spróbuj ponownie."
            exit 1
        fi
    fi
}

# --- Rozpoczęcie skryptu ---

print_header "Rozpoczynam instalację Hyprlanda z konfiguracją end-4 dla openSUSE Tumbleweed (minimalna instalacja)"
print_warning "Ten skrypt jest przeznaczony dla ŚWIEŻEJ, MINIMALNEJ INSTALACJI openSUSE Tumbleweed."
print_warning "Upewnij się, że masz połączenie z internetem."
print_warning "Ten skrypt nadpisze pliki konfiguracyjne w ~/.config."
confirm_action "Kontynuować?" || { print_info "Anulowano instalację."; exit 0; }

# 1. Sprawdzenie i aktualizacja systemu
print_header "Odświeżam repozytoria i aktualizuję system..."
sudo zypper refresh
sudo zypper update --no-confirm || { print_error "Aktualizacja systemu nie powiodła się."; exit 1; }

# 2. Instalacja podstawowych narzędzi i menedżera logowania (SDDM)
print_header "Instaluję podstawowe narzędzia, serwer Wayland i menedżer logowania (SDDM)..."
sudo zypper install --no-confirm \
    git \
    wget \
    curl \
    nano \
    tar \
    unzip \
    p7zip \
    xdg-user-dirs \
    NetworkManager \
    systemd-sysvinit \
    # Display server
    sddm \
    # Standardowa usługa Waylanda
    wayland \
    # Narzędzie do zarządzania dźwiękiem
    pipewire \
    wireplumber \
    # Narzędzia do Bluetooth
    blueman \
    # Podstawowe narzędzia do pulpitu
    polkit-gnome \
    gvfs \
    upower \
    # Podstawowy terminal, jeśli foot nie będzie działał od razu
    xterm # Możesz to zmienić na inny prosty terminal jak alacritty, ale xterm jest pewniejszy na start

# Upewnij się, że SDDM jest włączone i uruchomione
print_info "Włączam i uruchamiam SDDM (Display Manager)..."
sudo systemctl enable sddm
sudo systemctl start sddm

# 3. Instalacja 'opi' (narzędzie do openSUSE Build Service)
print_header "Sprawdzam i instaluję 'opi'..."
install_opi

# 4. Instalacja pakietów dla Hyprlanda i jego zależności
print_header "Instaluję Hyprlanda i jego zależności..."

sudo zypper install --no-confirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    libqt5-qtwayland \
    libqt6-qtwayland \
    brightnessctl \
    pavucontrol \
    swaybg \
    waybar \
    rofi \
    wofi \
    mako \
    foot \
    kitty \
    swappy \
    grim \
    slurp \
    wl-clipboard \
    pamixer \
    playerctl \
    thunar \
    thunar-archive-plugin \
    file-roller \
    fontconfig \
    gnome-keyring \
    ImageMagick \
    npm # Potrzebne do niektórych skryptów w Waybar

# Czcionki i ikony - najważniejsze dla estetyki end-4
print_info "Instaluję czcionki i ikony..."
sudo zypper install --no-confirm \
    'font(Fira Code)' \
    'font(Noto Color Emoji)' \
    'font(Symbols Nerd Font)' \
    'font(Roboto Mono)' \
    'font(JetBrains Mono)' \
    adwaita-icon-theme \
    papirus-icon-theme \
    gtk3-metatheme-adwaita \
    gtk4-metatheme-adwaita \
    kde-gtk-config \
    qgnomeplatform-qt5 \
    qgnomeplatform-qt6 \
    kvantum

# Pakiety z openSUSE Build Service (poprzez opi) - odpowiedniki AUR
# Tutaj może być wymagana interakcja użytkownika.
print_header "Instaluję pakiety z openSUSE Build Service (OBS) - MOŻE BYĆ WYMAGANA INTERAKCJA OPI..."
print_info "Proszę wybrać najbardziej wiarygodne repozytorium (zwykle numer 1 lub 2, lub 'main repository')."

opi search hyprlock && sudo opi install hyprlock --no-confirm
opi search hypridle && sudo opi install hypridle --no-confirm
opi search swww && sudo opi install swww --no-confirm # end-4 używa swww do tapet

# nwg-look do konfiguracji GTK/Qt
opi search nwg-look && sudo opi install nwg-look --no-confirm

print_info "Zakończono instalację pakietów."

# 5. Tworzenie pliku sesji Hyprlanda dla menedżera logowania (SDDM)
print_header "Tworzę plik sesji Hyprlanda ($HYPRLAND_SESSION_FILE)..."
echo -e "[Desktop Entry]\nName=Hyprland\nComment=A dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application\nKeywords=wayland;tiling;wm;" | sudo tee "$HYPRLAND_SESSION_FILE" > /dev/null || { print_error "Nie udało się utworzyć pliku sesji Hyprlanda."; exit 1; }
print_info "Plik sesji Hyprlanda został utworzony w $HYPRLAND_SESSION_FILE."

# 6. Klonowanie repozytorium dotfiles
print_header "Klonuję repozytorium dotfiles end-4/dots-hyprland..."
if [ -d "$DOTS_DIR" ]; then
    print_warning "Katalog $DOTS_DIR już istnieje. Usuwam go..."
    rm -rf "$DOTS_DIR"
fi
git clone "$DOTS_REPO" "$DOTS_DIR" || { print_error "Nie udało się sklonować repozytorium dotfiles."; exit 1; }

# 7. Tworzenie kopii zapasowych istniejących configów i kopiowanie nowych
print_header "Kopiuję pliki konfiguracyjne Hyprlanda z repozytorium end-4..."

# Sprawdź, czy katalog .config istnieje
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# Lista katalogów i plików do skopiowania z repozytorium do ~/.config
CONFIGS=(
    "hypr"
    "waybar"
    "rofi"
    "mako"
    "foot"
    "kitty"
    "swappy"
    "wofi"
    "cava" # Jeśli używasz Cavy
    "mpv"
    "gtk-3.0"
    "gtk-4.0"
    "fontconfig"
)

# Kopiowanie katalogów
for dir in "${CONFIGS[@]}"; do
    if [ -d "$DOTS_DIR/$dir" ]; then
        if [ -d "$CONFIG_DIR/$dir" ]; then
            print_info "Tworzę kopię zapasową istniejącego $CONFIG_DIR/$dir do $CONFIG_DIR/${dir}_bak_$(date +%F_%H-%M-%S)"
            mv "$CONFIG_DIR/$dir" "$CONFIG_DIR/${dir}_bak_$(date +%F_%H-%M-%S)"
        fi
        print_info "Kopiuję $DOTS_DIR/$dir do $CONFIG_DIR/$dir"
        cp -r "$DOTS_DIR/$dir" "$CONFIG_DIR/"
    fi
done

# Kopiowanie plików (np. mimeapps.list, envvars.conf - to będzie osobno)
# end-4 ma też .zshrc i .bashrc
print_info "Kopiuję dodatkowe pliki konfiguracyjne (.zshrc, .bashrc, .gtkrc-2.0)..."

if [ -f "$DOTS_DIR/.zshrc" ]; then
    if [ -f "$HOME/.zshrc" ]; then mv "$HOME/.zshrc" "$HOME/.zshrc_bak_$(date +%F_%H-%M-%S)"; fi
    cp "$DOTS_DIR/.zshrc" "$HOME/"
fi

if [ -f "$DOTS_DIR/.bashrc" ]; then
    if [ -f "$HOME/.bashrc" ]; then mv "$HOME/.bashrc" "$HOME/.bashrc_bak_$(date +%F_%H-%M-%S)"; fi
    cp "$DOTS_DIR/.bashrc" "$HOME/"
fi

if [ -f "$DOTS_DIR/.gtkrc-2.0" ]; then
    if [ -f "$HOME/.gtkrc-2.0" ]; then mv "$HOME/.gtkrc-2.0" "$HOME/.gtkrc-2.0_bak_$(date +%F_%H-%M-%S)"; fi
    cp "$DOTS_DIR/.gtkrc-2.0" "$HOME/"
fi

# Utworzenie pliku environment.d/envvars.conf, który jest kluczowy dla end-4
print_header "Tworzę plik ~/.config/environment.d/envvars.conf dla zmiennych środowiskowych..."
mkdir -p "$CONFIG_DIR/environment.d"
echo "GTK_THEME=Adwaita:dark" | tee "$CONFIG_DIR/environment.d/envvars.conf" > /dev/null
echo "QT_QPA_PLATFORMTHEME=qt5ct" | tee -a "$CONFIG_DIR/environment.d/envvars.conf" > /dev/null
echo "QT_WAYLAND_CLIENT_BUFFERING=1" | tee -a "$CONFIG_DIR/environment.d/envvars.conf" > /dev/null
print_info "Plik ~/.config/environment.d/envvars.conf został utworzony."

# 8. Konfiguracja xdg-user-dirs
print_info "Aktualizuję katalogi użytkownika za pomocą xdg-user-dirs..."
xdg-user-dirs-update

# 9. Kopiowanie czcionek do lokalnego katalogu użytkownika (jeśli są w repo)
print_info "Kopiuję dodatkowe czcionki (jeśli są dostępne w repo end-4)..."
if [ -d "$DOTS_DIR/fonts" ]; then
    mkdir -p "$LOCAL_SHARE_FONTS"
    cp -r "$DOTS_DIR/fonts/"* "$LOCAL_SHARE_FONTS/"
    fc-cache -fv # Odśwież cache czcionek
else
    print_warning "Brak katalogu 'fonts' w repozytorium dotfiles. Pomięto kopiowanie dodatkowych czcionek."
fi

# 10. Kopiowanie tapet
print_info "Kopiuję tapety..."
mkdir -p "$HOME/.config/hypr/wallpapers"
cp "$DOTS_DIR/wallpapers/"* "$HOME/.config/hypr/wallpapers/" || print_warning "Nie znaleziono tapet w repozytorium dotfiles."

# 11. Czyszczenie
print_header "Czyszczę tymczasowe pliki..."
rm -rf "$DOTS_DIR"

print_header "Instalacja konfiguracji Hyprlanda end-4 ZAKOŃCZONA!"
print_info "SDDM powinien się już uruchomić i wyświetlić ekran logowania."
print_info "Po restarcie komputera wybierz 'Hyprland' z menedżera sesji."
print_info "Jeśli system nadal uruchamia się w tty, uruchom 'sudo systemctl start sddm'."
print_warning "Może być konieczne dostosowanie niektórych ustawień ręcznie (np. tapeta, jasność)."
print_info "Jeśli napotkasz problemy, sprawdź logi Hyprlanda: 'journalctl --user -b -u hyprland' lub 'Hyprland --debug' po zalogowaniu."
print_info "Użyj `nwg-look` (jeśli się zainstalował) do konfiguracji wyglądu GTK/Qt."

# --- Zakończenie skryptu ---
