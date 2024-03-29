grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:abstractsyntax;

abstract production templateAllocateDecl
top::Decl ::= id::Name  allocator::Name pfx::Maybe<Name>
{
  top.pp =
    case pfx of
    | just(pfx) -> pp"template allocate datatype ${id.pp} with ${allocator.pp} prefix ${pfx.pp};"
    | nothing() -> pp"template allocate datatype ${id.pp} with ${allocator.pp};"
    end;
  propagate env;
  
  local expectedAllocatorType::Type =
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier());
  local adtLookupErrors::[Message] =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> []
    | _ -> [errFromOrigin(id, id.name ++ " is not a template datatype")]
    end;
  local localErrors::[Message] =
    adtLookupErrors ++ allocator.valueLookupCheck ++
    (if !compatibleTypes(expectedAllocatorType, allocator.valueItem.typerep, true, false)
     then [errFromOrigin(allocator, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.valueItem.typerep)})")]
     else []);
  
  local adtLookup::Decorated ADTDecl =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> adt
    | _ -> error("adtLookup demanded when lookup failed")
    end;
  -- Re-decorate the found ADT decl, also supplying the allocator name
  local d::ADTDecl = new(adtLookup);
  d.env = adtLookup.env;
  d.controlStmtContext = adtLookup.controlStmtContext;
  d.adtGivenName = adtLookup.adtGivenName;
  d.templateParameters =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> params
    | _ -> error("adt template parameters demanded when lookup failed")
    end;
  d.allocatorName = allocator;
  d.allocatePfx =
    case pfx of
    | just(pfx) -> pfx.name
    | nothing() -> allocator.name ++ "_"
    end;
  
  forwards to
    if !null(adtLookupErrors)
    then warnDecl(localErrors)
    else if !null(localErrors)
    then decls(foldDecl([warnDecl(localErrors), defsDecl(d.templateAllocatorErrorDefs)]))
    else defsDecl(d.templateAllocatorDefs);
}

monoid attribute templateAllocatorDefs::[Def] with [], ++;
monoid attribute templateAllocatorErrorDefs::[Def] with [], ++;
attribute templateAllocatorDefs, templateAllocatorErrorDefs occurs on ADTDecl, ConstructorList, Constructor;

propagate templateAllocatorDefs, templateAllocatorErrorDefs on ADTDecl, ConstructorList;

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.templateAllocatorDefs :=
    [templateDef(
       allocateConstructorName,
       constructorTemplateItem(
         top.templateParameters.names, top.templateParameters.kinds, ps,
         templateAllocateConstructorInstDecl(
           name(top.adtGivenName),
           top.allocatorName, n, _, top.templateParameters.asTemplateArgNames, ps)))];
  top.templateAllocatorErrorDefs := [templateDef(allocateConstructorName, errorTemplateItem())];
}

abstract production constructorTemplateItem
top::TemplateItem ::= params::[String] kinds::[Maybe<TypeName>] constructorParams::Parameters decl::(Decl ::= Name)
{
  top.templateParams = params;
  top.kinds = kinds;
  top.decl = decl;
  top.maybeParameters = just(constructorParams);
  top.isItemValue = true;
}

abstract production templateAllocateConstructorInstDecl
top::Decl ::= adtName::Name allocatorName::Name constructorName::Name n::Name ts::TemplateArgNames ps::Parameters
{
  top.pp = pp"templateAllocateConstructorInstDecl ${n.pp};";
  propagate env, controlStmtContext;
  
  ps.position = 0;
  forwards to
    defsDecl([
      valueDef(
        n.name,
        templateAllocateConstructorInstValueItem(
          adtName, allocatorName, constructorName, ts, ps.typereps))]);
}

abstract production templateAllocateConstructorInstValueItem
top::ValueItem ::= adtName::Name allocatorName::Name constructorName::Name ts::TemplateArgNames paramTypes::[Type]
{
  top.pp = pp"templateAllocateConstructorInstValueItem(${adtName.pp}, ${allocatorName.pp}, ${constructorName.pp})";
  top.typerep = errorType();
  top.directRefHandler =
    \ n::Name ->
      errorExpr([errFromOrigin(n, s"Allocate constructor ${allocatorName.name}_${adtName.name}<${show(80, ppImplode(pp", ", ts.pps))}> cannot be referenced, only called directly")]);
  top.directCallHandler =
    templateAllocateConstructorInstCallExpr(adtName, allocatorName, constructorName, ts, paramTypes, _, _);
}

abstract production templateAllocateConstructorInstCallExpr
top::Expr ::= adtName::Name allocatorName::Name constructorName::Name ts::TemplateArgNames paramTypes::[Type] n::Name args::Exprs
{
  top.pp = parens(ppConcat([n.pp, parens(ppImplode(cat(comma(), space()), args.pps))]));
  attachNote extensionGenerated("ableC-template-algebraic-data-types");
  propagate env, controlStmtContext;

  local localErrors::[Message] = args.errors ++ args.argumentErrors;
  
  args.expectedTypes = paramTypes;
  args.argumentPosition = 1;
  args.callExpr = decorate declRefExpr(n) with {env = top.env; controlStmtContext = top.controlStmtContext;};
  args.callVariadic = false;
  
  local resultName::String = "result_" ++ toString(genInt());
  local fwrd::Expr =
    ableC_Expr {
      ({inst $TName{adtName}<$TemplateArgNames{ts}> *$name{resultName} = $Name{allocatorName}(sizeof(inst $TName{adtName}<$TemplateArgNames{ts}>));
        *$name{resultName} = inst $Name{constructorName}<$TemplateArgNames{ts}>($Exprs{args});
        $name{resultName};})
    };
  forwards to mkErrorCheck(localErrors, fwrd);
}
