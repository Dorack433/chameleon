#!/bin/bash
######################################################################
# CHAMELEON NETWORK - SCRIPT DE INÍCIO DO DOCKER CHAMELEON           #
######################################################################
# Este script é o ponto de entrada do container CHAMELEON. Ele       #
# configura o ambiente e executa o script principal chameleon.sh     #
# como o usuário não privilegiado 'chameleon'.                       #
######################################################################

set -euo pipefail  # Melhora a segurança e o controle de erros do script

# Função para exibir mensagens de erro de forma padronizada
erro() {
    echo "[ERRO] $1" >&2
    exit 1
}

# Função para verificar se um comando existe
comando_existe() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica se o diretório /chameleon existe
if [ ! -d /chameleon ]; then
    erro "Diretório /chameleon não encontrado. Certifique-se de que está montado corretamente no container."
fi

# Muda para o diretório /chameleon
cd /chameleon || erro "Falha ao acessar o diretório /chameleon."

# Verifica se o script principal existe e tem permissão de execução
if [ ! -x /chameleon/chameleon.sh ]; then
    erro "O script /chameleon/chameleon.sh não existe ou não tem permissão de execução."
fi

# (Opcional) Descomente a linha abaixo se quiser aplicar regras de firewall antes de iniciar
# if [ -x /chameleon/iptables_firewall.func ]; then
#     /bin/bash /chameleon/iptables_firewall.func || erro "Falha ao aplicar regras de firewall."
# fi

# Verifica se o usuário 'chameleon' existe
if ! id -u chameleon >/dev/null 2>&1; then
    erro "Usuário 'chameleon' não encontrado no sistema."
fi

# Executa o script como usuário 'chameleon' com os parâmetros desejados
echo "[INFO] Iniciando o Chameleon como usuário 'chameleon'..."
su -l chameleon -c "cd /chameleon && /bin/bash /chameleon/chameleon.sh -i 1 -c 10 -re exit" || erro "Falha ao executar o script chameleon.sh como 'chameleon'."

echo "[INFO] Execução finalizada com sucesso."
