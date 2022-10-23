#include <malloc.h>

static int size2bin(size_t s) { return 0; }
static void * bin[1];
static void free_small(void *p, size_t s) {
	int b = size2bin(s);
	void *q = bin[b];
	*((void **)p) = q;
	bin[b] = p;
}
int foo(int *p, void* q) {
	*p = 1;
	free_small(q, 0);
	return *p;
}
int main() {
	int* p = malloc(sizeof(int));
	if (!p) return 77;
	return foo(p, p);
}
/*
clang                      -O1 unmalloc_test.c -w -o /tmp/c && /tmp/c; echo $? # 1
clang -fno-strict-aliasing -O1 unmalloc_test.c -w -o /tmp/c && /tmp/c; echo $? # 0
*/
