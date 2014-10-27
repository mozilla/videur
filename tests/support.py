import sys
import os
import unittest
import time
import tempfile
import shutil
import subprocess

from webtest import TestApp
from nginxtest.server import NginxServer
import requests


PY3 = sys.version_info.major == 3

LIBDIR = os.path.normpath(os.path.join(os.path.dirname(__file__),
                          '..', 'lib'))

HTTP_OPTIONS = """\
  lua_package_path "%s/?.lua;;";
  lua_shared_dict cached_spec 512k;
  lua_shared_dict stats 100k;
"""  % LIBDIR


SERVER_OPTIONS = """\
  set $spec_url "http://127.0.0.1:8282/api-specs";
  set $target "";
  set $max_body_size 1M;
  access_by_lua_file '%s/videur.lua';
""" % LIBDIR


LOCATION = """
  proxy_pass $target;
"""

SPEC_FILE = os.path.join(os.path.dirname(__file__),
                         '..', 'spec', 'mig_example.json')


class TestMyNginx(unittest.TestCase):

    def start_server(self, locations=None, pages=None):
        if locations is None:
            locations = []

        if pages is None:
            pages = ('dashboard', 'action', 'search', 'welp/1234')

        locations.append({'path': '/',
                          'definition': LOCATION})

        self.serv_dir = tempfile.mkdtemp()
        target = os.path.join(self.serv_dir, 'api-specs')
        shutil.copy(SPEC_FILE, target)

        # and lets add some pages
        for page in pages:
            path = os.path.join(self.serv_dir, page)

            if not os.path.isdir(os.path.dirname(path)):
                os.makedirs(os.path.dirname(path))

            with open(path, 'w') as f:
                f.write('yeah')

        if PY3:
            server = 'http.server'
        else:
            server = 'SimpleHTTPServer'

        self._p = subprocess.Popen([sys.executable, '-m',
                                    server, '8282'],
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
            self.nginx = NginxServer(locations=locations,
                                     http_options=HTTP_OPTIONS,
                                     server_options=SERVER_OPTIONS)
            self.nginx.start()
        except Exception:
            self._kill_python_server()
            raise

    def _kill_python_server(self):
        try:
            self._p.terminate()
            os.kill(self._p.pid, 9)
        finally:
            shutil.rmtree(self.serv_dir)

    def stop_server(self):
        self._kill_python_server()
        self.nginx.stop()
