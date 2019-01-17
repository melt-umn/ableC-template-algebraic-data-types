grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:abstractsyntax;

abstract production templateAllocateDecl
top::Decl ::= id::Name  allocator::Name
{
  propagate substituted;
  top.pp = pp"template allocate datatype ${id.pp} with ${allocator.pp});";
  
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
    | _ -> [err(id.location, id.name ++ " is not a template datatype")]
    end;
  local localErrors::[Message] =
    adtLookupErrors ++ allocator.valueLookupCheck ++
    (if !compatibleTypes(expectedAllocatorType, allocator.valueItem.typerep, true, false)
     then [err(allocator.location, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.valueItem.typerep)})")]
     else []);
  
  local adtLookup::Decorated ADTDecl =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> adt
    end;
  -- Re-decorate the found ADT decl, also supplying the allocator name
  local d::ADTDecl = new(adtLookup);
  d.env = adtLookup.env;
  d.returnType = adtLookup.returnType;
  d.adtGivenName = adtLookup.adtGivenName;
  d.typeParameters =
    case lookupTemplate(id.name, top.env) of
    | adtTemplateItem(params, adt) :: _ -> params
    end;
  d.allocatorName = allocator;
  
  forwards to
    if !null(adtLookupErrors)
    then warnDecl(localErrors)
    else if !null(localErrors)
    then decls(foldDecl([warnDecl(localErrors), defsDecl(d.templateAllocatorErrorDefs)]))
    else defsDecl(d.templateAllocatorDefs);
}

synthesized attribute templateAllocatorDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;
synthesized attribute templateAllocatorErrorDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  top.templateAllocatorDefs = cs.templateAllocatorDefs;
  top.templateAllocatorErrorDefs = cs.templateAllocatorErrorDefs;
}

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.templateAllocatorDefs = c.templateAllocatorDefs ++ cl.templateAllocatorDefs;
  top.templateAllocatorErrorDefs = c.templateAllocatorErrorDefs ++ cl.templateAllocatorErrorDefs;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.templateAllocatorDefs = [];
  top.templateAllocatorErrorDefs = [];
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  top.templateAllocatorDefs =
    [templateDef(
       allocateConstructorName,
       valueTemplateItem(
         n.location, top.typeParameters.names, -- TODO: location should be allocate decl location
         templateAllocateConstructorInstDecl(
           name(top.adtGivenName, location=builtin),
           top.allocatorName, n, _, top.typeParameters.asTypeNames, ps)))];
  top.templateAllocatorErrorDefs = [templateDef(allocateConstructorName, errorTemplateItem())];
}

abstract production templateAllocateConstructorInstDecl
top::Decl ::= adtName::Name allocatorName::Name constructorName::Name n::Name ts::TypeNames ps::Parameters
{
  propagate substituted;
  top.pp = pp"templateAllocateConstructorInstDecl ${n.pp};";
  
  ps.position = 0;
  forwards to
    defsDecl([
      valueDef(
        n.name,
        templateAllocateConstructorInstValueItem(
          adtName, allocatorName, constructorName, ts, ps.typereps))]);
}

abstract production templateAllocateConstructorInstValueItem
top::ValueItem ::= adtName::Name allocatorName::Name constructorName::Name ts::TypeNames paramTypes::[Type]
{
  top.pp = pp"templateAllocateConstructorInstValueItem(${adtName.pp}, ${allocatorName.pp}, ${constructorName.pp})";
  top.typerep = errorType();
  top.sourceLocation = allocatorName.location;
  top.directRefHandler =
    \ n::Name l::Location ->
      errorExpr([err(l, s"Allocate constructor ${allocatorName.name}_${adtName.name}<${show(80, ppImplode(pp", ", ts.pps))}> cannot be referenced, only called directly")], location=builtin);
  top.directCallHandler =
    templateAllocateConstructorInstCallExpr(adtName, allocatorName, constructorName, ts, paramTypes, _, _, location=_);
}

abstract production templateAllocateConstructorInstCallExpr
top::Expr ::= adtName::Name allocatorName::Name constructorName::Name ts::TypeNames paramTypes::[Type] n::Name args::Exprs
{
  propagate substituted;
  top.pp = parens(ppConcat([n.pp, parens(ppImplode(cat(comma(), space()), args.pps))]));
  local localErrors::[Message] = args.errors ++ args.argumentErrors;
  
  args.expectedTypes = paramTypes;
  args.argumentPosition = 1;
  args.callExpr = decorate declRefExpr(n, location=n.location) with {env = top.env; returnType = top.returnType;};
  args.callVariadic = false;
  
  local resultName::String = "result_" ++ toString(genInt());
  local fwrd::Expr =
    ableC_Expr {
      ({inst $TName{adtName}<$TypeNames{ts}> *$name{resultName} = $Name{allocatorName}(sizeof(inst $TName{adtName}<$TypeNames{ts}>));
        *$name{resultName} = inst $Name{constructorName}<$TypeNames{ts}>($Exprs{args});
        $name{resultName};})
    };
  forwards to mkErrorCheck(localErrors, fwrd);
}
