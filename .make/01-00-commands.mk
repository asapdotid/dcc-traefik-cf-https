##@ [Utility Commands]

# @see https://stackoverflow.com/a/43076457
execute-in-container:
	@$(if $(DOCKER_SERVICE_NAME),,$(error DOCKER_SERVICE_NAME is undefined))
	@$(if $(COMMAND),,$(error COMMAND is undefined))
	$(EXECUTE_IN_ANY_CONTAINER) $(COMMAND)

.PHONY: traefik-shell
traefik-shell: ## Execute shell script in Traefik container with arguments ARGS="pwd"
	@$(EXECUTE_IN_TRAEFIK_CONTAINER) $(ARGS);

.PHONY: socket-shell
socket-shell: ## Execute shell script in Socket container with arguments ARGS="pwd"
	@$(EXECUTE_IN_DOCKER_SOCKET_CONTAINER) $(ARGS);
