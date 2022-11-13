// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.utils {

	import flash.utils.Dictionary;
	import mx.utils.NameUtil;
	import starling.errors.AbstractClassError;
	import starEx.utils.PoolEx;
	public class Utils {
		/* Shallow copy an array. */
		static public function copyArray(sourceA:Array,targetA:Array):void {
			if (sourceA && targetA) {
				const l:uint = sourceA.length;
				for (var i:uint=0; i<l; i++) {targetA[i] = sourceA[i];}
			}
		}
		static public function testObjectValue(object:Object,value:*):Boolean {
			if (object) {
				for each (var testValue:* in object) {
					if (testValue == value) return true;
				}
			}
			return false;
		}
		static public function deleteObject(object:Object,recurse:Boolean=true):void {
			for (var property:String in object) {
				if (recurse && object[property] is Object) {
					const nestedObject:Object = object[property] as Object;
					if (nestedObject.constructor == Object) deleteObject(nestedObject);
				} 
				delete object[property];
			}
		}
		static public function testDictionaryKey(dictionary:Dictionary,key:Object):Boolean {
			if (dictionary) {
				for (var testKey:Object in dictionary) {
					if (testKey == key) return true;
				}
			}
			return false;
		}
		static public function testDictionaryValue(dictionary:Dictionary,value:*):Boolean {
			if (dictionary) {
				for each (var testValue:* in dictionary) {
					if (testValue == value) return true;
				}
			}
			return false;
		}
		static public function deleteDictionary(dictionary:Dictionary):void {
			for (var key:Object in dictionary) {
				delete dictionary[key];
			}
		}
		static public function getID(object:Object):String {
			return NameUtil.createUniqueName(object);
		}
		static public function isPowerOfTwo(i:uint):Boolean {
			return (i != 0) && ((i & (i - 1)) == 0);
		}
		static public function nextPowerOfTwo(i:uint):uint {
			var result:uint = 1;
			while (result < i) result <<= 1;
			return result;
		}
		static public function previousPowerOfTwo(i:uint):uint {
			var next:uint = nextPowerOfTwo(i);
			if (next == i) return i;
			else return next >>= 1;
		}
		static public function greatestCommonDivisor(a:uint,b:uint):uint {
			var temp:uint;
			if (a < b) {
                temp = a;
                a = b;
                b = temp;
            }
			while (b > 0) {
                temp = a % b;
                a = b;
                b = temp;
            }
            return a;
		}
		static public function setPrecision(num:Number,decimals:int,roundUp:Boolean=false):Number {
			const m:int = Math.pow(10,decimals);
			var mathFunction:Function = Math.round;
			if (roundUp) mathFunction = Math.ceil;
			return mathFunction(num * m) / m;
		}
		static public function callFunctionWithPossibleArg(callFunction:Function,possibleArg:*):void {//If possibleArg is null, no argument is passed
			if (callFunction) {
				var applyA:Array;
				if (possibleArg) {
					applyA = PoolEx.getArray();
					applyA[0] = possibleArg;
				}
				callFunction.apply(null,applyA);
				PoolEx.putArray(applyA);
			}
		}

		public function Utils() {throw new AbstractClassError();}
	}

}
