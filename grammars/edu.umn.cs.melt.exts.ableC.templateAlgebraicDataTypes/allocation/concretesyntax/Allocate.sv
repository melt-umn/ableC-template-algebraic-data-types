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
terminal Prefix_t 'prefix' lexer classes {Keyword};

concrete production allocateDecl_c
-- id is Identifer_t here to avoid follow spillage
top::Declaration_c ::= 'template' 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_c ';'
{ top.ast = templateAllocateDecl(fromId(id), alloc.ast, nothing()); }
action {
  local constructors::Maybe<[String]> = lookup(id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(alloc.ast.name ++ "_" ++ c),
          constructors.fromJust),
        TemplateIdentifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}

concrete production allocateDeclPrefix_c
-- id is Identifer_t here to avoid follow spillage
top::Declaration_c ::= 'template' 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_t 'prefix' pfx::Identifier_c ';'
{ top.ast = templateAllocateDecl(fromId(id), fromId(alloc), just(pfx.ast)); }
action {
  local constructors::Maybe<[String]> = lookup(id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(pfx.ast.name ++ c),
          constructors.fromJust),
        TemplateIdentifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
