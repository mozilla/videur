build:
	cpan install Test::Nginx
	luarocks install lapis
	luarocks install etlua

export PATH := ./lib:$(PATH)

test:
	- pkill -9 nginx
	export PATH
	prove -r t/*.lua
