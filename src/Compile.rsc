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

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
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

str item(str op, str val) = "\<<op>\><val>\</<op>\>\n";
str myInput(AType t, AId ref, str name) {
	switch(t) {
		case booleanType():
			return "
			'\<label for=\"<ref.src.offset>T\"\>True\</label\>
			'\<input type=\"radio\" 
			'  id=\"<ref.src.offset>T\" name=\"<ref.src.offset>\" value=True
			'  onChange=\"myFunction(this.name, this.value)\"
			'\>
			'\<label for=\"<ref.src.offset>F\"\>False\</label\>
			'\<input type=\"radio\" 
			'  id=\"<ref.src.offset>F\" name=\"<ref.src.offset>\" value=False
			'  onChange=\"myFunction(this.name, this.value)\"
			'\>";
  	case integerType():
  		return "\<input type=numeric id=<ref.name>N name=<name> value=0\>";
  	case stringType():
  		return "\<input type=text id=<ref.name>T name=<name>\>";
	}
}


str simpleQuest(str q, AId ref, AType t) = "
	'<startTag("div", " id=`<ref.src.offset>Q`")>
	'		<item("p", q)>
	'  	<myInput(t, ref, q)>
	'<endTag("div")>
	";
	
str computedQuest(str q, AId ref, AType t, AExpr arg) {
	str output = "<startTag("div", " id=`<ref.src.offset>CQ`")>";
	output += "\<p\><q>: \</p\>";
	switch(t) {
  	case integerType():
  		output += "\<input readonly type=numeric id=<ref.name>N name=<name> value=<arg.val>\>";
  	case stringType():
  		output += "\<input readonly type=text id=<ref.name>T name=<name> value=<arg.name>\>";
	}
	
	return output + "<endTag("div")>";
}

	
str blockQuest(list[AQuestion] question) = "TODO";

str guardedQuest(AExpr guard, list[AQuestion] questions, UseDef useDef) = "TODO";

str guardedElse(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest, UseDef useDef) {
	str output = "";
	int offset = toList(useDef[guard.src])[0].offset;
	str qTrue = questionsToHTML(questions, useDef);
	str qFalse = questionsToHTML(else_quest, useDef);
	
	
	return "
	'<startTag("div", " id=\"IF_<offset>\"")>
	'		<startTag("div", " id=`IF_<offset>_True` style=display:None")>
	'  		<qTrue>
	'		<endTag("div")>
	'		<startTag("div", " id=`IF_<offset>_False` style=display:None")>
	'  		<qFalse>
	'		<endTag("div")>
	'<endTag("div")>
 	' ";
}


	
str questionsToHTML(list[AQuestion] qs, UseDef useDef) {
	str output = "";
	for(AQuestion q <- qs) {
		switch(q) {
			case simp_quest(str q1, AId ref, AType t): {
					output += simpleQuest(q1, ref, t);
				}
			case computed_quest(str q1, AId ref, AType t, AExpr arg):
				output += computedQuest(q1, ref, t, arg);
				
			case block_quest(list[AQuestion] questions):
				output += "NoT yEt";
				
  		case guarded_question(AExpr guard, list[AQuestion] questions):
  			output += "Not yet";
  			
  		case guarded_else(AExpr guard, list[AQuestion] questions, list[AQuestion] else_quest): {
  			output += guardedElse(guard, questions, else_quest, useDef);
  		}
			default:
				println("NOT YET ");
		}
		output += "\<hr\>";
	}
	return output;
}


HTML5Node form2html(AForm f) {
	UseDef useDef = resolve(f).useDef;
	return html("
		'\<head\>
		' \<title\><f.name>\</title\>
		'	\<script\>
		'  function myFunction(name, value) {
		'   console.log(`Custom function: ${name} changed to ${value}`);
		'   let b = (value === \'True\');
		'   let p = document.getElementById(`IF_${name}`);
		'   if (b) {
		'			p.childNodes[1].style.display = `block`;
		'  		p.childNodes[3].style.display = `none`;
		'   } else {
		'			p.childNodes[3].style.display = `block`;
		'			p.childNodes[1].style.display = `none`;
		'		}
		'	 }
		'	\</script\>
		'\</head\>
		'\<body\>
		'		<item("div", item("h1", "This is a form created from QL"))>
		'  	<startTag("div", " class=\"main\"")>
		'   	<questionsToHTML(f.questions, useDef)>
		'		<endTag("div")>
		'\</body\>"); 
}

str form2js(AForm f) {
  return "";
}
