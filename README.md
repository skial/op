# op

An experiment to extend `@:generic` to work
on operators, `+`, `-`, `*` and `/`.

Last tested with Haxe `3.3.0 (git build development @ 7bc28bc)`.

## Example

```Haxe
package ;

@:build( uhx.macro.Operator.build() )
class Main {
	
	static function main() {
		var total = sum(_ * _, [1, 2, 3, 4]);
		var joined = sum(_ + _, ['hello', ' ', 'world'] );
		var abstractJoined = sum(_ + _, (['hello', ' ', 'world']:Array<StringOp>) );
		
		trace( total, joined, abstractJoined ); // 24, hello world, hello dlrow
	}
	
	@:generic
	public static function sum<T>(op:Function, array:Array<T>):T {
		var result = array[0];
		for (i in 1...array.length) {
			trace( result );
			result = op( result, array[i] );
		}
		return result;
	}
	
}

abstract StringOp(String) from String to String {
	public inline function new(v) this = v;
	
	@:op(A + B) public static function add(a:StringOp, b:StringOp):String {
		var _b = (b:String).split('');
		_b.reverse();
		return (a:String) + _b.join('');
	}
	
}
```
