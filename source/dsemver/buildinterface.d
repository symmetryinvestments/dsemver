module dsemver.buildinterface;

import std.file;
import std.stdio;
import std.process;
import std.format;
import std.string;

import dsemver.options;

private enum dsemverDir = ".dsemver";

private string getDflags() {
	auto r = executeShell("dub describe --data=dflags");
	return r.output.strip();
}

private string jsonFile(string dfiles, string ver) {
	executeShell("dub clean");
	const fn = format("%s/dsemver_%s.json", dsemverDir, ver);
	const s = "DFLAGS=\"%s -X -Xf=%s\" dub build"
		.format(dfiles, fn);
	writeln(s);
	auto rc = executeShell(s);
	if (rc.status) {
		throw new Exception("The project doesn't compile:\n" ~ rc.output);
	}
	return fn;
}

string buildInterface(string ver) {
	string oldCwd = getcwd();
	scope(exit) {
		chdir(oldCwd);
	}
	chdir(getOptions().projectPath);

	if(!exists(dsemverDir)) {
		mkdir(dsemverDir);
	}

	const dflags = getDflags();
	return getOptions().projectPath ~ "/" ~ jsonFile(dflags, ver);
}
