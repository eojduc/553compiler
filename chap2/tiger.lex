(*
    How does this string regex work?
    [ -\[\]-~] - Match the printable characters other than \ (that is match the characters between space and [, and ] and ~)
*)
(* <INITIAL> \"([ -\[\]-~]|(\\([nt\"\\]|[0-9][0-9][0-9]|[\n\t\r]+\\)))*\" => (Tokens.STRING(String.extract(yytext, 1, SOME((size yytext) - 2)), yypos, yypos + (size yytext))); *)

type pos = int
type lexresult = Tokens.token

val lineNum = ErrorMsg.lineNum
val linePos = ErrorMsg.linePos
val commentCounter = ref 0
val currentString = ref ""
val stringOpen = ref false
val strStart = ErrorMsg.lineNum
fun err(p1,p2) = ErrorMsg.error p1

fun eof() = 
    let val pos = hd(!linePos)
    in
        if !commentCounter > 0 then
            (
                ErrorMsg.error pos ("Unclosed Comment");
                Tokens.EOF(pos,pos)
            )            
        else
            if !stringOpen then (
                ErrorMsg.error pos ("Unclosed String");
                Tokens.EOF(pos,pos)
            )
            else
                Tokens.EOF(pos,pos)
    end

fun getASCII (text, pos) =
    let val asciiInt = valOf(Int.fromString (String.extract(text, 1, NONE)))
    in
        if asciiInt > 255 then
            (
                ErrorMsg.error pos ("Invalid ASCII Code: " ^ text);
                ""
            )
        else
            String.str (Char.chr asciiInt)
    end

%%
alpha=[A-Za-z];
digit=[0-9];
ws = [\ \t];
%s COMMENT INITIAL STRING;
%%
<INITIAL, COMMENT> \n	=> (lineNum := !lineNum+1; linePos := yypos :: !linePos; continue());
<INITIAL> {ws} => (continue());
<INITIAL> "if" => (Tokens.IF(yypos, yypos+2));
<INITIAL> "while" => (Tokens.WHILE(yypos, yypos+5));
<INITIAL> "for" => (Tokens.FOR(yypos, yypos+3));
<INITIAL> "to" => (Tokens.TO(yypos, yypos+2));
<INITIAL> "break" => (Tokens.BREAK(yypos, yypos+5));
<INITIAL> "let" => (Tokens.LET(yypos, yypos+3));
<INITIAL> "in" => (Tokens.IN(yypos, yypos+2));
<INITIAL> "end" => (Tokens.END(yypos, yypos+3));
<INITIAL> "function" => (Tokens.FUNCTION(yypos, yypos+8));
<INITIAL> "type" => (Tokens.TYPE(yypos, yypos+4));
<INITIAL> "array" => (Tokens.ARRAY(yypos, yypos+5));
<INITIAL> "then" => (Tokens.THEN(yypos, yypos+4));
<INITIAL> "else" => (Tokens.ELSE(yypos, yypos+4));
<INITIAL> "do" => (Tokens.DO(yypos, yypos+2));
<INITIAL> "of" => (Tokens.OF(yypos, yypos+2));
<INITIAL> "nil" => (Tokens.NIL(yypos, yypos+3));
<INITIAL> ","	=> (Tokens.COMMA(yypos,yypos+1));
<INITIAL> var => (Tokens.VAR(yypos,yypos+3));
<INITIAL> ":" => (Tokens.COLON(yypos, yypos+1));
<INITIAL> ";" => (Tokens.SEMICOLON(yypos, yypos+1));
<INITIAL> "(" => (Tokens.LPAREN(yypos, yypos+1));
<INITIAL> ")" => (Tokens.RPAREN(yypos, yypos+1));
<INITIAL> "[" => (Tokens.LBRACK(yypos, yypos+1));
<INITIAL> "]" => (Tokens.RBRACK(yypos, yypos+1));
<INITIAL> "{" => (Tokens.LBRACE(yypos, yypos+1));
<INITIAL> "}" => (Tokens.RBRACE(yypos, yypos+1));
<INITIAL> "." => (Tokens.DOT(yypos, yypos+1));
<INITIAL> "+" => (Tokens.PLUS(yypos, yypos+1));
<INITIAL> "-" => (Tokens.MINUS(yypos, yypos+1));
<INITIAL> "*" => (Tokens.TIMES(yypos, yypos+1));
<INITIAL> "/" => (Tokens.DIVIDE(yypos, yypos+1));
<INITIAL> "=" => (Tokens.EQ(yypos, yypos+1));
<INITIAL> "<>" => (Tokens.NEQ(yypos, yypos+2));
<INITIAL> "<" => (Tokens.LT(yypos, yypos+1));
<INITIAL> ">" => (Tokens.GT(yypos, yypos+1));
<INITIAL> ">=" => (Tokens.GE(yypos, yypos+2));
<INITIAL> "<=" => (Tokens.LE(yypos, yypos+2));
<INITIAL> "&" => (Tokens.AND(yypos, yypos+1));
<INITIAL> "|" => (Tokens.OR(yypos, yypos+1));
<INITIAL> ":=" => (Tokens.ASSIGN(yypos, yypos+2));
<INITIAL> {alpha}+({alpha} | {digit} | "_")* => (Tokens.ID(yytext, yypos, yypos + String.size yytext));
<INITIAL> {digit}+          => (Tokens.INT(Option.valOf(Int.fromString(yytext)), yypos, yypos + (size yytext)));
<INITIAL> "/*"              => (YYBEGIN COMMENT; commentCounter:= !commentCounter+1; continue());
<COMMENT> "/*"              => (commentCounter:= !commentCounter+1; continue());
<COMMENT> "*/"              => (commentCounter:= !commentCounter-1; if !commentCounter <= 0 then (YYBEGIN (INITIAL)) else (); continue());
<COMMENT> .                 => (continue());
<INITIAL> "*/"              => (ErrorMsg.error yypos ("closed comment without opening"); continue());
<INITIAL> "\""              => (YYBEGIN STRING; strStart := !lineNum; stringOpen := true; currentString := ""; continue());
<STRING> "\""               => (YYBEGIN INITIAL; stringOpen := false; Tokens.STRING(!currentString, yypos, yypos + 1));
<STRING> \\n                => (currentString := (!currentString ^ "\n"); continue());
<STRING> \\t                => (currentString := (!currentString ^ "\t"); continue());
<STRING> "\\\""             => (currentString := (!currentString ^ "\""); continue());
<STRING> \\[0-9][0-9][0-9]  => (currentString := (!currentString ^ (getASCII (yytext, yypos))); continue());
<STRING> [ -\[\]-~]         => (currentString := (!currentString ^ yytext); continue());
<STRING> \n                 => (lineNum := !lineNum+1; linePos := yypos :: !linePos; ErrorMsg.error yypos ("Illegal String. Contains new line."); continue());
<STRING> \\[\n\t\r]+\\      => (continue());
<STRING> \\\\               => (currentString := (!currentString ^ "\\"); continue());
<STRING> .                  => (continue());
<INITIAL> .                 => (ErrorMsg.error yypos ("illegal character " ^ yytext); continue());
