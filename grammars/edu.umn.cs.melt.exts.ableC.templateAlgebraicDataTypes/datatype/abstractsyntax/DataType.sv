grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;

abstract production templateDatatypeDecl
top::Decl ::= params::Names adt::ADTDecl
{
  propagate substituted;
  top.pp = ppConcat([
    pp"template<", ppImplode(text(", "), params.pps), pp">", line(),
    text("datatype"), space(), adt.pp]);
  
  adt.typeParameters = params;
  adt.adtGivenName = adt.name;
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(adt.location, "Template declarations must be global")]
    else adt.templateADTRedeclarationCheck ++ params.typeParameterErrors;
  
  forwards to
    decls(
      foldDecl([
        defsDecl([templateDef(adt.name, adtTemplateItem(params, adt))]),
        if null(localErrors)
        then adt.templateTransform
        else warnDecl(localErrors)]));
}

abstract production templateDatatypeInstDecl
top::Decl ::= declTypeName::String adt::ADTDecl
{
  top.pp = ppConcat([ text("inst_datatype"), space(), adt.pp ]);
  propagate substituted; -- TODO: Interfering, see https://github.com/melt-umn/ableC/issues/121
  
  adt.adtGivenName = declTypeName;
  forwards to decls(adt.instDeclTransform);
}

autocopy attribute typeParameters :: Names occurs on ADTDecl, ConstructorList, Constructor;
inherited attribute declTypeName :: String occurs on ADTDecl;

synthesized attribute templateADTRedeclarationCheck::[Message] occurs on ADTDecl;
synthesized attribute templateTransform :: Decl occurs on ADTDecl;
synthesized attribute instDecl :: (Decl ::= Name) occurs on ADTDecl;
synthesized attribute instDeclTransform :: Decls occurs on ADTDecl;

flowtype ADTDecl = templateADTRedeclarationCheck {decorate}, templateTransform {decorate, typeParameters, adtGivenName}, instDecl {decorate}, instDeclTransform {decorate, adtGivenName};

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  top.templateADTRedeclarationCheck = n.templateRedeclarationCheck;
  top.templateTransform = decls(consDecl(adtEnumDecl, cs.templateFunDecls));
  top.instDecl =
    \ mangledName::Name ->
      templateDatatypeInstDecl(n.name, adtDecl(mangledName, cs, location=top.location));
  
  -- Evaluated on substituted version of the tree
  top.instDeclTransform =
    ableC_Decls {
      $Decl{defsDecl([adtRefIdDef(top.refId, adtRefIdItem(top))])}
      typedef $BaseTypeExpr{extTypeExpr(nilQualifier(), adtExtType(top.adtGivenName, n.name, top.refId))} $Name{n};
      $Decl{adtStructDecl}
      $Decls{adtProtos}
      $Decls{adtDecls}
    };
}

-- Constructs the initialization function for each constructor
synthesized attribute templateFunDecls :: Decls occurs on ConstructorList;

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.templateFunDecls = consDecl(c.templateFunDecl, cl.templateFunDecls);
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.templateFunDecls = nilDecl();
}

-- Constructs the function declaration to create each constructor
synthesized attribute templateFunDecl :: Decl occurs on Constructor;

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.templateFunDecl =
    ableC_Decl {
      template<$Names{top.typeParameters}>
      inst $tname{top.adtGivenName}<$TypeNames{top.typeParameters.asTypeNames}>
        $Name{n}($Parameters{ps}) {
        inst $tname{top.adtGivenName}<$TypeNames{top.typeParameters.asTypeNames}>
          result;
        result.tag = $name{top.adtGivenName ++ "_" ++ n.name};
        $Stmt{ps.asAssignments}
        $Stmt{foldStmt(initStmts)}
        return result;
      }
    };
}

synthesized attribute asTypeNames::TypeNames occurs on Names;

aspect production consName
top::Names ::= h::Name t::Names
{
  top.asTypeNames =
    consTypeName(typeName(typedefTypeExpr(nilQualifier(), h), baseTypeExpr()), t.asTypeNames);
}

aspect production nilName
top::Names ::=
{
  top.asTypeNames = nilTypeName();
}
