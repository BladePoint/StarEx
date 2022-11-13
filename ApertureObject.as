// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.utils {

	import starling.utils.Color;
	/* An ApertureObject stores color in both RGB and hexadecimal formats. */
	public class ApertureObject {
		static private const argumentErrorString:String = "ApertureObject must have 0, 1, or 3 arguments which are non-negative."
		static private const instancePool:Vector.<ApertureObject> = new <ApertureObject>[];
		static public function getInstance(p1:int=-1,p2:int=-1,p3:int=-1):ApertureObject {
			var apertureObject:ApertureObject;
			if (instancePool.length == 0) apertureObject = new ApertureObject(p1,p2,p3);
			else {
				apertureObject = instancePool.pop();
				apertureObject.init(p1,p2,p3);
			}
			return apertureObject;
		}
		static public function putInstance(apertureObject:ApertureObject):void {
			if (apertureObject) instancePool[instancePool.length] = apertureObject;
		}
		static public function multiply(true_AO:ApertureObject,parentMult_AO:ApertureObject):uint {
			if (parentMult_AO == null) return true_AO.hex;
			else if (parentMult_AO.hex == 0xffffff) return true_AO.hex;
			else if (parentMult_AO.hex == 0x000000) return 0x000000;
			else return Color.rgb(
				multiplyChannel(true_AO.r,parentMult_AO.r),
				multiplyChannel(true_AO.g,parentMult_AO.g),
				multiplyChannel(true_AO.b,parentMult_AO.b)
			);
		}
		static private function multiplyChannel(trueValue:uint,parentValue:uint):uint {
			return Math.round(
				trueValue * parentValue / 255
			);
		}

		/* If you wish to instantiate an ApertureObject with a color in hexadecimal format, pass that value as the first parameter
		   and leave the others as default. If you wish to instantiate with a color in RGB format, use the red, green, and blue values
		   as the parameters respectively. */
		private var _r:uint, _g:uint, _b:uint, _hex:uint;
		public function ApertureObject(p1:int=-1,p2:int=-1,p3:int=-1) {
			init(p1,p2,p3);
		}
		private function init(p1:int,p2:int,p3:int):void {
			if (p1 == -1 && p2 == -1 && p3 == -1) {
				_hex = 0xffffff;
				_r = _g = _b = 255;
			} else if (p1 != -1 && p2 == -1 && p3 == -1) {
				_hex = p1;
				calcRGB();
			} else if (p1 != -1 && p2 != -1 && p3 != -1) {
				_r = p1;
				_g = p2;
				_b = p3;
				calcHex();
			} else throw new ArgumentError(argumentErrorString);
		}
		private function calcRGB():void {
			_r = Color.getRed(_hex);
			_g = Color.getGreen(_hex);
			_b = Color.getBlue(_hex);
		}
		private function calcHex():void {
			_hex = Color.rgb(_r,_g,_b);
		}
		public function rgb(newR:uint,newG:uint,newB:uint):void {
			_r = newR;
			_g = newG;
			_b = newB;
			calcHex();
		}
		public function get r():uint {
			return _r;
		}
		public function set r(newR:uint):void {
			_r = newR;
			calcHex();
		}
		public function get g():uint {
			return _g;
		}
		public function set g(newG:uint):void {
			_g = newG;
			calcHex();
		}
		public function get b():uint {
			return _b;
		}
		public function set b(newB:uint):void {
			_b = newB;
			calcHex();
		}
		public function get hex():uint {
			return _hex;
		}
		public function set hex(newHex:uint):void {
			_hex = newHex;
			calcRGB();
		}
		public function clone():ApertureObject {
			const apertureObject:ApertureObject = getInstance(_hex);
			return apertureObject;
		}
	}

}