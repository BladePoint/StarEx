// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

    import flash.display3D.Context3DTextureFormat;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import starling.display.DisplayObject;
    import starling.events.Event;
    import starling.rendering.Painter;
    import starling.text.TextFieldAutoSize;
    import starling.utils.Color;
    import starling.utils.Pool;
    import starling.utils.RectangleUtil;
    import starEx.display.ApertureQuad;
    import starEx.display.ApertureSprite;
    import starEx.text.TextFormatEx;
	import starEx.text.TextLink;
    import starEx.text.TextOptionsEx;
    import starEx.utils.PoolEx;
    /* TextFieldEx supports formatting tags similar to BBCode. See TextTag for a list of available tags.
	   Much of this code is appropriated from starling.text.Textfield. */
    public class TextFieldEx extends ApertureSprite {
        static private const instancePool:Vector.<TextFieldEx> = new <TextFieldEx>[];
		static public function getInstance(width:int,height:int,text:String,format:TextFormatEx,options:TextOptionsEx=null,linkFunctionA:Array=null):TextFieldEx {
			var textField:TextFieldEx;
			if (instancePool.length == 0) textField = new TextFieldEx(width,height,text,format,options,linkFunctionA);
			else {
				textField = instancePool.pop();
				textField.init(width,height,text,format,options,linkFunctionA);
			}
			return textField;
		}
		static public function putInstance(textField:TextFieldEx):void {
			if (textField) {
				textField.reset();
				instancePool[instancePool.length] = textField;
			}
		}
		static private const spritePool:Vector.<ApertureSprite> = new <ApertureSprite>[];
		static public function getSprite():ApertureSprite {
			var apertureSprite:ApertureSprite;
			if (spritePool.length == 0) apertureSprite = new ApertureSprite();
			else apertureSprite = spritePool.pop();
			return apertureSprite;
		}
		static public function putSprite(apertureSprite:ApertureSprite):void {
			if (apertureSprite) {
				apertureSprite.x = apertureSprite.y = 0;
				apertureSprite.alpha = 1;
				apertureSprite.setHex(0xffffff);
				spritePool[spritePool.length] = apertureSprite;
			}
		}
		static private var sDefaultTextureFormat:String = Context3DTextureFormat.BGRA_PACKED;
		static public function get defaultTextureFormat():String {return sDefaultTextureFormat;}
		static public function set defaultTextureFormat(value:String):void {sDefaultTextureFormat = value;}
		static private const sMatrix:Matrix = Pool.getMatrix();
		static private const maxUint:uint = uint.MAX_VALUE;

        public var forceTouchable:Boolean;
		private var _text:String;
		private var _format:TextFormatEx;
		private var _options:TextOptionsEx;
		private var _hitArea:Rectangle, _textBounds:Rectangle;
		private var linkFunctionA:Array, textTagA:Array, tagObjectA:Array;
		private var text_AS:ApertureSprite, shadow_AS:ApertureSprite, _border:ApertureSprite;
		private var requiresRecomposition:Boolean, recomposing:Boolean;
		private var charLocationVectorA:Array;
		private var charLocationV:Vector.<CharLocation>;
		private var _originalRectA:Array, _finalRectA:Array;
		private var textLinkV:Vector.<TextLink>;
		/* If your text string includes link tags, be sure to pass an array of the functions to be called when they are clicked on. The first function
		   in the array will be assigned to the first link, the second function will be assigned to the second link, etc... */
		public function TextFieldEx(width:int,height:int,text:String,format:TextFormatEx,options:TextOptionsEx=null,linkFunctionA:Array=null) {
			init(width,height,text,format,options,linkFunctionA);
		}
		private function init(width:int,height:int,text:String,format:TextFormatEx,options:TextOptionsEx,linkFunctionA:Array):void {
			text_AS = getSprite();
			addChild(text_AS);
			_text = text;
			_format = format.clone();
			_format.assignTextField(this);
			_format.addEventListener(Event.CHANGE,setRequiresRecomposition);
			_format.addEventListener(TextFormatEx.APERTURE_CHANGE,apertureChange);
			//_format.addEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
			_options = options ? options.clone() : TextOptionsEx.getInstance();
			_options.addEventListener(Event.CHANGE,setRequiresRecomposition);
			this.linkFunctionA = linkFunctionA;
			initHitArea(width,height);
			requiresRecomposition = true;
		}
        private function initHitArea(w:int,h:int):void {
			_hitArea = Pool.getRectangle();
			if (w>0 && h>0) {
				_options.autoSize = TextFieldAutoSize.NONE;
				_hitArea.width = w;
				_hitArea.height = h;
			} else if (w>0 && h<=0) {
				_options.autoSize = TextFieldAutoSize.VERTICAL;
				_hitArea.width = w;
				_hitArea.height = maxUint;
			} else if (w<=0 && h>0) {
				_options.autoSize = TextFieldAutoSize.HORIZONTAL;
				_hitArea.width = maxUint;
				_hitArea.height = h;
			} else if (w<=0 && h<=0) {
				_options.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
				_hitArea.width = maxUint;
				_hitArea.height = maxUint;
			}
		}
		private function resetHitArea():void {
			if (_options.autoSize == TextFieldAutoSize.VERTICAL) _hitArea.height = maxUint;
			else if (_options.autoSize == TextFieldAutoSize.HORIZONTAL) _hitArea.width = maxUint;
			else if (_options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS) {
				_hitArea.width = maxUint;
				_hitArea.height = maxUint;
			}
		}
		public function getTextBounds(targetSpace:DisplayObject,out:Rectangle=null):Rectangle {
			if (requiresRecomposition) recompose();
			if (_textBounds == null) text_AS.getBounds(text_AS,_textBounds);
			getTransformationMatrix(targetSpace,sMatrix);
			return RectangleUtil.getBounds(_textBounds,sMatrix,out);
		}
		public function setRequiresRecomposition():void {
			if (!recomposing) {
				requiresRecomposition = true;
				setRequiresRedraw();
			}
		}
		public override function render(painter:Painter):void {
			if (requiresRecomposition) recompose();
			super.render(painter);
		}
		private function recompose():void {
			if (requiresRecomposition) {
				recomposing = true;
				resetText();
				parseText();
				updateText();
				updateTextLink();
				updateShadow();
				debugRect();
				updateBorder();
				requiresRecomposition = false;
				recomposing = false;
			}
		}
		private function resetText():void {
			disposeTextBounds();
			disposeTags();
			disposeTextLinkV();
			putVectorArray();
			CharLocation.putVector(charLocationV,true);
			charLocationV = null;
			putRectArray();
			putShadow();
		}
		private function putVectorArray():void {
			if (charLocationVectorA) {
				const l:uint = charLocationVectorA.length;
				for (var i:uint=0; i<l; i++) {
					const vector:Vector.<CharLocation> = charLocationVectorA[i];
					CharLocation.putVector(vector);
				}
				PoolEx.putArray(charLocationVectorA);
				charLocationVectorA = null;
			}
		}
		private function putRectArray():void {
			if (_originalRectA) {
				const ol:uint = _originalRectA.length;
				for (var i:uint=0; i<ol; i++) {
					const oRect:Rectangle = _originalRectA[i];
					Pool.putRectangle(oRect);
				}
				PoolEx.putArray(_originalRectA);
				_originalRectA = null;
			}
			if (_finalRectA) {
				const fl:uint = _finalRectA.length;
				for (var j:uint=0; j<fl; j++) {
					const fRect:Rectangle = _finalRectA[j];
					Pool.putRectangle(fRect);
				}
				PoolEx.putArray(_finalRectA);
				_finalRectA = null;
			}
		}
		private function parseText():void {
			while (stripTag()) stripTag();
			initTagObjects();
			/*import flash.utils.describeType;
			if (tagObjectA) {
				const l:uint = tagObjectA.length;
				for (var i:uint=0; i<l; i++) {
					const tagObject:TagObject = tagObjectA[i];
					if (tagObject) {
						var traceString:String = i+": ";
						const XMLlist:XMLList = describeType(tagObject)..variable;
						for each(var variable:XML in XMLlist) {
							const tagType:String = variable.@name;
							const textTag:TextTag = tagObject[tagType];
							if (textTag && textTag.value) traceString += tagType + "=" + textTag.value + ",";
						}
						trace(traceString);
					}
				}
			}*/
		}
		private function stripTag():Boolean {
			var returnB:Boolean;
			const resultO:Object = TextTag.regExp.exec(_text);
			if (resultO == null) returnB = false;
			else {
				/*trace("matched text: " + resultO[0] + " at index " + resultO.index);
				trace("slash capture group: " + resultO[1]);
				trace("tag capture group: " + resultO[2]);
				trace("value capture group: " + resultO[3]);*/
				const tagIndex:uint = resultO.index,
					tagLength:uint = resultO[0].length;
				const endTag:String = resultO[1],
					tagType:String = resultO[2],
					tagValue:String = resultO[3];
				_text = _text.slice(0,tagIndex) + _text.slice(tagIndex+tagLength);
				if (!endTag) newTextTag(tagType,tagIndex,tagValue);
				else endTextTag(tagType,tagIndex);
				returnB = true;
			}
			return returnB;
		}
		private function newTextTag(tagType:String,tagIndex:uint,valueString:String):void {
			if (textTagA == null) textTagA = PoolEx.getArray();
			const textTag:TextTag = TextTag.getInstance(tagType,tagIndex,valueString);
			textTagA[textTagA.length] = textTag;
		}
		private function endTextTag(tagType:String,tagIndex:uint):void {
			for (var i:int=textTagA.length-1; i>=0; i--) {
				const textTag:TextTag = textTagA[i];
				if (textTag.tagType == tagType) {
					textTag.endIndex = tagIndex - 1;
					break;
				}
			}
		}
		private function initTagObjects():void {
			if (textTagA) {
				tagObjectA = PoolEx.getArray()
				tagObjectA.length = _text.length;
				const l:uint = textTagA.length;
				for (var i:uint=0; i<l; i++) {
					const textTag:TextTag = textTagA[i];
					const tagType:String = textTag.tagType;
					for (var j:uint=textTag.startIndex; j<=textTag.endIndex; j++) {
						var tagObject:TagObject = tagObjectA[j];
						if (tagObject == null) tagObject = tagObjectA[j] = TagObject.getInstance();
						tagObject[tagType] = textTag;
					}
				}
			}
		}
		internal function getTagObject(index:uint):TagObject {
			var tagObject:TagObject;
			if (tagObjectA) tagObject = tagObjectA[index];
			return tagObject;
		}
		private function getTagValue(index:uint,tagType:String):* {
			var returnValue:*;
			const tagObject:TagObject = getTagObject(index);
			if (tagObject) returnValue = tagObject.getValue(tagType);
			return returnValue;
		}
		private function updateText():void {
			const width:Number  = _hitArea.width,
				height:Number = _hitArea.height;
			text_AS.x = text_AS.y = 0;
			const compositorA:Array = Compositor.fillContainer(this,width,height);
			charLocationVectorA = compositorA[0];
			charLocationV = compositorA[1];
			_originalRectA = compositorA[2];
			PoolEx.putArray(compositorA);
			if (_options.autoSize != TextFieldAutoSize.NONE) {
				_textBounds = Pool.getRectangle();
				text_AS.getBounds(text_AS,_textBounds);
				if (isHorizontalAutoSize) {
					text_AS.x = _textBounds.x = -_textBounds.x;
					_hitArea.width = _textBounds.width;
					_textBounds.x = 0;
				}
				if (isVerticalAutoSize) {
					text_AS.y = _textBounds.y = -_textBounds.y;
					_hitArea.height = _textBounds.height;
					_textBounds.y = 0;
				}
			} else disposeTextBounds();
			finalizeRectA();
			if (!_format.hasEventListener(Event.CHANGE)) _format.addEventListener(Event.CHANGE,setRequiresRecomposition);
			if (!_format.hasEventListener(TextFormatEx.APERTURE_CHANGE)) _format.addEventListener(TextFormatEx.APERTURE_CHANGE,apertureChange);
			if (!_format.hasEventListener(TextFormatEx.SHADOW_CHANGE)) _format.addEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
		}
		private function finalizeRectA():void {
			_finalRectA = PoolEx.getArray();
			const l:uint = _originalRectA.length;
			for (var i:uint=0; i<l; i++) {
				originalToFinalRect(i);
			}
		}
		private function originalToFinalRect(index:uint):void {
			const oRect:Rectangle = _originalRectA[index];
			var fRect:Rectangle;
			if (_finalRectA.length > index) {
				fRect = _finalRectA[index];
				fRect.x = text_AS.x + oRect.x;
				fRect.y = text_AS.y + oRect.y;
				fRect.width = oRect.width;
				fRect.height = oRect.height;
			} else fRect = _finalRectA[_finalRectA.length] = Pool.getRectangle(
																text_AS.x + oRect.x,
																text_AS.y + oRect.y,
																oRect.width,
																oRect.height
															 );
		}
		private function debugRect():void {
			/*clearDebugRect();
			const l:uint = _finalRectA.length;
			for (var i:uint=0; i<l; i++) {
				const rect:Rectangle = _finalRectA[i];
				const q:ApertureQuad = new ApertureQuad(rect.width,rect.height,0xffffff);
				q.touchable = false;
				q.x = rect.x;
				q.y = rect.y;
				q.alpha = .25;
				addChild(q);
			}*/
		}
		private function clearDebugRect():void {
			const l:uint = numChildren;
			import starling.display.DisplayObject;
			for (var i:int=l-1; i>=0; i--) {
				const displayObject:DisplayObject = getChildAt(i);
				if (displayObject is ApertureSprite) continue;
				else removeChild(displayObject);
			}
		}
		internal function addToTextSprite(apertureQuad:ApertureQuad,rect:Rectangle=null):void {
			text_AS.addChild(apertureQuad);
			if (isNaN(rect.x) || apertureQuad.x < rect.x) rect.x = apertureQuad.x;
			if (isNaN(rect.y) || apertureQuad.y < rect.y) rect.y = apertureQuad.y;
			const quadRight:Number = apertureQuad.x + apertureQuad.localW * apertureQuad.scaleX;
			if (rect.right < quadRight) rect.right = quadRight;
			const quadBottom:Number = apertureQuad.y + apertureQuad.localH * apertureQuad.scaleY;
			if (rect.bottom < quadBottom) rect.bottom = quadBottom;
		}
		internal function addTextLink(textLink:TextLink):void {
			if (textLink) {
				if (textLinkV == null) textLinkV = TextLink.getVector();
				textLinkV[textLinkV.length] = textLink;
			}
		}
		private function updateTextLink():void {
			if (textLinkV) {
				const l:uint = textLinkV.length;
				for (var i:uint=0; i<l; i++) {
					const textLink:TextLink = textLinkV[i];
					if (linkFunctionA && linkFunctionA.length > i) textLink.clickFunction = linkFunctionA[i];
					text_AS.addChild(textLink);
				}
				touchable = true;
			} else {
				if (forceTouchable) touchable = true;
				else touchable = false;
			}
			PoolEx.putArray(linkFunctionA);
			linkFunctionA = null;
		}
		public function getTextLinkAt(index:uint):TextLink {
			var textLink:TextLink;
			if (textLinkV && index < textLinkV.length) textLink = textLinkV[index];
			return textLink;
		}
		private function updateShadow():void {
			initShadow();
			positionShadow();
			alphaShadow();
			colorShadow();
		}
		private function initShadow():void {
			if (testShadow() && shadow_AS == null) {
				shadow_AS = getSprite();
				shadow_AS.touchable = false;
				addChildAt(shadow_AS,0);
				Compositor.fillShadow(charLocationV);
				addShadowQuad();
				_format.addEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
			} 
		}
		private function addShadowQuad():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				if (charLocation.shadowQuad) shadow_AS.addChild(charLocation.shadowQuad);
				addShadowLineArray(charLocation.shadowStrikethroughA);
				addShadowLineArray(charLocation.shadowUnderlineA);
				addShadowLineArray(charLocation.shadowLinkA);
			}
		}
		private function addShadowLineArray(shadowLineA:Array):void {
			if (shadowLineA) {
				const l:uint = shadowLineA.length;
				for (var i:uint=0; i<l; i++) {
					const shadowLine_AQ:ApertureQuad = shadowLineA[i];
					shadow_AS.addChild(shadowLine_AQ);
				}
			}
		}
		private function testShadow():Boolean {
			if (_format.dropShadowX == 0 && _format.dropShadowY == 0) return false;
			else if (_format.dropShadowAlpha == 0) return false;
			else return true;
		}
		private function positionShadow():void {
			if (shadow_AS) {
				shadow_AS.x = text_AS.x + _format.dropShadowX;
				shadow_AS.y = text_AS.y + _format.dropShadowY;
				updateFinalRect();
			}
		}
		private function updateFinalRect():void {
			const shadowIsVisible:Boolean = testShadow();
			const dropShadowX:Number = _format.dropShadowX,
				dropShadowY:Number = _format.dropShadowY;
			const l:uint = _originalRectA.length;
			for (var i:uint=0; i<l; i++) {
				const oRect:Rectangle = _originalRectA[i],
					fRect:Rectangle = _finalRectA[i];
				if (shadowIsVisible) {
					if (dropShadowX > 0) fRect.width = oRect.width + dropShadowX;
					else if (dropShadowX < 0) {
						fRect.x = text_AS.x + oRect.x + dropShadowX;
						fRect.width = oRect.width - dropShadowX;
					}
					if (dropShadowY > 0) fRect.height = oRect.height + dropShadowY;
					else if (dropShadowY < 0) {
						fRect.y = text_AS.y + oRect.y + dropShadowY;
						fRect.height = oRect.height - dropShadowY;
					}
				} else originalToFinalRect(i);
			}
			debugRect();
		}
		private function alphaShadow():void {
			if (shadow_AS) shadow_AS.alpha = _format.dropShadowAlpha;
		}
		private function colorShadow():void {
			if (shadow_AS) shadow_AS.setHex(_format.dropShadowColor);
		}
		private function shadowChange(evt:Event,changeHex:uint):void {
			const positionB:Boolean = Boolean(Color.getRed(changeHex)),
				alphaB:Boolean = Boolean(Color.getGreen(changeHex)),
				colorB:Boolean = Boolean(Color.getBlue(changeHex));
			if (shadow_AS == null) updateShadow();
			else {
				var updatedFinalRect:Boolean;
				if (positionB) {
					positionShadow();
					updatedFinalRect = true;
				}
				if (alphaB) {
					alphaShadow();
					if (!updatedFinalRect) updateFinalRect();
				}
				if (colorB) colorShadow();
			}
		}
		private function putShadow():void {
			if (shadow_AS) {
				while (shadow_AS.numChildren > 0) shadow_AS.removeChildAt(0);
				removeChild(shadow_AS);
				putSprite(shadow_AS);
				shadow_AS = null;
				_format.removeEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
			}
		}
		public function simpleCullY(parentY:Number,screenH:uint):void {
			const l:uint = charLocationVectorA.length;
			for (var i:uint=0; i<l; i++) {
				const lineRect:Rectangle = _finalRectA[i];
				if (parentY + y + lineRect.bottom < 1 || parentY + y + lineRect.top > screenH - 1) setLineVisibility(i,false);
				else setLineVisibility(i,true)
			}
		}
		private function setLineVisibility(lineIndex:uint,boolean:Boolean):void {
			const charLocationLine:Vector.<CharLocation> = charLocationVectorA[lineIndex];
			const l:uint = charLocationLine.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationLine[i];
				charLocation.visible = boolean;
			}
		}
		public function get border():Boolean {return _border != null;}
		public function set border(value:Boolean):void {
			if (value && _border == null) {
				_border = getSprite();
				addChild(_border);
				for (var i:int=0; i<4; ++i) {
					_border.addChild(new ApertureQuad(1,1));
				}
				updateBorder();
			}
			else if (!value && _border != null) disposeBorder();
		}
		private function updateBorder():void {
			if (_border == null) return;
			const width:Number  = _hitArea.width,
				height:Number = _hitArea.height;
			const topLine:ApertureQuad    = _border.getChildAt(0) as ApertureQuad,
				rightLine:ApertureQuad  = _border.getChildAt(1) as ApertureQuad,
				bottomLine:ApertureQuad = _border.getChildAt(2) as ApertureQuad,
				leftLine:ApertureQuad   = _border.getChildAt(3) as ApertureQuad;
			topLine.width    = width; topLine.height    = 1;
			bottomLine.width = width; bottomLine.height = 1;
			leftLine.width   = 1;     leftLine.height   = height;
			rightLine.width  = 1;     rightLine.height  = height;
			rightLine.x  = width  - 1;
			bottomLine.y = height - 1;
			topLine.color = rightLine.color = bottomLine.color = leftLine.color = _format.topLeftColor;
		}
		private function disposeBorder():void {
			if (_border) {
				removeChild(_border);
				while (_border.numChildren > 0) {
					const apertureQuad:ApertureQuad = _border.getChildAt(0) as ApertureQuad;
					_border.removeChild(apertureQuad);
					apertureQuad.dispose();
				}
				putSprite(_border);
				_border = null;
			}
		}
		private function apertureChange(evt:Event,changeHex:uint):void {
			const baseColorB:Boolean = Boolean(Color.getAlpha(changeHex)),
				outlineColorB:Boolean = Boolean(Color.getRed(changeHex)),
				outlineWidthB:Boolean = Boolean(Color.getGreen(changeHex)),
				outlineSoftnessB:Boolean = Boolean(Color.getBlue(changeHex));
			if (baseColorB) updateFormatColors();
			if (outlineColorB && !outlineWidthB) updateFormatOutlineColors();
			else if (!outlineColorB && outlineWidthB) updateFormatOutlineWidths();
			else if (outlineColorB && outlineWidthB) updateFormatOutline();
			if (outlineSoftnessB) updateAllSoftness();
		}
		private function updateFormatColors():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				const tagObject:TagObject = charLocation.tagObject;
				if (tagObject && tagObject.testAny(TextTag.LINK,i)) continue;
				const colorValue:* = getTagValue(i,TextTag.COLOR);
				if (colorValue == null) charLocation.updateColor(_format.topLeftColor,_format.topRightColor,_format.bottomLeftColor,_format.bottomRightColor);
			}
		}
		private function updateFormatOutlineColors():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const outlineValue:* = getTagValue(i,TextTag.OUTLINE_COLOR);
				if (outlineValue == null) {
					const charLocation:CharLocation = charLocationV[i];
					const tagObject:TagObject = charLocation.tagObject;
					if (tagObject && tagObject.testAny(TextTag.LINK,i)) continue;
					charLocation.updateOutlineColor(_format.outlineColor);
				}
			}
		}
		private function updateFormatOutlineWidths():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const outlineWidthValue:* = getTagValue(i,TextTag.OUTLINE_WIDTH);
				if (outlineWidthValue == null) {
					const charLocation:CharLocation = charLocationV[i];
					const tagObject:TagObject = charLocation.tagObject;
					if (tagObject && tagObject.testAny(TextTag.LINK,i)) continue;
					charLocation.updateOutlineWidth(_format.outlineWidth);
				}
			}
		}
		private function updateFormatOutline():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				const tagObject:TagObject = charLocation.tagObject;
				if (tagObject && tagObject.testAny(TextTag.LINK,i)) continue;
				const customOutlineColor:* = getTagValue(i,TextTag.OUTLINE_COLOR);
				var outlineColor:uint;
				if (customOutlineColor) outlineColor = customOutlineColor;
				else outlineColor = _format.outlineColor;
				var outlineWidth:Number;
				const customWidth:* = getTagValue(i,TextTag.OUTLINE_WIDTH);
				if (customWidth) outlineWidth = customWidth;
				else outlineWidth = _format.outlineWidth;
				charLocation.setupOutline(outlineColor,outlineWidth);
			}
		}
		private function updateAllSoftness():void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				charLocation.updateSoftness(_format.softness);
			}
		}
		public function getCharLocationAt(index:uint):CharLocation {
			var charLocation:CharLocation;
			if (index < charLocationV.length) charLocation = charLocationV[index];
			return charLocation;
		}
		public function get rectA():Array {return _finalRectA;}
		public function get text():String {return _text;}
		public function set text(value:String):void {
			setText(value,null);
		}
		public function setText(value:String,linkFunctionA:Array):void {
			_text = value;
			resetHitArea();
			setRequiresRecomposition();
			this.linkFunctionA = linkFunctionA;
		}
		private function get isHorizontalAutoSize():Boolean {
			return _options.autoSize == TextFieldAutoSize.HORIZONTAL || _options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
		}
		private function get isVerticalAutoSize():Boolean {
			return _options.autoSize == TextFieldAutoSize.VERTICAL || _options.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
		}
		public function get format():TextFormatEx {return _format;}
		public function set format(textFormat:TextFormatEx):void {
			if (textFormat == null) throw new ArgumentError("format cannot be null");
			_format.copyFrom(textFormat);
		}
		public function get options():TextOptionsEx {return _options;}
		public function get wordWrap():Boolean {return _options.wordWrap;}
		public function set wordWrap(value:Boolean):void {_options.wordWrap = value;}
		public override function getBounds(targetSpace:DisplayObject,out:Rectangle=null):Rectangle {
			if (requiresRecomposition) recompose();
			getTransformationMatrix(targetSpace,sMatrix);
			return RectangleUtil.getBounds(_hitArea,sMatrix,out);
		}
		private function disposeTextBounds():void {
			Pool.putRectangle(_textBounds);
			_textBounds = null;
		}
		private function disposeTags():void {
			if (textTagA) {
				var l:uint, i:uint;
				l = textTagA.length;
				for (i=0; i<l; i++) {
					const textTag:TextTag = textTagA[i];
					TextTag.putInstance(textTag);
				}
				PoolEx.putArray(textTagA);
				textTagA = null;
			}
			if (tagObjectA) {
				l = tagObjectA.length;
				for (i=0; i<l; i++) {
					const tagObject:TagObject = tagObjectA[i];
					if (tagObject) TagObject.putInstance(tagObject);
				}
				PoolEx.putArray(tagObjectA);
				tagObjectA = null;
			}
		}
		private function disposeTextLinkV():void {
			if (textLinkV) {
				const l:uint = textLinkV.length;
				for (var i:uint=0; i<l; i++) {
					const textLink:TextLink = textLinkV[i];
					text_AS.removeChild(textLink);
					TextLink.putInstance(textLink);
				}
				TextLink.putVector(textLinkV);
				textLinkV = null;
				touchable = false;
			}
		}
		private function reset():void {
			_format.removeEventListener(Event.CHANGE,setRequiresRecomposition);
			_format.removeEventListener(TextFormatEx.APERTURE_CHANGE,apertureChange);
			_format.removeEventListener(TextFormatEx.SHADOW_CHANGE,shadowChange);
			TextFormatEx.putInstance(_format);
			_format = null;
			_options.removeEventListener(Event.CHANGE,setRequiresRecomposition);
			TextOptionsEx.putInstance(_options);
			_options = null;
			Pool.putRectangle(_hitArea);
			_hitArea = null;
			disposeTextBounds();
			disposeTags();
			disposeTextLinkV();
			putVectorArray();
			CharLocation.putVector(charLocationV,true)
			charLocationV = null;
			putRectArray();
			removeChild(text_AS);
			putSprite(text_AS);
			text_AS = null;
			if (shadow_AS) {
				removeChild(shadow_AS);
				putSprite(shadow_AS);
				shadow_AS = null;
			}
			disposeBorder();
			removeEventListeners();
			transformationMatrix.identity();
			x = y = 0;
			alpha = 1;
			setAperture(1);
		}
		public override function dispose():void {
			reset();
			super.dispose();
		}
    }

}