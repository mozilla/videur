import subprocess
import sys
import os
import unittest
import time
import tempfile
import shutil

from webtest import TestApp
from nginxtest.server import NginxServer
import requests
from support import TestMyNginx


class TestSpecReader(TestMyNginx):

    def setUp(self):
        super(TestSpecReader, self).setUp()
        self.start_server()
        self.app = TestApp(self.nginx.root_url)

    def tearDown(self):
        self.stop_server()
        super(TestSpecReader, self).tearDown()

    def test_routing(self):
        res = self.app.get('/dashboard', headers={'User-Agent': 'Me'},
                           status=200)
        self.assertEqual(res.body, 'yeah')

    def test_405(self):
        res = self.app.delete('/dashboard', headers={'User-Agent': 'Me'},
                              status=405)
        # XXX check the allow header

    def test_reject_unknown_arg(self):
        self.app.get('/dashboard?ok=no', headers={'User-Agent': 'Me'},
                     status=400)

    def test_reject_missing_option(self):
        r = self.app.get('/action',
                         headers={'User-Agent': 'Me'},
                         status=400)
        self.assertEqual(r.body, 'Missing actionid\n')

    def test_reject_bad_arg(self):
        # make sure we just accept integers
        self.app.get('/action',
                     params={'actionid': 'no'},
                     headers={'User-Agent': 'Me'},
                     status=400)

        r = self.app.get('/action',
                        params={'actionid': '1234'},
                        headers={'User-Agent': 'Me'},
                        status=200)
        self.assertEqual(r.body, 'yeah')

    def test_values(self):
        # make sure we just accept some values
        self.app.get('/search',
                     params={'type': 'meh'},
                     headers={'User-Agent': 'Me'},
                     status=400)

        for value in ('action', 'command', 'agent'):
            r = self.app.get('/search',
                            params={'type': value},
                            headers={'User-Agent': 'Me'},
                            status=200)
            self.assertEqual(r.body, 'yeah')

    def test_date(self):
        self.app.get('/search',
                     params={'before': 'bad date'},
                     headers={'User-Agent': 'Me'},
                     status=400)

        self.app.get('/search',
                     params={'before': '2014-06-26T04:25:24Z'},
                     headers={'User-Agent': 'Me'},
                     status=200)

    def test_post_limit(self):
        self.app.post('/action/create', params='data',
                      headers={'User-Agent': 'Me'},
                      status=501)

        # should not work because > 10k
        data = 'data' * 10 * 1024
        self.app.post('/action/create', params=data,
                      headers={'User-Agent': 'Me'},
                      status=413)

    def test_regexp_routes(self):
        # make sure we match regexps for URLs
        self.app.get('/welp/1234',
                     headers={'User-Agent': 'Me'},
                     status=200)

        self.app.get('/welp/12__',
                     headers={'User-Agent': 'Me'},
                     status=404)
