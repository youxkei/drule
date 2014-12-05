import ctpg;

 struct Grammar
{
    Rule[] rules;

    string toString()
    {
        string result;

        foreach (rule; rules)
        {
            result ~= rule.toString();
        }

        return result;
    }
}

struct Rule
{
    string lhs;
    Rhs[] rhss;

    string toString()
    {
        import std.string;

        string result = "Result %s(alias ruleSelector)(string src)\n{\nreturn setRuleName!(\"%s\",\n".format(lhs, lhs);

        if (rhss.length > 1)
        {
            result ~= "choice!(\n";
        }

        foreach (i, rhs; rhss)
        {
            if (i)
            {
                result ~= ",\n";
            }
            result ~= rhs.toString();
        }

        if (rhss.length > 1)
        {
            result ~= "\n)";
        }

        result ~= "\n)(src);\n}\n\n";

        return result;
    }
}

struct Rhs
{
    Term[] terms;

    string toString()
    {
        string result;

        if (terms.length > 1)
        {
            result ~= "sequence!(\n";
        }

        foreach (i, term; terms)
        {
            if (i)
            {
                result ~= ",\n";
            }

            result ~= term.toString();
        }

        if (terms.length > 1)
        {
            result ~= "\n)";
        }

        return result;
    }
}

struct Term
{
    string value;
    bool isTerminal;
    bool isOptional;

    string toString()
    {
        import std.string;

        string result;

        if (isOptional)
        {
            result ~= "option!(";
        }

        if (isTerminal)
        {
            result ~= `toToken!"%s"`.format(value);
        }
        else
        {
            result ~= `ruleSelector!"%s"`.format(value);
        }

        if (isOptional)
        {
            result ~= ")";
        }

        return result;
    }
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
    import std.stdio;
    import std.file;

    foreach (grammar; readText("grammar.dd").parse!grammars().value)
    {
        grammar.toString().writeln();
    }
}
