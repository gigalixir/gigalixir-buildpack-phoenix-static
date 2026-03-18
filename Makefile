.PHONY: test

test:
	@set -e; for tst in test/*.sh; do \
		[ -x "$$tst" ] || continue; \
		"$$tst"; \
	done
