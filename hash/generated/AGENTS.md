# Generated-output routing

This directory contains deterministic projections of canonical inputs. It
contains no semantic source and no policy.

This `AGENTS.md` file is the directory's only authored file. Generators must
exclude every `AGENTS.md`; they may neither create nor replace instructions.

## Allowed projections

- the vendor manifest: one row per pinned third-party file with its SHA-256
  and size, written by `lake exe hash_vendorseal --write`;
- theorem and axiom receipt tables: one row per declaration with the exact
  axiom set it reaches, joined across hosts and across the move from the
  repositories this package was extracted from;
- declaration and public-signature snapshots.

Each projection records its canonical inputs, generator identity, format
version, and exact regeneration command, either in a header line or in the
generator's module documentation. Output must be byte-deterministic and must
not contain machine-specific absolute paths or timestamps that make an
unchanged input drift.

Never hand-edit a generated projection. Repair its authored input or
generator, regenerate into a clean tree, and compare bytes. A generator may
report a missing receipt or an unjoined row, but it may not supply a manual
completion override or generate an instruction file.
