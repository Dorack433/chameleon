#!/bin/bash

################################################
### FUNÇÃO PARA SELECIONAR UM PAÍS ALEATÓRIO ###
################################################
# Função que seleciona aleatoriamente países da lista ACCEPTED_COUNTRIES
# Retorna 0 em caso de sucesso, 1 em caso de erro
# Variáveis dependentes:
#   - COUNTRIES: Quantidade de países a selecionar
#   - ACCEPTED_COUNTRIES: Lista de países aceitos separados por vírgula
# Saída:
#   - Define MY_COUNTRY_LIST com os países selecionados
#   - Chama boot_tor_per_country() ao finalizar

random_country() {
    # Verifica se variáveis necessárias estão definidas
    if [[ -z "${COUNTRIES}" ]]; then
        echo "Erro: Variável COUNTRIES não está definida" >&2
        return 1
    fi
    
    if [[ -z "${ACCEPTED_COUNTRIES}" ]]; then
        echo "Erro: Variável ACCEPTED_COUNTRIES não está definida" >&2
        return 1
    fi

    # Valida se COUNTRIES é um número positivo
    if ! [[ "${COUNTRIES}" =~ ^[0-9]+$ ]] || [[ "${COUNTRIES}" -le 0 ]]; then
        echo "Erro: COUNTRIES deve ser um número positivo" >&2
        return 1
    fi

    # Verifica se há países na lista aceita
    if [[ -z $(echo "${ACCEPTED_COUNTRIES}" | tr -d '[:space:]') ]]; then
        echo "Erro: Lista de países aceitos está vazia" >&2
        return 1
    fi

    local MY_COUNTRY_LIST=""
    local unique_countries=0
    local max_retries=50  # Limite para evitar loops infinitos
    local retry_count=0

    # Função auxiliar para selecionar um país único
    sort_country() {
        ((retry_count++))
        
        # Verifica se excedeu o número máximo de tentativas
        if [[ "${retry_count}" -gt "${max_retries}" ]]; then
            echo "Erro: Número máximo de tentativas alcançado ao selecionar países únicos" >&2
            return 1
        fi

        local COUNTRY_CANDIDATE
        COUNTRY_CANDIDATE=$(echo "${ACCEPTED_COUNTRIES}" | tr ',' '\n' | awk '{$1=$1};1' | grep -v '^$' | shuf -n 1)

        # Verifica se obteve um país candidato válido
        if [[ -z "${COUNTRY_CANDIDATE}" ]]; then
            echo "Erro: Falha ao selecionar um país candidato" >&2
            return 1
        fi

        # Adiciona o país à lista se for único
        if [[ -z "${MY_COUNTRY_LIST}" ]]; then
            MY_COUNTRY_LIST="${COUNTRY_CANDIDATE}"
            unique_countries=1
        else
            if ! echo "${MY_COUNTRY_LIST}" | grep -qi "^${COUNTRY_CANDIDATE}$"; then
                MY_COUNTRY_LIST=$(printf '%s\n%s' "${MY_COUNTRY_LIST}" "${COUNTRY_CANDIDATE}")
                unique_countries=$((unique_countries + 1))
            else
                # Chama recursivamente para tentar outro país
                sort_country || return 1
            fi
        fi
    }

    # Seleciona a quantidade especificada de países
    for ((i=1; i<=COUNTRIES; i++)); do
        sort_country || return 1
        retry_count=0  # Reseta o contador de tentativas para cada novo país
    done

    # Verifica se conseguiu todos os países necessários
    if [[ "${unique_countries}" -ne "${COUNTRIES}" ]]; then
        echo "Erro: Não foi possível selecionar ${COUNTRIES} países únicos" >&2
        return 1
    fi

    # Exporta a lista de países para uso global
    export MY_COUNTRY_LIST

    # Registra ação para logging (opcional)
    echo "Países selecionados: ${MY_COUNTRY_LIST}" >&2

    # Chama a função de inicialização do Tor
    if ! boot_tor_per_country; then
        echo "Erro: Falha ao inicializar Tor para os países selecionados" >&2
        return 1
    fi

    return 0
}