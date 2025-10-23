.PHONY: test test-scanner test-plugin

# Run all tests
test: test-scanner test-plugin

# Run C++ scanner tests
test-scanner:
	@echo "Running scanner tests..."
	cd scanner/build && ctest -C Release --output-on-failure

# Run Lua plugin tests
test-plugin:
	@echo "Running plugin tests..."
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('tests/', {minimal_init='tests/minimal_init.lua'})"
