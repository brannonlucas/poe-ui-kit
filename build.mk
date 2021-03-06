# poe-ui-kit builder

### Source files

JS_SRC      = $(shell find public -type f -name '*.js')
CSS_SRC     = $(shell find public -type f -name '*.css')
STYL_SRC    = $(shell find public -type f -name '*.styl')
PARTIAL_SRC = $(shell find public -type f -name '*.jade') $(shell find public -type f -name '*.html')
SRC         = $(JS_SRC) $(CSS_SRC) $(STYL_SRC) $(PARTIAL_SRC)

### Out files

ifneq ($(MAKECMDGOALS),init)
EXTRAS    := $(shell node -p "Object.keys(require('./component.json').extra || {}).join(' ')")
endif
CSS_EXTRA = $(filter %.css,$(EXTRAS))
CSS_OUT   = build/style.css $(CSS_EXTRA)
JS_EXTRA  = $(filter %.js,$(EXTRAS))
JS_OUT    = build/app.js build/vendor.js build/require.js build/ie-fixes.js build/script.js $(JS_EXTRA)
OUT       = $(CSS_OUT) $(JS_OUT)

### Min files

CSS_MIN = $(CSS_OUT:.css=.min.css)
JS_MIN  = $(JS_OUT:.js=.min.js)
MIN     = $(CSS_MIN) $(JS_MIN)

### Find the poe-ui-kit directory

POE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

### Add node_modules executables to the path

LOCAL_PATH := $(CURDIR)/node_modules/.bin:$(POE)/node_modules/.bin
PATH := $(LOCAL_PATH):$(PATH)

### Define some generic build targets

build   : install lint $(OUT)
prod    : build $(MIN) manifest.json
install : node_modules

### General targets

start: build .env
	@foreman start

clean:
	rm -fr build components manifest.json

### Install targets

.env: .env.example
	@cp $< $@

node_modules: package.json
	@npm install

### Javscript targets

build/script.js:
	@curl https://raw.githubusercontent.com/ded/script.js/v2.5.3/dist/script.js -o $@

build/ie-fixes.js:
	@mkdir -p build && \
	 cp $(POE)/src/ie-fixes.js $@

build/require.js:
	@mkdir -p build && \
	 cp $(POE)/node_modules/component-require2/index.js $@

build/app.js: $(JS_SRC) $(PARTIAL_SRC) component.json
	@$(POE)/bin/build-app-scripts $(CURDIR) $(CURDIR)/$@

build/vendor.js: component.json
	@$(POE)/bin/build-vendor-scripts $(CURDIR) $(CURDIR)/$@

$(JS_EXTRA): build/app.js

define UGLIFYJS
$(1:.js=.min.js): $(1)
	@PATH=$(PATH) uglifyjs \
	  --compress \
	  --mangle \
	  -o $$@ $$?
endef
$(foreach i,$(JS_OUT),$(eval $(call UGLIFYJS,$(i))))

### CSS Targets

build/style.css: $(CSS_SRC) $(STYL_SRC) component.json
	@$(POE)/bin/build-styles $(CURDIR) $(CURDIR)/$@

$(CSS_EXTRA): build/style.css

define CLEANCSS
$(1:.css=.min.css): $(1)
	@PATH=$(PATH) cleancss \
	  --s0 \
	  --skip-import \
	  --output $$@ $$?
endef
$(foreach i,$(CSS_OUT),$(eval $(call CLEANCSS,$(i))))

### Lint/test targets

lint: app.js $(JS_SRC)
	@PATH=$(PATH) jshint $?

### Production targets

manifest.json: $(MIN)
	@PATH=$(PATH) simple-assets \
	  --glob 'build/**/!(cache-)*' \
	  --copy \
	  --prefix cache-

.PHONY: clean build prod install lint
