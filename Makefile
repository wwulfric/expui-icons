EMACS ?= emacs
LOAD_PATH ?= -L .

.PHONY: all compile test checkdoc clean

all: compile checkdoc test

compile:
	$(EMACS) -Q --batch --eval '(setq load-prefer-newer t)' $(LOAD_PATH) \
	  --eval '(setq byte-compile-error-on-warn t)' \
	  -f batch-byte-compile expui-icons.el

test:
	$(EMACS) -Q --batch --eval '(setq load-prefer-newer t)' -L . -l test/expui-icons-test.el \
	  -f ert-run-tests-batch-and-exit

checkdoc:
	$(EMACS) -Q --batch --eval '(setq load-prefer-newer t)' $(LOAD_PATH) \
	  --eval '(checkdoc-file "expui-icons.el")'

clean:
	rm -f *.elc test/*.elc
