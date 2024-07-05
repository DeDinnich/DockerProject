#!/bin/bash

# Vérifie si le fichier .env existe, sinon le crée avec des valeurs par défaut
if [ ! -f .env ]; then
  echo "Fichier .env non trouvé. Création en cours..."
  cat <<EOF > .env
NETWORK_NAME=custom_network
DB_USER=root
DB_PASSWORD=root
DB_ROOT_PASSWORD=root
DOCKER_HUB_USERNAME=root
DOCKER_HUB_PASSWORD=root
EOF
  echo "Fichier .env créé avec les valeurs par défaut."
fi

# Charger les variables d'environnement
export $(cat .env | xargs)

# Vérifie si Docker est installé
if ! [ -x "$(command -v docker)" ]; then
  echo "Docker n'est pas installé. Installation en cours..."
  # Installe Docker
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
else
  echo "Docker est déjà installé."
fi

# Vérifie si Docker Compose est installé
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "Docker Compose n'est pas installé. Installation en cours..."
  # Installe Docker Compose
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose est déjà installé."
fi

# Initialise Docker Swarm
docker swarm init || echo "Docker Swarm est déjà initialisé."

# Vérifie si connecté à Docker Hub
if ! docker info | grep -q "Username: $DOCKER_HUB_USERNAME"; then
  echo "Connexion à Docker Hub en cours..."
  echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
else
  echo "Déjà connecté à Docker Hub."
fi

# Crée le réseau personnalisé
docker network create --driver overlay $NETWORK_NAME

# Crée le Dockerfile pour le FrontEnd
cat <<EOF > Dockerfile-frontend
FROM nginx:latest

RUN apt-get update && apt-get install -y nano git openssh-client mailutils npm

COPY ./id_rsa /root/.ssh/id_rsa
COPY ./id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa.pub && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

EOF

# Crée le Dockerfile pour le BackEnd
cat <<EOF > Dockerfile-backend
FROM php:8.2-fpm

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    nano \
    git \
    openssh-client \
    mailutils \
    curl \
    zip \
    unzip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    nginx

# Installer les extensions PHP nécessaires
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd xml

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copier la clé SSH
COPY ./id_rsa /root/.ssh/id_rsa
COPY ./id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa.pub && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

# Copier la configuration Nginx
COPY default /etc/nginx/sites-available/default
RUN [ ! -e /etc/nginx/sites-enabled/default ] && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default || true

# Définir le répertoire de travail
WORKDIR /var/www

# Exposer le port
EXPOSE 80

# Démarrer les services Nginx et PHP-FPM
CMD service nginx start && php-fpm
EOF

# Crée le fichier de configuration Nginx
cat <<EOF > default
server {
    listen 80;
    server_name localhost;

    root /var/www/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Crée le Dockerfile pour MariaDB
cat <<EOF > Dockerfile-mariadb
FROM mariadb:latest

ENV MYSQL_ROOT_PASSWORD=\${DB_ROOT_PASSWORD}
ENV MYSQL_DATABASE=defaultdb
ENV MYSQL_USER=\${DB_USER}
ENV MYSQL_PASSWORD=\${DB_PASSWORD}

RUN apt-get update && apt-get install -y openssh-client

RUN echo "[mysqld]" >> /etc/mysql/my.cnf && \
    echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf

# Copier la clé SSH
COPY ./id_rsa /root/.ssh/id_rsa
COPY ./id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa.pub && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

EOF

# Construire les images Docker
docker build -t frontend-image -f Dockerfile-frontend .
docker build -t backend-image -f Dockerfile-backend .
docker build -t mariadb-image -f Dockerfile-mariadb .

# Pousser les images Docker sur Docker Hub
docker tag frontend-image $DOCKER_HUB_USERNAME/frontend-image:latest
docker tag backend-image $DOCKER_HUB_USERNAME/backend-image:latest
docker tag mariadb-image $DOCKER_HUB_USERNAME/mariadb-image:latest

docker push $DOCKER_HUB_USERNAME/frontend-image:latest
docker push $DOCKER_HUB_USERNAME/backend-image:latest
docker push $DOCKER_HUB_USERNAME/mariadb-image:latest

# Crée un fichier docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.7'

services:
  frontend:
    image: $DOCKER_HUB_USERNAME/frontend-image:latest
    ports:
      - "8080:80"
    volumes:
      - frontend-data:/usr/share/nginx/html
    networks:
      - \$NETWORK_NAME

  backend:
    image: $DOCKER_HUB_USERNAME/backend-image:latest
    ports:
      - "8081:80"
    volumes:
      - backend-data:/var/www
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      DB_HOST: mariadb
      DB_PORT: 3306
      DB_DATABASE: defaultdb
      DB_USERNAME: \$DB_USER
      DB_PASSWORD: \$DB_PASSWORD
    networks:
      - \$NETWORK_NAME

  admin:
    image: $DOCKER_HUB_USERNAME/frontend-image:latest
    ports:
      - "8082:80"
    volumes:
      - admin-data:/usr/share/nginx/html
    networks:
      - \$NETWORK_NAME

  mariadb:
    image: $DOCKER_HUB_USERNAME/mariadb-image:latest
    environment:
      - MYSQL_ROOT_PASSWORD=\${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=defaultdb
      - MYSQL_USER=\${DB_USER}
      - MYSQL_PASSWORD=\${DB_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mariadb-data:/var/lib/mysql
    networks:
      - \$NETWORK_NAME

volumes:
  frontend-data:
  backend-data:
  admin-data:
  mariadb-data:

networks:
  \$NETWORK_NAME:
    external: true
EOF

# Déployer les services avec Docker Swarm
docker stack deploy -c docker-compose.yml docker_project

# Message de fin
echo "Les Dockerfiles, les images Docker et le fichier docker-compose.yml ont été créés et poussés avec succès."
echo "Les services ont été déployés avec Docker Swarm. Pour vérifier l'état des services, utilisez la commande : docker stack services docker_project"