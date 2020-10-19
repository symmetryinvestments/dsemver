module dsemver.buildinterface;

import std.file;
import std.stdio;
import std.process;
import std.format;
import std.string;

import dsemver.options;

string getDflags() {
	auto r = executeShell("dub describe --data=dflags");
	return r.output.strip();
}

void jsonFile(string dfiles) {
	executeShell("dub clean");
	const s = "DFLAGS=\"%s -X -Xf=dsemver.json\" dub build".format(dfiles);
	writeln(s);
	executeShell(s);
}

void buildInterface() {
	string oldCwd = getcwd();
	scope(exit) {
		chdir(oldCwd);
	}
	chdir(getOptions().projectPath);

	const dflags = getDflags();
	jsonFile(dflags);
}
