struct Foo {
	struct Bar {
		int a;
	}
	int c;
}

//
// SPLIT HERE
//

struct Foo {
	struct Bar {
		int a;

		int b;
	}
	int c;
}
