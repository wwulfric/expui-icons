EMACS ?= emacs
# Directories holding Dirvish and its dependency compat, for the integration.
LOAD_PATH ?= -L . -L ../dirvish -L ../compat

.PHONY: all compile test checkdoc clean

all: compile checkdoc test

compile:
	$(EMACS) -Q --batch $(LOAD_PATH) \
	  --eval '(setq byte-compile-error-on-warn t)' \
	  -f batch-byte-compile expui-icons.el expui-icons-dirvish.el

test:
	$(EMACS) -Q --batch -L . -l test/expui-icons-test.el \
	  -f ert-run-tests-batch-and-exit

checkdoc:
	$(EMACS) -Q --batch $(LOAD_PATH) \
	  --eval '(dolist (f (list "expui-icons.el" "expui-icons-dirvish.el")) (checkdoc-file f))'

clean:
	rm -f *.elc test/*.elc
