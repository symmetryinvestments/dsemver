template Foo(T) {
	int fun(T t) {
		return cast(int)t;
	}
}

//
// SPLIT HERE
//

template Foo(T) {
	int fun(T t, int foo) {
		return cast(int)foo;
	}
}
