module dsemver.options;

import std.typecons : Nullable, nullable, Tuple, tuple;
import args;

struct Options {
	//@Arg('p', Optional.no,
	@Arg('p', "The path to the project the SemVer should be calculated for")
	string projectPath;

	@Arg('o')
	string old;

	@Arg('n')
	string neu;

	@Arg('t')
	string testParse;

	@Arg('l', "Compute the interface of the latest git tag as reference")
	bool buildLastestTag;

	@Arg('c', "Compute the next version number")
	bool buildNextSemVer;

	@Arg('v', "Enable verbose output")
	bool verbose;
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
	if(helpWanted || args.length == 1) {
		printArgsHelp(getOptions(),
`

dsemver lets the computer compute the SemVer of your dlang software.

If this is the first time running dsemver on your project you like want to
run

'''
$ ./dsemver -- -p PATH_TO_PROJECT -l
'''

To compute the public interface of your latest git tag that looked it a SemVer
than you can run

'''
$ ./dsemver -- -p PATH_TO_PROJECT -c
'''

To compute the next SemVer of your project.`);
		exit(0);
	}
}
