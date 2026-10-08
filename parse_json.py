import json, codecs
try:
    with codecs.open('analyzer_output.json', 'r', 'utf-16le') as f:
        d = json.loads(f.read())
except Exception as e:
    with codecs.open('analyzer_output.json', 'r', 'utf-8') as f:
        d = json.loads(f.read())

errors = [x for x in d['diagnostics'] if x['severity'] == 'ERROR']
for x in errors:
    f = x['location']['file']
    if 'planner_screen' in f or 'daily_trade_journal_screen' in f:
        print(f"{f}:{x['location']['range']['start']['line']} - {x['problemMessage']}")
