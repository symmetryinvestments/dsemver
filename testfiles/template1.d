// Result(major,major,major,major)

template Foo(T) {
	int fun(T t) {
		return cast(int)t;
	}
}

//
// SPLIT_HERE
//

template Foo(T) {
	int fun(T t, int foo) {
		return cast(int)foo;
	}
}
