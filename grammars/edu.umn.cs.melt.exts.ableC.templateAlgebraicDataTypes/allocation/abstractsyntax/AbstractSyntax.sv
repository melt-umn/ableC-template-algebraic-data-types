grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:abstractsyntax;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:allocation:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:constructor:abstractsyntax as ctor;
imports edu:umn:cs:melt:exts:ableC:templateConstructor:abstractsyntax;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  templateAdtDecls <- foldDecl([defsDecl(flatMap(\ c::(String, Decorated Parameters) ->
    [templateConstructorDef(c.1, templateAdtConstructorReference(^n, name(c.1))),
     ctor:constructorDef(c.1, templateAdtInferredConstructorReference(^n, name(c.1)))],
    cs.constructors))]);
}

production templateAdtConstructorReference implements TemplateConstructor
top::Expr ::= targs::TemplateArgNames args::Exprs adtName::Name constructorName::Name
{
  top.pp = pp"new ${constructorName}<${ppImplode(pp", ", targs.pps)}>(${ppImplode(pp", ", args.pps)})";

  nondecorated local tmpName::Name = freshName("tmp");
  nondecorated local resName::Name = freshName("res");
  local termExpr::Expr = templateDirectCallExpr(@constructorName, ^targs, foldExpr(args.bindRefExprs));
  forwards to bindTemplateConstructor(@targs, @args, ableC_Expr {
    ({$Decl{autoDecl(tmpName, @termExpr)}
      $directTypeExpr{termExpr.typerep} *$Name{resName} = allocate(sizeof($Name{tmpName}));
      *$Name{resName} = $Name{tmpName};
      $Name{resName};})
  });
}

production templateAdtInferredConstructorReference implements ctor:Constructor
top::Expr ::= args::Exprs adtName::Name constructorName::Name
{
  top.pp = pp"new ${constructorName}(${ppImplode(pp", ", args.pps)})";

  nondecorated local tmpName::Name = freshName("tmp");
  nondecorated local resName::Name = freshName("res");
  local termExpr::Expr = templateInferredDirectCallExpr(@constructorName, foldExpr(args.bindRefExprs));
  forwards to ctor:bindConstructor(@args, ableC_Expr {
    ({$Decl{autoDecl(tmpName, @termExpr)}
      $directTypeExpr{termExpr.typerep} *$Name{resName} = allocate(sizeof($Name{tmpName}));
      *$Name{resName} = $Name{tmpName};
      $Name{resName};})
  });
}

