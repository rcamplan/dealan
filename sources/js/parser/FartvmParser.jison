
%lex

%%

\s+ 				 		{}
'do'						{return 'DO';}
'.'							{return 'END';}
','							{return 'COMMA';}
'choose' 					{return 'CHOOSE';}
'when'						{return 'WHEN';}
'then'						{return 'THEN';}
'event' 					{return 'EVENT';} 
'is' 						{return 'IS';} 
'kindof'					{return 'KINDOF';}
'otherwise'					{return 'OTHERWISE';}

[0-9]+"."[0-9]+\b 			{return 'FLOAT';}
[0-9]+\b 					{return 'INTEGER';}
[a-zA-Z][a-zA-Z0-9]* 		{return 'IDENTIFIER';}
\"(\\.|[^\\"])*\"			{return 'STRING_LITERAL';}

<<EOF>>						{return 'EOF';}

/lex

%{

	var enableDebug = true;
	
	var _NODE_TYPE_ENUM = {
		INSTRUCTION = 0,
		CHOOSE = 1,
		BLOCK = 2,
		HALT = 3
	}

	function traceParserActivity(log){
		if(enableDebug)
			console.log(log);
	}



	function TreeExecutionNode(){
		var tev = {
			_childs: [],
			_type: null,
			_funcRef: null,
			_argList: [],
			_next: null,
			_chooseMap = {}
		};

		tev.addChild = function (aTev){
			tev._childs.push(aTev);
		};

		tev.addAll = function (aTevList){
			tev._childs = tev._childs.concat(aTevList);
		};

		tev.setType = function(type){
			tev._type = type;
		};

		tev._executeThenGoToNodeAt = function (idx){
			
			if(idx && _childs.length <= idx){
				var ex = 'index out of bound'
				throw ex;
			}

			if(tev._funcRef){
				if(tev._argList && tev._argList.length > 0){
					tev._funcRef(tev._argList);
					return _childs[idx];
				}
			}
			
			var ex = 'unable to execute specified instruction';
			throw ex;
		};

		tev._executeThenGoToNextNode = function (){
			tev._executeThenGoToNextNode(0);
		};

		tev._evalChoose = function(ev){
			if(ev && ev.type && _chooseMap[ev.type]){
				tev._next = _chooseMap[ev.type];				
			}
			else {
				if (_chooseMap['DEFAULT_CHOOSE']){
					tev._next = _chooseMap['DEFAULT_CHOOSE'];
				}
				else{
					var ex = 'no choose foe specified event type ' + ev.type;
					throw ex;
				}
			}
		};

		tev.execute = function (ev){
			switch(tev._type){
				case _NODE_TYPE_ENUM.BLOCK:{
					for (var idx = 0; idx < tev._childs.length; idx++) {
						var child = tev._childs[idx];
					};
				}
				case _NODE_TYPE_ENUM.INSTRUCTION:{
					return tev._executeThenGoToNextNode();				
					break;
				}
				case _NODE_TYPE_ENUM.CHOOSE:{
					tev._evalChoose(ev);
					return tev._executeThenGoToNodeAt(tev._next);				
					break;
				}
				case _NODE_TYPE_ENUM.HALT:{
					return null;
				}
			}
		};

		return tev;
	}

%}


%start fart_script

%%

fart_script:
		step_list EOF 	{ 
							var root = new TreeExecutionNode();
							root.setType(_NODE_TYPE_ENUM.BLOCK);
							root.addChild($1);
							var halt = new TreeExecutionNode();
							halt.setType(_NODE_TYPE_ENUM.HALT);
							root.addChild(halt);
							traceParserActivity("got fart_script rule"); 
							return root;
						}
	;

step_list:
		step step_list 	{
							var root = new TreeExecutionNode();
							root.setType(_NODE_TYPE_ENUM.BLOCK);
							root.addChild($1);
							root.addAll($2);
							$$ = root;
							traceParserActivity("got step_list+ rule"); 
						}
	|	step 			{
							var root = new TreeExecutionNode();
							root.addChild($1);					
							$$ = root;
							traceParserActivity("got step_list+ rule"); 
						}
	;

step:
		execution_block {
							var root = new TreeExecutionNode();
							root.addChild($1);
							root.setType(_NODE_TYPE_ENUM.INSTRUCTION);				
							$$ = root;								 
							traceParserActivity("got step (eb) rule"); 
						}
	|	choice_block 	{
							var root = new TreeExecutionNode();
							root.addChild($1);
							root.setType(_NODE_TYPE_ENUM.CHOOSE);				
							$$ = root;								 
							traceParserActivity("got step (cb) rule"); 
						}
	;

execution_block:
		DO 	IDENTIFIER	arglist END {traceParserActivity("got execution_block (arglist) rule");}
	|	DO 	IDENTIFIER	END {traceParserActivity("got execution_block rule");}
	;

arglist:
		arg COMMA arglist {traceParserActivity("got arglist+ rule");}
	|	arg {traceParserActivity("got arglist rule");}
	;

arg:
		FLOAT {traceParserActivity("got arg(FLOAT) rule");}
	|	INTEGER {traceParserActivity("got arg(INTEGER) rule");}
	|	STRING_LITERAL {traceParserActivity("got arg(STRING_LITERAL) rule");}
	;

choice_block:
		CHOOSE choose_statement default_statement END {traceParserActivity("got choice_block+ rule");}
	|	CHOOSE choose_statement END {traceParserActivity("got choice_block rule");}
	;

choose_statement:
		choose_element choose_statement {traceParserActivity("got arg(FLOAT) rule");}
	|	choose_element {traceParserActivity("got arg(FLOAT) rule");}
	;

default_statement:
		OTHERWISE step_list END {traceParserActivity("got default_statement rule");}
	;

choose_element:
		WHEN condition THEN step_list END {traceParserActivity("got choose_element rule");}
	;

condition:
		EVENT IS KINDOF IDENTIFIER {traceParserActivity("got condition rule");}
	;


