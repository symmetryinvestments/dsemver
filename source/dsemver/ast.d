module dsemver.ast;

import std.stdio;
import std.array : array, appender;
import std.algorithm.iteration : map;
import std.algorithm.searching : endsWith, startsWith;
import std.json;
import std.typecons : Nullable, nullable;
import std.traits : isArray, isSomeString, isIntegral, isFloatingPoint,
	   FieldNameTuple, isBasicType;
import std.algorithm : sort, setDifference;
import std.range : ElementEncodingType;
import std.format;
import std.exception : enforce;

struct Parameter {
	Nullable!(string) name;
	Nullable!(string) type;
	Nullable!(string) deco;
	Nullable!(string) kind;
	Nullable!(string) defaultValue;
	Nullable!(string) default_;
	Nullable!(string[]) storageClass;
}

struct Member {
	string name;
	string kind;
	Nullable!(string) originalType;
	Nullable!(string) type;
	Nullable!(string) base;
	Nullable!(string) init_;
	Nullable!(string) value;
	Nullable!(string[]) storageClass;
	Nullable!(string) deco;
	Nullable!(string) baseDeco;
	Nullable!(long) align_;
	Nullable!(long) offset;
	Nullable!(Parameter[]) parameters;
	Nullable!(string[]) overrides;
	Nullable!(string) protection;
	Nullable!(string[]) selective;
	Nullable!(Member[]) members;
}

struct Module {
	Nullable!string name;
	string kind;
	string file;
	Member[] members;
}

string moduleToName(ref const(Module) mod) pure @safe {
	return mod.name.isNull
		? mod.file
		: mod.name.get();
}

string toString(ref const(Parameter) p) {
	auto app = appender!string();
	formattedWrite(app, "\"%s", p.name);
	if(!p.type.isNull()) {
		formattedWrite(app, " type %s", p.type.get());
	}
	if(!p.deco.isNull()) {
		formattedWrite(app, " deco %s", p.deco.get());
	}
	if(!p.kind.isNull()) {
		formattedWrite(app, " kind %s", p.kind.get());
	}
	if(!p.defaultValue.isNull()) {
		formattedWrite(app, " defaultValue %s", p.defaultValue.get());
	}
	if(!p.default_.isNull()) {
		formattedWrite(app, " default %s", p.default_.get());
	}
	if(!p.storageClass.isNull()) {
		formattedWrite(app, " storageClass %(%s, %)", p.storageClass.get());
	}
	app.put("\"");
	return app.data;
}

string toString(ref const(Member) mem) {
	import core.demangle;
	auto app = appender!string();
	formattedWrite(app, "\"%s", mem.kind);
	formattedWrite(app, " '%s'", mem.name);
	if(!mem.originalType.isNull) {
		formattedWrite(app, " original_type '%s'", mem.originalType.get());
	}
	if(!mem.type.isNull) {
		formattedWrite(app, " type '%s'", mem.type.get());
	}
	if(!mem.value.isNull) {
		formattedWrite(app, " value '%s'", mem.value.get());
	}
	if(!mem.storageClass.isNull) {
		formattedWrite(app, " storage class '%s'", mem.storageClass.get());
	}
	if(!mem.deco.isNull) {
		formattedWrite(app, " of type '%s'", demangleType(mem.deco.get()));
	}
	if(!mem.baseDeco.isNull) {
		formattedWrite(app, " '%s'", mem.baseDeco.get());
	}
	if(!mem.align_.isNull) {
		formattedWrite(app, " align '%s'", mem.align_.get());
	}
	if(!mem.base.isNull) {
		formattedWrite(app, " base '%s'", mem.base.get());
	}
	if(!mem.offset.isNull) {
		formattedWrite(app, " offset '%s'", mem.offset.get());
	}
	if(!mem.init_.isNull) {
		formattedWrite(app, " init '%s'", mem.init_.get());
	}
	if(!mem.parameters.isNull) {
		formattedWrite(app, " parameters '%(%s, %)'"
				, mem.parameters.get().map!(p => p.toString()));
	}
	if(!mem.overrides.isNull) {
		formattedWrite(app, " overrides '%(%s, %)'", mem.overrides.get());
	}
	if(!mem.protection.isNull) {
		formattedWrite(app, " protection '%s'", mem.protection.get());
	}
	if(!mem.selective.isNull) {
		formattedWrite(app, " selective '%(%s, %)'", mem.selective.get());
	}
	if(!mem.members.isNull) {
		formattedWrite(app, " members '%(%s, %)'"
				, mem.members.get().map!(m => m.toString()));
	}
	app.put("\"");
	return app.data;
}

struct Ast {
	Module[] modules;
}

Ast parse(string filename) {
	import std.file : readText;

	JSONValue jv = parseJSON(readText(filename));
	return Ast(parseJson!(Module[])(jv));
}

T parseJson(T)(JSONValue jv) {
	static if(isBasicType!T) {
		return jv.get!T();
	} else static if(isSomeString!T) {
		return jv.get!string();
	} else static if(isArray!T && !isSomeString!T) {
		enforce(jv.type == JSONType.array, format("Expected array not '%s'",
					jv.type));
		T arr;
		alias ET = ElementEncodingType!T;
		//pragma(msg, T.stringof ~ " " ~ ET.stringof);
		foreach(it; jv.arrayNoRef()) {
			auto tmp = parseJson!ET(it);
			static if(is(ET == Member) || is(ET == Module)) {
				static if(is(typeof(tmp.name) : Nullable!F, F)) {
					if(tmp.name.isNull) {
						continue;
					}
					auto name = tmp.name.get;
				} else {
					auto name = tmp.name;
				}
				if(name.startsWith("__unittest_")) {
					continue;
				}
			}
			arr ~= tmp;
		}
		return arr;
	} else static if(is(T : Nullable!G, G)) {
		if(jv.type != JSONType.null_) {
			return nullable(parseJson!G(jv));
		} else {
			return Nullable!(G).init;
		}
	} else static if(is(T == struct)) {
		enforce(jv.type == JSONType.object, format("Expected object '%s' not '%s'\n%s",
					T.stringof, jv.type, jv.toPrettyString()));
		T ret;

		string[] jsNames = jv.objectNoRef().keys().sort.array;
		string[] sNames = ([FieldNameTuple!T] ~ ["endchar", "endline", "char", "line"])
			.map!(it => it.endsWith("_") ? it[0 .. $ - 1] : it)
			.array.sort.array;
		auto sd = setDifference(jsNames, sNames);
		if(!sd.empty) {
			writefln("%s", sd);
		}

		static foreach(mem; FieldNameTuple!T) {{
			alias MT = typeof(__traits(getMember, T, mem));
			//pragma(msg, T.stringof ~ " " ~ mem ~ " " ~ MT.stringof);

			enum memNoPostfix = mem.endsWith("_") ? mem[0 .. $ - 1] : mem;

			auto p = memNoPostfix in jv;
			static if(is(MT : Nullable!F, F)) {
				if(p !is null) {
					__traits(getMember, ret, mem) = parseJson!(F)(*p);
				}
			} else {
				enforce(p !is null, format("Couldn't find '%s'\n%s", mem,
							jv.toPrettyString()));
				__traits(getMember, ret, mem) = parseJson!MT(*p);
			}
		}}
		return ret;
	}
}

unittest {
	import std.file;

	foreach(f; dirEntries("testdirgen/", "*.json", SpanMode.depth)) {
		try {
			auto a = parse(f.name);
		} catch(Exception e) {
			assert(false, format("%s\n%s", f.name, e));
		}
	}
}
