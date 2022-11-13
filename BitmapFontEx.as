// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.Mesh;
	import starling.styles.MeshStyle;
	import starling.text.BitmapFontType;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.Align;
	import starling.utils.Pool;
	import starling.utils.StringUtil;
	import starEx.display.ApertureQuad;
	import starEx.styles.ApertureDistanceFieldStyle;
	import starEx.text.Char;
	import starEx.text.Compositor;
	import starEx.text.IFont;
	import starEx.text.TextFormatEx;
	import starEx.utils.PoolEx;
	/* A BitmapFontEx is a class for bitmap fonts to be used with TextFieldEx. Some of this code is appropriated from starling.text.BitmapFont. */
	public class BitmapFontEx implements IFont {
		static private const instancePool:Vector.<BitmapFontEx> = new <BitmapFontEx>[];
		static public function getInstance(fontTexture:Texture,fontXml:XML,squareTexture:Texture=null):BitmapFontEx {
			var bitmapFont:BitmapFontEx;
			if (instancePool.length == 0) bitmapFont = new BitmapFontEx(fontTexture,fontXml,squareTexture);
			else {
				bitmapFont = instancePool.pop();
				bitmapFont.init(fontTexture,fontXml,squareTexture);
			}
			return bitmapFont;
		}
		static public function putInstance(bitmapFont:BitmapFontEx):void {
			if (bitmapFont) {
				bitmapFont.reset();
				instancePool[instancePool.length] = bitmapFont;
			}
		}

		public var threshold:Number = Compositor.defaultThreshold,
			softness:Number;
		private var fontTexture:Texture, squareTexture:Texture;
		private var _name:String, _smoothing:String, _type:String;
		private var _chars:Dictionary;
		private var _offsetX:Number, _offsetY:Number, _padding:Number, _size:Number, _lineHeight:Number, _baseline:Number, _distanceFieldSpread:Number, _italicRadians:Number, _sinItalicRadians:Number, _lineThicknessProportion:Number, _baselineProportion:Number, _underlineProportion:Number, charQuadFactorySoftness:Number;
		private var charQuadA:Array, lineQuadA:Array;
		/* Pass a squareTexture that is part of the same atlas as fontTexture to reduce draw calls when drawing underlines and strikethroughs.*/
		public function BitmapFontEx(fontTexture:Texture,fontXml:XML,squareTexture:Texture=null) {
			init(fontTexture,fontXml,squareTexture);
		}
		private function init(fontTexture:Texture,fontXml:XML,squareTexture:Texture):void {
			this.fontTexture = fontTexture;
			this.squareTexture = squareTexture;
			_offsetX = _offsetY = _padding = 0.0;
			addChar(Compositor.CHAR_NON,Char.getInstance(this,Compositor.CHAR_NON,null,0,0,0)); //Quadless chars
			addChar(Compositor.CHAR_MISSING,Char.getInstance(this,Compositor.CHAR_MISSING,null,0,0,0)); //Missing chars
			parseXmlData(fontXml);
			parseXmlChar(fontXml);
			charQuadA = PoolEx.getArray();
			lineQuadA = PoolEx.getArray();
		}
		private function addChar(charID:int,char:Char):void {
			if (_chars == null) _chars = new Dictionary();
			_chars[charID] = char;
		}
		public function getChar(charID:int):Char {
			return _chars[charID];
		}
		private function parseXmlData(fontXML:XML):void {
			_name = StringUtil.clean(fontXML.info.@face);
			_size = parseFloat(fontXML.info.@size);
			_lineHeight = parseFloat(fontXML.common.@lineHeight);
			_baseline = parseFloat(fontXML.common.@base);
			if (fontXML.info.@smooth.toString() == "0") _smoothing = TextureSmoothing.NONE;
			if (_size <= 0) throw new Error("Warning: invalid font size in '" + _name + "' font.");
			if (fontXML.distanceField.length()) {
				_distanceFieldSpread = parseFloat(fontXML.distanceField.@distanceRange);
				_type = fontXML.distanceField.@fieldType == "msdf" ? BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD : BitmapFontType.DISTANCE_FIELD;
			} else {
				_distanceFieldSpread = 0.0;
				_type = BitmapFontType.STANDARD;
			}
		}
		protected function parseXmlChar(fontXML:XML):void {
			for each (var xml:XML in fontXML.chars.char) initChar(xml);
			for each (var kerningElement:XML in fontXML.kernings.kerning) {
				const first:int = parseInt(kerningElement.@first);
				const second:int = parseInt(kerningElement.@second);
				const amount:Number = parseFloat(kerningElement.@amount);
				if (second in _chars) getChar(second).addKerning(first,amount);
			}
		}
		private function initChar(xml:XML):void {
			if (xml) {
				const id:int = parseInt(xml.@id);
				const region:Rectangle = Pool.getRectangle(
					parseFloat(xml.@x),
					parseFloat(xml.@y),
					parseFloat(xml.@width),
					parseFloat(xml.@height)
				);
				const texture:Texture = Texture.fromTexture(fontTexture,region);
				Pool.putRectangle(region);
				const xOffset:Number = parseFloat(xml.@xoffset);
				const yOffset:Number = parseFloat(xml.@yoffset);
				const xAdvance:Number = parseFloat(xml.@xadvance);
				const char:Char = Char.getInstance(this,id,texture,xOffset,yOffset,xAdvance);
				addChar(id,char);
			}
		}
		public function initFormat(format:TextFormatEx):void {
			if (format.softness >= 0) charQuadFactorySoftness = format.softness;
			else {
				if (!isNaN(softness)) charQuadFactorySoftness = softness;
				else charQuadFactorySoftness = _size / (format.size * _distanceFieldSpread);
			}
		}
		public function get name():String {return _name;}
		public function get size():Number {return _size;}
		public function get type():String {return _type;}
		public function get distanceFont():Boolean {
			var returnB:Boolean;
			if (_type == BitmapFontType.DISTANCE_FIELD || _type == BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD) returnB = true;
			return returnB;
		}
		public function get multiChannel():Boolean {
			if (_type == BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD) return true;
			else return false;
		}
		public function get padding():Number {return _padding;}
		public function get lineHeight():Number {return _lineHeight;}
		public function get offsetX():Number {return _offsetX;}
		public function get offsetY():Number {return _offsetY;}
		public function get italicRadians():Number {
			return _italicRadians;
		}
		public function set italicRadians(radians:Number):void {
			_italicRadians = radians;
			calcSinItalicRadians();
		}
		private function calcSinItalicRadians():void {
			_sinItalicRadians = Math.sin(_italicRadians);
		}
		public function get sinItalicRadians():Number {
			return _sinItalicRadians;
		}
		public function getCharQuad(char:Char):ApertureQuad {
			var charQuad:ApertureQuad;
			if (charQuadA.length == 0) {
				if (distanceFont) Mesh.defaultStyleFactory = charQuadDistanceStyleFactory;
				charQuad = new ApertureQuad();
				Mesh.defaultStyleFactory = null;
			} else charQuad = charQuadA.pop();
			charQuad.texture = char.texture;
			charQuad.readjustSize();
			return charQuad;
		}
		public function putCharQuad(charQuad:ApertureQuad):void {
			if (charQuad) {
				charQuad.texture = null;
				charQuad.visible = true;
				charQuad.alignPivot(Align.LEFT,Align.TOP);
				charQuad.skewX = 0;
				charQuadA[charQuadA.length] = charQuad;
			}
		}
		private function charQuadDistanceStyleFactory():MeshStyle {
			const apertureDistanceFieldStyle:ApertureDistanceFieldStyle = new ApertureDistanceFieldStyle(charQuadFactorySoftness);
			apertureDistanceFieldStyle.multiChannel = multiChannel;
			return apertureDistanceFieldStyle;
		}
		public function getLineQuad(w:Number,h:Number):ApertureQuad {
			var lineQuad:ApertureQuad;
			if (lineQuadA.length == 0) {
				if (distanceFont) Mesh.defaultStyleFactory = lineQuadDistanceStyleFactory;
				lineQuad = new ApertureQuad(w,h);
				lineQuad.texture = squareTexture;
				Mesh.defaultStyleFactory = null;
			} else {
				lineQuad = lineQuadA.pop();
				lineQuad.readjustSize(w,h);
			}
			return lineQuad;
		}
		public function putLineQuad(lineQuad:ApertureQuad):void {
			if (lineQuad) lineQuadA[lineQuadA.length] = lineQuad;
		}
		private function lineQuadDistanceStyleFactory():MeshStyle {
			const apertureDistanceFieldStyle:ApertureDistanceFieldStyle = new ApertureDistanceFieldStyle();
			apertureDistanceFieldStyle.multiChannel = multiChannel;
			apertureDistanceFieldStyle.setupOutline(0,0x000000,0);
			return apertureDistanceFieldStyle;
		}
		public function get lineThicknessProportion():Number {
			return _lineThicknessProportion;
		}
		public function set lineThicknessProportion(decimal:Number):void {
			_lineThicknessProportion = decimal;
		}
		public function get baselineProportion():Number {
			return _baselineProportion;
		}
		public function set baselineProportion(decimal:Number):void {
			_baselineProportion = decimal;
		}
		public function get underlineProportion():Number {
			return _underlineProportion;
		}
		public function set underlineProportion(decimal:Number):void {
			_underlineProportion = decimal;
		}
		public function reset():void {
			threshold = Compositor.defaultThreshold;
			_name = _smoothing = _type = "";
			if (_chars) {
				for (var charID:int in _chars) {
					const char:Char = _chars[charID];
					if (char.texture) {
						const texture:Texture = char.texture;
						texture.dispose();
					}
					Char.putInstance(char);
					delete _chars[charID];
				}
			}
			_size = _lineHeight = _baseline = _distanceFieldSpread = _italicRadians = _sinItalicRadians = _lineThicknessProportion = _baselineProportion = _underlineProportion = charQuadFactorySoftness = NaN;
			disposeQuadArray(charQuadA);
			PoolEx.putArray(charQuadA);
			disposeQuadArray(lineQuadA);
			PoolEx.putArray(lineQuadA);
			charQuadA = lineQuadA = null;
			fontTexture = squareTexture = null;
		}
		private function disposeQuadArray(array:Array):void {
			const l:uint = array.length;
			for (var i:uint=0; i<l; i++) {
				const apertureQuad:ApertureQuad = array[i];
				apertureQuad.dispose();
			}
			array.length = 0;
		}
		public function dispose():void {
			reset();
			_chars = null;
		}
	}

}