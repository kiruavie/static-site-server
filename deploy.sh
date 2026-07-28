#!/usr/bin/env bash

set -Eeuo pipefail

REMOTE_USER="harlem_dev"
REMOTE_HOST="prod_vps"
REMOTE_PATH="/var/www/static-site"
LOCAL_PATH="./site/"

echo "Vérification du dossier local..."

if [[ ! -d "$LOCAL_PATH" ]]; then
    echo "Erreur : le dossier $LOCAL_PATH n'existe pas."
    exit 1
fi

echo "Vérification de la connexion SSH..."

if ! ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "${REMOTE_USER}@${REMOTE_HOST}" \
    "exit"; then
    echo "Erreur : connexion SSH impossible."
    exit 1
fi

echo "Déploiement du site..."

rsync \
    --archive \
    --verbose \
    --compress \
    --delete \
    --human-readable \
    --exclude=".git/" \
    "$LOCAL_PATH" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

echo "Vérification du site distant..."

if curl \
    --fail \
    --silent \
    --show-error \
    "http://${REMOTE_HOST}" \
    > /dev/null; then
    echo "Déploiement terminé avec succès."
    echo "Site : http://${REMOTE_HOST}"
else
    echo "Les fichiers ont été transférés, mais le site ne répond pas."
    exit 1
fi
