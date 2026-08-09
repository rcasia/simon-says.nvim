.PHONY: test test-unit lint check

test: test-unit

test-unit:
	@scripts/test tests/unit/

lint:
	@luacheck lua/ tests/

check: lint test
