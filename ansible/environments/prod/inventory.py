#!/usr/bin/env python3
import sys
import subprocess
import json

# set default STDout
if len(sys.argv) > 1:
    if sys.argv[1] == "--host":
        print('{"_meta": {"hostvars": {}}}')
        sys.exit()
    if sys.argv[1] != "--list":
        print('{}')
        sys.exit()
else:
    print("--list | --host | ...")
    sys.exit(99)

result = subprocess.run(['yc','compute', 'instances', 'list'], stdout=subprocess.PIPE).stdout.decode('utf-8')

# keep only instance lines
instance_line = []
for line in result.rstrip('\n').split("\n"):
    if "|" in line and "STATUS" not in line:
        instance_line.append(line)

# making list of instances
instance = []
for j in instance_line:
    j = j.split()
    while "|" in j: j.remove("|")
    instance.append({"host": j[1], "ip": j[4]})

# creating groups
all_group = []
app_group = []
db_group = []
for i in instance:
    if "-app" in i["host"]:
        app_group.append(i["ip"])
    if "-db" in i["host"]:
        db_group.append(i["ip"])
    all_group.append(i["ip"])
_meta = {"hostvars": {}}

# fullfil response:
response = {}
#response["app"] = {"hosts": app_group, "vars":{"db_ipaddr": db_group[0]}}
#response["db"] = {"hosts": db_group, "vars":{"db_ipaddr": db_group[0]}}
response["app"] = {"hosts": app_group, "vars":{"db_host": db_group[0]}}
response["db"] = {"hosts": db_group, "vars":{"db_host": db_group[0]}}

response["all"] = {"hosts": all_group}
response["_meta"] = {"hosts": _meta}

print(json.dumps(response, sort_keys=True, indent=4))
sys.exit(0)
