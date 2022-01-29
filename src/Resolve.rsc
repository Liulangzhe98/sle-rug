module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
	Use ref_uses = {};
  for(/AExpr expr := f) {
    ref_uses += {<ref.src, ref.name> | /AId ref := expr};
  }
  return ref_uses;
	
}

Def defs(AForm f) {
  return 
  	{ <ref.name, ref.src> | /simp_quest(str _, AId ref, AType _) := f} + 
  	{ <ref.name, ref.src> | /computed_quest(str _, AId ref, AType _, AExpr _) := f};
}