
%{

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "lib/json/cJSON.h"

#define YYSTYPE char*

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
	cJSON *fan = cJSON_CreateArray();
	cJSON_AddItemToObject(rv, "FaceN", fan);
	cJSON *normal = cJSON_CreateArray();
	cJSON_AddItemToObject(rv, "Normal", normal);
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

cJSON *mc_addNormal(cJSON *host
	,const char *vn1, const char *vn2, const char *vn3){
	return mc_addTriple(host, "Normal", vn1, vn2, vn3);
}

cJSON *mc_addFaceN(cJSON *host, int v1, int vn1, int v2, int vn2, int v3, int vn3, int v4, int vn4)
{
	cJSON *facena = cJSON_GetObjectItem(host, "FaceN");
	char text[2][3][32];
	sprintf(text[0][0], "%d/%d", v2, vn2);
	sprintf(text[0][1], "%d/%d", v1, vn1);
	sprintf(text[0][2], "%d/%d", v3, vn3);

	sprintf(text[1][0], "%d/%d", v3, vn3);
	sprintf(text[1][1], "%d/%d", v1, vn1);
	sprintf(text[1][2], "%d/%d", v4, vn4);
	for(int i=0;i<2;++i){
		cJSON* face = cJSON_CreateArray();
		for(int j=0;j<3;++j){
			cJSON_AddItemToArray(face, cJSON_CreateString(text[i][j]));
		}
		cJSON_AddItemToArray(facena, face);
	}
}

cJSON *curObj = 0;
cJSON *curVertexTriple = 0;

struct VertexNormal
{
	int v;
	int vn;
};

struct FaceElement{
	int v;
	int vn;
	struct FaceElement *next;
};

struct FaceElement faceElementBottom;
struct FaceElement *faceElementStack = &faceElementBottom;
int _faceElementCount;

int faceElementStackTop()
{
	return _faceElementCount;
}

void pushFaceE(int v, int vn)
{
	struct FaceElement *fe = (struct FaceElement*)malloc(sizeof(struct FaceElement));
	fe->v = v;
	fe->vn = vn;
	fe->next = faceElementStack;
	faceElementStack = fe;  
	++_faceElementCount;
}

void popFaceE(struct VertexNormal *out)
{
	if(_faceElementCount <= 0){
		fprintf(stderr,"error poping face element! (stack empty)\n");
		abort();
	}
	--_faceElementCount;
	out->v = faceElementStack->v;
	out->vn = faceElementStack->vn;
	faceElementStack = faceElementStack->next;
}

#define _ReleaseJson(a)	\
	if(a){ cJSON_Delete(a); a = 0;}
	
%}

%token TokenV
%token TokenVN
%token TokenS
%token TokenF
%token TokenO
%token ConstFloat
%token ConstInt
%token TokenSlashSlash
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
| NormalLine{
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
	if(!curObj){
		fprintf(stderr, "object not defined\n");
		abort();
	}
	mc_addVertex(curObj, $2, $3, $4);

	free($4);
	free($3);
	free($2);
}
;

NormalLine:
TokenVN ConstFloat ConstFloat ConstFloat{
	if(!curObj){
		fprintf(stderr, "object not defined!\n");
		abort();
	}
	mc_addNormal(curObj, $2, $3, $4);
	free($4);
	free($3);
	free($2);
}

FaceLine:
TokenF ConstInt ConstInt ConstInt{
	DBG("Face (%s, %s, %s)", $2, $3, $4);
	if(!curObj){
			fprintf(stderr, "No curObj defined !\n");
			abort();  /// compiling error
	}
	mc_addFace(curObj, $2, $3, $4);

	free($4);
	free($3);
	free($2);
}
|TokenF Face0 Face0 Face0 Face0{
	DBG("Face with four v");
	// Get four Face0 out of stack
	struct VertexNormal a[4];
	for(int i=sizeof(a)/sizeof(a[0])-1;i>=0;--i){
		popFaceE(&a[i]);
	}
	DBG("Face with four (%d,%d), (%d,%d), (%d,%d) ,(%d,%d)", 
				a[0].v, a[0].vn,
				a[1].v, a[1].vn,
				a[2].v, a[2].vn,
				a[3].v, a[3].vn
		);
	if(!curObj){
		fprintf(stderr, "No object defined!\n");
		abort();
	}
	mc_addFaceN(curObj, a[0].v, a[0].vn, a[1].v, a[1].vn,
									a[2].v, a[2].vn, a[3].v, a[3].vn);
}
;

Face0:
ConstInt TokenSlashSlash ConstInt{
	//DBG("Face0 with (%s, %s)", $1, $3);
	pushFaceE(atoi($1), atoi($3));
}

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
		printf("%s\n", outs);
		cJSON_Delete(curObj);
		curObj = 0;

		if(faceElementStackTop()){
			fprintf(stderr,"face element stack un-balanced\n");
		}


	} else {
		fprintf(stderr, "No objects imported?\n");
	}

	
}

