# Prior-art search (step 0)

## Contents

- Why search first
- Where to search, and with what terms
- Recording the decision
- What the gate checks

## Why search first

Most functional parts have been designed before. Searching first can save the
whole modeling job, or give a tested starting point, or at least confirm that a
new design is warranted. It also catches the failure that shipped on the antenna
perch: nobody searched, and the owner later asked whether anyone had. The search
is a required step, not a courtesy, and its result is recorded so a reviewer can
see it was done.

## Where to search, and with what terms

Search these, in roughly this order:

- MakerWorld, Printables, and Thingiverse (the large model repositories).
- STLFinder and 3DGO as aggregators across many sites.

Search with the device's product name and generic terms only. For example, "USB
Bluetooth adapter holder", "antenna perch mount", "Raspberry Pi 3 case". Never put
anything about the owner into a search query: no names, no address, no location,
no account handles. The query leaves this machine; keep it generic.

## Recording the decision

Record the outcome in the intent file's `prior_art` block, and decide one of:

- `use_as_is`: an existing design fits. Record the `found` design with its `url`
  and `license`. A downloaded mesh still goes through every intent check and, if
  it touches a device, the interference check.
- `remix`: an existing design is close and its license permits derivatives (most
  are CC BY or CC BY-NC, fine for personal use with attribution recorded). Record
  the `found` design with `url` and `license`, and the reason for the change.
- `design_new`: nothing close, or the fit is too specific. Record the reason.

```json
"prior_art": {
  "decision": "remix",
  "reason": "base perch fits; widened the slot for the 25 mm shelf",
  "found": [
    { "url": "https://www.printables.com/model/...", "license": "CC BY 4.0" }
  ]
}
```

For `use_as_is` or `remix`, keep the attribution with the part (the source and
license), as the licenses require.

## What the gate checks

`check_part.py` and the PreToolUse export gate both require:

- `decision` is one of `design_new`, `use_as_is`, `remix`.
- `reason` is non-empty.
- `use_as_is` and `remix` carry at least one `found` entry with a `url` and a
  `license`.

A mesh cannot be exported until these are filled in. The check is on the record,
not the quality of the search; the reviewer checklist is where a human confirms
the search was real.
