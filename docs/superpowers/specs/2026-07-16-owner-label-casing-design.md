# Owner-label casing

## Context

The walk-details screen initially formats the owner label as
`WALKING:  HIM/HER`, but toggling the owner writes `walking: HIM/HER` with
different casing and spacing. The two paths duplicate the same presentation.

## Design

Add one pure formatter to `main.gd`:

```gdscript
func _owner_label_text(owner_id: String) -> String:
	return "WALKING:  %s" % owner_id.to_upper()
```

Use it both when applying menu step 2 and immediately after
`Game.toggle_owner()`. Do not rerun the full menu-step function or change owner
state behavior.

## Regression

Add `tests/test_owner_label.gd`. Load the real `main.gd` script without adding
it to the tree and verify:

- `him` formats as `WALKING:  HIM`;
- `her` formats as `WALKING:  HER`;
- mixed-case input is normalized.

The test exits nonzero on failure and prints `test_owner_label: OK` on success.
Run it in CI immediately after the bandana preview regression.

## Documentation and scope

Add a newest-first changelog entry and remove the resolved capitalization item
from `HANDOVER.md`. Do not change menu layout, owner choices, input, save data,
or any gameplay behavior.
