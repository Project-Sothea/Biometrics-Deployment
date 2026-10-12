#!/bin/sh
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    echo "Please do not run this script as root. Create a user and run. Exiting."
    exit 1
fi

for cmd in git podman ssh psql systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# PostgreSQL check
if ! systemctl is-active --quiet postgresql.service; then
    echo "PostgreSQL service is not active."
    exit 1
fi

if ! PGCONNECT_TIMEOUT=5 psql -X -h 127.0.0.1 -U biometrics -d biometrics -w -v ON_ERROR_STOP=1 -c 'SELECT 1;'; then
    echo "PostgreSQL connection or authentication failed."
    exit 1
fi

# Check SSH connection to GitHub
exit_code=0
ssh_output=$(ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1) || exit_code=$?

git_username=$(printf '%s\n' "$ssh_output" | sed -n 's/^Hi \([^!]*\)!.*/\1/p')

if [ "$exit_code" -ne 1 ] || [ -z "$git_username" ]; then
    printf 'GitHub SSH authentication failed:\n%s\n' "$ssh_output" >&2
    exit 1
fi
echo "SSH connection to GitHub successful. Logged in as: $git_username"

cd ~
if [ ! -d ~/deployment ]; then
    git clone git@github.com:Project-Sothea/Biometrics-Deployment.git ~/deployment
else
    cd ~/deployment
    git pull --ff-only
fi
if [ ! -d ~/backend ]; then
    git clone git@github.com:Project-Sothea/Sothea-Backend.git ~/backend
else
    cd ~/backend
    git pull --ff-only
fi
if [ ! -d ~/frontend ]; then
    git clone git@github.com:Project-Sothea/Sothea-Frontend.git ~/frontend
else
    cd ~/frontend
    git pull --ff-only
fi

cd ~
podman build -t backend ~/backend
podman build -t frontend ~/frontend --build-arg VITE_API_URL=/api

quadlet_path="$HOME/.config/containers/systemd"
mkdir -p "$HOME/.config/containers"

if [ -e "$quadlet_path" ] && [ ! -L "$quadlet_path" ]; then
    echo "Error: $quadlet_path exists and is not a symlink." >&2
    exit 1
fi

ln -sfnT "$HOME/deployment/quadlets" "$quadlet_path"

systemctl --user daemon-reload
systemctl --user restart biometrics-pod.service
