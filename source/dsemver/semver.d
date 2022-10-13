module dsemver.semver;

import std.ascii : isAlpha, isDigit;
import std.array : array, empty, front;
import std.typecons : nullable, Nullable;
import std.algorithm.iteration : each, filter, map, splitter;
import std.algorithm.searching : all, countUntil;
import std.conv : to;
import std.format : format;
import std.exception : enforce, basicExceptionCtors, assertThrown,
	   assertNotThrown;
import std.utf : byChar, byUTF;
import std.range : popFront;

@safe pure:

struct SemVer {
@safe:

	uint major;
	uint minor;
	uint patch;

	string[] preRelease;
	string[] buildIdentifier;

	static immutable(SemVer) MinRelease = SemVer(0, 0, 0);
	static immutable(SemVer) MaxRelease = SemVer(uint.max, uint.max, uint.max);

	bool opEquals(const(SemVer) other) scope const nothrow pure @nogc {
		return compare(this, other) == 0;
	}

	int opCmp(const(SemVer) other) scope const nothrow pure @nogc {
		return compare(this, other);
	}

	size_t toHash() scope const nothrow @nogc pure {
		size_t hash = this.major.hashOf();
		hash = this.minor.hashOf(hash);
		hash = this.patch.hashOf(hash);
		this.preRelease.each!(it => hash = it.hashOf(hash));
		this.buildIdentifier.each!(it => hash = it.hashOf(hash));
		return hash;
	}

	@property SemVer dup() const pure {
		auto ret = SemVer(this.major, this.minor, this.patch,
				this.preRelease.dup(), this.buildIdentifier.dup());
		return ret;
	}

	static SemVer max() pure {
		return SemVer(uint.max, uint.max, uint.max);
	}

	static SemVer min() pure {
		return SemVer(uint.min, uint.min, uint.min);
	}

	string toString() const @safe pure {
		import std.array : appender, empty;
		import std.format : format;
		string ret = format("%s.%s.%s", this.major, this.minor, this.patch);
		if(!this.preRelease.empty) {
			ret ~= format("-%-(%s.%)", this.preRelease);
		}
		if(!this.buildIdentifier.empty) {
			ret ~= format("+%-(%s.%)", this.buildIdentifier);
		}
		return ret;
	}
}

int compare(const(SemVer) a, const(SemVer) b) nothrow pure @nogc {
	if(a.major != b.major) {
		return a.major < b.major ? -1 : 1;
	}

	if(a.minor != b.minor) {
		return a.minor < b.minor ? -1 : 1;
	}

	if(a.patch != b.patch) {
		return a.patch < b.patch ? -1 : 1;
	}

	if(a.preRelease.empty != b.preRelease.empty) {
		return a.preRelease.empty ? 1 : -1;
	}

	size_t idx;
	while(idx < a.preRelease.length && idx < b.preRelease.length) {
		string aStr = a.preRelease[idx];
		string bStr = b.preRelease[idx];
		if(aStr.length != bStr.length && aStr.isAllNumImpl && bStr.isAllNumImpl) {
			return aStr.length < bStr.length ? -1 : 1;
		}
		if(aStr != bStr) {
			return aStr < bStr ? -1 : 1;
		}
		++idx;
	}

	if(idx == a.preRelease.length && idx == b.preRelease.length) {
		return 0;
	}

	return idx < a.preRelease.length ? 1 : -1;
}

private bool isAllNumImpl(string s) nothrow pure @nogc {
	import std.utf : byUTF;
	import std.ascii : isDigit;
	import std.algorithm.searching : all;
	return s.byUTF!char().all!isDigit();
}

Nullable!uint isAllNum(string s) nothrow pure {
	const bool allNum = s.isAllNumImpl;
	if(allNum) {
		try {
			return nullable(to!uint(s));
		} catch(Exception e) {
			assert(false, s);
		}
	}
	return Nullable!(uint).init;
}

unittest {
	import std.format : format;
	auto i = isAllNum("hello world");
	assert(i.isNull());

	i = isAllNum("12354");
	assert(!i.isNull());
	assert(i.get() == 12354);

	i = isAllNum("0002354");
	assert(!i.isNull());
	assert(i.get() == 2354);
}

SemVer parseSemVer(string input) {
	SemVer ret;

	char[] inputRange = to!(char[])(input);

	if(!inputRange.empty && inputRange.front == 'v') {
		inputRange.popFront();
	}

	ret.major = splitOutNumber!isDot("Major", "first", inputRange);
	ret.minor = splitOutNumber!isDot("Minor", "second", inputRange);
	ret.patch = toNum("Patch", dropUntilPredOrEmpty!isPlusOrMinus(inputRange));
	if(!inputRange.empty && inputRange[0].isMinus()) {
		inputRange.popFront();
		ret.preRelease = splitter(dropUntilPredOrEmpty!isPlus(inputRange), '.')
			.map!(it => checkNotEmpty(it))
			.map!(it => checkASCII(it))
			.map!(it => to!string(it))
			.array;
	}
	if(!inputRange.empty) {
		enforce!InvalidSeperator(inputRange[0] == '+',
			format("Expected a '+' got '%s'", inputRange[0]));
		inputRange.popFront();
		ret.buildIdentifier =
			splitter(dropUntilPredOrEmpty!isFalse(inputRange), '.')
			.map!(it => checkNotEmpty(it))
			.map!(it => checkASCII(it))
			.map!(it => to!string(it))
			.array;
	}
	enforce!InputNotEmpty(inputRange.empty,
		format("Surprisingly input '%s' left", inputRange));
	return ret;
}

char[] checkNotEmpty(char[] cs) {
	enforce!EmptyIdentifier(!cs.empty,
		"Build or prerelease identifier must not be empty");
	return cs;
}

char[] checkASCII(char[] cs) {
	foreach(it; cs.byUTF!char()) {
		enforce!NonAsciiChar(isDigit(it) || isAlpha(it) || it == '-', format(
			"Non ASCII character '%s' surprisingly found input '%s'",
			it, cs
		));
	}
	return cs;
}

uint toNum(string numName, char[] input) {
	enforce!OnlyDigitAllowed(all!(isDigit)(input.byUTF!char()),
		format("%s range must solely consist of digits not '%s'",
			numName, input));
	return to!uint(input);
}

uint splitOutNumber(alias pred)(const string numName, const string dotName,
		ref char[] input)
{
	const ptrdiff_t dot = input.byUTF!char().countUntil!pred();
	enforce!InvalidSeperator(dot != -1,
		format("Couldn't find the %s dot in '%s'", dotName, input));
	char[] num = input[0 .. dot];
	const uint ret = toNum(numName, num);
	enforce!EmptyInput(input.length > dot + 1,
		format("Input '%s' ended surprisingly after %s version",
			input, numName));
	input = input[dot + 1 .. $];
	return ret;
}

char[] dropUntilPredOrEmpty(alias pred)(ref char[] input) @nogc nothrow pure {
	size_t pos;
	while(pos < input.length && !pred(input[pos])) {
		++pos;
	}
	char[] ret = input[0 .. pos];
	input = input[pos .. $];
	return ret;
}

bool isFalse(char c) @nogc nothrow pure {
	return false;
}

bool isDot(char c) @nogc nothrow pure {
	return c == '.';
}

bool isMinus(char c) @nogc nothrow pure {
	return c == '-';
}

bool isPlus(char c) @nogc nothrow pure {
	return c == '+';
}

bool isPlusOrMinus(char c) @nogc nothrow pure {
	return isPlus(c) || isMinus(c);
}

class SemVerParseException : Exception {
	mixin basicExceptionCtors;
}

class NonAsciiChar : SemVerParseException {
	mixin basicExceptionCtors;
}

class EmptyInput : SemVerParseException {
	mixin basicExceptionCtors;
}

class OnlyDigitAllowed : SemVerParseException {
	mixin basicExceptionCtors;
}

class InvalidSeperator : SemVerParseException {
	mixin basicExceptionCtors;
}

class InputNotEmpty : SemVerParseException {
	mixin basicExceptionCtors;
}

class EmptyIdentifier : SemVerParseException {
	mixin basicExceptionCtors;
}

private struct StrSV {
	string str;
	SemVer sv;
}

unittest {
	StrSV[] tests = [
		StrSV("0.0.4", SemVer(0,0,4)),
		StrSV("1.2.3", SemVer(1,2,3)),
		StrSV("10.20.30", SemVer(10,20,30)),
		StrSV("1.1.2-prerelease+meta", SemVer(1,1,2,["prerelease"], ["meta"])),
		StrSV("1.1.2+meta", SemVer(1,1,2,[],["meta"])),
		StrSV("1.0.0-alpha", SemVer(1,0,0,["alpha"],[])),
		StrSV("1.0.0-beta", SemVer(1,0,0,["beta"],[])),
		StrSV("1.0.0-alpha.beta", SemVer(1,0,0,["alpha", "beta"],[])),
		StrSV("1.0.0-alpha.beta.1", SemVer(1,0,0,["alpha", "beta", "1"],[])),
		StrSV("1.0.0-alpha.1", SemVer(1,0,0,["alpha", "1"],[])),
		StrSV("1.0.0-alpha0.valid", SemVer(1,0,0,["alpha0", "valid"],[])),
		StrSV("1.0.0-alpha.0valid", SemVer(1,0,0,["alpha", "0valid"],[])),
		StrSV("1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay",
				SemVer(1,0,0,["alpha-a", "b-c-somethinglong"],
					["build","1-aef","1-its-okay"])),
		StrSV("1.0.0-rc.1+build.1", SemVer(1,0,0,["rc", "1"],["build","1"])),
		StrSV("2.0.0-rc.1+build.123", SemVer(2,0,0,["rc", "1"],["build", "123"])),
		StrSV("1.2.3-beta", SemVer(1,2,3,["beta"],[])),
		StrSV("10.2.3-DEV-SNAPSHOT", SemVer(10,2,3,["DEV-SNAPSHOT"],[])),
		StrSV("1.2.3-SNAPSHOT-123", SemVer(1,2,3,["SNAPSHOT-123"],[])),
		StrSV("1.0.0", SemVer(1,0,0,[],[])),
		StrSV("2.0.0", SemVer(2,0,0,[],[])),
		StrSV("1.1.7", SemVer(1,1,7,[],[])),
		StrSV("2.0.0+build.1848", SemVer(2,0,0,[],["build","1848"])),
		StrSV("2.0.1-alpha.1227", SemVer(2,0,1,["alpha", "1227"],[])),
		StrSV("1.0.0-alpha+beta", SemVer(1,0,0,["alpha"],["beta"])),
		StrSV("1.0.0-0A.is.legal", SemVer(1,0,0,["0A", "is", "legal"],[])),
		StrSV("1.1.2+meta-valid", SemVer(1,1,2, [], ["meta-valid"])),

		StrSV("v0.0.4", SemVer(0,0,4)),
		StrSV("v1.2.3", SemVer(1,2,3)),
		StrSV("v10.20.30", SemVer(10,20,30)),
		StrSV("v1.1.2-prerelease+meta", SemVer(1,1,2,["prerelease"], ["meta"])),
		StrSV("v1.1.2+meta", SemVer(1,1,2,[],["meta"])),
		StrSV("v1.0.0-alpha", SemVer(1,0,0,["alpha"],[])),
		StrSV("v1.0.0-beta", SemVer(1,0,0,["beta"],[])),
		StrSV("v1.0.0-alpha.beta", SemVer(1,0,0,["alpha", "beta"],[])),
		StrSV("v1.0.0-alpha.beta.1", SemVer(1,0,0,["alpha", "beta", "1"],[])),
		StrSV("v1.0.0-alpha.1", SemVer(1,0,0,["alpha", "1"],[])),
		StrSV("v1.0.0-alpha0.valid", SemVer(1,0,0,["alpha0", "valid"],[])),
		StrSV("v1.0.0-alpha.0valid", SemVer(1,0,0,["alpha", "0valid"],[])),
		StrSV("v1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay",
				SemVer(1,0,0,["alpha-a", "b-c-somethinglong"],
					["build","1-aef","1-its-okay"])),
		StrSV("v1.0.0-rc.1+build.1", SemVer(1,0,0,["rc", "1"],["build","1"])),
		StrSV("v2.0.0-rc.1+build.123", SemVer(2,0,0,["rc", "1"],["build", "123"])),
		StrSV("v1.2.3-beta", SemVer(1,2,3,["beta"],[])),
		StrSV("v10.2.3-DEV-SNAPSHOT", SemVer(10,2,3,["DEV-SNAPSHOT"],[])),
		StrSV("v1.2.3-SNAPSHOT-123", SemVer(1,2,3,["SNAPSHOT-123"],[])),
		StrSV("v1.0.0", SemVer(1,0,0,[],[])),
		StrSV("v2.0.0", SemVer(2,0,0,[],[])),
		StrSV("v1.1.7", SemVer(1,1,7,[],[])),
		StrSV("v2.0.0+build.1848", SemVer(2,0,0,[],["build","1848"])),
		StrSV("v2.0.1-alpha.1227", SemVer(2,0,1,["alpha", "1227"],[])),
		StrSV("v1.0.0-alpha+beta", SemVer(1,0,0,["alpha"],["beta"])),
		StrSV("v1.0.0-0A.is.legal", SemVer(1,0,0,["0A", "is", "legal"],[])),
		StrSV("v1.1.2+meta-valid", SemVer(1,1,2, [], ["meta-valid"]))
	];

	foreach(test; tests) {
		SemVer sv = assertNotThrown(parseSemVer(test.str),
			format("An exception was thrown while parsing '%s'", test.str));
		assert(sv == test.sv, format("\ngot: %s\nexp: %s", sv, test.sv));
	}
}

unittest {
	assertThrown!InvalidSeperator(parseSemVer("Hello World"));
	assertThrown!OnlyDigitAllowed(parseSemVer("Hello World."));
	assertThrown!OnlyDigitAllowed(parseSemVer("1.2.332a"));
	assertThrown!NonAsciiChar(parseSemVer("1.2.3+ßßßßääü"));
	assertThrown!EmptyInput(parseSemVer("1.2."));
	assertThrown!EmptyInput(parseSemVer("1."));
	assertThrown!EmptyIdentifier(parseSemVer("2.0.1-alpha.1227.."));
	assertThrown!EmptyIdentifier(parseSemVer("2.0.1+alpha.1227.."));
}
