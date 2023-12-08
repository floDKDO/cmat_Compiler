all: cmat

cmat: cmat.tab.o lex.yy.o main.o tds.o quad.o
	$(CC) $(LDFLAGS) -g -O0 $^ -o $@ $(LDLIBS) 
	
tds.o : tds.c tds.h
	gcc -c -g -O0 tds.c
	
quad.o : quad.c quad.h
	gcc -c -g -O0 quad.c

cmat.tab.c: cmat.y
	bison -d -v cmat.y

lex.yy.c: cmat.lex cmat.tab.h
	flex cmat.lex

doc:
	bison --report=all --report-file=cmat.output \
		--graph=cmat.dot --output=/dev/null \
		cmat.y
	dot -Tpdf < cmat.dot > cmat.pdf

clean:
	rm -f *.o cmat.tab.c cmat.tab.h lex.yy.c cmat \
		cmat.output cmat.dot cmat.pdf
