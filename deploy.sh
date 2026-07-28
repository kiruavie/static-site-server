#!/usr/bin/env bash

set -Eeuo pipefail

REMOTE="prod_vps"
REMOTE_PATH="/var/www/static-site"
LOCAL_PATH="./site/"
SITE_URL="${MYIP}"

echo "Vérification du dossier local..."

if [[ ! -d "$LOCAL_PATH" ]]; then
    echo "Erreur : le dossier $LOCAL_PATH n'existe pas."
    exit 1
fi

echo "Vérification de la connexion SSH..."

if ! ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "$REMOTE" \
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
    "${REMOTE}:${REMOTE_PATH}/"

echo "Vérification du site distant..."

if curl \
    --fail \
    --silent \
    --show-error \
    "$SITE_URL" \
    > /dev/null; then
    echo "Déploiement terminé avec succès."
    echo "Site : $SITE_URL"
else
    echo "Les fichiers ont été transférés, mais le site ne répond pas."
    exit 1
fi
