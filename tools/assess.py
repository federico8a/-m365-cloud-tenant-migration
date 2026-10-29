#!/usr/bin/env python3
"""Offline cloud-only migration assessment. No network or tenant mutation.

Reads sensitive tenant exports from ./output, never uploads or prints employee details.
"""
import argparse
import csv
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

REQUIRED_KEYS = {"sourceId", "sourceUPN", "targetUPN", "targetId", "approved"}


def read_json(directory, name):
    file = Path(directory) / f"{name}.json"
    if not file.exists():
        return None
    with file.open(encoding="utf-8-sig") as handle:
        return json.load(handle)


def assess(source, target, mapping_path):
    issues = []
    source_users = read_json(source, "users")
    target_users = read_json(target, "users")
    if source_users is None or target_users is None:
        issues.append({"severity": "BLOCKER", "component": "Inventory", "message": "Source and target users.json are mandatory"})
        return {"status": "BLOCKED", "issues": issues}
    for tenant, folder in (("source", source), ("target", target)):
        errors = read_json(folder, "collection-errors")
        if errors is None:
            issues.append({"severity": "BLOCKER", "component": tenant, "message": "Missing collection-errors.json; cannot establish complete discovery"})
        elif errors:
            issues.append({"severity": "BLOCKER", "component": tenant, "message": f"{len(errors)} inventory endpoints failed; review errors locally"})
    target_ids = {u.get("id", "").lower(): u for u in target_users}
    source_ids = {u.get("id", "").lower(): u for u in source_users}
    for source_user in source_users:
        if source_user.get("onPremisesSyncEnabled") is True:
            issues.append({"severity": "BLOCKER", "component": "Identity", "message": "Hybrid identity detected, outside cloud-only project scope"})
            break
    with Path(mapping_path).open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if not REQUIRED_KEYS.issubset(reader.fieldnames or []):
            raise ValueError("Mapping CSV lacks mandatory columns")
        mapping = list(reader)
    src_counts = Counter(r["sourceId"].lower() for r in mapping)
    dst_counts = Counter(r["targetId"].lower() for r in mapping if r["targetId"])
    if any(count > 1 for count in src_counts.values()) or any(count > 1 for count in dst_counts.values()):
        issues.append({"severity": "BLOCKER", "component": "Identity", "message": "Duplicate source or destination identity mapping"})
    for row in mapping:
        if not row["targetId"] or row["targetId"].lower() not in target_ids:
            issues.append({"severity": "BLOCKER", "component": "Identity", "message": "One or more mappings have an unknown target Entra object ID"})
            break
    for row in mapping:
        if row["sourceId"].lower() not in source_ids:
            issues.append({"severity": "BLOCKER", "component": "Identity", "message": "One or more source object IDs are absent from source inventory"})
            break
    if any(row["approved"].strip().lower() != "true" for row in mapping):
        issues.append({"severity": "BLOCKER", "component": "Approval", "message": "At least one mapping was not approved"})
    # Target inventory cannot prove mailbox/OneDrive absence; require live service-specific validation.
    issues.append({"severity": "MANUAL_GATE", "component": "Exchange", "message": "Verify target objects are MailUsers, NOT mailboxes; stamp ExchangeGuid via Microsoft cross-tenant identity mapping before licensing"})
    issues.append({"severity": "MANUAL_GATE", "component": "OneDrive", "message": "Verify target OneDrive sites do not exist and automatic creation is disabled"})
    issues.append({"severity": "MANUAL_GATE", "component": "Licensing", "message": "Confirm destination workload SKUs, cross-tenant migration SKU, billing terms and customer purchase orders"})
    issues.append({"severity": "MANUAL_GATE", "component": "Compliance", "message": "Legal/retention/hold review and source/target security approval required"})
    issues.append({"severity": "MANUAL_GATE", "component": "DNS", "message": "Confirm domain release inventory, registrar access, relay/coexistence and cutover rollback point"})
    issues.append({"severity": "MANUAL_GATE", "component": "Unsupported workloads", "message": "Teams sites/channels, Intune devices, apps, Purview and Power Platform must follow separate workstreams"})
    result = {
        "generatedUtc": datetime.now(timezone.utc).isoformat(),
        "status": "BLOCKED" if any(x["severity"] == "BLOCKER" for x in issues) else "HUMAN_GATES_REQUIRED",
        "counts": {"sourceUsers": len(source_users), "targetUsers": len(target_users), "mappedUsers": len(mapping)},
        "issues": issues,
        "canMigrateAutomatically": False,
    }
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for field in ("source", "target", "mapping", "output"):
        parser.add_argument(f"--{field}", required=True)
    args = parser.parse_args()
    result = assess(args.source, args.target, args.mapping)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"Status: {result['status']}; source={result['counts']['sourceUsers']}; mapped={result['counts']['mappedUsers']}")
    print("Saved privacy-sensitive readiness report locally. Do not commit ./output to GitHub.")


if __name__ == "__main__":
    main()
