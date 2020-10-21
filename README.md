# dsemver

Let the computer compute the SemVer of the software.

# Idea

Semantic versioning is useful, but 0.x.x versioning is a pointless loophole.
When a piece of D software is published, and it is published if other people
can find it on dub, it is released.
And released means 1.0.0 at least.

Now, spending your time deciding what the right next version for a release is,
is a waste of time.
This can be computed.
This is what dsemver does.

# dlang semver

First release is 1.0.0.
There is no 0.x.x nightmare.

If a symbol is removed or its signature changed the major version is increment
and the minor and the bugfix number reset to 0.

If a new symbol gets added, the minor number is incremented and the bug fix
number is set to 0.

If all symbol stay the same the bugfix number is incremented.

# Usage

```sh
# print help imformation
./dsemver -h
```

```sh
# This will show the computed next version if there already exists a version tag
./dsemver -p PATH_TO_DUB_FOLDER -c
```

```sh
# compare two files
./dsemver -o OLD_FILE.json -n NEW_FILE.json
```

```sh
# using indirectly through dub
dub run dsemver -- YOUR options here
```

# FAQ

## Doesn't that mean we are going to have packages with version 1000.0.0

So what, all that stats for sure is that release 1000 has not backwards
comparability changes in relation to version 999.x.x.

## Found a bug?

Please create an issue, and if you are really nice, create a pull request that
fixes it.

## Isn't this what the ELM project repository does?

Yes, this is where I proudfully stole/copied/borrows the idea from.
So, thank you elm people.
