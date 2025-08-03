#!/bin/bash
##################################################################################
# CHAMELEON.SH                                                                   #
#                                                                                #
# Ferramenta de anonimato que permite usar múltiplas instâncias TOR de forma     #
# distribuída e balanceada, oferecendo estabilidade, velocidade e segurança.     #
#                                                                                #
# Público-alvo: jornalistas, ativistas, profissionais de segurança e usuários    #
# avançados que necessitam de privacidade em alto nível.                         #
#                                                                                #
# Versão aprimorada com boas práticas, tratamento de erros e estrutura clara.    #
##################################################################################

# ---------------------------- CONFIGURAÇÕES E DEPENDÊNCIAS ---------------------------- #
set -euo pipefail  # Boa prática: falhar no primeiro erro, variáveis indefinidas causam erro
trap 'echo "[ERRO] Ocorreu uma falha no script. Verifique os logs." >&2' ERR

# Carregando configurações e funções externas
for f in \
  settings.cfg banner.func user_start_input.func help.func \
  loadbalancing_choice.func killprevious_instances.func pre_loading.func \
  check_if_port_available.func random_country.func boot_tor_per_country.func \
  boot_tor_instances.func; do
  if [[ -f "$f" ]]; then
    source "$f"
  else
    echo "[ERRO] Arquivo requerido não encontrado: $f" >&2
    exit 1
  fi
done

# ---------------------------- FLUXO PRINCIPAL ---------------------------- #

source settings.cfg                   # Arquivo principal de configuração
source banner.func                    # Banner do script
source user_start_input.func          # Verifica a entrada inicial do usuário
source check_dependencies.func        # Checa as dependencias faltantes
source help.func                      # Mensagem de ajuda
source loadbalancing_choice.func      # Define o algoritmo de balanceamento de carga
source killprevious_instances.func    # Mata instâncias anteriores em execução
source pre_loading.func               # Prepara o ambiente para execução
source check_if_port_available.func   # Verifica se a porta está disponível antes de vincular
source random_country.func            # Seleciona países aleatórios antes de iniciar
source boot_tor_per_country.func      # Inicia a instância TOR baseada na lista de países selecionados
source boot_tor_instances.func        # Configura e inicia as instâncias TOR e PRIVOXY

# Seleção e inicialização de países/instâncias
if [[ "${MY_COUNTRY_LIST}" != "RANDOM" ]]; then
  MY_COUNTRY_LIST=$(echo "$MY_COUNTRY_LIST" | tr ',' '\n' | sort -R)
  boot_tor_per_country
else
  MY_COUNTRY_LIST="FIRST_EXECUTION"
  random_country
fi

# Força novos circuitos TOR (renovação aleatória)
sort -R "${TOR_TEMP_FILES}/temp_force_new_circuit.txt" |
  sed 's|\.exp|.exp\\nsleep 1|g' >> "${TOR_TEMP_FILES}/force_new_circuit.sh"
echo "done" >> "${TOR_TEMP_FILES}/force_new_circuit.sh"
rm -f "${TOR_TEMP_FILES}/temp_force_new_circuit.txt"

# Ajuste de permissões e salva lista de países utilizados
chown -R "$USER_ID" "$TOR_TEMP_FILES"
chmod 700 -R "$TOR_TEMP_FILES"
echo "$MY_COUNTRY_LIST" > "$TOR_TEMP_FILES/current_country_list.txt"
echo "$MY_COUNTRY_LIST" > "$TOR_TEMP_FILES/used_country_list.txt"

# Atualiza configuração do HAProxy
for f in haproxy_TOR_HTTP_PROXY.txt haproxy_http_backend.txt haproxy_TOR_SOCKS_PROXY.txt haproxy_socks_backend.txt; do
  cat "$TOR_TEMP_FILES/$f" >> "$MASTER_PROXY_CFG" && rm -f "$TOR_TEMP_FILES/$f"
done

# Inicia o balanceador de carga principal
"$HAPROXY_PATH" -f "$MASTER_PROXY_CFG" >/dev/null 2>&1 &

# Configura a política de distribuição do DNS
# echo "setServerPolicy(roundrobin)" >> "$TOR_TEMP_FILES/dnsdist.conf"
echo "setServerPolicy(leastOutstanding)" >> "$TOR_TEMP_FILES/dnsdist.conf"

# Define variáveis de ambiente no .bashrc do usuário
BASHRC_TEMP="${TOR_TEMP_FILES}/.bashrc_temp"
grep -vE "CHAMELEON|no_proxy|all_proxy|http_proxy|https_proxy|ftp_proxy|rsync_proxy" \
  "/home/$USER_ID/.bashrc" > "$BASHRC_TEMP"
echo "##### CRIADO POR CHAMELEON #####" >> "$BASHRC_TEMP"
for proxy in all http https ftp rsync; do
  echo "export ${proxy}_proxy=http://127.0.0.1:${MASTER_PROXY_SOCKS_PORT}" >> "$BASHRC_TEMP"
done
mv -f "$BASHRC_TEMP" "/home/$USER_ID/.bashrc"

# Status final do ambiente e instruções ao usuário
banner
cat <<EOF
Dicas:
 1) Aguarde até que todas as (${TOR_CURRENT_INSTANCE}) instâncias TOR estejam prontas.
 2) Monitoramento de saúde:
    http://127.0.0.1:${MASTER_PROXY_STAT_PORT}${MASTER_PROXY_STAT_URI}
    Usuário: ${USER_ID} | Senha: ${MASTER_PROXY_STAT_PWD}
 3) Configure o proxy no navegador:
    SOCKSv5:    127.0.0.1:${MASTER_PROXY_SOCKS_PORT}
    HTTP/HTTPS: 127.0.0.1:${MASTER_PROXY_HTTP_PORT}
EOF

if [[ "$COUNTRY_LIST_CONTROLS" != "none" ]]; then
  echo -e "\nInstâncias TOR por país: $TOR_INSTANCES | Países: $COUNTRIES\nTotal: $TOR_CURRENT_INSTANCE | Relay forçado: $COUNTRY_LIST_CONTROLS"
  echo "Lista de países usados:"
  echo "$MY_COUNTRY_LIST" | tr '\n' ',' | sed 's/,\$//'  # Remove última vírgula
else
  echo -e "\nTotal de instâncias TOR: $TOR_CURRENT_INSTANCE"
  echo "TOR está controlando dinamicamente entrada/saída."
fi

# Executa troca de países dinâmica, se ativado
if [[ "$CHANGE_COUNTRY_ONTHEFLY" == "YES" && "$COUNTRIES" -gt 5 && "$MY_COUNTRY_LIST" == "FIRST_EXECUTION" ]]; then
  /bin/bash change_country_on_the_fly.func >/dev/null 2>&1 &
  echo "Chameleon mudará país automaticamente a cada ${CHANGE_COUNTRY_INTERVAL} segundos."
fi

# Exibe status, se configurado
[[ "$SHOW_STATUS" == "yes" ]] && /bin/bash status.func &

# Mantém o balanceador de DNS rodando
/bin/bash dnsloadbalance.func >/dev/null 2>&1

# Encerra com limpeza
killprevious_instances >/dev/null
exit 0
