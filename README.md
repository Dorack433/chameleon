🦎 Chameleon Proxy Tool

Um script Bash avançado para gerenciamento de múltiplas instâncias Tor, Privoxy e HAProxy, com balanceamento de carga, roteamento de tráfego anônimo e suporte a múltiplos países.

Ideal para quem busca privacidade, anonimato, bypass de censura e controle completo sobre a infraestrutura proxy.

📦 Recursos Principais

🌍 Suporte a múltiplos países (US, BR, DE, etc.)
🔁 Algoritmos de balanceamento: roundrobin, leastconn, random
🧩 Arquitetura modular e personalizável via settings.cfg
🐳 Suporte completo ao Docker
🚦 Auto-verificação de dependências
📈 Modo detalhado (--verbose) para depuração
🔐 Tor Bridges compatíveis (obfs4, meek, snowflake – configurável)
📥 Instalação

Pré-requisitos
Certifique-se de ter os seguintes pacotes instalados:

bash (versão 4.0+)
git
docker (opcional)
Clonar o repositório
git clone https://github.com/seu-usuario/chameleon-proxy.git
cd chameleon-proxy
3. Instalar dependências
./install_dependencies.sh
Esse script instala: tor, privoxy, haproxy, obfs4proxy, entre outros.

4. (Opcional) Tornar o script global
sudo cp chameleon.sh /usr/local/bin/chameleon
sudo chmod +x /usr/local/bin/chameleon
Agora você pode rodar com:

chameleon --start
🚀 Como Usar
✅ Modo Básico
./chameleon.sh --start --country BR,US,DE
Inicia múltiplas instâncias com saída em Brasil, EUA e Alemanha.

🧪 Exemplos Avançados
./chameleon.sh \
  --start \
  --country US,DE,NL,JP \
  --load-balance leastconn \
  --max-instances 8 \
  --verbose
🛠️ Opções Disponíveis
Comando	Descrição
--start	Inicia o proxy com as configurações definidas
--stop	Encerra todas as instâncias
--restart	Reinicia todos os serviços
--country XX,YY,ZZ	Define a lista de países (ex: US,DE,JP)
--load-balance algo	Define algoritmo (roundrobin, leastconn, random)
--check-deps	Verifica dependências do sistema
--docker	Executa o ambiente via Docker
--help	Exibe a ajuda completa

🐳 Executando com Docker
1. Build da imagem
docker build -t chameleon-proxy .
2. Executar container
docker run -d --name chameleon \
  -p 8118:8118 \     # Privoxy
  -p 9050:9050 \     # Tor SOCKS
  -p 8080:8080 \     # HAProxy
  chameleon-proxy \
  --country US,DE --load-balance roundrobin
⚙️ Configuração Avançada
Você pode personalizar o comportamento do script no arquivo settings.cfg.

Exemplo:
DEFAULT_COUNTRIES="US,DE,FR"
MAX_TOR_INSTANCES=5
LOAD_BALANCER_ALGO="leastconn"
TOR_BRIDGE_TYPE="obfs4"
ENABLE_VERBOSE=true
❓ FAQ
🔎 Como verificar se o proxy está funcionando?

curl --proxy http://localhost:8118 ifconfig.me
Deve retornar o IP de algum país configurado (ex: EUA ou Alemanha).

🌐 Como mudar os países sem reiniciar tudo?

chameleon --update-country CA,MX,BR
⚠️ Porta em uso – como resolver?
Verifique quais portas estão ocupadas:

sudo netstat -tulnp | grep 8118
Edite settings.cfg para definir outras portas se necessário.