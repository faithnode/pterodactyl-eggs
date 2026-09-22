.PHONY: build test index clean toolbox

TOOLBOX_IMAGE := pterodactyl-eggs-toolbox
URL ?= https://pterodactyl-eggs.faithnode.com/
AUTHOR ?= admin@faithnode.com
COMMENT ?= GENERATED WITH FAITHNODE

toolbox:
	docker build -t $(TOOLBOX_IMAGE) -f ./Dockerfile .

build: toolbox clean
	@docker run --rm \
		-v "$(CURDIR):/repo" -w /repo \
		-e URL="$(URL)" -e AUTHOR="$(AUTHOR)" -e COMMENT="$(COMMENT)" \
		$(TOOLBOX_IMAGE) bin/build.sh

test: build
	@docker run --rm \
		-v "$(CURDIR):/repo" -w /repo \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(TOOLBOX_IMAGE) bin/test.sh $(EGG)

index: toolbox
	@docker run --rm \
		-v "$(CURDIR):/repo" -w /repo \
		-e URL="$(URL)" \
		$(TOOLBOX_IMAGE) bin/index.sh

clean:
	@rm -rf .dist
