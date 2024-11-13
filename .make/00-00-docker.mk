# For local builds we always want to use "latest" as tag per default
TAG:=latest

# Enable buildkit for docker and docker-compose by default for every environment.
# For specific environments (e.g. MacBook with Apple Silicon M1 CPU) it should be turned off to work stable
# - this can be done in the .make/.env file
COMPOSE_DOCKER_CLI_BUILD?=1
DOCKER_BUILDKIT?=1

export COMPOSE_DOCKER_CLI_BUILD
export DOCKER_BUILDKIT

# Container names
## must match the names used in the docker-composer.yml files
DOCKER_SERVICE_NAME_DOCKER_SOCKET:=dockersocket
DOCKER_SERVICE_NAME_TRAEFIK:=traefik
DOCKER_SERVICE_NAME_LOGGER:=logger

# FYI:
# Naming convention for images is $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_SERVICE_NAME)-$(ENV)
# e.g.               docker.io/asapdotid/traefik:latest
# $(DOCKER_REGISTRY)---^          ^       ^      ^        docker.io
# $(DOCKER_NAMESPACE)-------------^       ^      ^        asapdotid
# $(DOCKER_SERVICE_NAME)------------------^      ^        traefik

DOCKER_DIR:=$(CURDIR)/src
DOCKER_ENV_FILE:=$(DOCKER_DIR)/.env
DOCKER_COMPOSE_DIR:=$(DOCKER_DIR)/compose
DOCKER_COMPOSE_FILE:=$(DOCKER_COMPOSE_DIR)/compose.yml
DOCKER_COMPOSE_FILE_ENV:=$(DOCKER_COMPOSE_DIR)/compose.local.yml

# we need a couple of environment variables for docker-compose so we define a make-variable that we can
# then reference later in the Makefile without having to repeat all the environment variables
DOCKER_COMPOSE_COMMAND:= \
    DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
    DOCKER_NAMESPACE=$(DOCKER_NAMESPACE) \
    DOCKER_SOCKET_VERSION=$(DOCKER_SOCKET_VERSION) \
    TRAEFIK_VERSION=$(TRAEFIK_VERSION) \
    ALPINE_VERSION=$(ALPINE_VERSION) \
    TIMEZONE=$(TIMEZONE) \
    TAG=$(TAG) \
    docker compose -p $(DOCKER_PROJECT_NAME) --env-file $(DOCKER_ENV_FILE)

DOCKER_COMPOSE:=$(DOCKER_COMPOSE_COMMAND) -f $(DOCKER_COMPOSE_FILE) -f $(DOCKER_COMPOSE_FILE_ENV)

EXECUTE_IN_ANY_CONTAINER?=

DOCKER_SERVICE_NAME?=

# we can pass EXECUTE_IN_CONTAINER=true to a make invocation in order to execute the target in a docker container.
# Caution: this only works if the command in the target is prefixed with a $(EXECUTE_IN_*_CONTAINER) variable.
# If EXECUTE_IN_CONTAINER is NOT defined, we will check if make is ALREADY executed in a docker container.
# We still need a way to FORCE the execution in a container, e.g. for Gitlab CI, because the Gitlab
# Runner is executed as a docker container BUT we want to execute commands in OUR OWN docker containers!
EXECUTE_IN_CONTAINER?=
ifndef EXECUTE_IN_CONTAINER
	# check if 'make' is executed in a docker container, see https://stackoverflow.com/a/25518538/413531
	# `wildcard $file` checks if $file exists, see https://www.gnu.org/software/make/manual/html_node/Wildcard-Function.html
	# i.e. if the result is "empty" then $file does NOT exist => we are NOT in a container
	ifeq ("$(wildcard /.dockerenv)","")
		EXECUTE_IN_CONTAINER=true
	endif
endif
ifeq ($(EXECUTE_IN_CONTAINER),true)
	EXECUTE_IN_ANY_CONTAINER:=$(DOCKER_COMPOSE) exec -T $(DOCKER_SERVICE_NAME)
    EXECUTE_IN_TRAEFIK_CONTAINER:=$(DOCKER_COMPOSE) exec -T $(DOCKER_SERVICE_NAME_TRAEFIK)
	EXECUTE_IN_DOCKER_SOCKET_CONTAINER:=$(DOCKER_COMPOSE) exec -T $(DOCKER_SERVICE_NAME_DOCKER_SOCKET)
	EXECUTE_IN_LOGGER_CONTAINER:=$(DOCKER_COMPOSE) exec -T $(DOCKER_SERVICE_NAME_LOGGER)
endif

##@ [Docker]

validate-variables:
	@$(if $(TAG),,$(error TAG is undefined))
	@$(if $(DOCKER_REGISTRY),,$(error DOCKER_REGISTRY is undefined - Did you run make-init?))
	@$(if $(DOCKER_NAMESPACE),,$(error DOCKER_NAMESPACE is undefined - Did you run make-init?))
	@$(if $(DOCKER_PROJECT_NAME),,$(error DOCKER_PROJECT_NAME is undefined - Did you run make-init?))

.docker/.env:
	@cp $(DOCKER_ENV_FILE).example $(DOCKER_ENV_FILE)

build-image: validate-variables
	@$(DOCKER_COMPOSE) build $(DOCKER_SERVICE_NAME)

.PHONY: build
build: build-image ## Build the php image and then all other docker images

.PHONY: clean
clean: ## Removing dangling and unused images
	@docker rmi -f $$(docker images -f "dangling=true" -q)

.PHONY: prune
prune: ## Remove ALL unused docker resources, including volumes
	@docker system prune -a -f --volumes

##@ [Docker Compose]

.PHONY: env
env: .docker/.env ## Setup environment variables (src/.env)
env:
	@echo "Please update your src/.env file with your settings"

.PHONY: up
up: validate-variables ## Create and start all docker containers.
	@$(DOCKER_COMPOSE) up -d $(DOCKER_SERVICE_NAME)

.PHONY: down
down: validate-variables ## Stop and remove all docker containers.
	@$(DOCKER_COMPOSE) down --remove-orphans -v

.PHONY: restart
restart: validate-variables ## Restart docker containers.
	@$(DOCKER_COMPOSE) restart $(DOCKER_SERVICE_NAME)

.PHONY: config
config: validate-variables ## List the configuration
	@$(DOCKER_COMPOSE) config $(DOCKER_SERVICE_NAME)

.PHONY: logs
logs: validate-variables ## Logs docker containers.
	@$(DOCKER_COMPOSE) logs --tail=100 -f $(DOCKER_SERVICE_NAME)

.PHONY: ps
ps: validate-variables ## Docker composer PS containers.
	@$(DOCKER_COMPOSE) ps $(DOCKER_SERVICE_NAME)
