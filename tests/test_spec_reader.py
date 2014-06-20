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
  set $spec_url "http://localhost:8282/api-specs";
  access_by_lua_file '%s/dynamic_proxy_pass.lua';
""" % LIBDIR


SPEC_FILE = os.path.join(os.path.dirname(__file__),
                         '..', 'spec', 'mig_example.json')


class TestMyNginx(unittest.TestCase):

    def setUp(self):
        # let's run a server with a spec file on 8282
        self.serv_dir = tempfile.mkdtemp()
        target = os.path.join(self.serv_dir, 'api-specs')
        shutil.copy(SPEC_FILE, target)
        self._p = subprocess.Popen([sys.executable, '-m',
                                    'SimpleHTTPServer', '8282'],
                                    cwd=self.serv_dir)
        try:
            while not requests.get('http://127.0.0.1:8282'):
                time.sleep(.1)
        except requests.ConnectionError:
            pass

        try:
            self.nginx = NginxServer(http_options=_HTTP_OPTIONS,
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
        self.app.get('/dashboard', headers={'User-Agent': 'Me'}, status=200)
