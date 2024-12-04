# CSS Builder

## Installing Node and Dependencies

You will need to [install node](https://nodejs.org/en/download/package-manager).

Install the needed dependencies by switching to the `pretext/script/cssbuilder` and doing `npm install`.

## Use

To build all targets to `pretext/css/dist`, from the cssbuilder directory do:

```bash
npm run build
```

For debugging, you likely want to build one target (`default-modern` in this case) to a specified output directory (generally the `_static/pretext/css` folder of your book), rebuilding with any changes (`-w` for "watch"). That can be done with:

```bash
npm run build -- -t default-modern -o yourbookpath/_static/pretext/css -w'
```

To specify options or variables you can add the `-c` flag followed by a string containing JSON like this:

```bash
npm run build -- -w -t theme-default-modern -o ../../examples/sample-article/out/_static/pretext/css -c '{"options":{"assemblages":"oscar-levin"},"variables":{"primary-color":"rgb(80, 30, 80)", "secondary-color":"rgb(20, 160, 30)", "primary-color-dark":"#b88888"}}'
```

For full help:

```bash
npm run build -- -h
```

Also see [README.md in css](../../css/README.md)
