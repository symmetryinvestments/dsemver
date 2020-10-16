struct Foo {
	struct Bar {
		int a;
	}
	int a;
}

//
// SPLIT HERE
//

struct Foo {
	struct Bar {
		double a;
	}
	int a;
}
