##@ [Commands]

# @see https://stackoverflow.com/a/43076457
.PHONY: execute-in-container
execute-in-container: ## Execute a command in a container. E.g. via "make execute-in-container DOCKER_SERVICE_NAME=traefik COMMAND="echo 'hello'"
	@$(if $(DOCKER_SERVICE_NAME),,$(error DOCKER_SERVICE_NAME is undefined))
	@$(if $(COMMAND),,$(error COMMAND is undefined))
	$(EXECUTE_IN_ANY_CONTAINER) $(COMMAND)
