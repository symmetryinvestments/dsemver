// Result(major,major,major,major)

template Foo(T) {
	T var;
}

//
// SPLIT_HERE
//

template Foo(T) {
	const(T) var;
}
