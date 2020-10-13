module options;

import std.typecons : Nullable, nullable, Tuple, tuple;
import args;

struct Options {
	//@Arg('p', Optional.no, 
	@Arg('p', 
			"The path to the project the SemVer should be calculated for")
	string projectPath;

	@Arg('o')
	string old;

	@Arg('n')
	string neu;

	@Arg('t')
	string testParse;
}

ref const(Options) getOptions() {
	return getWritableOptions();
}

ref Options getWritableOptions() {
	static Options ret;
	return ret;
}

void getOptOptions(ref string[] args) {
	import core.stdc.stdlib : exit;
	bool helpWanted = parseArgsWithConfigFile(getWritableOptions(), args);
	if(helpWanted) {
		printArgsHelp(getOptions(), "A text explaining the program");
		exit(0);
	}
}
