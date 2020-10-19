// Result(major,major,major,major)

int fun(T)(T t) {
	return cast(int)t;
}

//
// SPLIT_HERE
//

T fun(T)(T t) {
	return t;
}
