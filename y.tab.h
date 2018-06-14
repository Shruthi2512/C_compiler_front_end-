/* A Bison parser, made by GNU Bison 3.0.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2013 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    DOT = 258,
    SINGLE = 259,
    SC = 260,
    COMMA = 261,
    LETTER = 262,
    OPBRACE = 263,
    CLBRACE = 264,
    CONTINUE = 265,
    BREAK = 266,
    IF = 267,
    ELSE = 268,
    FOR = 269,
    WHILE = 270,
    POW = 271,
    OPEN = 272,
    CLOSE = 273,
    COMMENT = 274,
    SQ_OPEN = 275,
    SQ_CLOSE = 276,
    INT = 277,
    FLOAT = 278,
    CHAR = 279,
    ID = 280,
    NUM = 281,
    PLUS = 282,
    MINUS = 283,
    MULT = 284,
    DIV = 285,
    AND = 286,
    OR = 287,
    LESS = 288,
    GREAT = 289,
    LESEQ = 290,
    GRTEQ = 291,
    NOTEQ = 292,
    EQEQ = 293,
    ASSIGN = 294,
    SPLUS = 295,
    SMINUS = 296,
    SMULT = 297,
    SDIV = 298,
    INC = 299,
    DEC = 300,
    SWITCH = 301,
    MAIN = 302,
    RETURN = 303,
    DEFAULT = 304,
    CASE = 305,
    COLON = 306
  };
#endif
/* Tokens.  */
#define DOT 258
#define SINGLE 259
#define SC 260
#define COMMA 261
#define LETTER 262
#define OPBRACE 263
#define CLBRACE 264
#define CONTINUE 265
#define BREAK 266
#define IF 267
#define ELSE 268
#define FOR 269
#define WHILE 270
#define POW 271
#define OPEN 272
#define CLOSE 273
#define COMMENT 274
#define SQ_OPEN 275
#define SQ_CLOSE 276
#define INT 277
#define FLOAT 278
#define CHAR 279
#define ID 280
#define NUM 281
#define PLUS 282
#define MINUS 283
#define MULT 284
#define DIV 285
#define AND 286
#define OR 287
#define LESS 288
#define GREAT 289
#define LESEQ 290
#define GRTEQ 291
#define NOTEQ 292
#define EQEQ 293
#define ASSIGN 294
#define SPLUS 295
#define SMINUS 296
#define SMULT 297
#define SDIV 298
#define INC 299
#define DEC 300
#define SWITCH 301
#define MAIN 302
#define RETURN 303
#define DEFAULT 304
#define CASE 305
#define COLON 306

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE YYSTYPE;
union YYSTYPE
{
#line 59 "c_ICG.y" /* yacc.c:1909  */
char* var_type; char* text; struct AST *node; struct attributes{
	char* code; 
	char* optimized_code;
	char* true;
	char* false;
	char* next_lab;
	char* next;
	char* addr;
	float val;
	int is_dig;
}A;

#line 169 "y.tab.h" /* yacc.c:1909  */
};
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
