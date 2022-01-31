module Eval

import AST;
import Resolve;
import IO;
/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// Value defaultValue
// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  for(q <- f.questions) {
    switch(q) {
      case simp_quest(str _, AId ref, AType t):	
      	venv[ref.name] = defaultValue(t);
      case computed_quest(str _, AId ref, AType t, AExpr _):
      	venv[ref.name] = defaultValue(t);
      case block_quest(list[AQuestion] questions):
      	venv += initialEnv(form("block", questions));
      case guarded_question(AExpr _, list[AQuestion] questions):
     	venv += initialEnv(form("guarded", questions));
      case guarded_else(AExpr _, list[AQuestion] questions, list[AQuestion] else_quest):
        venv += initialEnv(form("if", questions)) + initialEnv(form("else", else_quest));
    }
  }    
  return venv;
}

Value defaultValue(AType t)  {
  switch(t) {
  	case booleanType():	return vbool(false);
  	case integerType():	return vint(0);
  	case stringType():	return vstr("");
  	default: throw "Unsupported  type";
  	}
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(q <- f.questions)  {
    venv = eval(q, inp, venv);
  }
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch(q) {
      case simp_quest(str question, AId ref, AType _):
      	if("\""+inp.question + "\"" == question) venv[ref.name] = inp.\value;
      case computed_quest(str _, AId ref, AType _, AExpr e):
      	  venv[ref.name] = eval(e, venv);
      case block_quest(list[AQuestion] questions):
      	for(qs <- questions) {
      	  venv = eval(qs, inp, venv);
      	}
      case guarded_question(AExpr e, list[AQuestion] questions):
        if(eval(e, venv) == vbool(true)) {
          for(qs <- questions) {
      	    venv = eval(qs, inp, venv);
      	  }
      	}
      case guarded_else(AExpr e, list[AQuestion] questions, list[AQuestion] else_quest):
      	if(eval(e, venv) == vbool(true)) {
      	  for(qs <- questions) {
      	    venv = eval(qs, inp, venv);
      	  }
      	} else {
      	  for(qs <- else_quest) {
      	    venv = eval(qs, inp, venv);
      	  }
      	}
    }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): 					return venv[x];
    case integer(int n): 					return vint(n);
    case boolean(bool b):					return vbool(b);
    case string(str s):						return vstr(s);
    case un_min(AExpr e):					return vint(-1 * eval(e, venv).n);
    case not(AExpr e):						return vbool(!eval(e, venv).b);
    case mult(AExpr lhs, AExpr rhs): 		return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): 		return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case plus(AExpr lhs, AExpr rhs): 		return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case min(AExpr lhs, AExpr rhs):			return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs):			return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs):			return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case lesser(AExpr lhs, AExpr rhs):		return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case greater(AExpr lhs, AExpr rhs):		return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case equals(AExpr lhs, AExpr rhs):		return vbool(eval(lhs, venv).n == eval(rhs, venv).n);
    case not_equals(AExpr lhs, AExpr rhs):	return vbool(eval(lhs, venv).n != eval(rhs, venv).n);
    case and(AExpr lhs, AExpr rhs):			return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs):			return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    default: throw "Unsupported expression <e>";
  }
}