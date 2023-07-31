grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:datatype:abstractsyntax;

abstract production templateDatatypeDecl
top::Decl ::= params::TemplateParameters adt::ADTDecl
{
  top.pp = ppConcat([
    pp"template<", ppImplode(text(", "), params.pps), pp">", line(),
    text("datatype"), space(), adt.pp, semi()]);
  propagate env, isTopLevel, controlStmtContext;
  
  adt.templateParameters = params;
  adt.adtGivenName = adt.name;
  -- Not really used, only needed (possibly) to compute an environment for
  -- ParameterDecl to use to forward
  adt.givenRefId = nothing();
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [errFromOrigin(adt, "Template declarations must be global")]
    else adt.templateADTRedeclarationCheck ++ params.errors;
  
  forwards to
    decls(
      foldDecl([
        defsDecl([templateDef(adt.name, adtTemplateItem(params, adt))]),
        if null(localErrors)
        then adt.templateTransform
        else warnDecl(localErrors)]));
}

abstract production templateDatatypeInstDecl
top::Decl ::= adtName::String adtDeclName::String adt::ADTDecl
{
  top.pp = ppConcat([ text("inst_datatype"), space(), adt.pp ]);
  propagate isTopLevel, controlStmtContext;
  
  local refId::String = s"edu:umn:cs:melt:exts:ableC:templating:${adtDeclName}";
  -- adt may potentially contain type expressions referencing the adt currently being defined.
  -- The translation will contain an appropriate typedef before the struct declaration, but here
  -- we must explicitly place the type definition in the environment to avoid attempting to
  -- re-instantiate the ADT template and cause infinite recursion.
  local typeDecl::Decl =
    ableC_Decl {
      typedef $BaseTypeExpr{
        extTypeExpr(nilQualifier(), adtExtType(adtName, adtDeclName, refId))}
        $name{adtDeclName};
    };
  typeDecl.env = top.env;
  typeDecl.controlStmtContext = top.controlStmtContext;
  typeDecl.isTopLevel = top.isTopLevel;
  local typeDeclDefs::[Def] =
    [valueDef(adtDeclName, head(foldr(consDefs, nilDefs(), typeDecl.defs).valueContribs).snd)];
  
  adt.givenRefId = just(refId);
  adt.adtGivenName = adtName;
  adt.env = addEnv(typeDeclDefs, top.env);
  forwards to decls(adt.instDeclTransform);
}

inherited attribute templateParameters :: TemplateParameters occurs on ADTDecl, ConstructorList, Constructor;
inherited attribute declTypeName :: String occurs on ADTDecl;

synthesized attribute templateADTRedeclarationCheck::[Message] occurs on ADTDecl;
synthesized attribute templateTransform :: Decl occurs on ADTDecl;
synthesized attribute instDecl :: (Decl ::= Name) occurs on ADTDecl;
synthesized attribute instDeclTransform :: Decls occurs on ADTDecl;

flowtype ADTDecl = templateADTRedeclarationCheck {env, controlStmtContext}, templateTransform {env, controlStmtContext, templateParameters, givenRefId, adtGivenName}, instDecl {}, instDeclTransform {decorate, adtGivenName};

propagate templateParameters on ADTDecl, ConstructorList, Constructor;

aspect production adtDecl
top::ADTDecl ::= attrs::Attributes n::Name cs::ConstructorList
{
  top.templateADTRedeclarationCheck = n.templateRedeclarationCheck;
  top.templateTransform = decls(consDecl(adtEnumDecl, cs.templateFunDecls));
  top.instDecl =
    \ mangledName::Name ->
      templateDatatypeInstDecl(
        n.name, mangledName.name,
        -- Discard attributes, since we don't allow specifying refIds on templated types anyway
        adtDecl(nilAttribute(), mangledName, cs));
  
  -- Evaluated on substituted version of the tree
  top.instDeclTransform =
    ableC_Decls {
      $Decl{defsDecl(preDefs)}
      typedef $BaseTypeExpr{adtTypeExpr} $Name{n};
      $Decl{
        foldr(
          deferredDecl,
          -- Only declare the adt struct, etc. if the datatype doesn't already have a definition
          maybeDecl(
            \ env::Decorated Env -> null(lookupRefId(top.refId, env)),
            decls(
              ableC_Decls {
                $Decl{adtStructDecl}
                $Decl{defsDecl(postDefs)}
                $Decls{adtProtos}
                $Decls{adtDecls}
              })),
          catMaybes(
            map(
              (.maybeRefId),
              concat(map((.typereps), map(snd, top.constructors))))))
      }
    };
}

-- Constructs the initialization function for each constructor
synthesized attribute templateFunDecls :: Decls occurs on ConstructorList;
flowtype ConstructorList = templateFunDecls {decorate, templateParameters, adtGivenName, adtDeclName};

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
flowtype Constructor = templateFunDecl {decorate, templateParameters, adtGivenName};

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.templateFunDecl =
    ableC_Decl {
      template<$TemplateParameters{top.templateParameters}>
      inst $tname{top.adtGivenName}<$TemplateArgNames{top.templateParameters.asTemplateArgNames}>
        $Name{n}($Parameters{ps.asTemplateConstructorParameters}) {
        inst $tname{top.adtGivenName}<$TemplateArgNames{top.templateParameters.asTemplateArgNames}>
          result;
        result.tag = $name{top.adtGivenName ++ "_" ++ n.name};
        $Stmt{ps.asAssignments}
        $Stmt{foldStmt(initStmts)}
        return result;
      }
    };
}

synthesized attribute asTemplateArgNames::TemplateArgNames occurs on TemplateParameters;

aspect production consTemplateParameter
top::TemplateParameters ::= h::TemplateParameter t::TemplateParameters
{
  top.asTemplateArgNames = consTemplateArgName(h.asTemplateArgName, t.asTemplateArgNames);
}

aspect production nilTemplateParameter
top::TemplateParameters ::=
{
  top.asTemplateArgNames = nilTemplateArgName();
}

synthesized attribute asTemplateArgName::TemplateArgName occurs on TemplateParameter;

aspect production typeTemplateParameter
top::TemplateParameter ::= n::Name
{
  top.asTemplateArgName =
    typeTemplateArgName(
      typeName(typedefTypeExpr(nilQualifier(), n), baseTypeExpr()));
}

aspect production valueTemplateParameter
top::TemplateParameter ::= bty::BaseTypeExpr n::Name mty::TypeModifierExpr
{
  top.asTemplateArgName =
    valueTemplateArgName(declRefExpr(n));
}

functor attribute asTemplateConstructorParameters occurs on Parameters, ParameterDecl;
flowtype asTemplateConstructorParameters {decorate} on Parameters, ParameterDecl;
propagate asTemplateConstructorParameters on Parameters;

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  n::MaybeName  attrs::Attributes
{
  top.asTemplateConstructorParameters = parameterDecl(storage, bty, mty, justName(fieldName), attrs);
}
