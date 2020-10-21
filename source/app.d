module app;

import std.stdio;
import std.array : empty, front;
import std.algorithm.iteration : map;

import dsemver.ast;
import dsemver.buildinterface;
import dsemver.compare;
import dsemver.git;
import dsemver.options;

int main(string[] args) {
	getOptOptions(args);

	string latest = getOptions().old;
	if(!getOptions().projectPath.empty
			&& getOptions().buildNextSemVer
			&& latest.empty
		)
	{
		latest = buildInterface("latest");
	}

	if(!getOptions().testParse.empty) {
		auto tp = parse(getOptions().testParse);
	}

	if(!getOptions().old.empty && !getOptions().neu.empty) {
		auto old = parse(getOptions().old);
		auto neu = parse(getOptions().neu);
		auto onrs = compareOldNew(old, neu);
		const onr = summarize(onrs);

		auto nors = compareOldNew(neu, old);
		const nor = summarize(nors);
		writefln("%s + %s = %s", onr, nor, combine(onr, nor));
	}

	string latestTagFn = getOptions().neu;

	if((getOptions().buildLastestTag || getOptions().buildNextSemVer)
			&& latestTagFn.empty
		)
	{
		const c = isClean(getOptions().projectPath);
		if(!c) {
			writefln("the git of the project '%s' has uncommited changes"
					~ " this is not supported"
					, getOptions().projectPath);
			return 1;
		}
		auto tags = getTags(getOptions().projectPath);
		if(tags.empty) {
			writefln("No tags that match a semver found in '%s'"
					, getOptions().projectPath);
			return 1;
		}

		scope(exit) {
			checkoutRef(getOptions().projectPath, "master");
		}

		checkoutRef(getOptions().projectPath, tags.front.gitRef);
		latestTagFn = buildInterface(tags.front.semver.toString());
	}

	if(getOptions().buildNextSemVer) {
		if(latest.empty) {
			writefln("No latest dsemver file available");
			return 1;
		}

		if(latestTagFn.empty) {
			writefln("No latest git tag dsemver file available");
			return 1;
		}

		auto old = parse(latestTagFn);
		auto neu = parse(latest);
		auto onrs = compareOldNew(old, neu);
		writefln("%--(%s\n%)", onrs.map!(i => i.reason));
		const onr = summarize(onrs);

		auto nors = compareOldNew(neu, old);
		const nor = summarize(nors);
		writefln("%s + %s = %s", onr, nor, combine(onr, nor));
	}
	return 0;
}
