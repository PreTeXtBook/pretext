# PreTeXt (Miscellaneous) Support Files

### Runestone Services

The `webpack_static_imports.xml` file contains the current version of the minimal set of JS and CSS files for providing "Runestone Services", either when hosted on a Runestone Server or when creating HTML for self-hosting.

As of 2024-07-31 the latest version can obtained with a `wget` from [https://runestone.academy/cdn/runestone/latest/webpack_static_imports.xml](https://runestone.academy/cdn/runestone/latest/webpack_static_imports.xml).

An outline of the procedure to update this file is:

```
cd xsl/support
wget -O webpack_static_imports.xml https://runestone.academy/cdn/runestone/latest/webpack_static_imports.xml
git diff
git st

<verify/obtain new version number in diff, use in commit message>

git commit -am "Runestone: update services file to vX.Y.Z"

<push new commit to PreTeXt repository>
```
