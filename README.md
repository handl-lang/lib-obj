# lib-obj

`obj` — record introspection primitives (keys/values/entries); the Rust crate
embedding `src/index.hnl`.

## Development

```bash
cargo xtask gate        # fmt --check → clippy -D warnings → test → doc
```

`cargo xtask` wraps the repo's `xtask/` crate (`fmt`, `clippy`, `test`, `doc`,
`check`, `gate`).

## License

MIT.
