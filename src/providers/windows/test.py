import json
import pathlib
import sys

current_path, profile_name, common_path, role_path = sys.argv[1:5]

def parse_profile(path):
    result = {"features": [], "modules": [], "services": []}
    section = None
    mapping = {
        "## Windows Features": "features",
        "## PowerShell Modules": "modules",
        "## Windows Services": "services",
    }
    for raw in pathlib.Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line in mapping:
            section = mapping[line]
        elif line.startswith("## "):
            section = None
        elif section and line.startswith("- "):
            value = line[2:].strip()
            if value not in result[section]:
                result[section].append(value)
    return result

desired = {"features": [], "modules": [], "services": []}
for p in (common_path, role_path):
    parsed = parse_profile(p)
    for key in desired:
        for value in parsed[key]:
            if value not in desired[key]:
                desired[key].append(value)

doc = json.loads(pathlib.Path(current_path).read_text(encoding="utf-8"))
if doc.get("Operation") != "Get":
    raise SystemExit("CURRENT_STATE_OPERATION_INVALID")
if doc.get("Profile") != profile_name:
    raise SystemExit("CURRENT_STATE_PROFILE_MISMATCH")

current = doc["CurrentState"]
delta = []
features = set(current.get("InstalledFeatures", []))
for name in desired["features"]:
    if name not in features:
        delta.append({"Resource":"WindowsFeature","Name":name,"Actual":"Absent","Desired":"Present"})

modules = {x["Name"]: x for x in current.get("Modules", [])}
for name in desired["modules"]:
    state = modules.get(name)
    if state is None or not state.get("Present", False):
        delta.append({"Resource":"PowerShellModule","Name":name,"Actual":"Absent","Desired":"PresentAndImportable"})
    elif not state.get("Importable", False):
        item = {"Resource":"PowerShellModule","Name":name,"Actual":"PresentButNotImportable","Desired":"PresentAndImportable"}
        if state.get("Error"):
            item["Error"] = state["Error"]
        delta.append(item)

services = {x["Name"].lower(): x for x in current.get("Services", [])}
for name in desired["services"]:
    state = services.get(name.lower())
    if state is None or not state.get("Present", False):
        delta.append({"Resource":"WindowsService","Name":name,"Actual":"Absent","Desired":"Running"})
    elif state.get("State") != "Running":
        delta.append({"Resource":"WindowsService","Name":name,"Actual":state.get("State"),"Desired":"Running"})

print(json.dumps({
    "Provider":"Windows",
    "ProviderVersion":"1.6.0",
    "Operation":"Test",
    "Target":doc["Target"],
    "Profile":profile_name,
    "InDesiredState":len(delta) == 0,
    "Delta":delta,
}, indent=2, ensure_ascii=False))