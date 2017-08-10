SKIP_SQUASH?=0

ifndef common_dir
    common_dir = common
endif

build = $(common_dir)/build.sh
test = $(common_dir)/test.sh
tag = $(common_dir)/tag.sh

ifeq ($(TARGET),rhel7)
	OS := rhel7
else ifeq ($(TARGET),fedora)
	OS := fedora
else
	OS := centos7
endif

script_env = \
	SKIP_SQUASH=$(SKIP_SQUASH)                      \
	UPDATE_BASE=$(UPDATE_BASE)                      \
	OS=$(OS)                                        \
	CLEAN_AFTER=$(CLEAN_AFTER)                      \
	OPENSHIFT_NAMESPACES="$(OPENSHIFT_NAMESPACES)"

.PHONY: build
build: $(VERSIONS)
	VERSIONS="$(VERSIONS)" $(script_env) $(tag)

.PHONY: $(VERSIONS)
$(VERSIONS): % : %/root/help.1
	VERSION="$@" $(script_env) $(build)

.PHONY: test
test: script_env += TEST_MODE=true
test: $(VERSIONS)
	VERSIONS="$(VERSIONS)" $(script_env) $(test)
	VERSIONS="$(VERSIONS)" $(script_env) $(tag)

.PHONY: test-openshift
test-openshift: script_env += TEST_OPENSHIFT_MODE=true
test-openshift: $(VERSIONS)
	VERSIONS="$(VERSIONS)" $(script_env) $(test)
	VERSIONS="$(VERSIONS)" $(script_env) $(tag)

%root/help.1: %README.md
	mkdir -p $(@D)
	echo hello
	# go-md2man -in "$^" -out "$@"
