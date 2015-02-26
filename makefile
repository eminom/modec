all:
	yacc -d modec.y
	flex -l modec.l
	cc -std=c99 -o parser lex.yy.c y.tab.c lib/json/cJSON.c -lm

clean:
	rm -f *.json
	rm -f *.o
	rm -f parser
	rm -f y.tab.h y.tab.c lex.yy.c lex.yy.h
