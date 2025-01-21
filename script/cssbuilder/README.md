# CSS Builder

## Installing Node and Dependencies

You will need to [install node](https://nodejs.org/en/download/package-manager).

Install the needed dependencies by switching to the `pretext/script/cssbuilder` and doing `npm install`.

## Use

To build all targets to `pretext/css/dist`, from the cssbuilder directory do:

```bash
npm run build
```

To view the help, do:

```bash
npm run build -- -h
```

Note that parameters being passed to the script must come after a `--` or they will be interpreted as parameters for npm itself.

For debugging, you likely want to build one target by using:

* The `-t` flag to specify a target matching one of the output targets listed in cssbuilder (`theme-salem`, `theme-default-modern`, etc...)
* The `-o` flag to specify an output directory (generally the `_static/pretext/css` folder of your book)
* The `-w` flag to specify that you want cssbuilder to "watch" the source files and rebuild any time they are changed.

Something like this:

```bash
npm run build -- -t theme-default-modern -o yourbookpath/_static/pretext/css -w'
```

To specify options or variables you can add the `-c` flag followed by a string containing JSON like this:

```bash
npm run build -- -t theme-default-modern -o ../../examples/sample-article/out/_static/pretext/css -c '{"options":{"color-scheme":"blues", "primary-color":"rgb(80, 30, 80)"}'
```

The options that can be set for a given theme correspond to the variables with default values in that that theme's entry file. For example, theme-salem lists:

```sass
// light colors
$color-scheme: 'ice-fire' !default; 
$color-main: null !default;
$color-do: null !default;
$color-fact: null !default;
$color-meta: null !default;

// dark colors
$primary-color-dark: #9db9d3 !default;
$background-color-dark: #23241f !default;
```

So to override the `color-scheme` and `primary-color-dark` while building theme-salem, you could do:

```bash
npm run build -- -t theme-default-modern -o ../../examples/sample-article/out/_static/pretext/css -c '{"options":{"color-scheme":"leaves", "primary-color-dark":"#549676"}'
```

For full help:

```bash
npm run build -- -h
```

Also see [README.md in css](../../css/README.md)
