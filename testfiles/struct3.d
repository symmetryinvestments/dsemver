// Result(equal,major,minor,major)

struct Foo {
	struct Bar {
		int a;
	}
	int c;
}

//
// SPLIT_HERE
//

struct Foo {
	struct Bar {
		int a;

		int b;
	}
	int c;
}
