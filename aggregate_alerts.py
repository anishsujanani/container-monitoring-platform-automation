import json
import pprint
import elasticsearch

es = elasticsearch.Elasticsearch()

# import falco
# client = falco.Client(endpoint="unix:///var/run/falco.sock", output_format='json')
# print(dir(client))
# for event in client.get():
# 	print(event)

#with open('out.txt', 'w') as f:

def upload_to_ES(alert_body):
	alert_body['timestamp'] = alert_body['time']
	del alert_body['time']

	es.index(index='test', body=alert_body)
	
	return

while True:
	alert_body = json.loads(input())

	print('------------------------\n')
	pprint.pprint(alert_body)
	upload_to_ES(alert_body)
	print('------------Uploaded to ES------------\n')