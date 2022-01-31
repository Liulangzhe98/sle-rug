module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

Type ATypeConv(AType atype) {
	switch(atype) {
		case booleanType(): return tbool();
		case integerType(): return tint();
		case stringType():  return tstr();
		default: 						return tunknown();
	}
}

// Function for better error handling
str TypeConv(Type t) {
	switch(t) {
		case tbool(): return "boolean";
		case tint():  return "integer";
		case tstr():  return "string";
		default:  		return "unknown type";
	}
}

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
	TEnv result = {};
	for(/simp_quest(str name, AId ref, AType t) := f) {
		result += { <ref.src, name, ref.name, ATypeConv(t)>};
	}
	for(/computed_quest(str name, AId ref, AType t, AExpr _) := f) {
		result += { <ref.src, name, ref.name, ATypeConv(t)>};
	}
	return result;
}

/* The check form function will create error/warning messages for the following problems:
	 * (ERROR) Duplicate names, but different types
	 * (ERROR) Duplicate labels
	 * (ERROR) Expression type does not match the declared type	 
	 * (ERROR) Invalid operands used for an operator
	 * (ERROR) Reference to undeclared question
	 * (ERROR) The guard of if(/else)-statement is not of type boolean
	 * (WARNING) Different label for the same question
	 * TODO: Check for cyclic reference
*/
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	set[Message] output = {};
	set[str] names = {};
	set[str] labels = {};
	rel[str name, Type st] knownTypes = {};
	rel[str name, str label, Type st] knownLabels = {};
	
	for(<loc def, str label, str name, Type t> <- tenv) {
		if (name in names) 
			if (<name, t> notin knownTypes) {
				output += { error("Duplicate name with different types.", def)};
			} else {
				if (<name, label, t> notin knownLabels)  {
					output += { warning("Possible wrong label for same question.", def);
				}
			}
		}
		names += {name};
		labels += {label};
		knownTypes += {<name, t>};
		knownLabels += {<name, label, t>};
	}
	for (/AQuestion q := f) {
		output += check(q, tenv, useDef);
	}
	return output; 
}

/* The check question function takes care of checking if the questions are formulated correctly.
		*	The declared type of computed questions should match the type of the expression.
		* The guarded questions are checked on validity
*/
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] output = {};
	switch(q) {
		case simp_quest(str _, AId _, AType _): ; 

  	case computed_quest(str _, AId _, AType t, AExpr arg): {
			if(ATypeConv(t) != typeOf(arg, tenv, useDef)) {
        output += { error(
        	"The expression type does not correspond with the type of the question. 
        	'Expected: <TypeConv(ATypeConv(t))> found <TypeConv(typeOf(arg, tenv, useDef))>", arg.src)};
      }
      output += check(arg, tenv, useDef);
 		}
  		
  	case guarded_question(AExpr guard, list[AQuestion] _):
			output += check_guard(guard, tenv, useDef);
			
		case guarded_else(AExpr guard, list[AQuestion] _, list [AQuestion] _):
			output += check_guard(guard, tenv, useDef);
			
  	case block_quest(list[AQuestion] questions):
  		for(/question := questions) {
  			output += check(question, tenv, useDef);
  		}
		default:
			output += {warning("Unhandled question <q>", q.src)};
	}
  return output; 
}

/* The check guard function take care of checking if the guarded question are formulated correctly.
		* Check if guard is of type boolean 
		* Check if the guard expression is valid
*/
set[Message] check_guard(AExpr guard, TEnv tenv, UseDef useDef) {
	set[Message] output = check(guard, tenv, useDef);
	if (typeOf(guard, tenv, useDef) != tbool()) {
		output += {error("The guard of the if-statement is not of type boolean", guard.src)};
	}
	return output;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
  	case boolean(bool _): ;
  	case integer(int _): ;
  	case string(str _): ;
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
		case un_min(AExpr x): 
			msgs += { 
				error("Invalid type for unary minus", e.src) | typeOf(x, tenv, useDef) != tint()
				} + check(x, tenv, useDef);
		case not(AExpr x):
			msgs += { 
				error("Invalid type for logical not", e.src) | typeOf(x, tenv, useDef) != tbool()
				} + check(x, tenv, useDef);
	  case and(AExpr x, AExpr y):
	 		msgs += { 
	 			error("Invalid type for logical and", e.src) | 
	 				typeOf(x, tenv, useDef) != tbool() || typeOf(y, tenv, useDef) != tbool()
	 			} + check(x, tenv, useDef) + check(y, tenv, useDef);
	  case or(AExpr x, AExpr y):
	 		msgs += { 
	 			error("Invalid type for logical or", e.src) | 
					typeOf(x, tenv, useDef) != tbool() || typeOf(y, tenv, useDef) != tbool()
				} + check(x, tenv, useDef) + check(y, tenv, useDef);
		default:  {// all binary integer expressions will reach here
			msgs += { 
				error("Invalid type for operand. 
				'Expected: integer, integer
				` found <TypeConv(typeOf(e.lhs, tenv, useDef))>, <TypeConv(typeOf(e.rhs, tenv, useDef))>", e.src) | 				
					typeOf(e.lhs, tenv, useDef) != tint() || typeOf(e.rhs, tenv, useDef) != tint()
				} + check(e.lhs, tenv, useDef) + check(e.rhs, tenv, useDef);
		}
  }
  return msgs; 
}


Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
	switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
		case boolean(bool _): return tbool();
		case integer(int _):  return tint();
		case string(str _):		return tstr();
		case un_min(AExpr _): return tint();
		case not(AExpr _):  	return tbool();
	  case mult(AExpr _, AExpr _): return tint();
	  case div(AExpr _, AExpr _):  return tint();
	  case plus(AExpr _, AExpr _): return tint();
	  case min(AExpr _, AExpr _):  return tint();
	  case leq(AExpr _, AExpr _):  return tbool();
	  case geq(AExpr _, AExpr _):  return tbool();
	  case lesser(AExpr _, AExpr _):   	 return tbool();
	  case greater(AExpr _, AExpr _):    return tbool();
	  case equals(AExpr _, AExpr _):   	 return tbool();
	  case not_equals(AExpr _, AExpr _): return tbool();
	  case and(AExpr _, AExpr _):				 return tbool();
	  case or(AExpr _, AExpr _):         return tbool(); 
	  default:							return tunknown(); 
  }
}

