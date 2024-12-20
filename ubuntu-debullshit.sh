#!/usr/bin/env bash

disable_ubuntu_report() {
    ubuntu-report send no
    apt remove ubuntu-report -y
}

remove_appcrash_popup() {
    apt remove apport apport-gtk -y
}

remove_snaps() {
    while [ "$(snap list | wc -l)" -gt 0 ]; do
        for snap in $(snap list | tail -n +2 | cut -d ' ' -f 1); do
            snap remove --purge "$snap"
        done
    done

    systemctl stop snapd
    systemctl disable snapd
    systemctl mask snapd
    apt purge snapd -y
    rm -rf /snap /var/lib/snapd
    for userpath in /home/*; do
        rm -rf $userpath/snap
    done
    cat <<-EOF | tee /etc/apt/preferences.d/nosnap.pref
	Package: snapd
	Pin: release a=*
	Pin-Priority: -10
	EOF
}

disable_terminal_ads() {
    sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news
    pro config set apt_news=false
}

update_system() {
    apt update && apt upgrade -y
}

cleanup() {
    apt autoremove -y
}

setup_flathub() {
    apt install flatpak -y
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}


restore_firefox() {
    apt purge firefox -y
    snap remove --purge firefox
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- > /etc/apt/keyrings/packages.mozilla.org.asc
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list 
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' > /etc/apt/preferences.d/mozilla
    apt update
    apt install firefox -y
}

ask_reboot() {
    echo 'Reboot now? (y/n)'
    while true; do
        read choice
        if [[ "$choice" == 'y' || "$choice" == 'Y' ]]; then
            reboot
            exit 0
        fi
        if [[ "$choice" == 'n' || "$choice" == 'N' ]]; then
            break
        fi
    done
}

msg() {
    tput setaf 2
    echo "[*] $1"
    tput sgr0
}

error_msg() {
    tput setaf 1
    echo "[!] $1"
    tput sgr0
}

check_root_user() {
    if [ "$(id -u)" != 0 ]; then
        echo 'Please run the script as root!'
        echo 'We need to do administrative tasks'
        exit
    fi
}

print_banner() {
    echo '                                                                                                                                   
    ▐            ▗            ▐     ▐       ▝▜  ▝▜      ▐    ▝   ▗   ▗  
▗ ▗ ▐▄▖ ▗ ▗ ▗▗▖ ▗▟▄ ▗ ▗      ▄▟  ▄▖ ▐▄▖ ▗ ▗  ▐   ▐   ▄▖ ▐▗▖ ▗▄  ▗▟▄  ▐  
▐ ▐ ▐▘▜ ▐ ▐ ▐▘▐  ▐  ▐ ▐     ▐▘▜ ▐▘▐ ▐▘▜ ▐ ▐  ▐   ▐  ▐ ▝ ▐▘▐  ▐   ▐   ▐  
▐ ▐ ▐ ▐ ▐ ▐ ▐ ▐  ▐  ▐ ▐  ▀▘ ▐ ▐ ▐▀▀ ▐ ▐ ▐ ▐  ▐   ▐   ▀▚ ▐ ▐  ▐   ▐   ▝  
▝▄▜ ▐▙▛ ▝▄▜ ▐ ▐  ▝▄ ▝▄▜     ▝▙█ ▝▙▞ ▐▙▛ ▝▄▜  ▝▄  ▝▄ ▝▄▞ ▐ ▐ ▗▟▄  ▝▄  ▐  
                                                                                                      
 By @polkaulfield
 '
}

show_menu() {
    echo 'Choose what to do: '
    echo '1 - Apply everything (RECOMMENDED)'
    echo '2 - Disable Ubuntu report'
    echo '3 - Remove app crash popup'
    echo '4 - Remove snaps and snapd'
    echo '5 - Disable terminal ads (LTS versions)'
    echo '6 - Install flathub'
    echo '7 - Install firefox from the Mozilla repo'
    echo 'q - Exit'
    echo
}

main() {
    check_root_user
    while true; do
        print_banner
        show_menu
        read -p 'Enter your choice: ' choice
        case $choice in
        1)
            auto
            msg 'Done!'
            ask_reboot
            ;;
        2)
            disable_ubuntu_report
            msg 'Done!'
            ;;
        3)
            remove_appcrash_popup
            msg 'Done!'
            ;;
        4)
            remove_snaps
            msg 'Done!'
            ask_reboot
            ;;
        5)
            disable_terminal_ads
            msg 'Done!'
            ;;
        6)
            update_system
            setup_flathub
            msg 'Done!'
            ask_reboot
            ;;
        7)
            restore_firefox
            msg 'Done!'
            ;;

        q)
            exit 0
            ;;

        *)
            error_msg 'Wrong input!'
            ;;
        esac
    done

}

auto() {
    msg 'Updating system'
    update_system
    msg 'Disabling ubuntu report'
    disable_ubuntu_report
    msg 'Removing annoying appcrash popup'
    remove_appcrash_popup
    msg 'Removing terminal ads (if they are enabled)'
    disable_terminal_ads
    msg 'Deleting everything snap related'
    remove_snaps
    msg 'Setting up flathub'
    setup_flathub
    msg 'Restoring Firefox from mozilla repository'
    restore_firefox
    cleanup
}

(return 2> /dev/null) || main
