package uhx.macro;

import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.TypeTools;

using StringTools;
using haxe.macro.ExprTools;

/**
 * ...
 * @author Skial Bainn
 */
class Operator {

	public static function build() {
		var fields = Context.getBuildFields();
		
		var names = [];
		var newFields = [];
		
		for (field in fields) switch (field.kind) {
			case FFun(method) if (field.meta.filter(hasMeta.bind(_, ':generic')).length > 0 && hasOperator( method.args )):
				names.push( field.name );
				
				for (id in ['Add', 'Div', 'Mult', 'Sub']) {
					newFields.push( { 
						name: '${field.name}_$id',
						access: field.access,
						doc: field.doc,
						meta: field.meta/*.filter( function (m) return m.name != ':generic' )*/,
						pos: field.pos,
						kind: FFun( {
							args: method.args.slice(1),
							ret: method.ret,
							params: method.params,
							expr: replaceOperatorSite( method.expr, field.name, '${field.name}_$id', method.args[0].name ),
						} ),
					} );
					
				}
				
			case _:
				
		}
		
		// find call sites in other methods and replace.
		for (field in fields) switch (field.kind) {
			case FFun(method):
				method.expr = replaceCallSite( method.expr );
				
			case _:
				
		}
		
		fields = fields.filter( function(f) return names.indexOf( f.name ) == -1 ).concat( newFields );
		
		for (field in fields) trace( new Printer().printField( field ) );
		return fields;
	}
	
	public static function hasMeta(m:MetadataEntry, expected:String):Bool {
		return m.name == expected;
	}
	
	public static function hasOperator(args:Array<FunctionArg>):Bool {
		return 
			args.length > 0 && 
			args[0].type != null && 
			(matchTPath( args[0].type, macro:haxe.Constraints.Function ) || matchTPath( args[0].type, macro:Function ));
	}
	
	public static function matchTPath(t1:ComplexType, t2:ComplexType):Bool {
		return switch ([t1, t2]) {
			case [ TPath({ name:n1 }), TPath({ name:n2 }) ]: n1 == n2;
			case _: false;
		}
	}
	
	public static function replaceOperatorSite(expr:Expr, prev:String, now:String, op:String):Expr {
		return switch (expr.expr) {
			case ECall( { expr:EConst(CIdent(name)), pos:_ }, args) if (name == op):
				var e1 = macro $e { replaceOperatorSite( args[0], prev, now, op ) };
				var e2 = macro $e { replaceOperatorSite( args[1], prev, now, op ) };
				switch (now) {
					case _.endsWith('Add') => true:
						macro $e1 + $e2;
						
					case _.endsWith('Sub') => true:
						macro $e1 - $e2;
						
					case _.endsWith('Div') => true:
						macro $e1 / $e2;
						
					case _.endsWith('Mult') => true:
						macro $e1 * $e2;
						
					case _:
						expr;
				}
				
			case ECall( { expr:EConst(CIdent(name)), pos:_ }, args) if (name == prev):
				(macro $i { now } ($a { args.slice(1) } ));
				
			case _:
				expr.map( replaceOperatorSite.bind(_, prev, now, op) );
				
		}
	}
	
	public static function replaceCallSite(expr:Expr):Expr {
		return switch (expr.expr) {
			case ECall( { expr:EConst(CIdent(name)), pos:_ }, args):
				if (args[0].expr.match( EBinop(OpAdd, _, _) )) {
					macro $i { name + '_Add' } ($a { args.slice(1) } );
					
				} else if (args[0].expr.match( EBinop(OpSub, _, _) )) {
					macro $i { name + '_Sub' } ($a { args.slice(1) } );
					
				} else if (args[0].expr.match( EBinop(OpMult, _, _) )) {
					macro $i { name + '_Mult' } ($a { args.slice(1) } );
					
				} else if (args[0].expr.match( EBinop(OpDiv, _, _) )) {
					macro $i { name + '_Div' } ($a { args.slice(1) } );
					
				} else {
					expr;
				}
			
			case _:
				expr.map( replaceCallSite );
				
		}
	}
	
}