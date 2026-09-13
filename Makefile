
NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml

# La règle principale qui lance toute l'infrastructure
all: 
	@echo "Création des dossiers de volumes s'ils n'existent pas..."
	@sudo mkdir -p /home/sm-gaidi/data/mariadb
	@sudo mkdir -p /home/sm-gaidi/data/wordpress
	@echo "Lancement des conteneurs en arrière-plan..."
	@docker compose -f $(COMPOSE_FILE) up -d --build

# Arrête les conteneurs et supprime le réseau interne, mais conserve les volumes intacts
down:
	@echo "Arrêt de l'infrastructure..."
	@docker compose -f $(COMPOSE_FILE) down

# Nettoie les ressources Docker de ce projet
clean:
	@echo "Nettoyage des ressources Docker du projet..."
	@docker compose -f $(COMPOSE_FILE) down --rmi local --remove-orphans


# Nettoyage total : supprime les ressources Docker et les données du projet
fclean:
	@echo "Suppression des ressources et des données du projet..."
	@docker compose -f $(COMPOSE_FILE) down -v --rmi local --remove-orphans
	@sudo rm -rf /home/sm-gaidi/data/mariadb
	@sudo rm -rf /home/sm-gaidi/data/wordpress

# Reconstruit tout de zéro
re: fclean all

.PHONY: all down clean fclean re