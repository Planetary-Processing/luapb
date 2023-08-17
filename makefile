build:
	gcc -c -fPIC luapb.c -o tmp.o
	gcc tmp.o -shared -o libluapb.so
	rm tmp.o
