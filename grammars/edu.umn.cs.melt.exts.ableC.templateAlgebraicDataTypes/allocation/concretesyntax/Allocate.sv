grammar edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templateAlgebraicDataTypes:allocation:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

terminal Allocate_t 'allocate' lexer classes {Ckeyword};
terminal Datatype_t 'datatype';
terminal With_t 'with';

concrete production allocateDecl_c
-- id is Identifer_t here to avoid follow spillage
top::Declaration_c ::= 'template' 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_c ';'
{ top.ast = templateAllocateDecl(fromId(id), alloc.ast); }
