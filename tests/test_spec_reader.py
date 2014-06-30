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


LIBDIR = os.path.normpath(os.path.join(os.path.dirname(__file__),
                          '..', 'lib'))
LUA_SCRIPT = os.path.join(LIBDIR, 'spec_reader.lua')


_HTTP_OPTIONS = """\
  lua_package_path "%s/?.lua;;";
  lua_shared_dict cached_spec 512k;
"""  % LIBDIR


_SERVER_OPTIONS = """\
  set $spec_url "http://127.0.0.1:8282/api-specs";
  set $target "";
  set $max_body_size 10000;
  access_by_lua_file '%s/dynamic_proxy_pass.lua';
""" % LIBDIR


_LOCATION = """
  proxy_pass $target;
"""

SPEC_FILE = os.path.join(os.path.dirname(__file__),
                         '..', 'spec', 'mig_example.json')


class TestMyNginx(unittest.TestCase):

    def setUp(self):
        # let's run a server with a spec file on 8282
        self.serv_dir = tempfile.mkdtemp()
        target = os.path.join(self.serv_dir, 'api-specs')
        shutil.copy(SPEC_FILE, target)

        # and lets add some pages
        for page in ('dashboard', 'action', 'search'):
            with open(os.path.join(self.serv_dir, page), 'w') as f:
                f.write('yeah')

        self._p = subprocess.Popen([sys.executable, '-m',
                                    'SimpleHTTPServer', '8282'],
                                    cwd=self.serv_dir,
                                    stderr=subprocess.PIPE,
                                    stdout=subprocess.PIPE)
        start = time.time()
        res = None
        while time.time() - start < 2:
            try:
                res = requests.get('http://127.0.0.1:8282/api-specs')
                break
            except requests.ConnectionError:
                time.sleep(.1)
        if res is None:
            self._kill_python_server()
            raise IOError("Could not start the Py server")

        try:
            self.nginx = NginxServer(locations=[{'path': '/',
                                                 'definition': _LOCATION}],
                                     http_options=_HTTP_OPTIONS,
                                     server_options=_SERVER_OPTIONS)
            self.nginx.start()
        except Exception:
            self._kill_python_server()
            raise

        self.app = TestApp(self.nginx.root_url)

    def _kill_python_server(self):
        try:
            self._p.terminate()
            os.kill(self._p.pid, 9)
        finally:
            shutil.rmtree(self.serv_dir)

    def tearDown(self):
        self._kill_python_server()
        self.nginx.stop()

    def test_routing(self):
        res = self.app.get('/dashboard', headers={'User-Agent': 'Me'},
                           status=200)
        self.assertEqual(res.body, 'yeah')

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

        self.app.post('/action/create', params='data'*100,
                      headers={'User-Agent': 'Me'},
                      status=413)
