grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:concretesyntax;

imports silver:langutil only ast, pp, errors; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

-- TODO: This also exports regular datatype declarations, maybe we don't want to do that?
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typeParameters;

terminal TemplateDatatype_t 'datatype';

-- Ambiguity with template functions containing a datatype as the return type 
-- e.g. template<a> datatype Foo f() { ... }
disambiguate Datatype_t, TemplateDatatype_t {
  pluck TemplateDatatype_t;
}

concrete production templateADTDecl_c
top::Declaration_c ::= 'template' '<' params::TypeParameters_c '>' 'datatype'
id::Identifier_c '{' cs::ConstructorList_c '}'  ';'
{
  top.ast = templateDatatypeDecl(params.ast, adtDecl(id.ast, cs.ast, location=top.location));
}
action {
  context = lh:closeScope(context); -- Opened by TypeParameters_c
  context = lh:addTypenamesToScope([id.ast], context);
}
