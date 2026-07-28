#!/usr/bin/env bash

set -Eeuo pipefail

ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Erreur : le fichier $ENV_FILE est introuvable."
    echo "Crée-le à partir du fichier .env.example."
    exit 1
fi

# Charge les variables du fichier .env.
set -a
source "$ENV_FILE"
set +a

# Vérifie que les variables obligatoires existent.
required_variables=(
    REMOTE
    REMOTE_PATH
    LOCAL_PATH
    SITE_URL
)

for variable in "${required_variables[@]}"; do
    if [[ -z "${!variable:-}" ]]; then
        echo "Erreur : la variable $variable n'est pas définie dans $ENV_FILE."
        exit 1
    fi
done

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
    echo "Erreur : connexion SSH impossible vers $REMOTE."
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
