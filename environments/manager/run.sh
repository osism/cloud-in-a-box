#!/usr/bin/env bash

# DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN

INSTALL_ANSIBLE=${INSTALL_ANSIBLE:-true}
INSTALL_ANSIBLE_ROLES=${INSTALL_ANSIBLE_ROLES:-true}
VENV_PATH=${VENV_PATH:-.venv}
VENV_PYTHON_BIN=${VENV_PYTHON_BIN:-python3}

if [[ $# -lt 1 ]]; then
    echo "usage: $0 PLAYBOOK [ANSIBLEARGS...]"
    exit 1
fi

playbook=$1
shift

if [[ $INSTALL_ANSIBLE == "true" ]]; then
    if [[ ! -e $VENV_PATH ]]; then

        command -v virtualenv >/dev/null 2>&1 || { echo >&2 "virtualenv not installed"; exit 1; }

        virtualenv -p "$VENV_PYTHON_BIN" "$VENV_PATH"
        # shellcheck source=/dev/null
        source "$VENV_PATH/bin/activate"
        pip3 install -r requirements.txt

    else

        # shellcheck source=/dev/null
        source "$VENV_PATH/bin/activate"

    fi
fi

command -v ansible-playbook >/dev/null 2>&1 || { echo >&2 "ansible-playbook not installed"; exit 1; }
command -v ansible-galaxy >/dev/null 2>&1 || { echo >&2 "ansible-galaxy not installed"; exit 1; }

ANSIBLE_USER=${ANSIBLE_USER:-dragon}
CLEANUP=${CLEANUP:-false}

if [[ $INSTALL_ANSIBLE_ROLES == "true" ]]; then

    ansible-galaxy install -f -r requirements.yml

fi

if [[ ! -e id_rsa.operator ]]; then

    ansible-playbook \
        -i localhost, \
        -e @../secrets.yml \
        -e "keypair_dest=$(pwd)/id_rsa.operator" \
        osism.manager.keypair "$@"
fi

if [[ $playbook == "k8s" || $playbook == "netbox" || $playbook == "traefik" ]]; then

    ansible-playbook \
        --private-key id_rsa.operator \
        -i hosts \
        -e @../images.yml \
        -e @../configuration.yml \
        -e @../secrets.yml \
        -e @../infrastructure/images.yml \
        -e @../infrastructure/configuration.yml \
        -e @../infrastructure/secrets.yml \
        -e @images.yml \
        -e @configuration.yml \
        -e @secrets.yml \
        -u "$ANSIBLE_USER" \
        osism.manager."$playbook" "$@"

else

    ansible-playbook \
        --private-key id_rsa.operator \
        -i hosts \
        -e @../images.yml \
        -e @../configuration.yml \
        -e @../secrets.yml \
        -e @images.yml \
        -e @configuration.yml \
        -e @secrets.yml \
        -u "$ANSIBLE_USER" \
        osism.manager."$playbook" "$@"

fi

if [[ $CLEANUP == "true" ]]; then

    rm id_rsa.operator
    rm -rf "$VENV_PATH"

fi
