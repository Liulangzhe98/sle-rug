module Check

import AST;
import Resolve;
import Message; // see standard library

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
		case stringType(): return tstr();
		default: return tunknown();
	}
}

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
	TEnv result = {};
	for(/simp_quest(str name, AId ref, AType t) := f) {
		result += { <ref.src, name, ref.name, ATypeConv(t)>} 	;
	}
	for(/computed_quest(str name, AId ref, AType t, AExpr _) := f) {
		result += { <ref.src, name, ref.name, ATypeConv(t)>} 	;
	}
	return {};
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	set[Message] output = {};
	for (/AQuestion q := f) {
		output += check(q, tenv, useDef);
	}
	return output; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
// - check that if (/else) question are valid and use a boolean as guard
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] output = {};
	switch(q) {
		case guarded_question(AExpr guard, list[AQuestion] _):
			output += check_guard(guard, tenv, useDef);
		case guarded_else(AExpr guard, list[AQuestion] _, list [AQuestion] _):
			output += check_guard(guard, tenv, useDef);
	}
	throw "Unhandled check for q: <q>";
  return output; 
}

// - check if guard is of type boolean 
// - check if the guard expression is valid
set[Message] check_guard(AExpr guard, TEnv tenv, UseDef useDef) {
	set[Message] output = check(guard, tenv, useDef);
	if (output == {} && typeOf(guard, tenv, useDef) != tbool()) {
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
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
		case boolean(bool _):
			return tbool();
		case integer(int _):
			return tint();
		case string(str _):
			return tstr();
		case un_min(AExpr _):
			return tint();
		case not(AExpr _):
			return tbool();
	  case mult(AExpr _, AExpr _):
	  	return tint();
	  case div(AExpr _, AExpr _):
	  	return tint();
	  case plus(AExpr _, AExpr _):
	  	return tint();
	  case min(AExpr _, AExpr _):
	  	return tint();
	  case leq(AExpr _, AExpr _):
	  	return tbool();
	  case geq(AExpr _, AExpr _):
	  	return tbool();
	  case lesser(AExpr _, AExpr _):
	  	return tbool();
	  case greater(AExpr _, AExpr _):
	  	return tbool();
	  case equals(AExpr _, AExpr _):
	  	return tbool();
	  case not_equals(AExpr _, AExpr _):
	  	return tbool();
	  case and(AExpr _, AExpr _):
	  	return tbool();
	  case or(AExpr _, AExpr _):
	  	return tbool(); 
  }
  return tunknown(); 
}

