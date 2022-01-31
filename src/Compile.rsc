module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import String;
import Set;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map 
 		* - booleans to checkboxes, 
 		* - strings to textfields, 
 		* - ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */
 
// Function that should be called to compile the QL into HTML/JS
void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

// ===== HTML generation =====

// Main function creating the HTML needed for the form
HTML5Node form2html(AForm f) {
	UseDef useDef = resolve(f).useDef;
	return html("
		'\<head\>
		'  \<title\><f.name>\</title\>
		'  \<script src=\"<f.src[extension="js"].file>\"\><endTag("script")>
		'\</head\>
		'\<body\>
		'  <item("div", item("h1", "This is a form created from QL"))>
		'  <startTag("div", " class=\"main\"")>
		'    <questionsToHTML(f.questions, useDef)>
		'	 <endTag("div")>
		'\</body\>"); 
}


// Function that goes over the questions and creates the HTML needed
// Each question is seperated by a horizontal line create by <hr>
str questionsToHTML(list[AQuestion] qs, UseDef useDef) {
	str output = "";
	for(AQuestion q <- qs) {
		switch(q) {
			case simp_quest(str q1, AId ref, AType t):
				output += simpleQuest(q1, ref, t);
			case computed_quest(str q1, AId ref, AType t, AExpr arg):
				output += computedQuest(q1, ref, t, arg);
			case block_quest(list[AQuestion] questions):
				output += blockQuest(questions, useDef);
  		case guarded_question(AExpr guard, list[AQuestion] questions):
  			output += guardedQuest(guard, questions, useDef);
  		case guarded_else(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest): 
  			output += guardedElse(guard, questions, else_quest, useDef);
			default:
				println("NOT YET ");
		}
		output += "\<hr\>";
	}
	return output;
}


// Function to make simple question into HTML
// 	example: "Did you buy a house in 2010?" hasBoughtHouse: boolean
str simpleQuest(str q, AId ref, AType t) = "
	'<startTag("div", " id=\"<ref.src.offset>Q\"")>
	'		<item("p", q)>
	'  	<inputMaker(t, ref, q)>
	'<endTag("div")>";
	
	
// Function to make computed question into HTML
//  example: "Value residue:" valueResidue: integer = sellingPrice - privateDebt
str computedQuest(str q, AId ref, AType t, AExpr arg) {
	str output = "<startTag("div", " id=\"<ref.src.offset>CQ\"")>";
	output += "  \<p\><q>\</p\>";
	switch(t) {
  	case integerType():
  		output += "  \<input disabled type=number id=<ref.name>\>";
  	case stringType():
  		output += "  \<input disabled type=text id=<ref.name>\>";
	}
	return output + "<endTag("div")>";
}


// Function to make block question into HTML
str blockQuest(list[AQuestion] questions, UseDef useDef) = {
	return 
		"<startTag("div", " id=\"Block\"")>
		'  <questionsToHTML(questions, useDef)>
		'<endTag("div")>";
};


// Function to make if-statements into hideable HTML
//  example: if (hasSoldHouse) { ... }
str guardedQuest(AExpr guard, list[AQuestion] questions, UseDef useDef) {
	int offset = toList(useDef[guard.src])[0].offset;
	
	return 
	"<startTag("div", " id=\"IF_<offset>\"")>
	'  <startTag("div", " id=\"IF_<offset>_true\" style=display:None")>
	'    <questionsToHTML(questions, useDef)>
	'	 <endTag("div")>
	'<endTag("div")>";
}

// Function to make if-else-statements into hideable HTML
//  example: if (hasSoldHouse) { ... } else { ... }
str guardedElse(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest, UseDef useDef) {
	str output = "";
	int offset = toList(useDef[guard.src])[0].offset;
	
	return 
	"<startTag("div", " id=\"IF_<offset>\"")>
	'  <startTag("div", " id=\"IF_<offset>_true\" style=display:None")>
	'    <questionsToHTML(questions, useDef)>
	'	 <endTag("div")>
	'	 <startTag("div", " id=\"IF_<offset>_false\" style=display:None")>
	'    <questionsToHTML(else_quest, useDef)>
	'	 <endTag("div")>
	'<endTag("div")>";
}

// ===== Helper function to keep the code clean =====

// Helper str for easy html tag creation
str item(str op, str val) = "\<<op>\><val>\</<op>\>\n"; 
 

// Function to create radio button with labels
str radioInputMaker(AId ref, str val) 
		= "\<label for=\"<ref.src.offset>T\"\><val>\</label\>
			'\<input type=\"radio\" 
			'  id=\"<ref.src.offset>_<val>\" name=\"<ref.src.offset>\" value=<val>
			'  onChange=\"updateValues(this)\"
			'\>";


// Function that maps the abstract type to the corresponding HTML input type
str inputMaker(AType t, AId ref, str name) {
	switch(t) {
		case booleanType():
			return radioInputMaker(ref, "True") + radioInputMaker(ref, "False");
  	case integerType():
  		return 
  			"\<input type=number 
  			' id=<ref.name> name=<name> value=0
  			' onChange=\"updateValues(this)\"\>";
  	case stringType():
  		return 
  			"\<input type=text 
  			' id=<ref.name> name=<name>
  			' onChange=\"updateValues(this)\"\>";
  	default:
  		throw "Unknown abstract type <t>";
	}
}


// Function that maps all the computed question into a json.
// A cq is transformed into a key and value. The value can be evaluated via
// javascript's eval() function.
str cq2json(AForm f) {
	str output = "{";
	for (/computed_quest(str q1, AId id, AType _, AExpr arg) := f) {
		output += "<id.name>: \"<expr2str(arg)>\",";
	}
	return output + "}";
}

// ===== Javascript generation =====
// Function that creates the native javascript that is needed to change the values.
str form2js(AForm f) {
  return "
'var cq = <cq2json(f)>;
'
'<updateJS()>
'
'<boolJS()>
'
'<numberJS()>
'
'<getKey()>";
}

// Main JS function of the webpage that handles all onChange handles
str updateJS() = 
	"function updateValues(question) {
	'  switch(question.type) {
	'    case(`radio`): 
	'      boolQuestion(question.name, question.value);
	'      break;
	'    case(`number`):
	'      numberQuestion(question.id, question.value);
	'			 break;
	'		 default:
	'      console.log(`This type has not been implemented`);
	'      break;
	'  }
	'}";


// Function that handles the toggling of visibility of questions
//  depending on filled in questions
str boolJS() = 
	"function boolQuestion(name, value) {
	'  let b = (value === \"True\");
	'  let p = document.getElementById(`IF_${name}`);
	'  if (p == null) { return; }
	'  Array.from(p.children).forEach(c =\> {
	'    if ((c.id).includes(b.toString())) {
	'      c.style.display = `block`;
	'    } else {
	'      c.style.display = `none`;
	'    }
	'  });
	'}";


// Function that handles the computed question
//  which belong to the number category
str numberJS() = 
	"function numberQuestion(id, value) {
	'  let key = getKeyByValue(cq, id);
	'	 document.getElementById(key).value = eval(cq[key]);
	'}";


// Function to retrieve a key from any object,
//  where the value includes a given value parameter
str getKey() = 
	"function getKeyByValue(object, value) {
	'  return Object.keys(object).find(key =\> object[key].includes(value));
	'}";


// Function that transforms the abstract expressions into expression that can be 
// evaluated via javascript's eval() function.
str expr2str(AExpr arg) {
	switch (arg) {
		case ref(AId id):
			return "<id.name>.value";
		case boolean(bool b):
			return b.toString();
		case integer(int x):
			return "<x>.value";		
		case string(str s):
			return "<s>.value";
		case un_min(AExpr x):
			return "-1*<expr2str(x)>";
		case not(AExpr x):
			return "!<expr2str(x)>";
	  case mult(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>*<expr2str(rhs)>";			
	  case div(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>/<expr2str(rhs)>";
	  case plus(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>+<expr2str(rhs)>";
	  case min(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>-<expr2str(rhs)>";
	  case leq(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>\<=<expr2str(rhs)>";
	  case geq(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>\>=<expr2str(rhs)>";
	  case lesser(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>\<<expr2str(rhs)>";
	  case greater(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>\><expr2str(rhs)>";
	  case equals(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>===<expr2str(rhs)>";
	  case not_equals(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)>!==<expr2str(rhs)>";
  	case and(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)> && <expr2str(rhs)>";
  	case or(AExpr lhs, AExpr rhs):
	  	return "<expr2str(lhs)> || <expr2str(rhs)>";
	  				
		default:
			throw "Unknown AExpr";
	}
}

