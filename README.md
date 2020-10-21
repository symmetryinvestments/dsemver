# dsemver

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

If a symbol is removed or its signature changed the major version is increment
and the minor and the bugfix number reset to 0.

If a new symbol gets added, the minor number is incremented and the bug fix
number is set to 0.

If all symbol stay the same the bugfix number is incremented.

If no symbol is changed, added or removed the bug fix number is incremented.

# Usage

```d
./dsemver -p PATH_TO_DUB_FOLDER c
```

# FAQ

## Doesn't that mean we are going to have packages with version 1000.0.0

So what, all that stats for sure is that release 1000 has not backwards
comparability changes in relation to version 999.x.x.
