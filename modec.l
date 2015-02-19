

%{
#include <stdio.h>
#include <stdlib.h>

#define YYSTYPE char*

#include "y.tab.h"
int yylex(void);
extern char* strdup(const char*);

#define PRT(...)    {printf(__VA_ARGS__); puts("");}
#define ERROR(...)  {fprintf(stderr,__VA_ARGS__); fprintf(stderr,"\n");}
%}

%%
o {
	//PRT("OBJECT");
	return TokenO;
}
	
v {
	//PRT("Vertex\n");
	return TokenV;
}

f {
	//PRT("Face\n");
	return TokenF;
}

s {
	return TokenS;
}

-?[0-9][0-9]*\.[0-9][0-9]* {
	yylval = strdup(yytext);
	return ConstFloat;
}

[0-9][0-9]* {
	yylval = strdup(yytext);
	return ConstInt;
}

[A-Za-z][A-Za-z0-9_]* {
	//PRT("VAR");
	yylval = strdup(yytext);
	return Var;
}

[ \n\t\r]   /*All ignored here.*/;

. {
	// And the rest. 
	ERROR("Unknown token\n");
	abort();
	//Shall we remove all the comments ??
}

%%

int yywrap(void){
	return 1;
}








