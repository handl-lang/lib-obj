# lib-obj

`obj` — record introspection primitives (`keys`/`values`/`entries`
over Handl objects): the `.hnl` interface plus the Rust crate
embedding it.

## Layout

| path | role |
| --- | --- |
| `src/index.hnl` | the interface — cap/op declarations |
| `src/lib.rs`, `src/ops.rs` | the Rust crate (native `op` atoms) |
| `atoms.yaml` | atom declarations |
| `Cargo.toml`, `xtask/` | crate manifest + `cargo xtask` gate |
| `pkg.hnl` | package manifest — `modules: ["obj"]` |
| `scripts/hnl-gate.sh`, `ci.sh` | the hnl gate / bupha entry |

## Contract

- Transitional layout: interface is `src/index.hnl`; implementations
  are native `op` atoms in the crate.

## Verification

```bash
cargo xtask gate        # fmt --check → clippy -D warnings → test → doc
HNL=../host-cli/target/debug/hnl scripts/hnl-gate.sh   # the .hnl side
```

## License

MIT.

<!-- myco:agent-awareness -->

## Agent awareness

- Session start / any work discussion: run `myco status --prompt`
  before proposing next steps — know the board first.
- User describes new work → offer to capture it (`myco todo add`,
  `issue new`, `proposal new`). Don't wait to be asked.
- Picking up a task: `myco resume <ID>` is the briefing.
- Wrapping up: `myco handoff <ID>` anything resumable; keep statuses
  honest (claimed → in-progress → blocked/done).

<!-- /myco:agent-awareness -->
