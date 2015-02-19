
%{

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "lib/json/cJSON.h"

#define YYSTYPE char *

int yylex(void);
void yyerror(char*);

extern int yylineno;

#define AssertType(json, t)	assert( json->type == t )

//#define DBG(...)	{printf(__VA_ARGS__);puts("");}
#define DBG(...)	

cJSON* mc_createObj(const char *name){
	cJSON *rv = cJSON_CreateObject();
	cJSON_AddItemToObject(rv, "Object", cJSON_CreateString(name));
	// init vertex array
	cJSON *va = cJSON_CreateArray();
	cJSON_AddItemToObject(rv, "Vertex", va);
	cJSON *fa = cJSON_CreateArray();
	cJSON_AddItemToObject(rv, "Face", fa);
	return rv;
}

cJSON* mc_addTriple(cJSON *host, const char *name
	, const char *v1, const char *v2, const char *v3){
	cJSON *a = cJSON_GetObjectItem(host, name);
	assert(a);
	assert(cJSON_Array == a->type);
	//A triple is made
	cJSON *pt = cJSON_CreateArray();
	float nu[]={ atof(v1), atof(v2), atof(v3) };
	for(int i=0;i<sizeof(nu)/sizeof(nu[0]);++i){
		cJSON_AddItemToArray(pt, cJSON_CreateNumber(nu[i]));
	}
	cJSON_AddItemToArray(a, pt);
	return host;
}

cJSON* mc_addVertex(cJSON *host, const char *v1,
	const char *v2, const char *v3){
	return mc_addTriple(host, "Vertex", v1, v2, v3);
}

cJSON* mc_addFace(cJSON *host
	,const char *v1, const char *v2, const char *v3){
	return mc_addTriple(host, "Face", v1, v2, v3);
}

cJSON *curObj = 0;
cJSON *curVertexTriple = 0;

#define _ReleaseJson(a)	\
	if(a){ cJSON_Delete(a); a = 0;}
	
%}

%token TokenV
%token TokenS
%token TokenF
%token TokenO
%token ConstFloat
%token ConstInt
%token Var

%%
ObjDescription:
StatementOp {
}
;

Statement:
ObjectLine {
	//DBG("ObjectLine marked");
}
| VertexLine {
}
| SLine{
	//DBG("SLine marked");
}
| FaceLine{
}
;

StatementOp:
Statement StatementOp{
}
|{}
;

ObjectLine:
TokenO Var{
	DBG("Object %s", $2);
	_ReleaseJson(curObj);
	curObj = mc_createObj($2);
	free($2);
}
;

VertexLine:
TokenV ConstFloat ConstFloat ConstFloat {
	DBG("(%s, %s, %s)", $2, $3, $4);
	mc_addVertex(curObj, $2, $3, $4);

	free($4);
	free($3);
	free($2);
}
;

FaceLine:
TokenF ConstInt ConstInt ConstInt{
	DBG("Face (%s, %s, %s)", $2, $3, $4);
	mc_addFace(curObj, $2, $3, $4);

	free($4);
	free($3);
	free($2);
}
;

SLine:
TokenS Var {
	free($2);
};

%%

void yyerror(char *err){
	printf("error:%s, line %d\n", err, yylineno);
}

int main(void)
{
	if(yyparse()){
		printf("Aborted due to error(s) above\n");
		return -1;
	}
	if(curObj){
		//printf("Yes, there is one\n");
		const char *outs = cJSON_Print(curObj);
		printf("%s", outs);
	} else {
		fprintf(stderr, "No object imported?");
	}
}

