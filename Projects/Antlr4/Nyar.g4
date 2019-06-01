grammar Nyar;
import NyarKeywords, NyarOperators;
// $antlr-format useTab false ;reflowComments false;
// $antlr-format alignColons hanging;
program: statement* EOF;
statement
    : empty_statement
    | block_statement eos?
    | expression_statement eos?
    | assign_statement eos?
    | branch_statement eos?
    | try_statement eos?
    | module_statement eos?
    | class_statement eos?
    | loop_statement eos?;
/*====================================================================================================================*/
// $antlr-format alignColons hanging;
blockStatement: '{' statement* '}' | Colon expression | Colon statement* End;
blockNonEnd: '{' statement* '}' | statement*;
// $antlr-format alignColons trailing;
End   : 'end';
Colon : ':' | '\uFF1A'; //U+FF1A ：
/*====================================================================================================================*/
empty_statement: eos # EmptyStatement;
eos: Semicolon;
symbol: Identifier (DOT Identifier)*;
global: Section Identifier (DOT Identifier)*;
/*====================================================================================================================*/
// $antlr-format alignColons hanging;
expressionStatement: expression (Comma expression)*;
expression
    : functionCall                                                      # FunctionApply
    | left = expression Dot right = symbol                              # GetterApply
    | left = expression Dot right = functionCall                        # MethodApply
    | left = expression right = index                                   # IndexApply
    | assignStatment                                                    # AssignApply
    | left = identifier right = string                                  # SpecialString
    | left = expression As right = typeExpression                       # TypeConversion
    | op = pre_ops right = expression                                   # PrefixExpression
    | left = expression op = pst_ops                                    # PostfixExpression
    | left = expression op = bit_ops right = expression                 # BinaryLike
    | left = expression op = lgk_ops right = expression                 # LogicLike
    | left = expression op = cpr_ops right = expression                 # CompareLike
    | <assoc = right> left = expression op = pow_ops right = expression # PowerLike
    | left = expression op = mul_ops right = expression                 # MultiplyLike
    | left = expression op = add_ops right = expression                 # PlusLike
    | left = expression op = list_ops right = expression                # ListLike
    | atom = data                                                       # DataLiteral
    | '(' expression ')'                                                # PriorityExpression
    | controlFlow                                                       # ControlExpression
    | expression BitAnd                                                 # SlotCatch;
/* | left = number right = expression                                  # SpaceExpression*/
/*====================================================================================================================*/
// $antlr-format alignColons hanging;
assignStatment
    : Val assignLHS assignRHS                                               # AssignValue
    | Var assignLHS assignRHS                                               # AssignVariable
    | Def assignLHS assignRHS                                               # AssignDefer
    | Def symbol '(' parameter (Comma parameter)* ')' typeSuffix? assignRHS # AssignFunction
    | symbol '(' parameter (Comma parameter)* ')' typeSuffix? Set assignRHS # AssignFunction
    | assignLHS Set assignRHS                                               # AssignValue
    | assignLHS Flexible assignRHS                                          # AssignVariable
    | assignLHS Delay assignRHS                                             # AssignDefer;
assignLHS
    : symbol typeSuffix?               # LHSSingle
    | maybeSymbol (Comma maybeSymbol)* # LHSTuple
    | symbols                          # LHSMaybeSetter
    | symbols index                    # LHSMaybeIndex;
assignRHS
    : expression                  # RHSExpression
    | Colon expression            # RHSExpression
    | '{' statement* '}'          # RHSStatement
    | Colon statement* End        # RHSStatement
    | expressionStatement         # RHSTuple
    | '(' expressionStatement ')' # RHSTuple
    | statement                   # RHSStatement;
maybeSymbol: symbols typeSuffix? | head = Tilde;
symbols: (symbol | symbolName) (Dot symbol)*;
symbolName: symbol (Name symbol)*;
// $antlr-format alignColons trailing;
Val      : 'val';
Var      : 'var';
Let      : 'let';
Def      : 'def';
Set      : '=';
Flexible : '.=' | '\u2250'; //U+2250 ≐
Name     : '::' | '\u2237'; //U+2237 ∷
Delay    : ':=' | '\u2254'; //U+2254 ≔
/*====================================================================================================================*/
module_statement
    : Using module = symbol module_controller?      # ModuleInclude
    | Using module = symbol As alias = Identifier   # ModuleAlias
    | Using source = symbol With? name = Identifier # ModuleSymbol
    | Using source = symbol With? id_tuples         # ModuleSymbols
    | Using dictLiteral                             # ModuleResolve;
id_tuples: LL Identifier (COMMA Identifier)* RL;
module_controller: Times | Power; //@Inline
//TODO: Support Nested Using Statement
/*====================================================================================================================*/
class_statement
    : Class id = Identifier class_implement? class_define               # ClassBase
    | Class id = Identifier class_fathers class_implement? class_define # ClassWithFather;
class_fathers
    : Extend father = symbol          # ClassFather
    | LS father = symbol RS           # ClassFather
    | LS (symbol (COMMA symbol)+)? RS # ClassFathers;
class_implement: (Implement | Colon) symbol # ClassImplement;
class_define: LL expression RL # ClassDefine;
/*====================================================================================================================*/
interface_Statement: Interface expression eos;
/*====================================================================================================================*/
template_Statement: Template expression eos;
/*====================================================================================================================*/
macro_Statement: Macro expression eos;
/*====================================================================================================================*/

/*====================================================================================================================*/
branch_statement
    : If condition_statement expr_or_block if_else?            # IfSingle
    | If condition_statement expr_or_block if_elseif* if_else? # IfNested
    | Switch condition_statement expr_or_block                 # SwitchStatement
    | Match condition_statement expr_or_block                  # MatchStatement;
condition_statement: LS? expression RS? # ConditionStatement;
if_else: Else expr_or_block # ElseStatement;
if_elseif
    : Else If condition_statement Then? expr_or_block # ElseIfStatement;
/*====================================================================================================================*/
try_statement
    : Try block_statement finalProduction
    | Try block_statement (catchProduction finalProduction?);
catchProduction: Catch LS? symbol RS? block_statement;
finalProduction: Final block_statement;
//TODO: USE expr_block
/*====================================================================================================================*/
loop_statement
    : For LS for_inline1 RS expr_or_block        # ForLoop
    | For Identifier In expression expr_or_block # ForInLoop
    | While condition_statement expr_or_block    # WhileLoop
    | Do expr_or_block                           # DoLoop;
for_inline1
    : initial = expression COMMA condition = expression COMMA increment = expression; //@Inline
/*====================================================================================================================*/
// $antlr-format alignColons trailing;
dictLiteral   : LL (keyvalue (COMMA keyvalue)*)? COMMA? RL;
keyvalue      : key = key_valid Colon value = element;
key_valid     : (NUMBER | STRING | symbol);
listLiteral   : LM (element (COMMA? element)*)? COMMA? RM;
element       : (expression | dictLiteral | listLiteral);
indexLiteral  : LM index_valid (COMMA? index_valid)+? RM;
index_valid   : (symbol | Integer) Colon?;
signedInteger : (Plus | Minus)? Integer;
//FIXME: replace NUMBER with signedInteger
/*====================================================================================================================*/
LineComment : Shebang ~[\r\n]* -> channel(HIDDEN);
PartComment : Comment .*? Comment -> channel(HIDDEN);
WhiteSpace  : UnicodeWhiteSpace+ -> skip;
NewLine     : ('\r'? '\n' | '\r')+ -> skip;
