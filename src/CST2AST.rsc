module CST2AST

import Syntax;
import AST;
import ParseTree;
import Boolean;
import String;


/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return cst2ast(f); 
}

AForm cst2ast(frm: (Form) `form <Id f> { <Question* qs> }`)
  = form("<f>", [ cst2ast(q) | Question q <- qs], src = frm@\loc);

AQuestion cst2ast(Question q) {
  switch (q) {
  	case (Question) `<Str question> <Id ref> : <Type t>`: 
  		return simp_quest("<question>", id("<ref>", src=ref@\loc), cst2ast(t), src=question@\loc); 			
  	case (Question) `<Str question> <Id ref> : <Type t> = <Expr e>`:
  		return computed_quest("<question>", id("<ref>", src=ref@\loc), cst2ast(t), cst2ast(e), src=question@\loc);
  	case (Question) `{ <Question* questions> }`:
  		return block_quest([cst2ast(quest) | Question quest <- questions], src= q@\loc);
  	case (Question) `if ( <Expr guard> ) { <Question* questions> }`:
  		return guarded_question(cst2ast(guard), [cst2ast(quest) | Question quest <- questions], src = q@\loc);
  	case (Question) `if ( <Expr guard> ) { <Question* questions> } else { <Question* else_quest> }`:
  		return guarded_else(cst2ast(guard), 
  			[cst2ast(quest) | Question quest <- questions], 
  			[cst2ast(else_q) | Question else_q <- else_quest], src = q@\loc);
  	default: 
  		throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 		  return ref(id("<x>", src=x@\loc), src=x@\loc);
    case (Expr)`<Bool x>`: 		return boolean(fromString("<x>"), src=x@\loc);
    case (Expr)`<Int x>`: 		return integer(toInt("<x>"), src=x@\loc);
    case (Expr)`<Str x>`: 		return string("<x>", src=x@\loc);
    case (Expr)`(<Expr x>)`: 	return cst2ast(x);
    case (Expr)`-<Expr x>`: 	return un_min(cst2ast(x), src=x@\loc);
    case (Expr)`!<Expr x>`: 	return not(cst2ast(x), src=x@\loc);
    case (Expr)`<Expr lhs> * <Expr rhs>`: 
    	return mult(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> / <Expr rhs>`: 
    	return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> + <Expr rhs>`: 
    	return plus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> - <Expr rhs>`: 
    	return min(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: 
    	return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: 
    	return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \< <Expr rhs>`: 
    	return lesser(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \> <Expr rhs>`:
    	return greater(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> == <Expr rhs>`: 
    	return equals(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> != <Expr rhs>`: 
    	return not_equals(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> && <Expr rhs>`: 
    	return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> || <Expr rhs>`:
    	return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
  	case (Type)`boolean`: return booleanType(src=t@\loc);
  	case (Type)`integer`: return integerType(src=t@\loc);
  	case (Type)`string` : return stringType(src=t@\loc);
  
  	default: throw "Unhandled type: <t>";
  }
}
