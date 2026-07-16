# Plantation field-gradient candidates (Refs #3961)

Hand-painted **candidates only** — not shipped map art until PO locks a letter
per crop on [#3961](https://github.com/waigore/colonizethisv3/issues/3961).

| Crop | A | B | C |
|------|---|---|---|
| sugar_cane | sage / olive | tea green | warm olive cane |
| cotton | soft taupe | grey fibre | warm cream |
| spices | cinnamon / umber | muted paprika | ochre / turmeric |

Regenerate:

```bash
uv run --project pytool python pytool/paint_plains_plantation_field_gradients.py
```

After PO lock (does **not** touch tobacco):

```bash
uv run --project pytool python pytool/finalize_plantation_field_retune_3961.py \
  --picks sugar_cane=A,cotton=B,spices=C
cd app && flutter test test/plains_plantation_terrain_goldens_test.dart --update-goldens
```

(`--dry-run` previews means without writing. Legacy promote-only path:
`paint_plains_plantation_field_gradients.py --promote …` then manual SPEC/test pins.)
