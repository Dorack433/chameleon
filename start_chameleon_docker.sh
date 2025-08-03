#!/bin/bash

# ----------------------------------------------------------------------
# Script: start_chameleon_docker.sh
# Objetivo: Iniciar o container Docker do projeto Chameleon
# Público-alvo: Jornalistas, Ativistas, Militares, Pentesters e usuários de dados sensíveis
# Requisitos: VPN anônima ativa antes de iniciar este script
# ----------------------------------------------------------------------

# Nome e tag da imagem/container
IMAGE_NAME="chameleon:local"
CONTAINER_NAME="chameleon_v.0.2.4"

# Portas a serem mapeadas
PORTS=(
    "-p 53:5353"
    "-p 53:5353/udp"
    "-p 63536:63536"
    "-p 63537:63537"
    "-p 63539:63539"
)

# Verifica se a imagem Docker do Chameleon já está disponível localmente
docker image inspect "$IMAGE_NAME" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "[INFO] Imagem Docker '$IMAGE_NAME' encontrada localmente."
else
    echo "[INFO] Imagem não encontrada. Iniciando processo de build..."

    # Compila a imagem Docker a partir do Dockerfile no diretório atual
    if ! docker build -t "$IMAGE_NAME" .; then
        echo "[ERRO] Falha ao construir a imagem Docker '$IMAGE_NAME'."
        exit 1
    fi
fi

# Verifica se o container anterior está rodando e tenta parar/remover
echo "[INFO] Parando e removendo containers antigos (se existirem)..."
docker container stop "$CONTAINER_NAME" > /dev/null 2>&1
docker container rm "$CONTAINER_NAME" > /dev/null 2>&1

# Inicia o novo container com os parâmetros apropriados
echo "[INFO] Iniciando container '$CONTAINER_NAME'..."
if ! docker run -it \
    "${PORTS[@]}" \
    --cap-add=NET_ADMIN \
    -v "$(pwd)":/chameleon \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME" /bin/bash; then
    echo "[ERRO] Falha ao iniciar o container '$CONTAINER_NAME'."
    exit 1
fi
