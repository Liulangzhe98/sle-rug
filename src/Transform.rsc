module Transform

import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  f.questions = flatten(f.questions, boolean(true));
  return f; 
}

list[AQuestion] flatten(list[AQuestion] qs, AExpr e)  {
  list[AQuestion] fqs = [];
  for(q <- qs) {
    fqs += flatten(q, e);
   }
  return fqs;
}

list[AQuestion] flatten(AQuestion q, AExpr e)  {
  list[AQuestion] qs = [];
  switch(q)  {
    case simp_quest(str _, AId _, AType _):	
      qs += [guarded_question(e, [q])];
    case computed_quest(str _, AId _, AType _, AExpr _):
      qs += [guarded_question(e, [q])];
    case block_quest(list[AQuestion] questions):
      for(question <- questions) {
        qs += flatten(question, e);
      }
    case guarded_question(AExpr expr, list[AQuestion] questions):
      for(question <- questions) {
        qs += flatten(question, and(e, expr));
      }
    case guarded_else(AExpr expr, list[AQuestion] questions, list[AQuestion] else_quest):
      for(question <- questions) {
        qs += flatten(question, and(e, expr)) + flatten(else_quest, and(not(e), expr));
      }
    }
  return qs;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

