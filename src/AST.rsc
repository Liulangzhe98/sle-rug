module AST


/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = simp_quest(str question, AId ref, AType t)
  | computed_quest(str question, AId ref, AType t, AExpr arg)
  | block_quest(list[AQuestion] questions)
  | guarded_question(AExpr guard, list[AQuestion] questions) 
  | guarded_else(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolean(bool boolean)
  | integer(int val)
  | string(str name)
  | un_min(AExpr arg)
  | not(AExpr arg)
  | mult(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | plus(AExpr lhs, AExpr rhs)
  | min(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | lesser(AExpr lhs, AExpr rhs)
  | greater(AExpr lhs, AExpr rhs)
  | equals(AExpr lhs, AExpr rhs)
  | not_equals(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)  
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = booleanType()
  | integerType()
  | stringType()
  ;
