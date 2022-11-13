// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.utils {

	import flash.utils.Dictionary;
	import starling.errors.AbstractClassError;
	import starEx.utils.Utils;
	public class PoolEx {
		static private var arrayV:Vector.<Array> = new <Array>[];
		static public function getArray():Array {
			if (arrayV == null || arrayV.length == 0) return [];
			else return arrayV.pop();
		}
		static public function putArray(array:Array):void {
			if (array) {
				array.length = 0;
				if (arrayV == null) arrayV = new <Array>[];
				arrayV[arrayV.length] = array;
			}
		}
		static private var objectV:Vector.<Object>;
		static public function getObject():Object {
			if (objectV == null || objectV.length == 0) return {};
			else return objectV.pop();
		}
		static public function putObject(object:Object):void {
			if (object) {
				Utils.deleteObject(object,false);
				if (objectV == null) objectV = new <Object>[];
				objectV[objectV.length] = object;
			}
		}
		static private var dictionaryV:Vector.<Dictionary>;
		static public function getDictionary():Dictionary {
			if (dictionaryV == null || dictionaryV.length == 0) return new Dictionary(false);
			else return dictionaryV.pop();
		}
		static public function putDictionary(dictionary:Dictionary):void {
			if (dictionary) {
				Utils.deleteDictionary(dictionary);
				if (dictionaryV == null) dictionaryV = new <Dictionary>[];
				dictionaryV[dictionaryV.length] = dictionary;
			}
		}
		static private var uintVV:Vector.<Vector.<uint>>;
		static public function getUintV(startUint:uint=0,endUint:uint=0):Vector.<uint> {
			var uintV:Vector.<uint>;
			if (uintVV == null || uintVV.length == 0) uintV = new <uint>[];
			else uintV = uintVV.pop();
			if (startUint == 0 && endUint == 0) return uintV;
			else {
				var sign:int;
				var l:uint;
				if (endUint >= startUint) {
					sign = 1;
					l = endUint - startUint + 1;
				} else {
					sign = -1;
					l = startUint - endUint + 1;
				}
				for (var i:uint=0; i<l; i++) {
					uintV[uintV.length] = startUint + i*sign;
				}
				return uintV;
			}
		}
		static public function putUintV(uintV:Vector.<uint>):void {
			if (uintV) {
				uintV.length = 0;
				if (uintVV == null) uintVV = new <Vector.<uint>>[];
				uintVV[uintVV.length] = uintV;
			}
		}
		static private var stringVV:Vector.<Vector.<String>>;
		static public function getStringV():Vector.<String> {
			var stringV:Vector.<String>;
			if (stringVV == null || stringVV.length == 0) stringV = new <String>[];
			else stringV = stringVV.pop();
			return stringV;
		}
		static public function putStringV(stringV:Vector.<String>):void {
			if (stringV) {
				stringV.length = 0;
				if (stringVV == null) stringVV = new <Vector.<String>>[];
				stringVV[stringVV.length] = stringV;
			}
		}

		public function PoolEx() {throw new AbstractClassError();}
	}

}