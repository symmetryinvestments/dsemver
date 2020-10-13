module compare;

import std.array : empty, front;
import std.algorithm.searching;
import std.typecons : nullable, Nullable;
import ast;

enum Result {
	equal,
	minor,
	major
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
	foreach(ref mod; neu.modules) {
		Nullable!(const(Module)) fMod = findModule(old, mod);	
	}

	return Result.equal;
}
