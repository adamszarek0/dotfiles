#!/bin/bash

# Skrypt instalacyjny konfiguracji Hyprlanda end-4/dots-hyprland
# PRZECZYTAJ UWAŻNIE KAŻDY KROK PRZED URUCHOMIENIEM!
#
# Przeznaczony dla openSUSE Tumbleweed.
# Wymaga połączenia z internetem.
# Zaleca się uruchomienie na świeżej instalacji systemu.

# --- Zmienne globalne ---
DOTS_REPO="https://github.com/end-4/dots-hyprland.git"
DOTS_DIR="$HOME/dots-hyprland-temp"
CONFIG_DIR="$HOME/.config"
LOCAL_SHARE_FONTS="$HOME/.local/share/fonts"

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

print_header "Rozpoczynam instalację konfiguracji Hyprlanda end-4 dla openSUSE Tumbleweed"
print_warning "Ten skrypt nadpisze istniejące pliki konfiguracyjne w ~/.config."
print_warning "Upewnij się, że masz kopie zapasowe ważnych danych!"
confirm_action "Kontynuować?" || { print_info "Anulowano instalację."; exit 0; }

# 1. Sprawdzenie i instalacja opi (jeśli potrzebne)
print_header "Sprawdzam i instaluję 'opi'..."
install_opi

# 2. Instalacja podstawowych pakietów systemowych i zależności Hyprlanda
print_header "Instaluję podstawowe pakiety systemowe i zależności Hyprlanda..."
print_info "Używam 'zypper install'. Może być wymagane Twoje hasło."

# Lista pakietów dla openSUSE Tumbleweed (dostosowane nazwy)
# Staram się dobrać odpowiedniki z Arch Linuxa.
# Pakiety podstawowe i zależności Hyprlanda
sudo zypper install --no-confirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    libqt5-qtwayland \
    libqt6-qtwayland \
    pipewire \
    wireplumber \
    xdg-user-dirs \
    NetworkManager \
    brightnessctl \
    pavucontrol \
    blueman \
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
    upower \
    xdg-utils \
    gvfs \
    playerctl \
    polkit-gnome \
    thunar \
    thunar-archive-plugin \
    file-roller \
    zip \
    unzip \
    unrar \
    p7zip \
    fontconfig \
    gnome-keyring \
    ImageMagick \
    npm # Potrzebne do niektórych skryptów w Waybar

# Czcionki i ikony - tutaj jest największa różnica
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
# Tutaj musimy ostrożnie, bo nie wszystkie pakiety będą miały dokładne odpowiedniki.
# end-4 używa paru programów, które są popularne na AUR.
# Będziemy szukać ich w openSUSE Build Service (OBS).
print_header "Instaluję pakiety z openSUSE Build Service (OBS) - może być wymagana interakcja 'opi'..."

# Szukamy pakietów, które mogą nie być w głównych repozytoriach
# Note: 'hyprlock' i 'hypridle' są często dostarczane razem z hyprlandem lub w osobnych pakietach w OBS.
# Jeśli 'opi' nie znajdzie, być może trzeba będzie skompilować ręcznie.
opi search hyprlock && sudo opi install hyprlock --no-confirm
opi search hypridle && sudo opi install hypridle --no-confirm
opi search swww && sudo opi install swww --no-confirm # Alternatywa dla swaybg, end-4 go używa
opi search nwg-look && sudo opi install nwg-look --no-confirm # Narzędzie do konfiguracji GTK/Qt

# Niektóre programy end-4 używa (np. web-greeter, wlsunset) mogą wymagać kompilacji ręcznej
# lub nie mieć bezpośrednich odpowiedników w OBS/repozytoriach.
# Możesz spróbować wyszukać je ręcznie za pomocą 'opi search <nazwa_pakietu>'
# lub skompilować ze źródeł, jeśli są krytyczne dla konfiguracji end-4.

print_info "Zakończono instalację pakietów. Przejdź do kopiowania plików konfiguracyjnych."

# 3. Klonowanie repozytorium dotfiles
print_header "Klonuję repozytorium dotfiles end-4/dots-hyprland..."
if [ -d "$DOTS_DIR" ]; then
    print_warning "Katalog $DOTS_DIR już istnieje. Usuwam go..."
    rm -rf "$DOTS_DIR"
fi
git clone "$DOTS_REPO" "$DOTS_DIR" || { print_error "Nie udało się sklonować repozytorium."; exit 1; }

# 4. Tworzenie kopii zapasowych istniejących configów i kopiowanie nowych
print_header "Kopiuję pliki konfiguracyjne Hyprlanda..."

# Sprawdź, czy katalog .config istnieje
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# Lista katalogów do skopiowania z repozytorium do ~/.config
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
    "mimeapps.list" # Plik
)

for dir in "${CONFIGS[@]}"; do
    if [ -d "$CONFIG_DIR/$dir" ]; then
        print_info "Tworzę kopię zapasową istniejącego $CONFIG_DIR/$dir do $CONFIG_DIR/${dir}_bak_$(date +%F_%H-%M-%S)"
        mv "$CONFIG_DIR/$dir" "$CONFIG_DIR/${dir}_bak_$(date +%F_%H-%M-%S)"
    elif [ -f "$CONFIG_DIR/$dir" ]; then # Jeśli to plik, a nie katalog
        print_info "Tworzę kopię zapasową istniejącego $CONFIG_DIR/$dir do $CONFIG_DIR/${dir}_bak_$(date +%F_%H-%M-%S)"
        mv "$CONFIG_DIR/$dir" "$CONFIG_DIR/${dir}_bak_$(date +%F_%H-%M-%S)"
    fi
    # Kopiuj z repozytorium dots-hyprland
    if [ -d "$DOTS_DIR/$dir" ]; then
        print_info "Kopiuję $DOTS_DIR/$dir do $CONFIG_DIR/$dir"
        cp -r "$DOTS_DIR/$dir" "$CONFIG_DIR/"
    elif [ -f "$DOTS_DIR/$dir" ]; then
        print_info "Kopiuję $DOTS_DIR/$dir do $CONFIG_DIR/$dir"
        cp "$DOTS_DIR/$dir" "$CONFIG_DIR/"
    fi
done

# Dodatkowe pliki konfiguracyjne end-4 (np. zshrc, xdg-user-dirs)
print_info "Kopiuję dodatkowe pliki konfiguracyjne..."
# ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc_bak_$(date +%F_%H-%M-%S)"
fi
cp "$DOTS_DIR/.zshrc" "$HOME/"

# ~/.bashrc (jeśli używasz)
if [ -f "$DOTS_DIR/.bashrc" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        mv "$HOME/.bashrc" "$HOME/.bashrc_bak_$(date +%F_%H-%M-%S)"
    fi
    cp "$DOTS_DIR/.bashrc" "$HOME/"
fi

# ~/.gtkrc-2.0
if [ -f "$HOME/.gtkrc-2.0" ]; then
    mv "$HOME/.gtkrc-2.0" "$HOME/.gtkrc-2.0_bak_$(date +%F_%H-%M-%S)"
fi
cp "$DOTS_DIR/.gtkrc-2.0" "$HOME/"

# Ustawienia xdg-user-dirs
print_info "Aktualizuję katalogi użytkownika za pomocą xdg-user-dirs..."
xdg-user-dirs-update

# Kopiowanie czcionek do lokalnego katalogu użytkownika (jeśli są w repo)
print_info "Kopiuję dodatkowe czcionki (jeśli są dostępne w repo end-4)..."
if [ -d "$DOTS_DIR/fonts" ]; then
    mkdir -p "$LOCAL_SHARE_FONTS"
    cp -r "$DOTS_DIR/fonts/"* "$LOCAL_SHARE_FONTS/"
    fc-cache -fv # Odśwież cache czcionek
else
    print_warning "Brak katalogu 'fonts' w repozytorium dotfiles. Pomięto kopiowanie dodatkowych czcionek."
fi

# Kopiowanie tapet
print_info "Kopiuję tapety..."
mkdir -p "$HOME/.config/hypr/wallpapers"
cp "$DOTS_DIR/wallpapers/"* "$HOME/.config/hypr/wallpapers/" || print_warning "Nie znaleziono tapet w repozytorium dotfiles."

# Konfiguracja GDM/SDDM (jeśli używasz) - wymaga ręcznego przełączenia sesji na Hyprland
print_info "Konfiguracja logowania: po restarcie komputera wybierz 'Hyprland' z menedżera sesji (np. GDM, SDDM)."

# 5. Czyszczenie
print_header "Czyszczę tymczasowe pliki..."
rm -rf "$DOTS_DIR"

print_header "Instalacja konfiguracji Hyprlanda end-4 ZAKOŃCZONA!"
print_info "Proszę teraz zrestartować komputer."
print_info "Po restarcie wybierz 'Hyprland' z menedżera sesji (np. GDM, SDDM)."
print_warning "Może być konieczne dostosowanie niektórych ustawień ręcznie (np. tapeta, jasność)."
print_info "Jeśli napotkasz problemy, sprawdź logi Hyprlanda: 'journalctl --user -b -u hyprland' lub 'hyprland --debug'."
print_info "Nie zapomnij o konfiguracji `GTK_THEME`, `QT_QPA_PLATFORMTHEME`, `QT_WAYLAND_CLIENT_BUFFERING` w pliku `~/.config/environment.d/envvars.conf` jak w konfiguracji end-4."
print_info "Możesz użyć `nwg-look` do konfiguracji wyglądu GTK/Qt."
print_info "Pamiętaj, że niektóre elementy konfiguracji end-4 (np. Waybar modules) mogą wymagać dodatkowej konfiguracji lub usług."

# --- Zakończenie skryptu ---
