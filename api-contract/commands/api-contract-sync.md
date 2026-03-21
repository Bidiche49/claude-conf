---
description: Check if API_CONTRACT.md is in sync with the actual code
---

Compare `API_CONTRACT.md` against the real codebase and report differences. **Do NOT modify the contract automatically.**

## 1. Locate the contract

Search in order: `shared/API_CONTRACT.md`, `API_CONTRACT.md`, `../shared/API_CONTRACT.md`. If not found, tell the user to run `/api-contract-init` first.

## 2. Parse the contract

Extract all documented endpoints: method, path, request/response types.

## 3. Scan the code

Use the same stack detection and route scanning logic as `/api-contract-init` to find all endpoints currently in the codebase.

## 4. Compare and classify

| Status | Meaning |
|--------|---------|
| **MISSING** | Endpoint exists in code but not in contract |
| **REMOVED** | Endpoint exists in contract but not in code |
| **CHANGED** | Endpoint exists in both but signatures differ (params, types, method) |

## 5. Display the report

```
API CONTRACT SYNC
=================
[N] endpoints in sync

[If issues found:]
MISSING (in code, not in contract):
  [METHOD] [path] — [Controller.method()]

REMOVED (in contract, not in code):
  [METHOD] [path] — was in [Controller] (file deleted?)

CHANGED (signatures differ):
  [METHOD] [path] — contract says [X], code expects [Y]
```

If everything is in sync: `Contract in sync — [N] endpoints verified.`

## 6. Propose corrections

List suggested updates to the contract but **do NOT apply them**. Let the user decide.
