grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;

abstract production adtTemplateItem
top::TemplateItem ::= params::[String] adt::Decorated ADTDecl
{
  top.templateParams = params;
  top.decl = adt.instDecl;
  top.sourceLocation = adt.location;
  top.isItemValue = false;
  top.isItemType = true;
  top.isItemForwardDecl = false;
}
