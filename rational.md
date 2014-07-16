Rational
--------

Nginx is our standard web server of choice for all our services at Mozilla. It's 
been used for years now and is able to leverage any web service no matter what
framework is used, by reverse proxying incoming requests to a Node.js, Go or
Python powered service.

The classical server stack we deploy on Amazon is :

	ELB -> Nginx -> {NodeJS, Python, Go, ...} -> Backend


Where **backend** can be a database system, or any 3rd party service the application
needs to interact with. 

To smoothly operate a cluster of such nodes, we are currently missing a few key 
features like:

- the ability to write efficient Web Application Firewalls
- the ability to interact live with the NGinx server
- the ability to provide highly customized filtering features, like 
  interactive rate-limiting.

Thanks to http://wiki.nginx.org/HttpLuaModule and OpenResty, 
Nginx's behavior can be completely customized to implement those features.


Videur has two goals:

- provide a set of Lua scripts in a library that can be added in our standard
  deployements
- offer a development environment for developers to write WAFs



