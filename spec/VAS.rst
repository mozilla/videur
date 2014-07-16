========================
Videur API Specification
========================

:version: 0.1
:author: Tarek Ziadé <tarek@mozilla.com>
:author: Julien Vehent <jvehent@mozilla.com>

The **Videur API Specification** file is a JSON document a web application
can provide to describe its HTTP endpoint.

The standard location to publish this document is <root>/api-specs but it
can be located elsewhere if needed.

The JSON document is a mapping containing a single **service** key.

The service key is in turn a mapping containing the following keys:

- **location** -- the root url for the service
- **version** -- the service version
- **resources** -- a list of resource for the service (see below)
- **configuration** -- a list of configuration options for the service (see below)
- **description** -- a description of the service (see below)

Examples for the **location** and **version** fields::

    {
        "service": {
            "location": "http://127.0.0.1:8282",
            "version": "1.1",
            ...
        }
    }


resources
---------

XXX

configuration
-------------

XXX

description
-----------

XXX

