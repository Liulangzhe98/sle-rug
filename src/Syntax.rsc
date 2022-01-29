module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = @Foldable "form" Id "{" Question* "}";

syntax Question
  = Str Id ":" Type // Simple question
  | Str Id ":" Type "=" Expr // computed question
  | "{" Question* "}" // block of questions
  | @Foldable "if" "(" Expr ")" "{" Question* "}"  // if-then 
  | @Foldable "if" "(" Expr ")" "{" Question* "}" "else" "{" Question* "}" // if-then-else clause  
  ; 
  
/*  
Java precedence: 
	All levels are LEFT to RIGHT unless written otherwise
	Level 16 : brackets
	Level 14 : unary minus (-6), !  (RIGHT to LEFT)
	Level 12 : *, / 
	Level 11 : +, -
	Level  9 : <=, >=, >, <
	Level  8 : ==, !=
	Level  4 : &&
	Level  3 : ||
*/
syntax Expr 
  	= Id \ "true" \ "false" // true/false are reserved keywords.
  	| Str | Bool | Int
  	| bracket "(" Expr ")"
  	> right ("-" | "!") Expr
  	> left Expr ("*" | "/") Expr
	> left Expr ("+" | "-") Expr
	> left Expr ("\<=" | "\>=" | "\<" | "\>") Expr
	> left Expr ("==" | "!=") Expr
	> left Expr "&&" Expr
	> left Expr "||" Expr
  ;
  
syntax Type
  = "boolean"
  | "integer"
  | "string" ;  
  
lexical Str 
	=  "\"" [a-zA-Z][a-zA-Z0-9_\ ?:]* "\"" ;

lexical Int 
  = [0-9]+;

lexical Bool 
	= "false" | "true";
