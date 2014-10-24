========================
Videur API Specification
========================

:version: 0.1
:author: Tarek Ziadé <tarek@mozilla.com>
:author: Julien Vehent <jvehent@mozilla.com>

The **Videur API Specification** file is a JSON document a web application
can provide to describe its HTTP endpoints.

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

This key contains a mapping describing all HTTP endpoints. Each resource is
identified the exact URI of the endpoint or a regular expression.

Examples of valid URIs:

- **/dashboard**
- **/action/one**
- **regexp:/welp/[a-zA-Z0-9]{1,64}**

Regular expression based URIs are prefixed by **regexp:**

The value of each resource is a mapping of all implemented methods.

Example::

    "/action": {
        "GET": {},
        "DELETE": {}
    }


This specification does not enforce any rule about the lack of the body
entity on methods like GET, as this part of the HTTP specification
is a bit vague. Some software like ElasticCache for instance will define
GET APIs with body content.

When specifying methods on a resources, there are a list of rules
that can be added in the method definition:

- **parameters**: rules on the query string
- **body**: rules on the body
- **limits**: limits on the request (rate, size, etc.)


parameters
==========

A validation rule can be defined for each query string parameter, in the
**paramaters** key for the resource.

The rule is identified by the option name and contains two fields:

- **validation**: the validation rule.
- **required**: a boolean to indicate if this option is mandatory when using the
  resource

The validation rule is a pattern the value of the option must match. It can
take the following values:

- **digits:<min>,<max>** : the value is composed of numbers. Its size is
  between <min> and <max> digits
- **regexp:<regexp>**: the value must follow the corresponding regexp
- **values:<a>|<b>|<c>**: the value must be one of a, b, c.
- **datetime**: the value is an ISO date

Examples::

    "/search": {
        "GET": {
            "parameters": {
                "before": {
                    "validation":"datetime",
                    "required": false
                },
                "after": {
                    "validation":"datetime",
                    "required": false
                },
                "type": {
                    "validation":"values:action|command|agent",
                    "required": false
                },
                "report": {
                    "validation":"regexp:[a-zA-Z0-9]{1,64}",
                    "required": false
                },
                "agentname": {
                    "validation":"regexp:[\\w\\n\\r\\t ]{0,256}",
                    "required": false
                },
                "actionname": {
                    "validation":"regexp:[\\w\\n\\r\\t ]{0,1024}",
                    "required": false
                },
                "status": {
                    "validation":"regexp:[a-zA-Z0-9]{1,64}",
                    "required": false
                },
                "threatfamily": {
                    "validation":"regexp:[a-zA-Z0-9]{1,64}",
                    "required": false
                },
                "limit": {
                    "validation":"digits:1,20",
                    "required": false
                }
            }
        }
    }



body
====

XXX

limits
======

XXX



configuration
-------------

XXX

description
-----------

XXX

