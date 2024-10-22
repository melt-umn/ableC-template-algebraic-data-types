grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:concretesyntax;

imports silver:langutil only ast, pp, errors; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;
imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

-- TODO: This also exports regular datatype declarations, maybe we don't want to do that?
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;

-- Non-marking version of datatype keyword
terminal TemplateDatatype_t 'datatype' lexer classes {Keyword, Global};

-- Ambiguity with template functions containing a datatype as the return type 
-- e.g. template<a> datatype Foo f() { ... }
-- Disambugation is done through the Scoped class, specify a preference using
-- globalPreferences instead of a disambiguation function.
--disambiguate Datatype_t, TemplateDatatype_t {
--  pluck TemplateDatatype_t;
--}
aspect parser attribute globalPreferences
  action {
    globalPreferences = ([TemplateDatatype_t, Datatype_t], TemplateDatatype_t) :: globalPreferences;
  };

concrete production templateADTDecl_c
top::Declaration_c ::= 'template' d::TemplateInitialDatatypeDeclaration_c '{' cs::ConstructorList_c '}' ';'
{
  top.ast = d.ast(cs.ast);
}
action {
  context = closeScope(context); -- Opened by TypeParameters_c
  context = addIdentsToScope([d.declaredIdent], TemplateTypeName_t, context);
  context = addIdentsToScope(cs.constructorNames, TemplateIdentifier_t, context);
  adtConstructors = (d.declaredIdent.name, map((.name), cs.constructorNames)) :: adtConstructors;
}

concrete production templateADTForwardDecl_c
top::Declaration_c ::= 'template' d::TemplateInitialDatatypeDeclaration_c ';'
{
  top.ast = decls(nilDecl());
}
action {
  context = closeScope(context); -- Opened by TypeParameters_c
  context = addIdentsToScope([d.declaredIdent], TemplateTypeName_t, context);
}

tracked nonterminal TemplateInitialDatatypeDeclaration_c with ast<(Decl ::= ConstructorList)>, declaredIdent;

concrete production templateInitialDatatypeDeclaration_c
top::TemplateInitialDatatypeDeclaration_c ::=
  '<' params::TemplateParameters_c '>' 'datatype' id::Identifier_c
{
  top.ast =
    \ cs::ConstructorList ->
      templateDatatypeDecl(params.ast, adtDecl(nilAttribute(), id.ast, cs));
  top.declaredIdent = id.ast;
}
action {
  context = addIdentsToScope([id.ast], TemplateTypeName_t, context);
}
