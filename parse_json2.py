import json, os, codecs

def parse():
    p = 'analyzer_output.json'
    try:
        with codecs.open(p, 'r', 'utf-16le') as f:
            d = json.load(f)
    except:
        with codecs.open(p, 'r', 'utf-8') as f:
            d = json.load(f)
    errs = [x for x in d['diagnostics'] if x['severity']=='ERROR' and 'lib/' in x['location']['file'].replace('\\', '/')]
    for e in errs:
        print(f"{e['location']['file']}:{e['location']['range']['start']['line']} - {e['problemMessage']}")

if __name__ == '__main__':
    parse()
