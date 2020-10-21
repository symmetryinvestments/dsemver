module dsemver.git;

import std.array : array;
import std.process : executeShell;
import std.datetime;
import std.algorithm.iteration : filter, map, splitter;
import std.algorithm.searching : any, canFind, startsWith;
import std.algorithm.sorting : sort;
import std.string : stripLeft;
import std.typecons : nullable, Nullable, tuple;
import std.exception : enforce;
import std.file : getcwd, chdir;
import std.format : format;

import dsemver.semver;

struct SheelRslt {
	const int rslt;
	string output;
}

private SheelRslt execute(string projectPath, string command) {
	const cwd = getcwd();
	chdir(projectPath);
	scope(exit) {
		chdir(cwd);
	}

	const r = executeShell(command);
	enforce(r.status == 0, format("'%s' failed in '%s'"
			~ "\nWith return code '%s' and msg %s"
			, command, projectPath, r.status, r.output));
	return SheelRslt(r.status, r.output);
}

bool isClean(string projectPath) {
	enum cmd = "git status --porcelain";

	const r = execute(projectPath, cmd);

	const m = r.output.splitter("\n").map!(l => l.stripLeft)
		.any!(l => l.startsWith("M "));

	return !m;
}

private Nullable!SemVer toSemVer(string sv) {
	try {
		SemVer ret = parseSemVer(sv);
		return nullable(ret);
	} catch(Exception e) {
		return Nullable!(SemVer).init;
	}
}

struct RefSemVer {
	string gitRef;
	SemVer semver;
}

RefSemVer[] getTags(string projectPath) {
	enum cmd = "git for-each-ref --sort=creatordate --format '%(refname)' refs/tags";
	const r = execute(projectPath, cmd);

	enum prefix = "refs/tags/";

	SemVer dummy;

	return r.output.splitter("\n").filter!(l => l.startsWith(prefix))
		.map!(v => tuple(v, toSemVer(v[prefix.length .. $])))
		.filter!(v => !v[1].isNull())
		.map!(v => RefSemVer(v[0], v[1].get()))
		.array
		.sort!((a,b) => a.semver > b.semver)
		.array;
}

void checkoutRef(string projectPath, string tag) {
	const cmd = format("git checkout %s", tag);
	const r = execute(projectPath, cmd);
}
