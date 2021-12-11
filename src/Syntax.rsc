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
  | @Foldable "if" "(" IF_Statement ")" "{" Question* "}"  // if-then 
  | @Foldable "else" "{" Question* "}" // else clause                     TODO: THIS BREAKS STUFF
  ; 
  
syntax IF_Statement
	= Id
	| Id "\>" Int ;  // TODO: implement correct if statement checking

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  	= Id \ "true" \ "false" // true/false are reserved keywords.
  	| bracket "(" Expr ")"
  	| left Expr "*" Expr
	| left Expr "+" Expr
	| left Expr "-" Expr
	| Int
  ;
  
syntax Type
  = "boolean"
  | "integer";  
  
lexical Str 
	=  "\"" [a-zA-Z][a-zA-Z0-9_\ ?:]* "\"" ;

lexical Int 
  = [0-9]+
  | "("[0-9]+")";

lexical Bool = ;



