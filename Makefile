OPENRESTY_PREFIX=/usr/local/openresty
PREFIX ?= /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?= $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: install build test

all: ;

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/videur
	$(INSTALL) lib/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/videur/

build: all
	virtualenv --no-site-packages .
	bin/pip install git+git://github.com/tarekziade/NginxTest
	bin/pip install nose
	bin/pip install webtest
	bin/pip install WSGProxy2
	luarocks install etlua
	luarocks install luasec
	luarocks install lua-resty-http
	luarocks install cjson
	luarocks install lrexlib-posix
	luarocks install date

export PATH := ./lib:$(PATH)

test: all
	export PATH
	bin/nosetests -sv tests
