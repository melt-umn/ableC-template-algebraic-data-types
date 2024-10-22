grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;

abstract production adtTemplateItem
top::TemplateItem ::= params::Decorated TemplateParameters adt::Decorated ADTDecl
{
  top.templateParams = params.names;
  top.kinds = params.kinds;
  top.decl = adt.instDecl;
  top.isItemValue = false;
  top.isItemType = true;
}
