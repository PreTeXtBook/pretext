# JS Builder

## Installing Node and Dependencies

You will need to [install node](https://nodejs.org/en/download/package-manager).

Install the needed dependencies by switching to the `pretext/script/jsbuilder` directory and running `npm install`.

## Use

To build all targets to `pretext/js/dist`, from the jsbuilder directory do:

```bash
npm run build
```

To view the help, do:

```bash
npm run build -- -h
```

Note that parameters being passed to the script must come after a `--` or they will be interpreted as parameters for npm itself.

For debugging, you likely want to build one target by using:

* The `-t` flag to specify a target (`pretext-core` or `pretext-search`)
* The `-o` flag to specify an output directory (generally the `_static/pretext/js` folder of your book)
* The `-w` flag to watch source files and rebuild on changes

Example:

```bash
npm run build -- -t pretext-core -o yourbookpath/_static/pretext/js -w
```

For full help:

```bash
npm run build -- -h
```

## Build Targets

| Target | Entry point | Description |
|--------|-------------|-------------|
| `pretext-core` | `js/src/pretext-core-entry.js` | Core JS: TOC, sidebar, knowls, permalinks, image magnify, keyboard nav, theming, code copy, etc. |
| `pretext-search` | `js/src/pretext-search-entry.js` | Native search UI (loaded only when `$has-native-search` is true) |

## Architecture

Source modules live in `js/src/`. Each module exports its initialization function. The entry-point files import all modules and wire up initialization.

Built bundles are committed to `js/dist/` so that users without Node.js can still build PreTeXt documents.

Also see [PLAN.md](PLAN.md) for the full modernization plan.
