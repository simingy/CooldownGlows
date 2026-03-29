.PHONY: build clean

clean:
	rm -rf build/

build:
	@echo "Building CooldownGlows..."
	@rm -rf build
	@mkdir -p build/CooldownGlows
	@rsync -am . build/CooldownGlows/ \
		--exclude="/build/" \
		--exclude="/.git/" \
		--exclude="/.github/" \
		--exclude="/.gitignore" \
		--exclude="/.pkgmeta" \
		--exclude="README.md" \
		--exclude="DESIGN.md" \
		--exclude="Makefile" \
		--exclude="AGENTS.md"
	@echo "Build complete. Addon is in build/CooldownGlows"
