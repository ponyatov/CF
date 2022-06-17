# var
MODULE = $(notdir $(CURDIR))
module = $(shell echo $(MODULE) | tr A-Z a-z)
OS     = $(shell uname -o|tr / _)
NOW    = $(shell date +%d%m%y)
REL    = $(shell git rev-parse --short=4 HEAD)
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
CORES  = $(shell grep processor /proc/cpuinfo| wc -l)
PEPS   = E26,E302,E305,E401,E402,E701,E702

# dir
CWD   = $(CURDIR)
TMP   = $(CWD)/tmp

# tool
CURL   = curl -L -o
CF     = clang-format
PY     = $(shell which python3)
PIP    = $(shell which pip3)
PEP    = $(shell which autopep8)

# src
P += $(MODULE).py config/__init__.py
P += metaL.py $(MODULE).meta.py
S += $(P) rc

# all
.PHONY: all
all: $(PY) $(MODULE).py
	$^ $@
	$(MAKE) format

.PHONY: watch
watch: $(PY) $(MODULE).py
	$(PY) -i $(MODULE).py
	$(MAKE) format
	$(MAKE) $@

.PHONY: meta
meta: $(PY) $(MODULE).meta.py
	$^ && $(MAKE) format

# format
.PHONY: format
format: tmp/format_py

tmp/format_py: $(P)
	$(PEP) --ignore=$(PEPS) -i $? && touch $@

# doc

.PHONY: doxy
doxy: doxy.gen
	rm -rf docs ; doxygen $< 1>/dev/null

.PHONY: doc
doc:
	rsync -rv ~/mdoc/CF/*            doc/CF/

# install
.PHONY: install update updev
install: $(OS)_install doc gz
	$(MAKE) update
update: $(OS)_update doc gz
	$(PIP) install --user -U pip autopep8 xxhash
	$(PIP) install --user -U -r requirements.txt
updev: update
	sudo apt install -yu `cat apt.dev`

GNU_Linux_install:
GNU_Linux_update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`

gz:

# merge
MERGE  = Makefile README.md .clang-format doxy.gen $(S)
MERGE += .vscode bin doc config lib inc src tmp
MERGE += apt.dev apt.txt requirements.txt

dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)
	$(MAKE) doc && git add doc

shadow:
	git push -v
	git checkout $@
	git pull -v

release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

ZIP = tmp/$(MODULE)_$(NOW)_$(REL)_$(BRANCH).zip
zip:
	git archive --format zip --output $(ZIP) HEAD
