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
// SPLIT HERE
//

int fun(int a) {
	return a;
}

int fun(string s) {
	return cast(int)s.length;
}
