// Result(major,equal,major,minor)

int fun(int a) {
	return a;
}

int fun(double a) {
	return cast(int)a;
}

int fun(string s) {
	return cast(int)s.length;
}

//
// SPLIT_HERE
//

int fun(int a) {
	return a;
}

int fun(string s) {
	return cast(int)s.length;
}
