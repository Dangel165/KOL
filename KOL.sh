#!/bin/bash

VERSION="2.0"
LOG_FILE="/var/log/korean_locale_setup.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Display ASCII banner
clear
echo -e "${CYAN}"
echo " _  __ ___  _     "
echo "| |/ // _ \| |    "
echo "|   /| | | | |    "
echo "|  \ | |_| | |___ "
echo "|_|\_\\___/|_____|"
echo -e "${NC}"
echo -e "${BLUE}=========================================="
echo "Korean Locale Setup Script v${VERSION}"
echo "==========================================${NC}"
echo -e "${GREEN}Supports: Kali Linux, Ubuntu, Raspberry Pi${NC}"
echo -e "${YELLOW}Display Server: Wayland & X11${NC}"
echo ""

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
    echo -e "${GREEN}Detected OS: $PRETTY_NAME${NC}"
    log "OS Detection: $PRETTY_NAME"
else
    echo -e "${RED}Cannot detect OS.${NC}"
    exit 1
fi

# Check root privileges
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}This script requires root privileges.${NC}"
    echo "Please run: sudo ./korean_locale_setup.sh"
    exit 1
fi

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        PKG_UPDATE="apt-get update -qq"
        PKG_INSTALL="apt-get install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="pacman -Sy"
        PKG_INSTALL="pacman -S --noconfirm"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update"
        PKG_INSTALL="dnf install -y"
    else
        echo -e "${RED}Unsupported package manager${NC}"
        exit 1
    fi
    log "Package manager: $PKG_MANAGER"
}

# Show main menu
show_menu() {
    echo ""
    echo -e "${YELLOW}=== Installation Options ===${NC}"
    echo "1) Full Installation (Recommended)"
    echo "2) Basic Installation (Language pack + Fonts)"
    echo "3) Minimal Installation (Language pack only)"
    echo "4) Custom Installation"
    echo "5) OS-Specific Installation"
    echo "6) Check Installation Status"
    echo "7) Uninstall"
    echo "0) Exit"
    echo ""
    read -p "Select (0-7): " choice
}

# Show OS-specific menu
show_os_menu() {
    echo ""
    echo -e "${CYAN}=== OS-Specific Installation ===${NC}"
    echo "1) Ubuntu (Standard)"
    echo "2) Kali Linux (Optimized for Kali)"
    echo "3) Raspberry Pi OS (Lightweight)"
    echo "0) Back to main menu"
    echo ""
    read -p "Select (0-3): " os_choice
}

# Create backup
create_backup() {
    echo -e "${YELLOW}Creating backup of current settings...${NC}"
    BACKUP_DIR="/root/locale_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    [ -f /etc/default/locale ] && cp /etc/default/locale "$BACKUP_DIR/"
    [ -f /etc/locale.gen ] && cp /etc/locale.gen "$BACKUP_DIR/"
    
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            [ -f "$user_home/.bashrc" ] && cp "$user_home/.bashrc" "$BACKUP_DIR/${username}_bashrc"
        fi
    done
    
    echo -e "${GREEN}Backup completed: $BACKUP_DIR${NC}"
    log "Backup created: $BACKUP_DIR"
}

# Update system
update_system() {
    echo -e "${YELLOW}Updating system...${NC}"
    $PKG_UPDATE
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        apt-get upgrade -y -qq
    fi
    log "System update completed"
}

# Install language pack
install_language_pack() {
    echo -e "${YELLOW}Installing Korean language pack...${NC}"
    
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        $PKG_INSTALL language-pack-ko language-pack-ko-base
        locale-gen ko_KR.UTF-8
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        # Arch-based systems
        sed -i 's/#ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen
        locale-gen
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        # Fedora/RHEL-based systems
        $PKG_INSTALL glibc-langpack-ko
    fi
    
    log "Language pack installation completed"
}

# Install fonts
install_fonts() {
    echo -e "${YELLOW}Installing Korean fonts...${NC}"
    
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        $PKG_INSTALL fonts-nanum fonts-nanum-coding fonts-nanum-extra \
                     fonts-noto-cjk fonts-noto-cjk-extra \
                     fonts-baekmuk fonts-unfonts-core
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        $PKG_INSTALL noto-fonts-cjk ttf-baekmuk adobe-source-han-sans-kr-fonts
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        $PKG_INSTALL google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts
    fi
    
    fc-cache -fv > /dev/null 2>&1
    log "Font installation completed"
}

# Detect display server
detect_display_server() {
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        DISPLAY_SERVER="wayland"
        echo -e "${CYAN}Detected: Wayland${NC}"
    elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
        DISPLAY_SERVER="x11"
        echo -e "${CYAN}Detected: X11${NC}"
    else
        # Fallback detection
        if [ -n "$WAYLAND_DISPLAY" ]; then
            DISPLAY_SERVER="wayland"
            echo -e "${CYAN}Detected: Wayland (fallback)${NC}"
        else
            DISPLAY_SERVER="x11"
            echo -e "${CYAN}Detected: X11 (fallback)${NC}"
        fi
    fi
    log "Display server: $DISPLAY_SERVER"
}

# Install input method
install_input_method() {
    echo -e "${YELLOW}Installing Korean input method...${NC}"
    
    detect_display_server
    
    # Detect desktop environment
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
        if [ "$DISPLAY_SERVER" = "wayland" ]; then
            # Wayland + GNOME: Use ibus (native Wayland support)
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                $PKG_INSTALL ibus ibus-hangul im-config
                im-config -n ibus
                
                # Configure for Wayland
                gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'hangul')]" 2>/dev/null || true
            fi
        else
            # X11 + GNOME
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                $PKG_INSTALL ibus ibus-hangul im-config
                im-config -n ibus
            fi
        fi
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        if [ "$DISPLAY_SERVER" = "wayland" ]; then
            # Wayland + KDE: Use fcitx5 (better Wayland support)
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                $PKG_INSTALL fcitx5 fcitx5-hangul fcitx5-config-qt
                
                # Wayland environment variables
                echo "export GTK_IM_MODULE=fcitx" >> /etc/environment
                echo "export QT_IM_MODULE=fcitx" >> /etc/environment
                echo "export XMODIFIERS=@im=fcitx" >> /etc/environment
            elif [ "$PKG_MANAGER" = "pacman" ]; then
                $PKG_INSTALL fcitx5 fcitx5-hangul fcitx5-configtool fcitx5-qt fcitx5-gtk
            fi
        else
            # X11 + KDE
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                $PKG_INSTALL fcitx fcitx-hangul fcitx-config-gtk
            elif [ "$PKG_MANAGER" = "pacman" ]; then
                $PKG_INSTALL fcitx5 fcitx5-hangul fcitx5-configtool
            fi
        fi
    else
        # Other desktop environments
        if [ "$DISPLAY_SERVER" = "wayland" ]; then
            # Prefer fcitx5 for Wayland
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                $PKG_INSTALL fcitx5 fcitx5-hangul fcitx5-config-qt
            elif [ "$PKG_MANAGER" = "pacman" ]; then
                $PKG_INSTALL fcitx5 fcitx5-hangul fcitx5-configtool
            fi
        else
            # X11 fallback
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                $PKG_INSTALL ibus ibus-hangul
            elif [ "$PKG_MANAGER" = "pacman" ]; then
                $PKG_INSTALL ibus ibus-hangul
            fi
        fi
    fi
    
    log "Input method installation completed"
}

# Configure Wayland input method
configure_wayland_input() {
    if [ "$DISPLAY_SERVER" = "wayland" ]; then
        echo -e "${YELLOW}Configuring Wayland input method...${NC}"
        
        # Create environment configuration
        cat > /etc/profile.d/korean_input.sh << 'EOF'
# Korean Input Method Configuration for Wayland
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
EOF
        
        chmod +x /etc/profile.d/korean_input.sh
        
        # Apply to all users
        for user_home in /home/*; do
            if [ -d "$user_home" ]; then
                username=$(basename "$user_home")
                
                # Add to user profile
                if ! grep -q "korean_input.sh" "$user_home/.profile" 2>/dev/null; then
                    echo "source /etc/profile.d/korean_input.sh" >> "$user_home/.profile"
                    chown $username:$username "$user_home/.profile"
                fi
            fi
        done
        
        log "Wayland input method configured"
    fi
}

# Configure locale
configure_locale() {
    echo -e "${YELLOW}Configuring locale settings...${NC}"
    
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8
    fi
    
    cat > /etc/default/locale << EOF
LANG=ko_KR.UTF-8
LC_ALL=ko_KR.UTF-8
LANGUAGE=ko_KR:ko
EOF

    # Apply to all users
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            if ! grep -q "LANG=ko_KR.UTF-8" "$user_home/.bashrc" 2>/dev/null; then
                echo "" >> "$user_home/.bashrc"
                echo "# Korean locale settings" >> "$user_home/.bashrc"
                echo "export LANG=ko_KR.UTF-8" >> "$user_home/.bashrc"
                echo "export LC_ALL=ko_KR.UTF-8" >> "$user_home/.bashrc"
                chown $username:$username "$user_home/.bashrc"
            fi
        fi
    done
    
    log "Locale configuration completed"
}

# Install extra tools
install_extra_tools() {
    echo -e "${YELLOW}Installing additional tools...${NC}"
    
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        $PKG_INSTALL hunspell-ko aspell-ko mythes-ko \
                     libreoffice-l10n-ko firefox-locale-ko 2>/dev/null || true
    fi
    
    log "Additional tools installation completed"
}

# Configure timezone
configure_timezone() {
    echo -e "${YELLOW}Set timezone to Korea/Seoul? (y/n)${NC}"
    read -p "Choice: " tz_choice
    if [ "$tz_choice" = "y" ] || [ "$tz_choice" = "Y" ]; then
        timedatectl set-timezone Asia/Seoul 2>/dev/null || \
        ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
        echo -e "${GREEN}Timezone set to Asia/Seoul${NC}"
        log "Timezone set: Asia/Seoul"
    fi
}

# Ubuntu-specific installation
ubuntu_install() {
    echo -e "${CYAN}=== Ubuntu Installation ===${NC}"
    create_backup
    detect_package_manager
    update_system
    install_language_pack
    install_fonts
    
    # Ubuntu-specific packages
    $PKG_INSTALL language-pack-gnome-ko language-pack-gnome-ko-base
    
    install_input_method
    configure_wayland_input
    configure_locale
    install_extra_tools
    configure_timezone
    
    echo -e "${GREEN}Ubuntu installation completed!${NC}"
    show_completion_message
}

# Kali Linux-specific installation
kali_install() {
    echo -e "${CYAN}=== Kali Linux Installation ===${NC}"
    create_backup
    detect_package_manager
    update_system
    install_language_pack
    install_fonts
    
    # Kali-specific: lightweight installation
    detect_display_server
    if [ "$DISPLAY_SERVER" = "wayland" ]; then
        $PKG_INSTALL fcitx5 fcitx5-hangul
    else
        $PKG_INSTALL ibus ibus-hangul
    fi
    
    configure_wayland_input
    configure_locale
    configure_timezone
    
    echo -e "${GREEN}Kali Linux installation completed!${NC}"
    echo -e "${YELLOW}Note: Some tools work better in English environment${NC}"
    show_completion_message
}

# Raspberry Pi-specific installation
raspi_install() {
    echo -e "${CYAN}=== Raspberry Pi OS Installation ===${NC}"
    create_backup
    detect_package_manager
    
    echo -e "${YELLOW}Lightweight installation for Raspberry Pi...${NC}"
    
    # Minimal update
    apt-get update -qq
    
    # Essential packages only
    install_language_pack
    
    # Lightweight fonts
    $PKG_INSTALL fonts-nanum fonts-nanum-coding
    
    # Lightweight input method
    $PKG_INSTALL ibus ibus-hangul
    
    configure_wayland_input
    configure_locale
    configure_timezone
    
    echo -e "${GREEN}Raspberry Pi installation completed!${NC}"
    echo -e "${YELLOW}Optimized for low memory usage${NC}"
    show_completion_message
}

# Check installation status
check_status() {
    echo -e "${BLUE}=========================================="
    echo "Installation Status"
    echo "==========================================${NC}"
    
    echo -e "\n${YELLOW}[Display Server]${NC}"
    if [ -n "$XDG_SESSION_TYPE" ]; then
        echo "Session Type: $XDG_SESSION_TYPE"
    fi
    if [ -n "$WAYLAND_DISPLAY" ]; then
        echo "Wayland Display: $WAYLAND_DISPLAY"
    fi
    if [ -n "$DISPLAY" ]; then
        echo "X11 Display: $DISPLAY"
    fi
    
    echo -e "\n${YELLOW}[Locale Settings]${NC}"
    locale | grep -E "LANG|LC_ALL"
    
    echo -e "\n${YELLOW}[Language Packs]${NC}"
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        dpkg -l | grep language-pack-ko || echo "Not installed"
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        locale -a | grep ko_KR || echo "Not installed"
    fi
    
    echo -e "\n${YELLOW}[Korean Fonts]${NC}"
    font_count=$(fc-list :lang=ko | wc -l)
    echo "$font_count Korean fonts installed"
    
    echo -e "\n${YELLOW}[Input Method]${NC}"
    if command -v ibus &> /dev/null; then
        echo "ibus: Installed"
    fi
    if command -v fcitx &> /dev/null; then
        echo "fcitx: Installed"
    fi
    if command -v fcitx5 &> /dev/null; then
        echo "fcitx5: Installed (Wayland compatible)"
    fi
    
    echo -e "\n${YELLOW}[Input Method Environment]${NC}"
    if [ -f /etc/profile.d/korean_input.sh ]; then
        echo "Wayland configuration: Installed"
        cat /etc/profile.d/korean_input.sh
    else
        echo "Wayland configuration: Not found"
    fi
    
    echo -e "\n${YELLOW}[Timezone]${NC}"
    timedatectl 2>/dev/null | grep "Time zone" || cat /etc/timezone
}

# Uninstall
uninstall() {
    echo -e "${RED}Remove Korean settings? (y/n)${NC}"
    read -p "Choice: " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "${YELLOW}Uninstalling...${NC}"
        
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            apt-get remove -y language-pack-ko language-pack-ko-base
            apt-get remove -y fonts-nanum fonts-nanum-coding fonts-nanum-extra
            apt-get remove -y ibus-hangul fcitx-hangul
            apt-get autoremove -y
            
            update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
        fi
        
        echo -e "${GREEN}Uninstallation completed${NC}"
        log "Korean settings removed"
    fi
}

# Full installation
full_install() {
    create_backup
    detect_package_manager
    update_system
    install_language_pack
    install_fonts
    install_input_method
    configure_wayland_input
    configure_locale
    install_extra_tools
    configure_timezone
    
    echo -e "${GREEN}=========================================="
    echo "Full installation completed!"
    echo "==========================================${NC}"
    show_completion_message
}

# Basic installation
basic_install() {
    create_backup
    detect_package_manager
    update_system
    install_language_pack
    install_fonts
    configure_wayland_input
    configure_locale
    
    echo -e "${GREEN}=========================================="
    echo "Basic installation completed!"
    echo "==========================================${NC}"
    show_completion_message
}

# Minimal installation
minimal_install() {
    create_backup
    detect_package_manager
    install_language_pack
    configure_locale
    
    echo -e "${GREEN}=========================================="
    echo "Minimal installation completed!"
    echo "==========================================${NC}"
    show_completion_message
}

# Custom installation
custom_install() {
    create_backup
    detect_package_manager
    
    echo -e "${YELLOW}Select components to install:${NC}"
    
    read -p "Install language pack? (y/n): " lang
    [ "$lang" = "y" ] && install_language_pack
    
    read -p "Install fonts? (y/n): " font
    [ "$font" = "y" ] && install_fonts
    
    read -p "Install input method? (y/n): " input
    if [ "$input" = "y" ]; then
        install_input_method
        configure_wayland_input
    fi
    
    read -p "Install extra tools? (y/n): " extra
    [ "$extra" = "y" ] && install_extra_tools
    
    configure_locale
    configure_timezone
    
    echo -e "${GREEN}Custom installation completed!${NC}"
    show_completion_message
}

# Completion message
show_completion_message() {
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Reboot your system: sudo reboot"
    echo "2. After reboot, configure input method:"
    
    if [ "$DISPLAY_SERVER" = "wayland" ]; then
        echo -e "   ${CYAN}[Wayland Detected]${NC}"
        echo "   - GNOME: Settings > Keyboard > Input Sources > Add Korean (Hangul)"
        echo "   - KDE: Run 'fcitx5-configtool'"
        echo "   - Switch input: Ctrl+Space or Shift+Space"
    else
        echo -e "   ${CYAN}[X11 Detected]${NC}"
        echo "   - GNOME: Run 'ibus-setup'"
        echo "   - KDE: Run 'fcitx-config-gtk' or 'fcitx5-configtool'"
        echo "   - Switch input: Shift+Space"
    fi
    
    echo ""
    echo "3. Verify installation:"
    echo "   - Check locale: locale"
    echo "   - Check fonts: fc-list :lang=ko"
    echo "   - Test input in any text editor"
    echo ""
    echo "Log file: $LOG_FILE"
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo -e "${GREEN}Wayland support: Enabled${NC}"
}

# Main loop
detect_package_manager

while true; do
    show_menu
    
    case $choice in
        1)
            full_install
            break
            ;;
        2)
            basic_install
            break
            ;;
        3)
            minimal_install
            break
            ;;
        4)
            custom_install
            break
            ;;
        5)
            show_os_menu
            case $os_choice in
                1) ubuntu_install; break ;;
                2) kali_install; break ;;
                3) raspi_install; break ;;
                0) continue ;;
                *) echo -e "${RED}Invalid choice${NC}" ;;
            esac
            ;;
        6)
            check_status
            ;;
        7)
            uninstall
            break
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
done
