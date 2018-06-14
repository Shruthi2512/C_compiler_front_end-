%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include <stdarg.h>
#include <ctype.h>
void yyerror(const char*);
int yylex();
int scope[100];
int scope_ctr;
int scope_ind;
int flag1 =1;

extern int yylineno;

int t=0;
int lab=0;
char stack[100][100];
int top=0;
int num_iter[10];
int iter_init[10];
int iter_top=0;
int number_of_iterations=0;
int return_flag=0;
typedef struct AST{
	char lexeme[100];
	int NumChild;
	struct AST **child;
}AST_node;
char typ[10]="nothing";
extern FILE *yyin;

/*
struct attributes{
	char* code; 
	struct attributes* true;
	struct attributes* false;
	struct attributes* next;
	char addr[20];
}; */

char* code_gen(int arg_count,...);
char* gen_addr(char* string);
char* new_temp();
char* code_concatenate(int arg_count,...);
char* new_label();
int is_int(char *,int);
void remove_rest(char *, char *);
char break_lab[20];
char switch_id[10];
%}





%token DOT SINGLE SC  COMMA LETTER  OPBRACE CLBRACE CONTINUE BREAK IF ELSE FOR WHILE POW OPEN CLOSE COMMENT SQ_OPEN SQ_CLOSE

%union {char* var_type; char* text; struct AST *node; struct attributes{
	char* code; 
	char* optimized_code;
	char* true;
	char* false;
	char* next_lab;
	char* next;
	char* addr;
	float val;
	int is_dig;
}A;}

%token <var_type> INT FLOAT CHAR 
%token <text> ID NUM PLUS MINUS MULT DIV AND OR LESS GREAT LESEQ GRTEQ NOTEQ EQEQ ASSIGN SPLUS SMINUS SMULT SDIV INC DEC SWITCH
%token <A> MAIN RETURN DEFAULT CASE COLON
%type <var_type> Type 
%type <text> relOp logOp s_op
%type <A> F T E assign_expr1 assign_expr relexp logexp cond decl s_operation unary_expr iter_stat stat comp_stat start jump_stat select_stat ST C B D Varlist 
%% 



start:INT MAIN OPEN CLOSE comp_stat  {  //printf("Here\n");
										$$=$5; print_sym_tab(); 
										if(return_flag)
										{	$$.code = code_concatenate(2,$$.code,"end: ");
											$$.optimized_code = code_concatenate(2,$$.optimized_code,"end: ");
										} 
										char* code1 = (char*)malloc(strlen($$.code)); 
										char* code2 = (char*)malloc(strlen($$.optimized_code));

										int a = remove_blank($$.code,code1); 
										a = remove_blank($$.optimized_code,code2);
										printf("\n IC: \n%s",code1); 
										printf("\n OC: \n%s",code2); 
										char* code3 = (char*)malloc(strlen(code1)); 
										char* code4 = (char*)malloc(strlen(code2));
										remove_rest(code1,code3);
										remove_rest(code2,code4);
										//printf("\n IC: \n%s",$$.code);  
										//printf("\n IC: \n%s",code1); 
										//printf("\n OC: \n%s",code2);
										//printf("\n\nOC: %s\n\n",$$.optimized_code);
										printf("\n\nIC\n\n");
										print_IC(code3);
										printf("\n\nOC\n\n");
										print_IC(code4);
										YYACCEPT;
										}   
     ;

comp_stat: OPBRACE {scope_ctr++;scope[scope_ind++]=scope_ctr;} stat CLBRACE {$$=$3; scope[scope_ind++]=0; $$.optimized_code = $3.optimized_code;}
		 ;
		 
stat:E SC stat               {$$.code = code_concatenate(2,$1.code,$3.code); $$.optimized_code = code_concatenate(2,$1.optimized_code, $3.optimized_code);}
    | assign_expr stat        {$$.code = code_concatenate(2,$1.code,$2.code); 
    							//printf("$2 optimized code: %s\n\n", $2.optimized_code);
    							$$.optimized_code = code_concatenate(2,$1.optimized_code, $2.optimized_code); 
    							$$.is_dig=$1.is_dig;
    							//printf("ABC\n");
    						  }
    |comp_stat stat          {$$.code = code_concatenate(2,$1.code,$2.code); $$.optimized_code = code_concatenate(2,$1.optimized_code, $2.optimized_code);}
    |{char * lab = new_label(); push(lab);} select_stat {pop();} stat         {$$.code = code_concatenate(2,$2.code,$4.code); 
    																			$$.optimized_code = code_concatenate(2,$2.optimized_code, $4.optimized_code);
    																			}   
    | {char * lab = new_label(); push(lab);} iter_stat {pop();} stat           {$$.code = code_concatenate(2,$2.code,$4.code); 
    																			$$.optimized_code = code_concatenate(2,$2.optimized_code, $4.optimized_code);
    																			}   
    | jump_stat stat           {$$.code = code_concatenate(2,$1.code,$2.code); $$.optimized_code = code_concatenate(2,$1.optimized_code, $2.optimized_code);}
    |decl stat   {$$.code = code_concatenate(2,$1.code,$2.code); $$.optimized_code = code_concatenate(2,$1.optimized_code, $2.optimized_code);}
    |%empty				{$$.code = " "; $$.optimized_code = $$.code;}
    ;



ST  : SWITCH OPEN ID CLOSE OPBRACE {scope_ctr++;scope[scope_ind++]=scope_ctr;} B CLBRACE 
											{
												scope[scope_ind++]=0;
												if(!look_up_sym_tab($3)){printf("Undeclared variable %s\n", $3); YYERROR;}
												$$.code = code_concatenate(2, $7.code, code_gen(2,stack[top],": "));
												$$.optimized_code = code_concatenate(2, $7.optimized_code, code_gen(2,stack[top],": "));
											}
    ; 

    
B   : C       {$$=$1;}
    | C D       {$$.code = code_concatenate(2,$1.code, $2.code); $$.optimized_code = code_concatenate(2,$1.optimized_code, $2.optimized_code);}
    | C B       {$$.code = code_concatenate(2,$1.code, $2.code); $$.optimized_code = code_concatenate(2,$1.optimized_code, $2.optimized_code);}
    ;
    
C   : CASE NUM COLON stat      {char* lab1 = new_label();
								//printf("in switch\n"); 
								char* lab2 = new_label(); 
								//printf("in switch\n"); 
								$$.code = code_concatenate(6,code_gen(4,"if ",$<text>-2," == ",$2," goto ", lab1), " goto ",lab2, code_gen(2,lab1,": "),$4.code, code_gen(2,lab2,": "));
								//printf("in switch\n"); 
								$$.optimized_code =code_concatenate(6,code_gen(6,"if ",$<text>-2," == ",$2," goto ", lab1), " goto ",lab2, code_gen(2, lab1,": "),$4.optimized_code, code_gen(2,lab2,": "));
								//printf("%s\n",$4.optimized_code);
								}
    ;


D   : DEFAULT COLON stat       {char* lab = new_label(); $$.code = code_concatenate(1,$3.code); $$.optimized_code = $3.optimized_code;}
    ;





select_stat: ST   {$$=$1;}
		   ;

iter_stat:FOR OPEN decl cond SC E CLOSE comp_stat		{char* begin = new_label(); 
															$3.next = begin; 
															$4.true = new_label(); 
															
															$8.next = stack[top];
															//push($8.next);
															$4.false = $8.next;   
															//printf("here %s",break_lab);
															strcpy(break_lab,$8.next);
															//printf("here2 %s",break_lab);
															//$8.next = new_label();
															$6.next = begin;

															$$.code = code_concatenate(8,$3.code, code_gen(2,begin,": "),code_gen(4,"if ", $4.code, "goto ", $4.true), 
															code_gen(2,"goto ", $4.false), code_gen(2,$4.true,": "),$8.code, code_gen(2,"goto ",begin),code_gen(2,$8.next,": \n"));

															if(num_iter)
															{
																//printf("HERE\n");
																$$.optimized_code = " ";
																$$.optimized_code = code_concatenate(2,$$.optimized_code,$3.optimized_code);
																
																
																
																//printf("number of iterations %d\n",number_of_iterations);
																int i;
																for(i=0;i<number_of_iterations;i++)
																{
																	$$.optimized_code = code_concatenate(2,$$.optimized_code,$8.optimized_code);
																}
																//printf("FOR OC%s\n",$$.optimized_code);
															}
															else
															{
																$$.optimized_code = $$.code;
															}
															}
		 ;

jump_stat: BREAK SC     {$$.code = code_gen(2,"goto ",stack[top]); $$.optimized_code = $$.code;}
		 |RETURN E SC    {$$.code = code_gen(3,"return ",$2.addr,"\ngoto end\n");  $$.optimized_code = $$.code; return_flag=1;}
		 ;		

cond:relexp    {$$=$1;}
	|logexp    {$$=$1;}
	|E          {$$=$1;}
	;


relexp:E relOp E  {$$.code = code_gen(3,$1.code,$3.code,code_gen(3,$1.addr,$2,$3.addr)); 
					if(strcmp($2,"<")==0)
					{
						num_iter[iter_top++]=atoi($3.addr);
						//printf("TOP: %d\n",iter_top);
						number_of_iterations = num_iter[--iter_top]-iter_init[iter_top];
						//num_iter = atoi($3.addr);
						//printf("Number of iterations: %d\n",num_iter);
					}
					
					if(strcmp($2,"<=")==0)
					{
						num_iter[iter_top++]=atoi($3.addr);
						printf("TOP: %d\n",iter_top);
						number_of_iterations = num_iter[--iter_top]-iter_init[iter_top]+1;
					}
					if(strcmp($2,">")==0)
					{
						num_iter[iter_top++]=atoi($3.addr);
						printf("TOP: %d\n",iter_top);
						number_of_iterations = iter_init[--iter_top] - num_iter[iter_top];
					}
					if(strcmp($2,">=")==0)
					{
						num_iter[iter_top++]=atoi($3.addr);
						printf("TOP: %d\n",iter_top);
						number_of_iterations = iter_init[--iter_top] - num_iter[iter_top]+1;
					}
					
					}
	  ;

logexp:E logOp E   {$$.code = code_gen(3,$1.code,$3.code,code_gen(3,$1.addr,$2,$3.addr)); $$.optimized_code = $$.code;}
	  ;

logOp:AND   {$$=$1;}
	 |OR    {$$=$1;}
	 ;

relOp:LESEQ     {$$=$1;}
     |GRTEQ     {$$=$1;}
     |NOTEQ     {$$=$1;} 
     |EQEQ      {$$=$1;}
	 |LESS      {$$=$1;}
	 |GREAT    {$$=$1;}
	 ;

decl:Type Varlist SC     {$$.code = code_gen(3,$1," ",$2.code); $$.optimized_code = $$.code;}
    |Type assign_expr1   {$$.code = code_gen(1,$2.code); $$.optimized_code = $2.optimized_code; }

    ;

 
Type:INT 		{ $$=$1; strcpy(typ,$1);}
	|FLOAT      {$$=$1;strcpy(typ,$1);}
	;

Varlist:Varlist COMMA ID    {if(look_up_sym_tab_dec($3,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; } 
								if(scope[scope_ind-1]>0){update_sym_tab($<var_type>0,$3,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab($<var_type>0,$3,yylineno,scop);} 

								$$.code = code_gen(3,$1.code,", ",$3); $$.optimized_code = code_gen(3,$1.optimized_code,", ",$3);
								}
	   |ID  {$$.addr=gen_addr($1); 
	   					if(look_up_sym_tab_dec($1,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; }
	   					if(scope[scope_ind-1]>0){update_sym_tab($<var_type>0,$1,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab($<var_type>0,$1,yylineno,scop);} 
	   					$$.code = $1; $$.optimized_code = $1;
	   					//printf("%s ID\n",$1);
	   					}
	   	
	   ;

assign_expr:ID ASSIGN E COMMA assign_expr     {$$.addr = gen_addr($1);  
			   							$$.code = code_concatenate(3,$3.code,code_gen(3,$$.addr," = ",$3.addr),$5.code);
			   							char buf[10];
			   							int scop=get_scope();
			   							int ret=is_int($1,scop);
			   							if(ret)
			   							{
			   								if(is_digit($3.addr))
			   								{
			   									float val=atof($3.addr);
			   									int val1=(int)val;
			   									char buf1[10];
			   									gcvt(val1, 6, buf1);
			   									$$.code = code_concatenate(3,$3.code,code_gen(3,$$.addr," = ",buf1),$5.code);
			   								}
			   								else
			   									$$.code = code_concatenate(3,$3.code,code_gen(3,$$.addr," = ",$3.addr),$5.code);
			   							} 
			   							else
			   								$$.code = code_concatenate(3,$3.code,code_gen(3,$$.addr," = ",$3.addr),$5.code);
			   							//printf("%s\n",$1);
			   							
			   							if(ret)
			   							{
			   								int val=(int)$3.val;
			   								float f = val;
			   								gcvt(val, 6, buf);
			   							}
			   							else
											gcvt($3.val, 6, buf);
										if($3.is_dig)
			   							$$.optimized_code = code_concatenate(2,code_gen(3,$$.addr," = ",buf),$5.optimized_code);
			   							else
			   							$$.optimized_code = code_concatenate(3,$3.optimized_code,code_gen(3,$$.addr," = ",$3.addr),$5.optimized_code);
			   							if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}flag1=1;
			   							}
		   |ID ASSIGN E SC            	{
		  								$$.addr = gen_addr($1); 
		  								int scop=get_scope(); 
		  								int ret=is_int($1,scop);
		  								if(ret)
			   							{
			   								if(is_digit($3.addr))
			   								{
			   									float val=atof($3.addr);
			   									int val1=(int)val;
			   									char buf1[10];
			   									gcvt(val1, 6, buf1);
			   									$$.code = code_concatenate(2,$3.code,code_gen(3,$$.addr," = ",buf1));
			   								}
			   								else
			   									$$.code = code_concatenate(2,$3.code,code_gen(3,$$.addr," = ",$3.addr));
			   							} 
			   							else
			   								$$.code = code_concatenate(2,$3.code,code_gen(3,$$.addr," = ",$3.addr));
			   							char buf[10];
			   							
										
			   							if(ret)
			   							{
			   								int val=(int)$3.val;
			   								float f = val;
			   								gcvt(val, 6, buf);
			   							}
			   							else
											gcvt($3.val, 6, buf);
										//printf("flag %d",flag1);
										if($3.is_dig)
										{
											//printf("Assign Here\n");
			   								$$.optimized_code = code_concatenate(1,code_gen(3,$$.addr," = ",buf)); 
			   								//printf("%s\n",$$.optimized_code);
			   							}
			   							else
			   							{
			   								$$.optimized_code = code_concatenate(2,$3.optimized_code,code_gen(3,$$.addr," = ",$3.addr)); 
			   								//flag1=1;
			   							}
			   							//printf("OC: %s\n",$$.optimized_code);
			   							if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
			   							flag1=1;												
			   							}
		   ;

assign_expr1:ID ASSIGN E COMMA assign_expr1    {$$.addr = gen_addr($1);  
										
										if(strcmp(typ,"int")==0)
		   								{
		   									if(is_digit($3.addr))
		   									{
		   										float val=atof($3.addr);
		   										int val1=(int)val;
		   										char buf1[10];
		   										gcvt(val1, 6, buf1);
		   										$$.code = code_concatenate(3,$3.code,code_gen(5,typ," ",$$.addr," = ",buf1),$5.code); 
		   									}
		   									else
		   										$$.code = code_concatenate(3,$3.code,code_gen(5,typ," ",$$.addr," = ",$3.addr),$5.code); 

		   								}
		   								else
			   								$$.code = code_concatenate(3,$3.code,code_gen(5,typ," ",$$.addr," = ",$3.addr),$5.code); 
			   							
			   							char buf[10];
			   							if(strcmp(typ,"int")==0)
			   							{
			   								int val=(int)$3.val;
			   								float f = val;
			   								gcvt(val, 6, buf);
			   							}
										else
											gcvt($3.val, 6, buf);
										if($3.is_dig)
			   								$$.optimized_code = code_concatenate(2,code_gen(3,$$.addr," = ",buf),$5.optimized_code);
			   							else
			   								$$.optimized_code = code_concatenate(3,$3.optimized_code,code_gen(3,$$.addr," = ",$3.addr),$5.optimized_code);
			   							//$$.optimized_code = code_concatenate(2,code_gen(5,typ," ",$$.addr," = ",buf),$5.optimized_code);
			   							 if(look_up_sym_tab_dec($1,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR;flag1=1; }
if(scope[scope_ind-1]>0){update_sym_tab(typ,$1,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab(typ,$1,yylineno,scop);}
			   							}
		   |ID ASSIGN E SC           {  $$.addr = gen_addr($1);  
		   								
		   								if(strcmp(typ,"int")==0)
		   								{
		   									if(is_digit($3.addr))
		   									{
		   										float val=atof($3.addr);
		   										int val1=(int)val;
		   										char buf1[10];
		   										gcvt(val1, 6, buf1);
		   										$$.code = code_concatenate(2,$3.code,code_gen(5,typ," ",$$.addr," = ",buf1)); 
		   									}
		   									else
		   										$$.code = code_concatenate(2,$3.code,code_gen(5,typ," ",$$.addr," = ",$3.addr)); 

		   								}
		   								else
			   								$$.code = code_concatenate(2,$3.code,code_gen(5,typ," ",$$.addr," = ",$3.addr)); 
			   							char buf[10];
			   							if(strcmp(typ,"int")==0)
			   							{
			   								int val=(int)$3.val;
			   								float f = val;
			   								gcvt(val, 6, buf);
			   							}
										else
											gcvt($3.val, 6, buf);
										if($3.is_dig)
										{
											//printf("Here\n");
			   								$$.optimized_code = code_concatenate(1,code_gen(3,$$.addr," = ",buf)); 
			   							}
			   							else
			   							{
			   								$$.optimized_code = code_concatenate(2,$3.optimized_code,code_gen(3,$$.addr," = ",$3.addr)); 
			   								//flag1=1;
			   							}
			   							//$$.optimized_code = code_concatenate(1,code_gen(5,typ," ",$$.addr," = ",buf)); 
			   							//printf("OC: %s\n",$$.optimized_code); 
			   							 if(look_up_sym_tab_dec($1,scope[scope_ind-1])){ yyerror("Redeclaration\n");  YYERROR; } if(scope[scope_ind-1]>0){update_sym_tab(typ,$1,yylineno,scope[scope_ind-1]);}else{int scop=get_scope();update_sym_tab(typ,$1,yylineno,scop);} 
			   							iter_init[iter_top]=atoi($3.addr);
			   							//printf("TOP: %d",iter_top);flag1=1;
			   						 }
		   ;

E:E PLUS T    {$$.addr = new_temp(); $$.code = code_concatenate(3,$1.code,$3.code,code_gen(5,$$.addr," = ",$1.addr," + ",$3.addr)); 
				
				if(($1.is_dig) && ($3.is_dig))
				{
					$$.is_dig=1;
					//printf("HERE\n");
					//printf("Constant folding\n");
					//float temp = atof($1.addr) + atof($3.addr);
					float temp = $1.val+$3.val;
					char buf[10];
					gcvt(temp, 6, buf);
					$$.optimized_code = code_concatenate(3,$1.optimized_code,$3.optimized_code,code_gen(3,$$.addr," = ",buf));
					//printf("%s\n",$$.optimized_code);
					$$.val = temp;
					flag1 &= 1;
				}
				else
				{
					$$.is_dig=0;
					//printf("HERE\n");
					$$.optimized_code = $$.code;
					flag1=0;
				}
				
				}
 |E MINUS T   {$$.addr = new_temp(); $$.code = code_concatenate(3,$1.code,$3.code,code_gen(5,$$.addr," = ",$1.addr," - ",$3.addr));
 				if(($1.is_dig) && ($3.is_dig))
				{
					$$.is_dig=1;
					//printf("Constant folding\n");
					//float temp = atof($1.addr) - atof($3.addr);
					float temp = $1.val-$3.val;
					char buf[10];
					gcvt(temp, 6, buf);
					$$.optimized_code = code_concatenate(3,$1.optimized_code,$3.optimized_code,code_gen(3,$$.addr," = ",buf));
					//printf("%s\n",$$.optimized_code);
					$$.val = temp;
					flag1 &=1;
				}
				else
				{
					$$.is_dig=0;
					$$.optimized_code = $$.code;
					flag1=0;
				}
 				}
 |T            {$$=$1;}
 ;
 
T:T MULT F    {$$.addr = new_temp(); $$.code = code_concatenate(3,$1.code,$3.code,code_gen(5,$$.addr," = ",$1.addr," * ",$3.addr)); 
				if(($1.is_dig) && ($3.is_dig))
				{
					$$.is_dig=1;
					//printf("HERE MULT\n");
					//printf("Constant folding\n");
					//float temp = atof($1.addr) * atof($3.addr);
					float temp = $1.val*$3.val;
					char buf[10];
					gcvt(temp, 6, buf);
					$$.optimized_code = code_concatenate(3,$1.optimized_code,$3.optimized_code,code_gen(3,$$.addr," = ",buf));
					//printf("%s\n",$$.optimized_code);
					$$.val = temp;
					flag1 &=1;
				}

				else
				{
					$$.is_dig=0;
					$$.optimized_code = $$.code;
					flag1=0;
				}
				}
 |T DIV F     {$$.addr = new_temp(); $$.code = code_concatenate(3,$1.code,$3.code,code_gen(5,$$.addr," = ",$1.addr," / ",$3.addr)); 
 				if(($1.is_dig) && ($3.is_dig))
				{
					$$.is_dig=1;
					//printf("Constant folding\n");
					//float temp = atof($1.addr) / atof($3.addr);
					float temp = $1.val/$3.val;
					char buf[10];
					gcvt(temp, 6, buf);
					$$.optimized_code = code_concatenate(3,$1.optimized_code,$3.optimized_code,code_gen(3,$$.addr," = ",buf));
					//printf("%s\n",$$.optimized_code);
					$$.val = temp;
					flag1 &=1;
				}
				else
				{
					$$.is_dig=0;
					$$.optimized_code = $$.code;
					flag1=0;
				}
 				}
 |F         {$$.addr = $1.addr; $$.code = $1.code; $$.optimized_code = $1.optimized_code; $$.val = $1.val;$$.is_dig=$1.is_dig;}
 ;
 
F:ID  {$$.addr = gen_addr($1); $$.code = code_gen(1," ");if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;} $$.optimized_code = $$.code;$$.is_dig=0;}
 |NUM     {$$.addr = gen_addr($1); $$.code = code_gen(1," ");$$.optimized_code = $$.code; $$.val = atof($1);$$.is_dig=1;}       
 |OPEN E CLOSE   {$$= $2;}
 |unary_expr      {$$=$1;}
 |s_operation     {$$=$1;}
 ;
 
s_operation: ID s_op ID  {$$.addr = new_temp(); 
								$$.code = code_concatenate(2,code_gen(5,$$.addr,"=",$1,$2,$3), code_gen(3,$1,"=",$$.addr)); 
								if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
								if(!look_up_sym_tab($3)){printf("Undeclared variable %s\n", $3); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
								}
			   | ID s_op NUM {$$.addr = new_temp(); 
								$$.code = code_concatenate(2,code_gen(5,$$.addr,"=",$1,$2,$3), code_gen(3,$1,"=",$$.addr)); 
								if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
								}
			   | ID s_op OPEN E CLOSE {$$.addr = new_temp(); 
								$$.code = code_concatenate(3,$4.code,code_gen(5,$$.addr,"=",$1,$2,$4.addr), code_gen(3,$1,"=",$$.addr)); 
								if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
								}
			   ;

s_op:SPLUS   {$$="+";}
	|SMINUS  {$$="-";}
	|SMULT   {$$="*";}
	|SDIV    {$$="/";}
	;

unary_expr:INC ID 			{ $$.addr = new_temp(); 
								$$.code = code_concatenate(2,code_gen(4,$$.addr,"=",$2,"+ 1"),code_gen(3,$2,"=",$$.addr)); 
								if(!look_up_sym_tab($2)){printf("Undeclared variable %s\n", $2); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
							}
		  |ID INC  			{ $$.addr = new_temp(); 
								$$.code = code_concatenate(2,code_gen(4,$$.addr,"=",$1,"+ 1"),code_gen(3,$1,"=",$$.addr));
								if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
							}
		  |DEC ID           {  $$.addr = new_temp(); 
								$$.code = code_concatenate(2,code_gen(4,$$.addr,"=",$2,"- 1"),code_gen(3,$2,"=",$$.addr));
								if(!look_up_sym_tab($2)){printf("Undeclared variable %s\n", $2); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
							}
		  |ID DEC 			{  $$.addr = new_temp(); 
								$$.code = code_concatenate(2,code_gen(4,$$.addr,"=",$1,"- 1"),code_gen(3,$1,"=",$$.addr));
								if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
							}
		  | MINUS ID       {  $$.addr = new_temp(); 
								$$.code = code_gen(4,$$.addr,"=",$1,$2); 
								if(!look_up_sym_tab($1)){printf("Undeclared variable %s\n", $1); YYERROR;}
								$$.optimized_code = $$.code;
								$$.is_dig=0;
							}
		  | MINUS NUM      {  $$.addr = new_temp(); 
								$$.code = code_gen(4,$$.addr,"=",$1,$2); 
								$$.optimized_code = $$.code;
								$$.is_dig=1;
							}
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
	//printf("%d\n",ctr);


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
int is_int (char *nam, int scop)
{
	int i;
	for(i=0;i<ctr;i++)
	{
		if(strcmp(sym_tab[i].name,nam)==0 && scop==sym_tab[i].scope)
		{
			if(strcmp(sym_tab[i].type,"int")==0)
				return 1;
			else
				return 0;
		}
	}
	return 1;
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





void push(char* string)
{

	strcpy(stack[++top],string); 
	
	//printf("top: %s %d\n",stack[top],top);
}

void pop()
{
	//printf("top: %d",top);
	top--;
}

/*
struct entry sym_tab[100];
int ctr = 0;

void update_sym_tab(char* typ, char* nam)
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
	ctr++;
	//printf("%d\n",ctr);


}

*/

int remove_spaces(char* text, char* blank)
{
	int p;
	FILE *fp = fopen("temp.txt", "w");
    if (fp != NULL)
    {
        fputs(text, fp);
        fclose(fp);
    }
    //printf("Here\n");
    fp=fopen("temp.txt","r");
    FILE* fp2=fopen("newfile.txt","w");  //all the content gets copied to this filename and blank lines are also removed from your file

            while((p=getc(fp))!=EOF)
            {
            	//printf("Here2\n");
                fputc(p,fp2);
                if (p==10)
                    {
                    	fputc(p,fp2);
                              while((p=getc(fp))==10)
                              {
                              	printf("%c\n",p);
                              }
                    fputc(p,fp2);
                    }
            }
printf("Here 3\n");
fclose(fp);
printf("Here 4\n");
fclose(fp2);
printf("Here 5\n");
fp=fopen("newfile.txt", "r");
printf("Here 6\n");


//struct stat buf;
//stat("speed",&buf);
        //char *str = malloc(buf.st_size);
        while(!feof(fp))
        {
                char *s=malloc(1024);
                fgets(s,1024,fp);
                s[strlen(s)-1]='\0';
                strcat(blank,s);
        }
        printf("File content:%s\n",blank);


return 1;
}

int remove_blank(char *text, char* blank)
{
	int c=0; int d=0;
       while (text[c] != '\0') {
      if (text[c] == ' ') {
         int temp = c + 1;
         if (text[temp] != '\0') {
            while (text[temp] == ' ' && text[temp] != '\0') {
               if (text[temp] == ' ') {
                  c++;
               }  
               temp++;
            }
         }
      }
      blank[d] = text[c];
      c++;
      d++;
   }
 
   blank[d] = '\0';
 
   //printf("Text after removing blanks\n%s\n", blank);
 
   return 0;
}

void remove_rest(char *text, char* blank)
{
	char *tok=strtok(text,"\n");
	while(tok!=NULL)
	{
		if(strlen(tok)>1)
		{
			/*
			if(strcmp(tok[0],"L")==0)
			{
				strcat(blank,tok);
				strcat(blank," ");
				tok=strtok(NULL,"\n");
				strcat(blank,tok);
				strcat(blank,"\n");
			}
			*/
			if(strcmp(tok," goto ")==0)
			{
				strcat(blank,"goto");
				strcat(blank," ");
				tok=strtok(NULL,"\n");
				strcat(blank,tok);
				strcat(blank,"\n");
			}
			//char tmp[100];
			//strcpy(tmp,tok);
			/*
			if(tmp[0]=='L')
			{
				strcat(blank,tok);
				strcat(blank," ");
				tok=strtok(NULL,"\n");
				char temp1[10];
				strcpy(temp1,tok);
				if(temp1[0]!='L')
				{
					strcat(blank,tok);
					strcat(blank,"\n");
				}
				else
				{
					strcat(blank,"\n");
					strcat(blank,tok);
					strcat(blank,"\n");
				}
			}*/
			else			
			{
				strcat(blank,tok);
				strcat(blank,"\n");
			}
		}
		tok=strtok(NULL,"\n");
	}
	/*
	char *temp=malloc(strlen(blank));
	strcpy(temp,blank);
	printf("-----------------------------------\n");
	printf("%s\n",temp);
	printf("-----------------------------------\n");
	strcpy(blank,"");
	char *tok1=strtok(temp,"\n");
	while(tok1!=NULL)
	{
		char tmp[100];
		strcpy(tmp,tok1);
		if(tmp[0]=='L')
		{
				strcat(blank,tok1);
				//strcat(blank," ");
				tok1=strtok(NULL,"\n");
				//strcat(blank,tok1);
				if(strcmp(tok1,": ")==0)
				{
					strcat(blank,tok1);
					//tok1=strtok(NULL,"\n");
					//strcat(blank," ");
					//strcat(blank,tok1);
				}
				strcat(blank,"\n");	
		}
		else			
		{
			//strcat(blank,tok1);
			//strcat(blank,"\n");	
			strcat(blank,tok1);
			strcat(blank,"\n");
		}
		tok1=strtok(NULL,"\n");
	}
	*/
}

int is_digit(char* tmp)
{
  int j=0;
  int isDigit = 1;
  while(j<strlen(tmp))
  {
  	if(isdigit(tmp[j])|| tmp[j]=='.')
  	{
  		j++;
  		continue;
  	}
  	else
  	{
  		isDigit = 0;
  		break;
  	}
  	j++;
  }
  return isDigit;
}

void print_IC(char* str)
{
	// Returns first token 
    char *token = strtok(str, "\n");
   
    // Keep printing tokens while one of the
    // delimiters present in str[].
    while (token != NULL)
    {
        printf("%s\n", token);
        token = strtok(NULL, "\n");
    }
 
}


/*
void print_sym_tab()
{
	int i;
	printf("\n\nSymbol Table: \n");
	for(i=0;i<ctr;i++)
	{
		printf("<%s,%s,%d> \n",sym_tab[i].name, sym_tab[i].type, sym_tab[i].width);
	}
}

int look_up_sym_tab(char* nam)
{
	int i; 
	for(i=0;i<ctr;i++)
	{
		if(strcmp(sym_tab[i].name,nam)==0)
		{
			return 1;
		}
	}
	return 0;
}
*/


void tostring(char str[], int num)
{
    int i, rem, len = 0, n;
 
    n = num;
    while (n != 0)
    {
        len++;
        n /= 10;
    }
    for (i = 0; i < len; i++)
    {
        rem = num % 10;
        num = num / 10;
        str[len - (i + 1)] = rem + '0';
    }
    str[len] = '\0';
}
 
char* new_temp()
{
	t++;
	char* num = (char*)malloc(sizeof(int));
	tostring(num,t);
	char* temp = (char*)malloc(sizeof(int));
	strcat(temp,"t");
	strcat(temp,num);
	return temp;
}


char* new_label()
{
	lab++;
	char* num = (char*)malloc(sizeof(int));
	tostring(num,lab);
	char* temp = (char*)malloc(sizeof(int));
	strcat(temp,"L");
	strcat(temp,num);
	return temp;
}

char* code_concatenate(int arg_count,...)
{
	//printf("\nConcatenating\n");
	int i;
	va_list ap;
	va_start(ap, arg_count);
	char* temp = malloc(1000);
	for (i = 1; i <= arg_count; i++)
    {   
     	char* a = va_arg(ap, char*);
     	temp = (char*)realloc(temp,(strlen(temp)+strlen(a)+10));
     	strcat(temp,"\n");
     	strcat(temp,a);
     }
     return temp;     
}


char* gen_addr(char* string)
{
	char* addr = (char*)malloc(sizeof(string));
	strcpy(addr, string);
	return addr;
}

char* code_gen(int arg_count,...)
{
	int i;
	va_list ap;
	va_start(ap, arg_count);
	char* temp = malloc(1000);
	for (i = 1; i <= arg_count; i++)
    {   
     	char* a = va_arg(ap, char*);
     	temp = (char*)realloc(temp,(strlen(temp)+strlen(a)+10));
     	strcat(temp,a);
    }
    strcat(temp,"   ");
     return temp;  
}



int main()
{
	printf("Enter a string\n");
	//yylex();
	yyin=fopen("test1.txt","r");
	if(!yyparse())
	{
		printf("\nSuccess\n");

	}
	else
		printf("Fail\n");
	/*
	int i;
	for(i=0;i<scope_ind;i++)
		printf("%d ",scope[i]);
	*/
	//printf("\n");
	//printf("%d\n",is_digit("2"));
}



