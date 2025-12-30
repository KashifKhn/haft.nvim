.PHONY: test format lint all clean

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

format:
	stylua lua/

lint:
	luacheck lua/ --globals vim

all: format lint test

clean:
	rm -rf .tests/
