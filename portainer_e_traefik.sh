#!/bin/bash

sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y apparmor-utils

##################################################

function prompt_input {
    local prompt_message="$1"
    local var_name="$2"
    while [ -z "${!var_name}" ]; do
        read -p "$prompt_message: " $var_name
        if [ -z "${!var_name}" ]; then
            echo "Resposta inválida. Não pode ser vazio."
        fi
    done
}

##################################################

clear

echo -e "\e[32m

        ██████╗ ██╗   ██╗    ██████╗ ██████╗  █████╗ 
        ██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔══██╗██╔══██╗
        ██████╔╝ ╚████╔╝     ██████╔╝██████╔╝███████║
        ██╔══██╗  ╚██╔╝      ██╔══██╗██╔═══╝ ██╔══██║
        ██████╔╝   ██║       ██║  ██║██║     ██║  ██║
        ╚═════╝    ╚═╝       ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝\e[0m"
echo -e "\e[32m                          BY RPA                                      \e[0m"
echo -e "\e[32m                  AUTOR ==> CARLOS FRAZÃO <==                           \e[0m"
echo -e "\e[32m\e[0m"

echo ""
echo ""
echo -e "\e[32m==============================================================================\e[0m"
echo -e "\e[32m=                                                                            =\e[0m"
echo -e "\e[32m=                 \e[33mPreencha as informações solicitadas abaixo\e[32m                 =\e[0m"
echo -e "\e[32m=                                                                            =\e[0m"
echo -e "\e[32m==============================================================================\e[0m"
echo ""

##################################################

# Gerar Senha do Usuario do Portainer
senhaportainer=$(openssl rand -base64 20 | tr -dc 'a-zA-Z0-9' | head -c20)

##################################################

while true; do

    prompt_input "Digite seu domínio para acessar o Portainer (ex: portainer.dominio.com)" portainer
    echo ""
    prompt_input "Crie o nome do usuario Portainer (ex: Admin)" usuarioportainer
    echo ""
    prompt_input "Já foi criada uma senha para o usuario Portainer automaticamente, caso não queira crie uma nova (Copia: $senhaportainer)" passwordportainer
    echo ""    
    prompt_input "Digite o seu Email (ex: meuemail@gmail.com)" emaill
    echo ""
    prompt_input "Digite a senha do aplicativo do Gmail" app
    echo ""
    prompt_input "Digite o nome do seu Servidor (ex: meuservidor1)" meuservidor
    echo ""

    clear

 # Pergunte ao usuário se as informações estão corretas

    echo ""  
    echo "As informações fornecidas estão corretas?"
    echo ""
    echo -e "\033[34m- Domínio do Portainer:\033[33m $portainer\033[0m"
    echo ""
    echo -e "\033[34m- Usuario do Portainer:\033[33m $usuarioportainer\033[0m"
    echo ""
    echo -e "\033[34m- Senha do Usuario do Portainer:\033[33m $passwordportainer\033[0m"
    echo ""   
    echo -e "\033[34m- Proxy Reverso Email:\033[33m $emaill\033[0m"
    echo ""
    echo -e "\033[34m- Senha do aplicativo Gmail:\033[33m $app\033[0m"
    echo ""
    echo -e "\033[34m- Nome do novo Servidor:\033[33m $meuservidor\033[0m"
    echo ""  

    read -p "Digite 'Y' para continuar ou 'N' para sair do script: " resposta

    if [ "$resposta" = "Y" ] || [ "$resposta" = "y" ]; then
        break
    elif [ "$resposta" = "N" ] || [ "$resposta" = "n" ]; then
        echo "Saindo do script."
        exit 1  # Isso encerrará o script
    else
        echo "Entrada inválida. Digite 'Y' para continuar ou 'N' para sair do script."
    fi

done

##################################################

# Trocar nome servidor
sudo hostnamectl set-hostname "$meuservidor"

# Altera localhost para
sudo sed -i "s/^127\.0\.0\.1 localhost$/127.0.0.1 $meuservidor/" /etc/hosts

##################################################

sudo curl -fsSL https://get.docker.com | bash

# Pausa de 15 segundos
sleep 15

sudo docker swarm init

# Solicita a entrada do usuário
read -p "Você deseja continuar com a execução do script? (y/n): " resposta

# Verifica a resposta do usuário
case $resposta in
    [Yy]* ) 
        # Continue a execução se a resposta for 'y' ou 'Y'
        echo "Continuando a execução..."
        # Coloque o resto do seu script aqui
        ;;
    [Nn]* ) 
        # Saia do script se a resposta for 'n' ou 'N'
        echo "Saindo do script."
        exit
        ;;
    * ) 
        # Se a resposta for diferente de 'y' ou 'n', informe o usuário
        echo "Por favor, responda com 'y' ou 'n'."
        ;;
esac

sudo docker network create --driver=overlay minha_rede

##################################################

clear

cd

cd /home/ubuntu

cat > traefik.yaml << EOL
version: "3.7"

services:

  traefik:
    image: traefik:latest
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=minha_rede"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=$emaill"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/etc/traefik/letsencrypt/acme.json"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=hostregexp()" #{host:.+}
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "vol_certificates:/etc/traefik/letsencrypt"
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
    networks:
      - minha_rede

volumes:

  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:

  minha_rede:
    external: true
    name: minha_rede
EOL

sudo sed -i 's/traefik\.http\.routers\.http-catchall\.rule=hostregexp()/traefik.http.routers.http-catchall.rule=hostregexp(`{host:.+}`)/' /home/ubuntu/traefik.yaml

sudo docker stack deploy --prune --resolve-image always -c traefik.yaml traefik

# Pausa de 15 segundos
sleep 15

##################################################

# Instalação portainer

cat > portainer.yaml << EOL
version: "3.7"

services:

  agent:
    image: portainer/agent:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - minha_rede
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:latest
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer_data:/data
    networks:
      - minha_rede
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=minha_rede"
        - "traefik.http.routers.portainer.rule=Host()" #portainer
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"
        - "traefik.http.routers.portainer.tls.certresolver=letsencryptresolver"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  minha_rede:
    external: true
    attachable: true
    name: minha_rede

volumes:
  portainer_data:
    external: true
    name: portainer_data
EOL

sudo sed -i "s/- \"traefik\.http\.routers\.portainer\.rule=Host()\"/- \"traefik.http.routers.portainer.rule=Host(\`$portainer\`)\"/" /home/ubuntu/portainer.yaml

sudo docker stack deploy --prune --resolve-image always -c portainer.yaml portainer

##################################################

cd install_P_T_TY_N_E_W_C_/Port_Traef

# Exibe o banner informativo

display_banner() {
  echo -e "\e[32m             ===================================="
  echo -e "                     FAÇA A SUA ESCOLHA\e[0m"
  echo -e "\e[32m             ====================================\e[0m"
}

# Função para exibir o menu
display_menu() { 
  echo ""
  echo -e "\e[34mEscolha uma opção para instalação:\e[0m"
  echo ""
  echo -e "  1. \e[31mInstalar TYPEBOT N8N EVOLUTION-API CHATWOOT\e[0m"   
  echo -e "  2. \e[31mInstalar TYPEBOT N8N EVOLUTION-API\e[0m"
  echo -e "  3. \e[31mInstalar TYPEBOT EVOLUTION-API\e[0m"  
  echo -e "  4. \e[31mSair\e[0m"
  echo ""
}

#########################################################

# Exibe o banner informativo
display_banner

# Exibe o menu
display_menu

#########################################################

# Ler a opção escolhida pelo usuário
read -p "Digite o número da opção desejada e pressione Enter: " option

# Executa a ação correspondente à opção escolhida
case $option in
  1)
    # Adicione aqui os comandos para instalar o TYPEBOT N8N EVOLUTION-API CHATWOOT
    git clone https://github.com/CarlosRPA/Repos_TY_N_E_C_.git
    cd Repos_TY_N_E_C_
    chmod +x _TY_N_E_C_.sh
    ./_TY_N_E_C_.sh
    ;;
  2)
    # Adicione aqui os comandos para instalar o TYPEBOT N8N EVOLUTION-API
    git clone https://github.com/CarlosRPA/_TY_N_E_.git
    cd _TY_N_E_
    chmod +x Repos_TY_N_E_.sh
    ./Repos_TY_N_E_.sh
    ;;
  3)
    # Adicione aqui os comandos para instalar o TYPEBOT EVOLUTION-API
    git clone https://github.com/CarlosRPA/_TY_E_.git
    cd _TY_E_
    chmod +x Repos_TY_E_.sh
    ./Repos_TY_E_.sh
    ;;    
  4)
    # Sair
    echo "Saindo do instalador."
    exit 0
    ;; 
  *)
    echo "Opção inválida. Por favor, escolha uma opção válida."
    ;;
esac

# Fim do script
exit 0
