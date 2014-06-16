Videur
======

***experimental project***

Videur is a library of Lua scripts for an OpenResty (=Nginx+Lua) environment.

Features we would like to build there:

- filter incoming web requests (rate limiting, custom rules, ..)
- log some behaviors
- provide an API so ***Mozilla Investigator*** https://github.com/mozilla/mig can
  interact with the server.
- build reverse proxy rules automatically using Swagger spec files provided 
  by the underlying service.
- ...

