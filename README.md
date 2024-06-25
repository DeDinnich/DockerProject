# DockerProject

## Description

Ce projet a pour objectif de conteneuriser une application full stack existante, composée d'un front-end, d'un back-end et d'une base de données, en utilisant Docker et Docker Compose. Chaque composant de l'application est déployé dans des conteneurs Docker distincts et orchestré à l'aide de Docker Swarm.

## Prérequis

- Docker
- Docker Compose
- Clé SSH configurée pour GitHub
- Compte Docker Hub

## Installation

Pour installer Docker et Docker Compose, ainsi que pour initialiser Docker Swarm et configurer les conteneurs, exécutez le script `Deploy.sh` :

```bash
sudo ./Deploy.sh
```

## Explications du Script

### Vérification et Installation de Docker et Docker Compose

Le script vérifie d’abord si Docker et Docker Compose sont installés. Si ce n’est pas le cas, il les installe.

### Initialisation de Docker Swarm

Le script initialise Docker Swarm, nécessaire pour orchestrer les conteneurs.

### Connexion à Docker Hub

Le script vérifie si l’utilisateur est connecté à Docker Hub. Sinon, il effectue la connexion en utilisant les informations d’identification fournies.

### Création des Dockerfiles

Trois Dockerfiles sont créés pour le front-end (Nginx), le back-end (PHP avec Nginx) et la base de données (MariaDB). Les Dockerfiles incluent l’installation des dépendances nécessaires et la configuration des conteneurs.

### Construction et Poussée des Images Docker

Les images Docker sont construites à partir des Dockerfiles et poussées sur Docker Hub.

### Création de docker-compose.yml

Un fichier docker-compose.yml est créé pour définir les services front-end, back-end, admin et mariadb, ainsi que les volumes pour la persistance des données.

### Déploiement des Services avec Docker Swarm

Les services sont déployés avec Docker Swarm à l’aide du fichier docker-compose.yml.

## Explications sur Docker

### Dockerfiles

- Front-end (Nginx)
  - Installation de Nginx et des dépendances nécessaires.
  - Configuration de SSH pour accéder à GitHub.
- Back-end (PHP avec Nginx)
  - Installation de PHP, Nginx et des dépendances nécessaires.
  - Configuration des extensions PHP.
  - Configuration de SSH pour accéder à GitHub.
- Base de Données (MariaDB)
  - Installation de MariaDB et configuration des paramètres de base de données.
  - Configuration de SSH pour accéder à GitHub.

### Stack Docker

La stack Docker est définie dans le fichier docker-compose.yml. Elle comprend quatre services : frontend, backend, admin et mariadb. Chaque service est configuré avec les ports, volumes et variables d’environnement nécessaires.

### Réseau Docker

Un réseau Docker par défaut est utilisé pour permettre la communication sécurisée entre les services. Les conteneurs utilisent les noms de service pour se connecter les uns aux autres.

### Volumes Docker

Les volumes Docker sont configurés pour garantir la persistance des données. Les volumes suivants sont définis :

- frontend-data
- backend-data
- admin-data
- mariadb-data

### Liens vers les Images Docker Hub

- [Frontend Image](https://hub.docker.com/repository/docker/dedinnich/frontend-image)
- [Backend Image](https://hub.docker.com/repository/docker/dedinnich/backend-image)
- [MariaDB Image](https://hub.docker.com/repository/docker/dedinnich/mariadb-image)

## Utilisation

Pour vérifier l’état des services déployés, utilisez la commande suivante :

```bash
docker stack services ls
```
