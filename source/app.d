import std.stdio;
import std.array : empty;

import aggregateprinter;

import ast;
import buildinterface;
import compare;
import options;

void main(string[] args) {
	getOptOptions(args);

	if(!getOptions().projectPath.empty) {
		buildInterface();
	}

	if(!getOptions().testParse.empty) {
		auto tp = parse(getOptions().testParse);
	}

	auto old = parse(getOptions().old);
	auto neu = parse(getOptions().neu);

	auto r = compareOldNew(old, neu);
	writeln(r);
}
