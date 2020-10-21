module dsemver.compare;

import std.array : array, empty, front;
import std.algorithm.searching;
import std.algorithm.comparison : equal;
import std.typecons : nullable, Nullable;
import std.exception : enforce;
import std.format;
import std.stdio;

import dsemver.ast;

enum ResultValue {
	equal,
	minor,
	major
}

ResultValue combine(const ResultValue on, const ResultValue no)
		pure @safe
{
	final switch(on) {
		case ResultValue.equal:
			final switch(no) {
				case ResultValue.equal: return ResultValue.equal;
				case ResultValue.minor:
						throw new Exception(format("%s %s", on, no));
				case ResultValue.major: return ResultValue.minor;
			}
		case ResultValue.minor: assert(false);
		case ResultValue.major:
			final switch(no) {
				case ResultValue.equal: return on;
				case ResultValue.minor:
						throw new Exception(format("%s %s", on, no));
				case ResultValue.major: return on;
			}
	}
}

struct Result {
	ResultValue value;
	string reason;
}

ResultValue summarize(const(Result)[] rslts) {
	ResultValue rv;
	foreach(ref r; rslts) {
		if(r.value > rv) {
			rv = r.value;
		}
	}
	return rv;
}

Nullable!(const(Module)) findModule(ref const(Ast) toFindIn
		, ref const(Module) mod)
{
	auto f = mod.name.isNull()
		? toFindIn.modules.find!(m => m.file == mod.file)
		: toFindIn.modules.find!(m => !m.name.isNull()
				&& m.name.get() == mod.name.get());

	return f.empty
		? Nullable!(const(Module)).init
		: nullable(f.front);
}

Result[] compareOldNew(ref const(Ast) old, ref const(Ast) neu) {
	Result[] ret;
	foreach(ref mod; old.modules) {
		Nullable!(const(Module)) fMod = findModule(neu, mod);
		if(fMod.isNull()) { // Not found
			ret ~= Result(ResultValue.major, format(
				"module '%s' could no longer be found", mod.moduleToName()));
			continue;
		} else { // module name added
			auto fModNN = fMod.get();
			if(!fModNN.name.isNull() && mod.name.isNull()) {
				ret ~= Result(ResultValue.major, format(
					"module '%s' added module name '%s'", mod.moduleToName()
						, fModNN.name.get()));
				continue;
			} else { // recurse into module
				foreach(ref mem; mod.members) {
					// we can ignore private members
					if(!mem.protection.isNull()
							&& mem.protection.get() == "private")
					{
						continue;
					}
					Nullable!(const(Member)) fm = findMember(fModNN, mem);
					if(fm.isNull()) {
						ret ~= Result(ResultValue.major, format(
							"Ast Member '%s' of module '%s' couldn't be found"
								, mem.name
								, mod.moduleToName()));
						continue;
					}
					const memsRslt = compareOldNew(mem, fm.get()
							, [mod.moduleToName()]);
					ret ~= memsRslt;
				}
			}
		}
	}

	return ret;
}

Result[] compareOldNew(ref const(Member) old, ref const(Member) neu
		, string[] path)
{
	Result[] ret;

	if(old.members.isNull()) {
		return ret;
	}

	foreach(ref mem; old.members) {
		Nullable!(const(Member)) f = neu.findMember(mem);
		if(f.isNull()) {
			ret ~= Result(ResultValue.major, format(
				"%s of '%--(%s.%)' couldn't be found"
					, mem.toString(), path));
			continue;
		}

		string[] np = path ~ mem.name;
		if(mem.members.isNull()) {
			continue;
		}
		foreach(ref const(Member) sub; mem.members) {
			// we can ignore private members
			if(!sub.protection.isNull() && sub.protection.get() == "private") {
				continue;
			}
			Nullable!(const(Member)) fm = findMember(f.get(), sub);
			if(fm.isNull()) {
				ret ~= Result(ResultValue.major, format(
					"%s of '%--(%s.%)' couldn't be found"
						, sub.toString(), np));
				continue;
			}
			const memsRslt = compareOldNew(sub, fm.get(), np);
			ret ~= memsRslt;
		}
	}

	return ret;
}

private bool areEqualImpl(T)(ref const(T) a, ref const(T) b) {
	import std.traits : isSomeString, isArray, FieldNameTuple, Unqual;
	import std.range : ElementEncodingType;

	static if(isSomeString!T) {
		return a == b;
	} else static if(isArray!T) {
		if(a.length != b.length) {
			return false;
		} else {
			alias ET = Unqual!(ElementEncodingType!T);
			static if(is(ET == string)) {
				return a.all!(i => canFind(b, i));
			} else {
				return equal!((g,h) => areEqualImpl(g, h))(a, b);
			}
		}
	} else static if(is(T == long)) {
		return a == b;
	} else static if(is(T == Nullable!F, F)) {
		if(a.isNull() != b.isNull()) {
			return false;
		} else if(!a.isNull()) {
			return areEqualImpl(a.get(), b.get());
		} else {
			return true;
		}
	} else static if(is(T == struct)) {
		static foreach(mem; FieldNameTuple!T) {
			if(mem != "members"
					&& !areEqualImpl(__traits(getMember, a, mem)
							, __traits(getMember, b, mem))
						)
			{
				return false;
			}
		}
		return true;
	} else {
		static assert(false, "Unhandled type " ~ T.stringof);
	}
}

Nullable!(const(Member)) findMember(ref const(Member) toFindIn
	, ref const(Member) mem)
{
	import std.range : isForwardRange;

	if(toFindIn.members.isNull()) {
		return Nullable!(const(Member)).init;
	}

	auto n = toFindIn.members.get().find!(a => a.name == mem.name)().array;
	auto f = n.find!(areEqualImpl)(mem);
	return f.empty
		? Nullable!(const(Member)).init
		: nullable(f.front);
}

Nullable!(const(Member)) findMember(ref const(Module) toFindIn
	, ref const(Member) mem)
{
	import std.range : isForwardRange;

	static assert(isForwardRange!(typeof(cast()toFindIn.members)));
	auto n = toFindIn.members.find!(a => a.name == mem.name)().array;
	auto f = n.find!(areEqualImpl)(mem);
	return f.empty
		? Nullable!(const(Member)).init
		: nullable(f.front);
}

unittest {
	import std.file : dirEntries, SpanMode, readText;
	import std.algorithm.searching : canFind, startsWith, find;
	import std.algorithm.iteration : splitter, map;
	import std.string : strip;

	struct ExpectedResult {
		ResultValue old;
		ResultValue neu;
		ResultValue oldC;
		ResultValue neuC;
	}

	ExpectedResult getExpected(string fn) {
		import std.conv : to;
		enum sstr = "// Result";
		string t = readText(fn);
		auto s = t.splitter("\n").find!(l => l.startsWith(sstr));
		assert(!s.empty, fn);

		string[] ws = s.front[sstr.length .. $].strip("()")
			.splitter(",")
			.map!(r => r.strip())
			.array;

		enforce(ws.length == 4, fn);
		return ExpectedResult
			( ws[0].to!ResultValue()
			, ws[1].to!ResultValue()
			, ws[2].to!ResultValue()
			, ws[3].to!ResultValue()
			);
	}

	enum o = "old.d.json";
	foreach(fn; dirEntries("testdirgen/", "*old.d.json", SpanMode.depth)) {
		auto a = parse(fn.name);
		auto b = parse(fn.name[0 .. $ - o.length] ~ "new.d.json");

		string expected = fn.name[0 .. $ - 5];
		const ExpectedResult er = getExpected(expected);

		auto cmpsON = compareOldNew(a, b);
		auto sON = summarize(cmpsON);
		assert(sON == er.old, format("\nwhich: old new\nfile: %s\ngot: %s\nexp: %s", fn.name
				, sON, er.old));

		auto cmpsNO = compareOldNew(b, a);
		auto sNO = summarize(cmpsNO);
		assert(sNO == er.neu, format("\nwhich: neu old\nfile: %s\ngot: %s\nexp: %s", fn.name
				, sNO, er.neu));

		auto compAB = combine(sON, sNO);
		assert(compAB == er.oldC, format(
				"\nwhich: old new comb\nfile: %s\ngot: %s\nexp: %s", fn.name
				, compAB, er.oldC));

		auto compBA = combine(sNO, sON);
		assert(compBA == er.neuC, format(
				"\nwhich: new old comb\nfile: %s\ngot: %s\nexp: %s", fn.name
				, compBA, er.neuC));
	}
}
