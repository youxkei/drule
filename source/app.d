import ctpg;

 struct Grammar
{
    Rule[] rules;
}

struct Rule
{
    string lhs;
    Rhs[] rhss;
}

struct Rhs
{
    Term[] terms;
}

struct Term
{
    string value;
    bool isTerminal;
    bool isOptional;
}

alias any = parseAnyChar;

mixin (generateParsers(
q{
    None sp = !((" " / "\t")*);

    @_setSkip(sp)

    None noneGrammarPart = !((^"$(GRAMMAR" any)*);

    string id = [_a-zA-Z] [_a-zA-Z0-9]* >> (dchar head, dchar[] rest){ return to!string(head) ~ to!string(rest); };

    Grammar[] grammars = noneGrammarPart (grammar noneGrammarPart)* $;

    Grammar grammar = !"$(GRAMMAR" rule+ !")" >> Grammar;

    Rule rule = !"\n$(GNAME" id !"):" rhs+ !"\n" >> Rule;

    Rhs rhs = !"\n" exp+ >> Rhs;

    Term exp = (glink2 / glink / notlink / terminal) ("$(OPT)")? >> (Term term, Option!string opt){ term.isOptional = opt.some; return term; };

    Term glink2 = !"$(GLINK2 " !((^"," any)*) !"," id !")" >> (string value){ return Term(value, false); };

    Term glink = !"$(GLINK " id !")" >> (string value){ return Term(value, false); };

    Term notlink = !"$(I " id !")" >> (string value){ return Term(value, false); };

    Term terminal = !"$(D " ( lparen / rparen / (^")" any)+ >> to!string) !")" >> (string value){ return Term(value, true); };

    string lparen = !"$(LPAREN)" >> { return "("; };

    string rparen = !"$(RPAREN)" >> { return ")"; };
}));

void main()
{
    import std.stdio : writeln;
    import std.file;
    import std.algorithm : count, filter;

    string src = readText("/home/youkei/repo/dlang.org/grammar.dd");
    auto parsed = src.parse!grammars();
    parsed.value.writeln();
    parsed.match.writeln();
}
