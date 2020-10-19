module app;

import std.stdio;
import std.array : empty;

import dsemver.ast;
import dsemver.buildinterface;
import dsemver.compare;
import dsemver.options;

void main(string[] args) {
	getOptOptions(args);

	if(!getOptions().projectPath.empty) {
		buildInterface();
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
}
