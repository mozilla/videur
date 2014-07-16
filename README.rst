Videur
======

***experimental project***

Videur is a Lua library for OpenResty that will automatically parse
an API specification file provided by a web server and proxy incoming
Nginx requests to that server.

Videur takes care of rejecting requests that do not comply with the
specification definitions, such as:

- unknown GET arguments
- bad types or out of limits arguments
- missing authorization headers
- POST body too big
- too many requests per second on a given API
- etc..

To get a detailed list of rules that can be used,
look at the `Videur API Specification 0.1
document <https://github.com/mozilla/videur/blob/master/spec/VAS.rst>`_


Installation
------------

To install Videur, you need to have an OpenResty environment deployed.

Then you can run::

	make install

If you have a specific Lua lib directory, you can use the **LUA_LIB_DIR** option.

This command will simply copy all the lua files of the Videur lib into
the OpenResty lib directory.


Usage
-----

Using Videur in Nginx is done in three directives.

First of all, you need to define a Lua shared dict called **cached_spec**,
where Videur will store the API specification the backend provided.

Then you need to set a **spec_url** variable with the URL of the API spec.
This URL should be a JSON document as defined in the `Videur API
Specification 0.1 document <https://github.com/mozilla/videur/blob/master/spec/VAS.rst>`_

Last, the **access_by_lua_file** directive needs to point to the
**dynamic_proxy_pass.lua** script from the Videur library.


Example::

    http {
        lua_shared_dict cached_spec 512k;
        server {
            listen 80;
            set $spec_url "http://127.0.0.1:8282/api-specs";
            access_by_lua_file "dynamic_proxy_pass.lua";
        }
    }


