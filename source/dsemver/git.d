module dsemver.git;

import std.process : executeShell;
import std.algorithm.iteration : map, splitter;
import std.algorithm.searching : any, canFind, startsWith;
import std.string : stripLeft;
import std.exception : enforce;
import std.file : getcwd, chdir;
import std.format : format;

bool isClean(string projectPath) {
	const cwd = getcwd();
	chdir(projectPath);
	scope(exit) {
		chdir(cwd);
	}

	enum cmd = "git status --porcelain";
	const r = executeShell(cmd);
	enforce(r.status == 0, format("git status --procelain failed in '%s'"
			~ "\nWith return code '%s' and msg %s"
			, projectPath, r.status, r.output));

	const m = r.output.splitter("\n").map!(l => l.stripLeft)
		.any!(l => l.startsWith("M "));

	return !m;
}
