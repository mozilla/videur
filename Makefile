build:
	virtualenv --no-site-packages .
	bin/pip install git+git://github.com/tarekziade/NginxTest
	bin/pip install nose
	bin/pip install webtest
	bin/pip install WSGProxy2
	luarocks install lapis
	luarocks install etlua
	luarocks install luasec
	luarocks install lua-resty-http
	luarocks install cjson

export PATH := ./lib:$(PATH)

test:
	export PATH
	bin/nosetests -sv tests
