module compare;

import std.array : array, empty, front;
import std.algorithm.searching;
import std.algorithm.comparison : equal;
import std.typecons : nullable, Nullable;
import std.format;
import ast;

enum ResultValue {
	equal,
	minor,
	major
}

struct Result {
	ResultValue value;
	string reason;
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

Result compareOldNew(ref const(Ast) old, ref const(Ast) neu) {
	foreach(ref mod; old.modules) {
		Nullable!(const(Module)) fMod = findModule(neu, mod);
		if(fMod.isNull()) { // Not found
			return Result(ResultValue.major, format(
				"module '%s' could no longer be found", mod.moduleToName()));
		} else { // module name added
			auto fModNN = fMod.get();
			if(!fModNN.name.isNull() && mod.name.isNull()) {
				return Result(ResultValue.major, format(
					"module '%s' added module name '%s'", mod.moduleToName()
						, fModNN.name.get()));
			} else { // recurse into module
				foreach(ref mem; mod.members) {
					Nullable!(const(Member)) fm = findMember(fModNN, mem);
					if(fm.isNull()) {
						return Result(ResultValue.major, format(
							"Member '%s' of module '%s' couldn't be found"
								, mem.name
								, mod.moduleToName()));
					}

				}
			}
		}
	}

	return Result(ResultValue.equal, "");
}

bool areEqualImpl(T)(ref const(T) a, ref const(T) b) {
	import std.traits : isSomeString, isArray, FieldNameTuple;
	static if(isSomeString!T) {
		return a == b;
	} else static if(isArray!T) {
		if(a.length != b.length) {
			return false;
		} else {
			return equal!((g,h) => areEqualImpl(g, h))(a, b);
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
			if(!areEqualImpl(__traits(getMember, a, mem)
					, __traits(getMember, b, mem)))
			{
				return false;
			}
		}
		return true;
	} else {
		static assert(false, "Unhandled type " ~ T.stringof);
	}
}

auto find2(alias pred, Rng, E)(Rng r, E e) {
	struct R {
		Rng r;

		@property auto front() {
			return r.front;
		}

		@property bool empty() {
			return r.empty;
		}

		private void popFrontImpl() {
			while(!this.r.empty && !pred(this.r.front, e)) {
				this.r = this.r[1 .. $];
			}
		}

		void popFront() {
			this.r = this.r[1 .. $];
			this.popFrontImpl();
		}
	}

	R ret;
	ret.r = r;
	ret.popFrontImpl();
	return ret;
}

auto find2(alias pred, Rng)(Rng r) {
	struct R {
		Rng r;

		@property auto front() {
			return r.front;
		}

		@property bool empty() {
			return r.empty;
		}

		private void popFrontImpl() {
			while(!this.r.empty && !pred(this.r.front)) {
				this.r = this.r[1 .. $];
			}
		}

		void popFront() {
			this.r = this.r[1 .. $];
			this.popFrontImpl();
		}
	}

	R ret;
	ret.r = r;
	ret.popFrontImpl();
	return ret;
}

Nullable!(const(Member)) findMember(ref const(Module) toFindIn
	, ref const(Member) mem)
{
	import std.range : isForwardRange;

	static assert(isForwardRange!(typeof(cast()toFindIn.members)));
	auto n = toFindIn.members.find2!(a => a.name == mem.name)().array;
	auto f = n.find2!(areEqualImpl)(mem);
	return f.empty
		? Nullable!(const(Member)).init
		: nullable(f.front);
}

unittest {
	enum o = "old.d.json";
	import std.file : dirEntries, SpanMode;
	import std.algorithm.searching : canFind;
	foreach(fn; dirEntries("testdirgen/", "*.json", SpanMode.depth)) {
		auto a = parse(fn.name);
		auto b = fn.name.canFind(o)
			? parse(fn.name[0 .. $ - o.length] ~ "new.d.json")
			: parse(fn.name[0 .. $ - o.length] ~ "old.d.json");
		auto c = compareOldNew(a, b);
	}
}
