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
