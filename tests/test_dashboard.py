import os
import unittest
from webtest import TestApp
from nginxtest.server import NginxServer

LIBDIR = os.path.normpath(os.path.join(os.path.dirname(__file__),
                          '..', 'lib'))
LUA_SCRIPT = os.path.join(LIBDIR, 'dashboard.lua')


class TestMyNginx(unittest.TestCase):

    def setUp(self):
        location = {'path': '/__dashboard',
                    'definition': "content_by_lua_file '%s';" % LUA_SCRIPT}

        http_options = 'lua_package_path "%s/?.lua;;";' % LIBDIR
        self.nginx = NginxServer(locations=[location],
                                 http_options=http_options)
        self.nginx.start()
        self.app = TestApp(self.nginx.root_url)

    def tearDown(self):
        self.nginx.stop()

    def testDashboard(self):
        resp = self.app.get('/__dashboard__')
        self.assertEqual(resp.status_int, 200)
        self.assertTrue('Hello' in resp.body, resp.body)
