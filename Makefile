.PHONY: help lint test format build-web build-web-pages ci clean

FLUTTER ?= flutter
DART ?= dart
FLUTTERRUN := $(FLUTTER) --suppress-analytics
DARTRUN := $(DART) --disable-analytics

help:
	@echo "Available tasks:"
	@echo "  make lint          # Run flutter analyze"
	@echo "  make test          # Run flutter test"
	@echo "  make format        # Format code with dart format"
	@echo "  make build-web     # Build web app (release mode)"
	@echo "  make build-web-pages BASE_HREF=/flipout/ # Build for GitHub Pages with base-href"
	@echo "  make ci            # Run lint + test + build-web"
	@echo "  make clean         # Clean build artifacts"

lint:
	HOME=$(PWD) $(FLUTTERRUN) analyze

test:
	HOME=$(PWD) $(FLUTTERRUN) test

format:
	HOME=$(PWD) $(DARTRUN) format lib/ test/

format-check:
	HOME=$(PWD) $(DARTRUN) format --set-exit-if-changed lib/ test/

build-web:
	HOME=$(PWD) $(FLUTTERRUN) build web --release

build-web-pages:
	HOME=$(PWD) $(FLUTTERRUN) build web --release --base-href "$(BASE_HREF)"

ci: lint format-check test build-web

clean:
	HOME=$(PWD) $(FLUTTERRUN) clean
	rm -rf build/
