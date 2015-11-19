# op

An attempted experiment to extend `@:generic` to work
on operators, `+`, `-`, `*` and `/`.

You cant have recursive functions due to issue [3523](https://github.com/HaxeFoundation/haxe/issues/3523).
	
None of this works, _unless_, during conversion some of the expressions are
cast to Dynamic or untyped, which I don't want to do.

## Example

```Haxe
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
		var total = sum(_ + _, [1, 2, 3, 4]);
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
	
}
```