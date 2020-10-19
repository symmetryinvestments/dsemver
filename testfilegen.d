enum temp =
`module %s;

%s`;

void main() {
	import std.array : array;
	import std.file : dirEntries, SpanMode, readText, isDir, mkdir, exists,
		   rmdirRecurse;
	import std.process : executeShell;
	import std.algorithm : splitter;
	import std.stdio;
	import std.format;

	enum dir = "testdirgen";

	if(exists(dir)) {
		rmdirRecurse(dir);
	}
	mkdir(dir);

	enum testfiles = "testfiles/";

	foreach(de; dirEntries(testfiles, SpanMode.depth).array) {
		string[] t = readText(de.name).splitter(
`//
// SPLIT_HERE
//`)
			.array;
		assert(t.length == 2, de.name);

		foreach(idx, it; ["_old", "_new"]) {
			string fn = format("%s%s.d", de.name[testfiles.length ..  $], it);
			string dfn = format("%s/%s", dir, fn);
			{
				auto f = File(dfn, "w");
				f.write(format(temp, de.name[testfiles.length .. $ - 2], t[idx]));
			}
			string dmd = format("dmd -od=%s -X %s -Xf=%s/%s.json", dir, dfn, dir, fn);
			executeShell(dmd);
		}
	}
}
