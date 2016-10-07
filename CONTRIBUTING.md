# Contribution guide

This guide aims to help developers working on this repository.

## Changing all images without copy-paste

We keep the multiple files for the different image versions in sync. Here is a
tip on how to use `git` commands to automatically apply patches targeting one
image to all the others, without incurring in manually editing each copy of each
modified file.

Supposing that changes were made to files in the 3.2 directory, we can then
apply those changes to all other images:

```bash
for version in 2.4 2.6 3.0-upg; do
  git diff -- 3.2 | git apply -p2 --directory ${version} --reject
done
```

Depending on the changes and the surrounding context, the patch may not apply
cleanly. In that case, Git will create `*.rej` files with the changes that could
not be applied.

You can show them all with:

```bash
find -name '*.rej' -exec cat {} \;
```

Fix the differences manually, then delete the `*.rej` files.

Notes:

- Sometimes it may be useful to ignore part of the context passing the `-C<n>`
  flag to `git apply`.
- Read `git help diff` and `git help apply` for details about the flags used
  here and further insights on how to combine them.

**Review the changes** before committing to make sure the patch to all versions
make sense.

Sometimes it is also useful to use a graphical diff tool such as
[Meld](http://meldmerge.org/) for a final verification, or working side-by-side
on the parts that actually differ and that cannot the copied over automatically.
