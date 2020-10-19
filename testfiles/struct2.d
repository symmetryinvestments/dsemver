// Result(major,major,major,major)

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
		double a;
	}
	int c;
}
