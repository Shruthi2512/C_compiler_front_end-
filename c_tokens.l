%{
#include<stdio.h>
#include "y.tab.h"
extern YYSTYPE yylval;
int flag=0;
int count = 0;
%}
%option yylineno
%%
"//"[' 'a-zA-Z0-9.]* ;
\/\*(.*\n)*.*\*\/ ;
int {ECHO; yylval.var_type=strdup(yytext);return INT;}
float {ECHO; yylval.var_type=strdup(yytext);return FLOAT;}
char {ECHO; yylval.var_type=strdup(yytext);return CHAR;}
"case" { ECHO; return CASE;}
switch {ECHO;return SWITCH;}
default {ECHO;return DEFAULT;}
"'" {ECHO;return SINGLE;}
"," {ECHO;return COMMA;}
":" {ECHO;return COLON;}
";" {ECHO; return SC;}
[0-9]+((\.[0-9]+)?) {ECHO;yylval.text=strdup(yytext);return NUM;}
"."  {ECHO; return DOT;}


"+=" {ECHO; yylval.text=strdup(yytext); return SPLUS;}
"-=" {ECHO; yylval.text=strdup(yytext); return SMINUS;}
"*=" {ECHO; yylval.text=strdup(yytext); return SMULT;}
"/=" {ECHO; yylval.text=strdup(yytext); return SDIV;}
"++" {ECHO; yylval.text=strdup(yytext); return INC;}
"--" {ECHO; yylval.text=strdup(yytext); return DEC;}
"("  {ECHO;return OPEN;}
")"  {ECHO;return CLOSE;}
"<=" {ECHO;yylval.text=strdup(yytext); return LESEQ; }
">=" {ECHO;yylval.text=strdup(yytext); return GRTEQ;}
"!=" {ECHO; yylval.text=strdup(yytext); return NOTEQ;}
"==" {ECHO; yylval.text=strdup(yytext); return EQEQ; }
"<"  {ECHO; yylval.text=strdup(yytext); return LESS;}
">"	 {ECHO; yylval.text=strdup(yytext); return GREAT;}
"{"	 {ECHO; return OPBRACE;}
"}"  {ECHO;return CLBRACE;}
"+"  {ECHO;yylval.text=strdup(yytext); return PLUS;}
"-"  {ECHO;yylval.text=strdup(yytext); return MINUS;}
"="	{ECHO;yylval.text=strdup(yytext); return ASSIGN; }
"*"	 {ECHO;yylval.text=strdup(yytext); return MULT;}
"/"	 {ECHO;yylval.text=strdup(yytext); return DIV;}
"^"	 {ECHO;yylval.text=strdup(yytext); return POW;}
"||" {ECHO;yylval.text=strdup(yytext); return OR;}
"&&" {ECHO;yylval.text=strdup(yytext); return AND;}
[' '\n\t\s] {ECHO;}
continue  {ECHO;return CONTINUE;}
break  {ECHO;return BREAK;}
return  {ECHO;return RETURN;}
if  {ECHO;return IF;}
while  {ECHO;return WHILE;}
for  {ECHO;return FOR;}
else  {ECHO;return ELSE;}
main	{ECHO; return MAIN;}

[a-zA-Z]+[a-zA-Z0-9]* {ECHO;yylval.text=strdup(yytext); return(ID);}
#					  return 0;
%%