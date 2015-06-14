module swift.util.utils;

import std.conv : to;
import std.c.string : strlen;

string CToString(const char[] str) {
	return CToString(str.ptr);
}

string CToString(const char * str) {
	return str[0 .. strlen(str)].dup;
}

IT GetTypeArray(T, IT)(T[] arr) {
	foreach(T item; arr) {
		if (cast(IT)item)
			return cast(IT)item;
	}
	return null;
}