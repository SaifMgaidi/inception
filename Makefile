
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

# Nettoie le système Docker en supprimant les images et conteneurs non utilisés
clean: down
	@echo "Nettoyage des images Docker..."
	@docker system prune -a --force

# Nettoyage total : supprime tout, y compris les volumes de données physiques
fclean: clean
	@echo "Suppression totale des données et des volumes..."
	@sudo rm -rf /home/sm-gaidi/data/mariadb/*
	@sudo rm -rf /home/sm-gaidi/data/wordpress/*
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true

# Reconstruit tout de zéro
re: fclean all

.PHONY: all down clean fclean re