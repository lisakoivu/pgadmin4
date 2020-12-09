##########################################################################
#
# pgAdmin 4 - PostgreSQL Tools
#
# Copyright (C) 2013 - 2020, The pgAdmin Development Team
# This software is released under the PostgreSQL Licence
#
##########################################################################

import json

from pgadmin.utils.route import BaseTestGenerator
from regression.python_test_utils import test_utils as utils
from regression import parent_node_dict
from regression.test_setup import config_data
from pgadmin.browser.server_groups.servers.databases.tests import utils as \
    database_utils
from os import path


class ERDSql(BaseTestGenerator):

    def setUp(self):
        self.db_name = "erdtestdb"
        self.sid = parent_node_dict["server"][-1]["server_id"]
        self.did = utils.create_database(self.server, self.db_name)
        self.sgid = config_data["server_group"]
        self.maxDiff = None

    def runTest(self):
        pass
        db_con = database_utils.connect_database(self,
                                                 self.sgid,
                                                 self.sid,
                                                 self.did)

        if not db_con["info"] == "Database connected.":
            raise Exception("Could not connect to database to add the schema.")

        url = '/erd/sql/{trans_id}/{sgid}/{sid}/{did}'.format(
            trans_id=123344, sgid=self.sgid, sid=self.sid, did=self.did)

        curr_dir = path.dirname(__file__)

        data_json = None
        with open(path.join(curr_dir, 'test_sql_input_data.json')) as fp:
            data_json = fp.read()

        response = self.tester.post(url,
                                    data=data_json,
                                    content_type='html/json')
        self.assertEqual(response.status_code, 200)

        data_sql = None
        with open(path.join(curr_dir, 'test_sql_output.sql')) as fp:
            data_sql = fp.read()

        resp_sql = json.loads(response.data.decode('utf-8'))['data']
        self.assertEqual(resp_sql, data_sql)

    def tearDown(self):
        connection = utils.get_db_connection(self.server['db'],
                                             self.server['username'],
                                             self.server['db_password'],
                                             self.server['host'],
                                             self.server['port'])
        utils.drop_database(connection, self.db_name)