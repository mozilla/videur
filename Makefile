OPENRESTY_PREFIX=/usr/local/openresty
PREFIX ?= /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?= $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install
LUA_TREE = $(PREFIX)/lib
VIRTUALENV = virtualenv

.PHONY: install build test

all: ;

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/videur
	$(INSTALL) lib/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/videur/

build: all
	luarocks --tree=$(LUA_TREE) install luasec
	luarocks --tree=$(LUA_TREE) install lua-resty-http
	luarocks --tree=$(LUA_TREE) install lua-cjson
	luarocks --tree=$(LUA_TREE) install lrexlib-posix
	luarocks --tree=$(LUA_TREE) install date

export PATH := ./lib:$(PATH)

test: all
	$(VIRTUALENV) --no-site-packages .
	bin/pip install git+git://github.com/tarekziade/NginxTest
	bin/pip install nose
	bin/pip install webtest
	bin/pip install WSGIProxy2
	export PATH
	bin/nosetests -sv tests
