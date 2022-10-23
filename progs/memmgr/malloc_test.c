// calling static functions within a compilation unit triggers more optimizations
#include "malloc.c"

int foo(int *p, void* q) {
	*p = 1;
	free_small(q, 4);
	return *p;
}
int main() {
	int* p = malloc_small(sizeof(int));
	if (!p) return 77;
	return foo(p, p)&1;
}
/*
clang                      -O1 malloc_test.c mmap0.c -w -o /tmp/c && /tmp/c; echo $? # 1
clang -fno-strict-aliasing -O1 malloc_test.c mmap0.c -w -o /tmp/c && /tmp/c; echo $? # 0
*/
