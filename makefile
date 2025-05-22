#! SIMPLE COMMANDS
#! ANSI COLOUR CODES
ORANGE=\033[0;33m
GREEN=\033[38;5;35m
PURPLE=\033[0;35m

#! FUNCTION TO CREATE A BOX AROUND A TEXT
define box
	@echo "$(GREEN)╔══════════════════════════════════════╗$(ORANGE)"
	@echo "$(GREEN)║$(ORANGE) $1$(GREEN) ║$(ORANGE)"
	@echo "$(GREEN)╚══════════════════════════════════════╝$(ORANGE)"
endef

#! FUNCTION TO DISPLAY LOADING ANIMATION
define loading
	@chars='| / - \\'; \
	for i in $$(seq 1 10); do \
		for c in $$chars; do \
			printf "\r$(PURPLE)🔄 Loading... $$c$(RESET)"; \
			sleep 0.1; \
		done; \
	done; \
	printf "\r$(GREEN)✅ Done!          $(RESET)\n"
endef

cleanAndGet:
	flutter clean && rm pubspec.lock && rm -rf .pub && flutter pub get
	$(call box,$(ORANGE)::: CLEAN AND GET COMMAND $(PURPLE)==>> $(GREEN)Done.)

gitFetchAndCheckoutMain:
	git fetch --prune --all && git pull --all && git checkout main && git pull && git remote prune origin
	$(call box,$(ORANGE)::: GIT FETCH & PULL ALL BRANCHES THEN CHECKOUT TO MAIN $(PURPLE)==>> $(GREEN)Done)

pubGet:
	flutter pub get && clear
	$(call box,$(ORANGE):::PUB GET COMMAND $(PURPLE)   ==>> $(GREEN)Done.)

commit:
	@read -p "Enter commit message: " msg && \
	git add -A && \
	git commit -m "$$msg" && \
	git push && clear

cleanIOS:
	$(call box,$(ORANGE)🚀 STARTING PROJECT CLEANUP $(PURPLE)==>>)
	$(call loading)
	cd example
	flutter clean && flutter pub get
	cd ios && rm -rf Pods Podfile.lock && pod install
	$(call box,$(GREEN)🎉 PROJECT BUILD COMPLETE $(PURPLE)==>> $(GREEN)Done)