# downstream

The [pure-algebra](https://github.com/pure-algebra) Lean family as one tree,
so a change that crosses packages can be built and tested as a whole before
it is released package by package.

It follows the shape of [leanprover/downstream-lean4](https://github.com/leanprover/downstream-lean4)
and uses its scripts unchanged, vendored under `.downstream/` as a git
subtree of [leanprover/downstream](https://github.com/leanprover/downstream).
What it does not have is that repository's nightly-toolchain tracking,
adaptation bots, and artifact cache; this family pins one released toolchain
and six repositories.

| Directory | Upstream | Depends on, inside this tree |
| --- | --- | --- |
| `effects/` | [lean4-effects](https://github.com/pure-algebra/lean4-effects) | nothing |
| `typescript/` | [lean4-typescript](https://github.com/pure-algebra/lean4-typescript) | nothing |
| `hash/` | [lean4-hash](https://github.com/pure-algebra/lean4-hash) | nothing |
| `nlp/` | [lean4-nlp](https://github.com/pure-algebra/lean4-nlp) | nothing |
| `effect4/` | [lean4-effect4](https://github.com/pure-algebra/lean4-effect4) | `../effects`, `../typescript`, `../whatwg` (planned) |
| `whatwg/` | [lean4-whatwg](https://github.com/pure-algebra/lean4-whatwg) | `../effects`, `../hash`, `../typescript` |

## How it works

- Each directory is a plain copy of its upstream's `main`, without history,
  taken by `.downstream/update.py`. The commit that adds or refreshes a copy
  carries `downstream-repo`, `downstream-url`, `downstream-rev`, and
  `downstream-sha` trailers naming exactly which upstream commit it is.
- `repos.toml` lists the five with their URLs, branches, and build options.
  `lean-toolchain` at the root is the toolchain for all of them; each copy's
  own `lean-toolchain` is a symlink to it.
- Dependencies are redirected without editing any manifest or lakefile. Lake
  reads `<package>/.lake/package-overrides.json`, and the updater writes one
  per copy mapping each in-family dependency to its sibling directory. The
  packages' own manifests keep their exact-commit git pins for use outside
  this tree.
- `.downstream/build.py . -t` builds, then tests, every copy in dependency
  order and fails if a package marked `critical` fails. `lean4-effect4`
  builds its production library only: its default build is red by design
  while a frozen breaker battery waits for its builder, and its own CI runs
  the trust self-test over the green remainder.

## Commands

```bash
python3 .downstream/update.py . -U          # refresh every copy from its branch
python3 .downstream/build.py . -t           # build and test all, in dependency order
python3 .downstream/list.py . --topo        # the build order
python3 .downstream/split.py . <repo>       # extract this tree's changes to <repo> as a branch on its base commit
```

`update.py` starts with `git clean -dffx`; commit anything you want to keep
before running it. Python 3.13 or newer; no other dependency.

## Working across packages

Make the change in the copies here, on a branch. CI builds the family. When
it is green, `split.py` produces, for each touched package, a branch based on
the upstream commit the copy came from, containing only that package's
changes, ready to push or open as a pull request there. Release stays
per-repository: tag the upstream, bump the exact-commit pin in its consumers,
and the next `update.py -U` brings the released state back here.

## Toolchain

`leanprover/lean4:v4.33.1`. Changing it is one edit to the root
`lean-toolchain`, which every copy follows through its symlink; the upstream
repositories change theirs when they adopt the release.
