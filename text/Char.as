// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

	import flash.utils.Dictionary;
	import starling.textures.Texture;
	import starEx.text.IFont;
	/* A helper class for arranging characters in a TextFieldEx by the Compositor class. */
	public class Char {
		static private const instancePool:Vector.<Char> = new <Char>[];
		static public function getInstance(iFont:IFont,id:int,texture:Texture,xOffset:Number,yOffset:Number,xAdvance:Number):Char {
			var char:Char;
			if (instancePool.length == 0) char = new Char(iFont,id,texture,xOffset,yOffset,xAdvance);
			else {
				char = instancePool.pop();
				char.init(iFont,id,texture,xOffset,yOffset,xAdvance);
			}
			return char;
		}
		static public function putInstance(char:Char):void {
			if (char) {
				char.reset();
				instancePool[instancePool.length] = char;
			}
		}

		private var _iFont:IFont;
		private var _charID:int;
		private var _texture:Texture;
		private var _xOffset:Number;
		private var _yOffset:Number;
		private var _xAdvance:Number;
		private var _kernings:Dictionary;
		public function Char(iFont:IFont,id:int,texture:Texture,xOffset:Number,yOffset:Number,xAdvance:Number) {
			init(iFont,id,texture,xOffset,yOffset,xAdvance);
		}
		private function init(iFont:IFont,id:int,texture:Texture,xOffset:Number,yOffset:Number,xAdvance:Number):void {
			_iFont = iFont;
			_charID = id;
			_texture = texture;
			_xOffset = xOffset;
			_yOffset = yOffset;
			_xAdvance = xAdvance;
		}
		public function addKerning(charID:int, amount:Number):void {
			if (_kernings == null) _kernings = new Dictionary();
			_kernings[charID] = amount;
		}
		public function getKerning(charID:int):Number {
			if (_kernings == null || _kernings[charID] == undefined) return 0.0;
			else return _kernings[charID];
		}
		public function get font():IFont {return _iFont;}
		public function get charID():int {return _charID;}
		public function get texture():Texture {return _texture;}
		public function get xOffset():Number {return _xOffset;}
		public function get yOffset():Number {return _yOffset;}
		public function get xAdvance():Number {return _xAdvance;}
		public function get width():Number {
			if (_texture) return _texture.width;
			else return 0;
		}
		public function get height():Number {
			if (_texture) return _texture.height;
			else return 0;
		}
		public function reset():void {
			_iFont = null;
			_texture = null;
			if (_kernings) {
				for (var charID:int in _kernings) {
					delete _kernings[charID];
				}
			}
		}
		public function dispose():void {
			reset();
			_kernings = null;
		}
	}

}
