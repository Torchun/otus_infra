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

result = subprocess.run(['yc','compute', 'instances', 'list', "--folder-name", "infra", "--format", "json"], stdout=subprocess.PIPE).stdout.decode('utf-8')

instance_list = json.loads(result)

# creating groups
all_group = []
gitlab_group = []
gitlab_vars = {}
for i in instance_list:
    if i["labels"]["tags"] == "gitlab-ci":
        gitlab_group.append(i["network_interfaces"][0]["primary_v4_address"]["one_to_one_nat"]["address"])
        gitlab_vars[i["name"]] = i["network_interfaces"][0]["primary_v4_address"]["one_to_one_nat"]["address"]
    all_group.append(i["network_interfaces"][0]["primary_v4_address"]["one_to_one_nat"]["address"])
_meta = {"hostvars": {}}

# fullfil response:
response = {}
response["gitlab"] = {"hosts": gitlab_group, "vars": gitlab_vars}
response["all"] = {"hosts": all_group}
response["_meta"] = {"hosts": _meta}

print(json.dumps(response, sort_keys=True, indent=4))
sys.exit(0)
