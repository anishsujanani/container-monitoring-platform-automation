'''
An extremely basic integration for Falco that takes alerts as
stdin and pushes to a local ES cluster.
This code is purely PoC, no judgement please.
- Anish Sujanani
'''

import json
import pprint
import elasticsearch

es = elasticsearch.Elasticsearch()

def upload_to_ES(alert_body):
	alert_body['timestamp'] = alert_body['time']
	del alert_body['time']

	es.index(index='test', body=alert_body)
	
	return

while True:
	alert_body = json.loads(input())
	#pprint.pprint(alert_body)
	upload_to_ES(alert_body)
