Problem Statement: 
Generating Intermediate Code and Abstract Syntax Tree for C - for and switch statements, and implementing 2 optimization techniques

Overview:
The project was implemented using flex and bison. 
First the input is tokeninzed, and the C grammar is used to parse it. Action rules are added to each production of the grammar, which generates the symbol table (including scoping rules), Intermediate code, Optimized code, and constructs the abstract syntax tree. 

The file c_ICG is the code that uses grammar rules and actions to generate ICG and optimized ICG. 
The file c_AST is the code that is used to generate an abstract syntax tree. 
The file c_tokens has all the lex tokens that are created. 
The files test and test1 are input files. 


Implementation:

- Symbol Table: 
The symbol table contains information about all the variables declared. Scoping is also implemented with the use of arrays. 
It contains: the variable name, the variable type, the size of variable, the scope variables. 
Each time a variable is declared, first it is checked whether that variable already exists in the symbol table in that scope, and then it is entered into the symbol table if it doesn't already exist. Otherwise, it gives a redeclaration error. 
Every time a variable is assigned, it checks the symbol table to see if its a variable that has previously been declared. Otherwise, it throws an undeclared variable error. 


- Abstract Syntax Tree: 
The structure of each node in the abstract syntax tree - 
struct AST{
	char lexeme[100];
	int NumChild;
	struct AST **child;
}
The structure elements are: The content of the node itself, the number of children, and a pointer to the children. 
A new node is created using the make_new_node function, which takes as arguments the node, the 1st child and the 2nd child. In it, the contents of that node is copied, and it is made to point to its children. That node is returned. 
All the nodes have 2 children, except the 'for' statement, and the miltiple assignment statement, which have 4 children.
Since bottom up parsing is followed, the syntax tree nodes are created from the bottom and propogated upwards (Eg. $$.node = new_node($1,$2,$3) ), and at the first rule, where the input gets acceped if it is syntactically correct, the abstract syntax tree is printed. 
The printing format is -  "node --> children"


- Intermediate Code: 
The structure used for generating the intermediate code - 
struct attributes{
	char* code; 
	char* optimized_code;
	char* true;
	char* false;
	char* next_lab;
	char* next;
	char* addr;
}
The structure elements are: The code itself (which is a string, to which new code is concatenated), the optimized code (string), the labels true, false and next, and addr which stores the values and takes care of temporary variables.
The code is generated using the functions code_gen() and code_concatenate(), which can take a variable number of string arguments. They concatenate the strings and return it. They also allocate memory from the heap, and use the realloc function to reallocate just enough memory for the next part, so that memory is used optimally, and not wasted.
- char* code_gen(int arg_count,...)
Labels and temporaries are generated using the new_label() and new_temp() functions, which generate labels and temporaries incrementally (ie, L1 first, then L2 and so on; t1 first, then t2, t3 and so on)
Since bottom up parsing is followed, the Intermediate Code is created from the bottom and propogated upwards (Eg. $$.code = $1.code+$2.code ), and at the first rule, where the input gets acceped if it is syntactically correct, the string whih contanins the code ($$.code) is pre processed to remove some extra spaces and lines and is then printed.



Optimizations:

- Optimization 1 : Constant Folding 
This kind of optimization technique evaluates the right hand side of expressions and stores the evaluated value, instead of storing the expression itself. It is implemented in the expression grammar. If the RHS of an expression contains only numbers, then they are converted to numbers, evaluated, and copied to $$.addr. 
Eg. a = 100+1   ->  will be stored as 101, instead of 100+1

- Optimization 2: Loop unrolling 
Loop unrolling is a loop transformation technique that helps to optimize the execution time of a program by removing or reducing iterations. Loop unrolling increases the program’s speed by eliminating loop control instruction and loop test instructions.
Here, in the for loops, the condition variable and initializations of the loop variables are used to calculate the number of iterations (**only for single incrementing), and the code inside the loop is unrolled, ie, repeated that many times, so that no checcking or disrupting program flow by jumps needs to be done, and the code can just directly execute sequentially. 
Eg. for(int i=0;i<=10;i++)  ->  the code inside the for loop will be unrolled and copied 11 times. 