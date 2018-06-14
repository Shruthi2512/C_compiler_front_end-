%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include <stdarg.h>
void yyerror(const char*);
int yylex();
int scope[100];
int scope_ctr;
int scope_ind;
char typ[10]="nothing";
typedef struct AST{
	char lexeme[100];
	int NumChild;
	struct AST **child;
}AST_node;

struct AST* make_for_node(char* root, AST_node* child1, AST_node* child2, AST_node* child3, AST_node* child4);
struct AST * make_node(char*, AST_node*, AST_node*);
struct AST* make_leaf(char* root);
void AST_print(struct AST *t);
extern FILE* yyin;
extern int yylineno;
%}

%locations



%token DOT SINGLE SC  COMMA LETTER  OPBRACE CLBRACE CONTINUE BREAK IF ELSE FOR WHILE POW OPEN CLOSE COMMENT 

%union {char* var_type; char* text; struct AST *node;}

%token <var_type> INT FLOAT CHAR 
%token <text> ID NUM PLUS MINUS MULT DIV AND OR LESS GREAT LESEQ GRTEQ NOTEQ EQEQ ASSIGN SPLUS SMINUS SMULT SDIV INC DEC SWITCH
%token <node> MAIN RETURN DEFAULT CASE COLON

%type <var_type> Type
%type <text> Varlist relOp logOp s_op

%type <node> F T E assign_expr1 assign_expr relexp logexp cond decl unary_expr iter_stat stat comp_stat start jump_stat select_stat ST C B D s_operation 


%% 



start:INT MAIN OPEN CLOSE comp_stat  {$$ = make_leaf($1); $$=make_node("Main",$1,$5);printf("\n\nAST:\n\n"); AST_print($$); 																printf("\n\n");print_sym_tab(); YYACCEPT;}   
     ;

comp_stat: OPBRACE SCOPE stat CLBRACE {$$=$3;scope[scope_ind++]=0;}
		 ;
		 
SCOPE: {scope_ctr++;scope[scope_ind++]=scope_ctr;}
	 ;
stat:E SC stat               {$$=make_node("Stat",$1,$3);}
    |assign_expr stat        {$$=make_node("Stat",$1,$2);}
    |comp_stat stat          {$$=make_node("Stat",$1,$2);}
    |select_stat stat        {$$=make_node("Stat",$1,$2);}
    |iter_stat stat          {$$=make_node("Stat",$1,$2);}
    |jump_stat stat     {$$=make_node("Stat",$1,$2);}
    |decl stat    {$$=make_node("Stat",$1,$2);}
    |				{$$=make_leaf("  ");}
    ;


ST  : SWITCH OPEN ID CLOSE OPBRACE  {scope_ctr++;scope[scope_ind++]=scope_ctr;}  B CLBRACE {scope[scope_ind++]=0;$3=make_leaf($3); 																$$=make_node("Switch",$3,$7);if(!look_up_sym_tab($3)){printf("Undeclared variable %s\n", $3); YYERROR;}}
    ; 

    
B   : C         {$$=$1;}
    | C D        {$$=make_node("Cases",$1,$2);}
    | C B       {$$=make_node("Cases",$1,$2);}
    ;
    
C   : CASE NUM COLON stat      {$$=make_node("Case",$2,$4);}
    ;

D   : DEFAULT COLON stat       {$1=make_leaf(" "); $$=make_node("Default",$1,$3);}
    ;





select_stat: ST   {$$=$1;}
		   ;

iter_stat:FOR OPEN decl cond SC E CLOSE comp_stat		{$$=make_for_node("for",$3,$4,$6,$8);}
		 ;

jump_stat:CONTINUE SC    {$$=make_leaf("Continue");}
		 | BREAK SC      {$$=make_leaf("Break");}
		 |RETURN E SC    {$1=make_leaf("Return");$$ = make_node("Stat",$1,$2);}
		 ;		

cond:relexp    {$$ = $1;}
	|logexp    {$$ = $1;}
	|E        {$$ = $1;}
	;


relexp:E relOp E   {$$=make_node($2,$1,$3);}
	  ;

logexp:E logOp E   {$$=make_node($2,$1,$3);}
	  ;

logOp:AND    {$$ = $1;}
	 |OR    {$$ = $1;}
	 ;

relOp:LESEQ   {$$ = $1;}
     |GRTEQ   {$$ = $1;}
     |NOTEQ   {$$ = $1;}
     |EQEQ   {$$ = $1;}
	 |LESS    {$$ = $1;}
	 |GREAT    {$$ = $1;}
	 ;

decl:Type Varlist SC    {$1=make_leaf($1); $$=make_leaf($2); $$=make_node("VarDecl",$1,$2); }     
    |Type assign_expr1   {$1=make_leaf($1); $$=make_node("VarDecl",$1,$2);} 
    ;
 
Type:INT 		{$$ = $1;strcpy(typ,$1);}
	|FLOAT      {$$ = $1;strcpy(typ,$1);}
	;

Varlist:Varlist COMMA ID    {$3=make_leaf($3);$$=make_node("VarList",$1,$3);if(look_up_sym_tab_dec($3,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; } 
								if(scope[scope_ind-1]>0){update_sym_tab($<var_type>0,$3,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab($<var_type>0,$3,yylineno,scop);}}
	   |ID 			{$$=make_leaf($1); if(look_up_sym_tab_dec($1,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; }
	   					if(scope[scope_ind-1]>0){update_sym_tab($<var_type>0,$1,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab($<var_type>0,$1,yylineno,scop);}}
	   

assign_expr:ID ASSIGN E COMMA assign_expr     {$1=make_leaf($1); $$=make_for_node($2,$1,$3,make_leaf(","),$5); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}}
		   |ID ASSIGN E SC            {$1=make_leaf($1); $$=make_node($2,$1,$3); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;} 												}
		   ;

assign_expr1:ID ASSIGN E COMMA assign_expr1    {$1=make_leaf($1);$$=make_for_node($2,$1,$3,make_leaf(","),$5); if(look_up_sym_tab_dec($1,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; }
if(scope[scope_ind-1]>0){update_sym_tab(typ,$1,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab(typ,$1,yylineno,scop);}}
		   |ID ASSIGN E SC           {$1=make_leaf($1);$$=make_node($2,$1,$3); if(look_up_sym_tab_dec($1,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; } if(scope[scope_ind-1]>0){update_sym_tab(typ,$1,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab(typ,$1,yylineno,scop);} }
		   ;

E:E PLUS T    {$$=make_node($2,$1,$3); }
 |E MINUS T    {$$=make_node($2,$1,$3);}
 |T            {$$=$1;}
 ;
 
T:T MULT F    {$$=make_node($2,$1,$3);}
 |T DIV F     {$$=make_node($2,$1,$3);}
 |F           {$$=$1;}
 ;
 
F:ID  {$$=make_leaf($1); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;} }
 |NUM            {$$=make_leaf($1);}
 |OPEN E CLOSE   {$$=$2;}
 |unary_expr        {$$=$1;}
 |s_operation      {$$=$1;}
 ;
 
s_operation: ID s_op ID  {$1=make_leaf($1); $3=make_leaf($3); $$=make_node($2,$1,$3); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}if(!look_up_sym_tab($3)){printf("Undeclared variable %s\n", $3); YYERROR;}}
			   | ID s_op NUM {$1=make_leaf($1); $3=make_leaf($3); $$=make_node($2,$1,$3); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}}
			   | ID s_op OPEN E CLOSE {$1=make_leaf($1); $$=make_node($2,$1,$4);}
			   ;

s_op:SPLUS   {$$=$1;}
	|SMINUS   {$$=$1;}
	|SMULT   {$$=$1;}
	|SDIV    {$$=$1;}
	;

unary_expr:INC ID {$$=make_leaf($1); $$=make_leaf($2);$$=make_node("temp",$1,$2); if(!look_up_sym_tab($2)){printf("Undeclared variable %s\n", $2); YYERROR;}}
		  |ID INC {$$=make_leaf($1); $$=make_leaf($2);$$=make_node("temp",$1,$2); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}}
		  |DEC ID {$$=make_leaf($1); $$=make_leaf($2);$$=make_node("temp",$1,$2); if(!look_up_sym_tab($2)){printf("Undeclared variable %s\n", $2); YYERROR;}}
		  |ID DEC {$$=make_leaf($1); $$=make_leaf($2);$$=make_node("temp",$1,$2); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}}
		  | MINUS ID {$$=make_leaf($1); $$=make_leaf($2);$$=make_node("temp",$1,$2); if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}}
		  | MINUS NUM   {$$=make_leaf($1); $$=make_leaf($2);$$=make_node("temp",$1,$2);}
		  ;
%%
void yyerror(const char* arg)
{
	printf("%s\n",arg);
}

struct entry
{
	char name[30];
	char type[10];
	int width;
	int line_num;
	int scope;
};




struct entry sym_tab[100];
int ctr = 0;

void update_sym_tab(char* typ, char* nam, int line, int scope)
{
	strcpy(sym_tab[ctr].name,nam);

	if(strcmp(typ,"int")==0)
	{
		strcpy(sym_tab[ctr].type,typ);
		sym_tab[ctr].width=4;
	}

	else if(strcmp(typ,"float")==0)
	{
		strcpy(sym_tab[ctr].type,typ);
		sym_tab[ctr].width=8;
	}
	else if(strcmp(typ,"char")==0)
	{
		strcpy(sym_tab[ctr].type,typ);
		sym_tab[ctr].width=1;	
	}
	sym_tab[ctr].line_num=line;
	sym_tab[ctr].scope=scope;
	ctr++;


}


void print_sym_tab()
{
	int i;
	printf("\n\nSymbol Table: \n");
	for(i=0;i<ctr;i++)
	{
		printf("<%s,%s,%d,%d, %d> \n",sym_tab[i].name, sym_tab[i].type, sym_tab[i].width,sym_tab[i].line_num,sym_tab[i].scope);
	}
}

int look_up_sym_tab(char* nam)
{
	int i; 
	for(i=0;i<ctr;i++)
	{
		if(strcmp(sym_tab[i].name,nam)==0)
		{
			int scop=sym_tab[i].scope;
			int flag=0;
			int zero_ctr=0;
			int j=scope_ind-1;
			while(j>=0)
			{
				if(scope[j]==0)
					zero_ctr++;
				else if(scope[j]!=0 && zero_ctr>0)
					zero_ctr--;
				else if(scope[j]!=0 && zero_ctr==0)
				{
					if(scope[j]==scop)
					{
						flag=1;
						return 1;
					}
				}
				j--;
			}
		}
	}
	return 0;
}

int look_up_sym_tab_dec(char* nam, int scop)
{
	int i; 
	for(i=0;i<ctr;i++)
	{
		if(strcmp(sym_tab[i].name,nam)==0 && sym_tab[i].scope==scop)
		{
			return 1;
		}
	}
	return 0;
}


void AST_print(struct AST *t)
{
	static int ctr=0;
	//printf("inside print tree\n");
	int i;
	if(t->NumChild==0) 
		return;

	struct AST *t2=t;
	printf("\n%s  -->",t2->lexeme);
	for(i=0;i<t2->NumChild;++i) 
	{
		printf("%s ",t2->child[i]->lexeme);
	}
	for(i=0;i<t2->NumChild;++i)
	{
		AST_print(t->child[i]);
	}

	
}



struct AST* make_node(char* root, AST_node* child1, AST_node* child2)
{
	//printf("Creating new node\n");
	struct AST * node = (struct AST*)malloc(sizeof(struct AST));
	node->child = (struct AST**)malloc(2*sizeof(struct AST *));
	node->NumChild = 2;//
	strcpy(node->lexeme,root);
	//printf("Copied lexeme\n");
	//printf("%s\n",node->lexeme);
	node->child[0] = child1;
	node->child[1] = child2;
	return node;
}

struct AST* make_for_node(char* root, AST_node* child1, AST_node* child2, AST_node* child3, AST_node* child4)
{
	//printf("Creating new node\n");
	struct AST * node = (struct AST*)malloc(sizeof(struct AST));
	node->child = (struct AST**)malloc(4*sizeof(struct AST *));
	node->NumChild = 4;
	strcpy(node->lexeme,root);
	node->child[0] = child1;
	node->child[1] = child2;
	node->child[2] = child3;
	node->child[3] = child4;
	return node;
}


struct AST* make_leaf(char* root)
{
	//printf("Creating new leaf ");
	struct AST * node = (struct AST*)malloc(sizeof(struct AST));
	strcpy(node->lexeme,root);
	//printf("%s\n",node->lexeme);
	node->NumChild = 0;
	node->child = NULL;
	return node;
}



int main()
{
	printf("Enter a string\n");
	yyin=fopen("test1.txt","r");
	//print_sym_tab();
	//yylex();
	if(!yyparse())
	{
		printf("Success\n");

	}
	else
	{
		printf("Fail\n");
		print_sym_tab();
	}
	/*
	for(int i=0;i<scope_ind;i++)
		printf("%d ",scope[i]);
	printf("\n");
	*/
}

int get_scope()
{
	//printf("ind :%d\n",scope_ind);
	int i=scope_ind-1;
	int zero_ctr=0;
	int flag=1;
	while(flag && i>0)
	{
		if(scope[i]!=0)
			zero_ctr--;
		else
			zero_ctr++;
		if(zero_ctr==0)
		{
			i--;
			flag=0;
			break;
		}
		i--;
	}
	return scope[i];
}

