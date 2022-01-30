module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, 
 * - strings to textfields, 
 * - ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

str item(str op, str val) = "\<<op>\><val>\</<op>\>\n";
str myInput(AType t, str id, str name) {
	switch(t) {
		case booleanType():
			return "
			'\<input type=radio id=<id>T name=<name> value=True\>
			'\<label for=<id>T\>True\</label\>
			'\<input type=radio id=<id>F name=<name> value=False\>
			'\<label for=<id>F\>False\</label\>";
  	case integerType():
  		return "\<input type=numeric id=<id>N name=<name> value=0\>";
  	case stringType():
  		return "\<input type=text id=<id>T name=<name>\>";
	}
}

/*
 * - map booleans to checkboxes, 
 * - strings to textfields, 
 * - ints to numeric text fields
*/
str ATypeToHTML(AType t) {
	switch(t) {
		case booleanType():
			return "radio";
  	case integerType():
  		return "numeric";
  	case stringType():
  		return "text";
  	default:
  		throw "ERROR";
	}
}


str simpleQuest(str q, AId ref, AType t) = "
	'<startTag("div", " id= <q>Q")>
	'		<item("p", q)>
	'  	<myInput(t, ref.name, q)>
	'  	<item("p", "A simple Question <q>")>
	'<endTag("div")>
	";
	
// TODO: Misses computed value
str computedQuest(str q, AId ref, AType t, AExpr arg) = "
	'<startTag("div", " id= <q>Q")>
	'		<item("p", q)>
	'  	<myInput(t, ref.name, q)>
	'  	<item("p", "A computed Question <q>")>
	'<endTag("div")>
 	' ";
	
str blockQuest(list[AQuestion] question) = "TODO";

str guardedQuest(AExpr guard, list[AQuestion] questions) = "TODO";

str guardedElse(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest) = "TODO";
	//TODO: create both paths and only show the part when the condition variable is known
  

	
str questionsToHTML(list[AQuestion] qs) {
	str output = "";
	for(AQuestion q <- qs) {
		switch(q) {
			case simp_quest(str q1, AId ref, AType t): 
				output += simpleQuest(q1, ref, t);
				
			case computed_quest(str q1, AId ref, AType t, AExpr arg):
				output += computedQuest(q1, ref, t, arg);
				
			case block_quest(list[AQuestion] questions):
				output += "NoT yEt";
				
  		case guarded_question(AExpr guard, list[AQuestion] questions):
  			output += "Not yet";
  			
  		case guarded_else(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest):
  			output += guardedElse(guard, questions, else_quest);
  
			default:
				println("NOT YET ");
		
		}
	}
	return output;
}


HTML5Node form2html(AForm f) {
	return html("
		'\<head\>
		'  \<title\><f.name>\</title\>
		'\</head\>
		'\<body\>
		'<item("div", item("h1", "This is a form created from QL"))>
		'  <startTag("div", " class=main")>
		'   <questionsToHTML(f.questions)>
		'	 <endTag("div")>
		'\</body\>
		"); 
  	//'div(h1("This is a form created from QL")), 
  	//'questions(f));
}

str form2js(AForm f) {
  return "";
}
