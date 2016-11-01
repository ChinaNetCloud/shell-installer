SRC_DIR=$(shell pwd)
AGGREGATE_PATH=/repo-aggregate

.PHONY: deploy
deploy:
	cp $(SRC_DIR)/src/opsstack-install.sh $(AGGREGATE_PATH)/ || true
