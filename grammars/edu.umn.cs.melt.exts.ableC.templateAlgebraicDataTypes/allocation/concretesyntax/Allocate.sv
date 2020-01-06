grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

-- Non-marking version of datatype and allocate keywords
terminal Allocate_t 'allocate' lexer classes {Keyword};
terminal Datatype_t 'datatype' lexer classes {Keyword};
terminal With_t 'with' lexer classes {Keyword};

concrete production allocateDecl_c
-- id is Identifer_t here to avoid follow spillage
top::Declaration_c ::= 'template' 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_c ';'
{ top.ast = templateAllocateDecl(fromId(id), alloc.ast); }
action {
  local constructors::Maybe<[String]> = lookupBy(stringEq, id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(alloc.ast.name ++ "_" ++ c, location=id.location),
          constructors.fromJust),
        TemplateIdentifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
