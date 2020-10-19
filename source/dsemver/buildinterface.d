module dsemver.buildinterface;

import std.file;
import std.stdio;
import std.process;
import std.format;
import std.string;

import dsemver.options;

enum dsemverDir = ".dsemver";

string getDflags() {
	auto r = executeShell("dub describe --data=dflags");
	return r.output.strip();
}

void jsonFile(string dfiles) {
	executeShell("dub clean");
	const s = "DFLAGS=\"%s -X -Xf=%s/dsemver_latest.json\" dub build"
		.format(dfiles, dsemverDir);
	writeln(s);
	executeShell(s);
}

void buildInterface() {
	string oldCwd = getcwd();
	scope(exit) {
		chdir(oldCwd);
	}
	chdir(getOptions().projectPath);

	if(!exists(dsemverDir)) {
		mkdir(dsemverDir);
	}

	const dflags = getDflags();
	jsonFile(dflags);
}
