#!/usr/bin/env bash

prime_print(){
    if [[ -x $(command -v prime-select) ]]; then
        echo $(prime-select query)
    fi
}

prime_toggle(){
    if [[ $(prime_print) == 'nvidia' ]]; then
        sudo prime-select intel && echo 'Mode change successful' || echo 'Mode change fail. Permissions?'
    elif [[ $(prime_print) == 'intel' ]]; then
        sudo prime-select nvidia && echo 'Mode change successful' || echo 'Mode change fail. Permissions?'
    else
        echo "Unknown prime mode!"
        return 1
    fi
}

case "$1" in
    --toggle)
        prime_toggle
        ;;
    *)
        prime_print
        ;;
esac
