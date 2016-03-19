package uhx.macro;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;

using StringTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
using haxe.macro.ComplexTypeTools;

/**
 * ...
 * @author Skial Bainn
 */
class Operator {

	private static var local:Type;
	private static var fields:Array<Field>;
	private static var newFields:Array<Field>;
	private static var genericMap:StringMap<haxe.macro.Expr.Function>;

	public static function build() {
		newFields = [];
		genericMap = new StringMap();
		local = Context.getLocalType();
		fields = Context.getBuildFields();
		
		var names = [];
		
		for (field in fields) switch (field.kind) {
			case FFun(method) if (field.meta.filter(hasMeta.bind(_, ':generic')).length > 0 && hasOperator( method.args )):
				genericMap.set( local.toString() + '::' + field.name, method );
				names.push( field.name );
				
			case _:
				
		}
		
		// find call sites in other methods and replace.
		for (field in fields) switch (field.kind) {
			case FFun(method):
				method.expr = replaceCallSite( method.expr );
				
			case _:
				
		}
		
		fields = fields.filter( function(f) return names.indexOf( f.name ) == -1 ).concat( newFields );
		
		if (Context.defined('debug')) for (field in fields) trace( new Printer().printField( field ) );
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
		var result = switch (expr.expr) {
			case ECall( { expr:EConst(CIdent(name)), pos:_ }, args) if (name == op):
				//trace( new Printer().printExpr( expr ), prev, now, op );
				var e1 = macro $e { replaceOperatorSite( args[0], prev, now, op ) };
				var e2 = macro $e { replaceOperatorSite( args[1], prev, now, op ) };
				switch (now) {
					case _.indexOf('Add') > -1 => true:
						macro $e1 + $e2;
						
					case _.indexOf('Sub') > -1 => true:
						macro $e1 - $e2;
						
					case _.indexOf('Div') > -1 => true:
						macro $e1 / $e2;
						
					case _.indexOf('Mult') > -1 => true:
						macro $e1 * $e2;
						
					case _:
						expr;
				}
				
			case ECall( { expr:EConst(CIdent(name)), pos:_ }, args) if (name == prev):
				(macro $i { now } ($a { args.slice(1) } ));
				
			case _:
				expr.map( replaceOperatorSite.bind(_, prev, now, op) );
				
		}
		//trace( now, new Printer().printExpr(expr), new Printer().printExpr(result) );
		return result;
	}
	
	public static function replaceCallSite(expr:Expr):Expr {
		var type = '';
		var result = switch (expr.expr) {
			case ECall( { expr:EConst(CIdent(name)), pos:_ }, args):
				//trace( new Printer().printExprs( args, ', '));
				if (args[0].expr.match( EBinop(OpAdd, _, _) )) {
					type = '_' + Context.typeof( args[1] ).toString().replace('<', '_').replace('>', '_');
					
					if (newFields.filter( hasField.bind(_, name + '_Add' + type ) ).length == 0) {
						if (!createSpecializedField(name, '_Add' , args)) expr;
						
					}
					macro $i { name + '_Add' + type } ($a { args.slice(1) } );
					
				} else if (args[0].expr.match( EBinop(OpSub, _, _) )) {
					type = '_' + Context.typeof( args[1] ).toString().replace('<', '_').replace('>', '_');
					
					if (newFields.filter( hasField.bind(_, name + '_Sub' + type ) ).length == 0) {
						if (!createSpecializedField(name, '_Sub' , args)) expr;
						
					}
					macro $i { name + '_Sub' + type } ($a { args.slice(1) } );
					
				} else if (args[0].expr.match( EBinop(OpMult, _, _) )) {
					type = '_' + Context.typeof( args[1] ).toString().replace('<', '_').replace('>', '_');
					
					if (newFields.filter( hasField.bind(_, name + '_Mult' + type ) ).length == 0) {
						if (!createSpecializedField(name, '_Mult', args)) expr;
						
					}
					macro $i { name + '_Mult' + type } ($a { args.slice(1) } );
					
				} else if (args[0].expr.match( EBinop(OpDiv, _, _) )) {
					type = '_' + Context.typeof( args[1] ).toString().replace('<', '_').replace('>', '_');
					
					if (newFields.filter( hasField.bind(_, name + '_Div' + type ) ).length == 0) {
						if (!createSpecializedField(name, '_Div', args)) expr;
						
					}
					macro $i { name + '_Div' + type } ($a { args.slice(1) } );
					
				} else {
					expr;
				}
			
			case _:
				expr.map( replaceCallSite );
				
		}
		
		//trace( new Printer().printExpr( result ) );
		return result;
	}
	
	private static function createSpecializedField(name:String, op:String, args:Array<Expr>):Bool {
		var field = fields.filter(function(f)return f.name == name)[0];
		/*var method = switch (field.kind) {
			case FFun(m): m;
			case _: null;
		}*/
		var method = genericMap.get( local.toString() + '::' + name);
		if (method == null) return false;
		var typeof = Context.typeof( args[1] );
		var ctype = Context.typeof( args[1] ).toComplexType();
		var type = '_' + typeof.toString().replace('<', '_').replace('>', '_');
		
		if (field.meta.filter(hasMeta.bind(_, ':generic')).length > 0 && hasOperator( method.args )) {
			//trace( method.args );
			// This is required to preserve the original `generic` method ast,
			// as the for loop before the `newField` creation will update the
			// original `generic` ast.
			var cargs = [for (arg in method.args) Reflect.copy( arg )];
			var sargs = cargs.slice(1);
			var cparams = method.params.copy();
			var mtp = mapTypeParameters( cparams, cargs.slice(1).map(function(c)return c.type), [ctype] );
			var rtp = replaceTypeParameters( cparams, cargs.slice(1).map(function(c)return c.type).concat([method.ret]), mtp );
			var ret = rtp.pop();
			/*trace( method.args );
			
			trace( [for (k in mtp.keys()) k] );
			trace( [for (k in mtp.keys()) mtp.get(k)] );*/
			
			for (i in 0...sargs.length) sargs[i].type = rtp[i];
			/*trace( method.args );
			trace( rtp );
			trace(new Printer().printExpr( method.expr ));*/
			var newField:Field = { 
				name: '${field.name}$op$type',
				access: field.access,
				doc: field.doc,
				meta: field.meta.filter( function (m) return m.name != ':generic' ),
				pos: field.pos,
				kind: FFun( {
					args: sargs,
					ret: ret,
					params: [],
					expr: replaceOperatorSite( method.expr, field.name, '${field.name}$op${type}', cargs[0].name ),
				} ),
			};
			//trace(new Printer().printExpr( method.expr ));
			newFields.push( newField );
			
		}
		
		return true;
	}
	
	private static function mapTypeParameters(typeParameters:Array<TypeParamDecl>, phantomTypes:Array<ComplexType>, concreteTypes:Array<ComplexType>) {
		var typeMap:StringMap<ComplexType> = new StringMap();
		
		for (index in 0...phantomTypes.length) {
			var phantom = phantomTypes[index];
			var concrete = concreteTypes[index];
			
			switch ([phantom, concrete]) {
				case [TPath(c1 = {name:n1, pack:p1, params:ps1}), TPath(c2 = {name:n2, pack:p2, params:ps2})]:
					var position = -1;
					for (i in 0...typeParameters.length) if (typeParameters[i].name == n1) {
						position = i;
						break;
						
					}
					
					var subMap:StringMap<ComplexType> = null;
					if (ps1.length > 0) {
						subMap = mapTypeParameters(typeParameters, ps1.map( unwrapTPType ), ps2.map( unwrapTPType ));
						
					}
					
					if (subMap != null) {
						for (key in subMap.keys()) typeMap.set( key, subMap.get( key ) );
						
					}
					
					if (position > -1) {
						typeMap.set( Context.signature( typeParameters[position] ), concrete );
						
					}
					
				case _:
					trace( phantom );
				
			}
			
		}
		
		return typeMap;
	}
	
	private static function replaceTypeParameters(typeParameters:Array<TypeParamDecl>, phantomTypes:Array<ComplexType>, typeMap:StringMap<ComplexType>) {
 		var results = [];
 		
 		for (index in 0...phantomTypes.length) {
 			var phantom = phantomTypes[index];
 			
 			switch (phantom) {
 				case TPath(c1 = {name:n1, pack:p1, params:ps1}):
 					var position = -1;
 					for (i in 0...typeParameters.length) if (typeParameters[i].name == n1) {
 						position = i;
 						break;
 						
 					}
 					
 					var subResults = [];
 					if (ps1.length > 0) {
 						subResults = replaceTypeParameters(typeParameters, ps1.map( unwrapTPType ), typeMap);
 						
 					}
					
 					if (position > -1) {
						if (typeMap.exists( Context.signature( typeParameters[position] ) )) {
							switch (typeMap.get( Context.signature( typeParameters[position] ) )) {
								case TPath(c2 = {name:n2, pack:p2, params:ps2}):
									//results.push( TPath( { name:n2, pack:p2, params:subResults.length > 0 ? subResults.map( wrapTPType ) : ps2 } ) );
									var rtp = Reflect.copy( c2 );
									if (subResults.length > 0) rtp.params = subResults.map( wrapTPType );
									results.push( TPath( rtp ) );
									
								case _:
									
							}
							
						}
 						
 						
 					}
					
					if (subResults.length > 0) {
						//var rtp = TPath( { name:n1, pack:p1, params:subResults.length > 0 ? subResults.map( wrapTPType ) : ps1 } );
						var rtp = Reflect.copy( c1 );
						if (subResults.length > 0) rtp.params = subResults.map( wrapTPType );
						results.push( TPath( rtp ) );
					}
 					
 				case _:
 					trace( phantom );
 				
 			}
 			
 		}
 		
 		return results;
 	}
	
	private static function unwrapTPType(tp:TypeParam):ComplexType {
		return switch (tp) {
			case TPType(c): c;
			case _: null;
		}
	}
	
	private static inline function wrapTPType(c:ComplexType):TypeParam {
		return TPType(c);
	}
	
	private static inline function hasField(field:Field, name:String):Bool {
		return field.name == name;
	}
	
}
