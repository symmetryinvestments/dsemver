module ast;

import std.json;
import std.typecons : Nullable, nullable;
import std.traits : isArray, isSomeString, isIntegral, isFloatingPoint,
	   FieldNameTuple, isBasicType;
import std.range : ElementEncodingType;
import std.format;
import std.exception : enforce;

struct Parameter {
	string name;
	Nullable!(string) deco;
	Nullable!(string) kind;
}

struct Member {
	string name;
	string kind;
	Nullable!(string) originalType;
	Nullable!(string) type;
	Nullable!(string[]) storageClass;
	Nullable!(string) deco;
	Nullable!(size_t) align_;
	Nullable!(size_t) offset;
	Nullable!(Parameter[]) parameters;
	Nullable!(string[]) overrides;
}

struct Symbol {
	string name;
	string kind;
	Nullable!(string) protection;
	Nullable!(string[]) selective;
	Nullable!(string) deco;
	Nullable!(Parameter[]) parameters;
}

struct Module {
	Nullable!string name;
	string kind;
	string file;
	Symbol[] members;
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
		foreach(it; jv.arrayNoRef()) {
			arr ~= parseJson!ET(it);
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
		static foreach(mem; FieldNameTuple!T) {{
			alias MT = typeof(__traits(getMember, T, mem));

			auto p = mem in jv;
			static if(is(MT : Nullable!F, F)) {
				if(p) {
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
