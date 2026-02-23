.PHONY: libs clean

libs:
	@echo "Fetching libraries..."
	@mkdir -p Libs
	@if [ ! -d "Libs/LibStub" ]; then \
		svn checkout https://repos.wowace.com/wow/libstub/trunk Libs/LibStub; \
	else \
		echo "LibStub already exists, skipping."; \
	fi
	@if [ ! -d "Libs/LibCustomGlow-1.0" ]; then \
		git clone https://github.com/muleyo/LibCustomGlow.git Libs/LibCustomGlow-1.0; \
	else \
		echo "LibCustomGlow-1.0 already exists, skipping."; \
	fi
	@echo "Done."

clean:
	rm -rf Libs/
