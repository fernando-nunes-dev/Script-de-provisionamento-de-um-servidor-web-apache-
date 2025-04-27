#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root" >&2
    exit 1
fi

echo "Atualizando pacotes do sistema..."
apt-get update -y && apt-get upgrade -y

echo "Instalando pacotes adicionais..."
apt-get install -y sudo curl git

echo "Criando grupos de usuários..."
grupos=("dev" "adm" "suporte")

for grupo in "${grupos[@]}"; do
    if ! getent group "$grupo" >/dev/null; then
        groupadd "$grupo"
        echo "Grupo $grupo criado com sucesso."
    else
        echo "Grupo $grupo já existe."
    fi
done

echo "Criando usuários..."
usuarios=(
    "maria:dev"
    "joao:adm"
    "carlos:suporte"
    "debora:dev"
)

for usuario_info in "${usuarios[@]}"; do
    usuario=$(echo "$usuario_info" | cut -d: -f1)
    grupo=$(echo "$usuario_info" | cut -d: -f2)
    
    if ! id -u "$usuario" >/dev/null 2>&1; then
        useradd -m -s /bin/bash -G "$grupo" "$usuario"
        echo "Usuário $usuario criado e adicionado ao grupo $grupo."
        
        # Definir senha padrão (será solicitada a alteração no primeiro login)
        echo "$usuario:Senha123" | chpasswd
        chage -d 0 "$usuario"
    else
        echo "Usuário $usuario já existe."
    fi
done

echo "Criando diretórios e configurando permissões..."
diretorios=(
    "/publico"
    "/adm"
    "/venv"
    "/suporte"
    "/dev"
)

for diretorio in "${diretorios[@]}"; do
    if [ ! -d "$diretorio" ]; then
        mkdir -p "$diretorio"
        echo "Diretório $diretorio criado."
    else
        echo "Diretório $diretorio já existe."
    fi
done

chmod 777 /publico
chown root:adm /adm
chmod 770 /adm
chown root:dev /dev
chmod 770 /dev
chown root:suporte /suporte
chmod 770 /suporte
chmod 755 /venv

echo "Configuração de permissões concluída."

echo "Configurando sudo para grupos administrativos..."
if ! grep -q "%adm ALL=(ALL) ALL" /etc/sudoers; then
    echo "%adm ALL=(ALL) ALL" >> /etc/sudoers
    echo "%dev ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get" >> /etc/sudoers
fi

echo "Infraestrutura básica configurada com sucesso!"