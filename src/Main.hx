package;

import haxe.Constraints;

/**
 * ...
 * @author Skial Bainn
 */
@:build( uhx.macro.Operator.build() )
class Main {
	
	static function main() {
		var arr = [1, 2, 3, 4];
		var total = sum(_ * _, [1, 2, 3, 4]);
		var joined = sum(_ + _, ['hello', ' ', 'world'] );
		
		trace( total, joined );
	}
	
	@:generic public static function sum<T>(op:Function, array:Array<T>):T {
		var result = array[0];
		for (i in 1...array.length) {
			trace( result );
			result = op( result, array[i] );
		}
		return result;
	}
	
	/*@:generic public static function fold<T>(op:Function, array:Array<T>, empty:T):T {
		if (array.length == 0) {
			return empty;
		} else {
			return op( array[0], fold(op, array.slice(1), empty) );
		}
		
	}*/
	
}

abstract StringOp(String) from String to String {
	public inline function new(v) this = v;
	
	@:op(A + B) public static function add(a:StringOp, b:StringOp):String;
	
	@:op(A - B) public static function sub(a:StringOp, b:StringOp) {
		return b;
	}
	
	@:op(A / B) public static function div(a:StringOp, b:StringOp) {
		return b + a;
	}
	
	@:op(A * B) public static function mult(a:StringOp, b:StringOp) {
		return a + a + b + b;
	}
}