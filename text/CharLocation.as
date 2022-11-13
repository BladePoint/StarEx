// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

	import flash.geom.Rectangle;
	import starling.display.DisplayObjectContainer;
	import starling.styles.DistanceFieldStyle;
	import starling.utils.Align;
	import starling.utils.MathUtil;
	import starEx.display.ApertureQuad;
	import starEx.styles.ApertureDistanceFieldStyle;
    import starEx.text.BitmapFontEx;
	import starEx.text.Char;
	import starEx.text.IFont;
	import starEx.text.TagObject;
	import starEx.text.TextFormatEx;
	import starEx.text.TextLink;
	import starEx.utils.PoolEx;
	/* A helper class that stores formatting information about a character such as position and scale. */
	public class CharLocation {
		static private const instancePool:Vector.<CharLocation> = new <CharLocation>[];
		static public function getInstance(char:Char,textFormat:TextFormatEx,tagObject:TagObject):CharLocation {
			var charLocation:CharLocation;
			if (instancePool.length == 0) charLocation = new CharLocation(char,textFormat,tagObject);
			else {
				charLocation = instancePool.pop();
				charLocation.init(char,textFormat,tagObject);
			}
			return charLocation;
		}
		static public function putInstance(charLocation:CharLocation):void {
			if (charLocation) {
				charLocation.reset();
				instancePool[instancePool.length] = charLocation;
			}
		}
		static private const vectorPool:Vector.<Vector.<CharLocation>> = new <Vector.<CharLocation>>[];
		static public function getVector():Vector.<CharLocation> {
			var vector:Vector.<CharLocation>;
			if (vectorPool.length == 0) vector = new <CharLocation>[];
			else vector = vectorPool.pop();
			return vector;
		}
		static public function putVector(vector:Vector.<CharLocation>,putContents:Boolean=false):void {
			if (vector) {
				if (putContents) {
					const l:uint = vector.length;
					for (var i:uint=0; i<l; i++) {
						const charLocation:CharLocation = vector[i];
						putInstance(charLocation);
					}
				}
				vector.length = 0;
				vectorPool[vectorPool.length] = vector;
			}
		}
		static private function getLineThickness(iFont:IFont,tagObject:TagObject,formatSize:Number):Number {
			var lineThicknessProportion:Number = iFont.lineThicknessProportion;
			if (isNaN(lineThicknessProportion)) lineThicknessProportion = Compositor.defaultLineThicknessProportion;
			const fontSize:Number = TagObject.getSize(tagObject,formatSize);
			const lineThickness:Number = MathUtil.max(1,Math.round(fontSize*lineThicknessProportion));
			return lineThickness;
		}
		static private function getTagSizeOffsetY(fontHeight:Number,formatScale:Number,tagScale:Number,currentFont:IFont):Number {
			return fontHeight * formatScale * (1-tagScale) * Compositor.getBaselineProportion(currentFont);
		}
		static private function getOuterH(charLocation:CharLocation,innerH:uint):uint {
			var outlineRatio:Number;
			const charQuad:ApertureQuad = charLocation._quad; 
			if (charQuad) {
				if (charQuad.style is DistanceFieldStyle) {
					const dfs:DistanceFieldStyle = charQuad.style as DistanceFieldStyle;
					outlineRatio = dfs.outerThreshold / dfs.threshold;
				} else if (charQuad.style is ApertureDistanceFieldStyle) {
					const adfs:ApertureDistanceFieldStyle = charQuad.style as ApertureDistanceFieldStyle;
					outlineRatio = adfs.outerThreshold / adfs.threshold;
				}
			} else {
				const iFont:IFont = charLocation.char.font;
				if (iFont is BitmapFontEx) {
					const bitmapFont:BitmapFontEx = iFont as BitmapFontEx;
					const outlineWidth:Number = TagObject.getOutlineWidth(charLocation.tagObject,charLocation.textFormat);
					const threshold:Number = bitmapFont.threshold;
					outlineRatio = MathUtil.clamp(threshold-outlineWidth,0,threshold) / threshold;
				}
			}
			var outerH:uint;
			if (!isNaN(outlineRatio)) {
				const outlineMult:Number = 1 + (1 - outlineRatio)*1;
				if (outlineMult > 1) {
					outerH = Math.ceil(innerH*outlineMult);
					if ((outerH-innerH) % 2 != 0) outerH++;
				}
			}
			return outerH;
		}
		static private function getUnderlineOffsetY(outerH:uint,innerH:uint):uint {
			return MathUtil.max(0,(outerH-innerH)*.5);
		}
		static private function getInnerLine(iFont:IFont,innerH:uint,baseY:Number,charLocation:CharLocation,x:Number):ApertureQuad {
			const inner_AQ:ApertureQuad = iFont.getLineQuad(1,innerH);
			const charQuad:ApertureQuad = charLocation._quad;
			if (charQuad) inner_AQ.setCornerHex(charQuad.getHex(0),charQuad.getHex(1),charQuad.getHex(2),charQuad.getHex(3),false);
			else charLocation.initQuadColor(inner_AQ);
			inner_AQ.x = x;
			inner_AQ.y = baseY;
			return inner_AQ;
		}
		static private function getOuterLine(iFont:IFont,outerH:Number,charLocation:CharLocation):ApertureQuad {
			const charQuad:ApertureQuad = charLocation._quad;
			var outerColor:int = -1;
			if (charQuad) {
				if (charQuad.style is DistanceFieldStyle) {
					const dfs:DistanceFieldStyle = charQuad.style as DistanceFieldStyle;
					outerColor = dfs.outerColor;
				} else if (charQuad.style is ApertureDistanceFieldStyle) {
					const adfs:ApertureDistanceFieldStyle = charQuad.style as ApertureDistanceFieldStyle;
					outerColor = adfs.getHex();
				}
			} else if (iFont.distanceFont) outerColor = charLocation.textFormat.outlineColor;
			var outer_AQ:ApertureQuad;
			if (outerColor != -1) {
				outer_AQ = iFont.getLineQuad(1,outerH);
				outer_AQ.setHex(outerColor);
			}
			return outer_AQ;
		}
		static private function setOuterLine(inner_AQ:ApertureQuad,outer_AQ:ApertureQuad):void {
			const outerWidthOffset:uint = outer_AQ.localH - inner_AQ.localH;
			const outerOffset:uint = outerWidthOffset / 2;
				outer_AQ.x = inner_AQ.x - outerOffset;
				outer_AQ.y = inner_AQ.y - outerOffset;
				outer_AQ.readjustSize(inner_AQ.localW+outerWidthOffset,outer_AQ.localH);
		}
		static private function colorInnerArray(innerA:Array,topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint):void {
			if (innerA) {
				const l:uint = innerA.length;
				for (var i:uint=0; i<l; i++) {
					const textLine:ApertureQuad = innerA[i];
					textLine.setCornerHex(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor,true);
				}
			}
		}
		static private function colorOuterArray(outerA:Array,outlineColor:uint):void {
			if (outerA) {
				const l:uint = outerA.length;
				for (var i:uint=0; i<l; i++) {
					const outer_AQ:ApertureQuad = outerA[i];
					outer_AQ.setHex(outlineColor);
				}
			}
		}
		static private function addTextLineArray(textLineA:Array,iFont:IFont,addToTextSprite:Function,rect:Rectangle):void {
			if (textLineA) {
				const l:uint = textLineA.length;
				for (var i:uint=0; i<l; i++) {
					const textLine_AQ:ApertureQuad = textLineA[i];
					addToTextSprite(textLine_AQ,rect);
				}
			}
		}
		static private function clearTextLineArray(textLineA:Array,iFont:IFont):void {
			if (textLineA) {
				const l:uint = textLineA.length;
				for (var i:uint=0; i<l; i++) {
					const textLine_AQ:ApertureQuad = textLineA[i];
					textLine_AQ.removeFromParent();
					iFont.putLineQuad(textLine_AQ);
				}
				textLineA.length = 0;
			}
		}

		public var char:Char;
		public var scale:Number, x:Number, y:Number, rowY:Number, tagScale:Number;
		internal var outerStrikethroughA:Array, innerStrikethroughA:Array, shadowStrikethroughA:Array,
			outerUnderlineA:Array, innerUnderlineA:Array, shadowUnderlineA:Array,
			outerLinkA:Array, innerLinkA:Array, shadowLinkA:Array;
		internal var textLink:TextLink;
		private var textFormat:TextFormatEx;
		private var _tagObject:TagObject;
		private var _quad:ApertureQuad, _shadowQuad:ApertureQuad;
		public function CharLocation(char:Char,textFormat:TextFormatEx,tagObject:TagObject) {
			init(char,textFormat,tagObject);
		}
		private function init(char:Char,textFormat:TextFormatEx,tagObject:TagObject):void {
			this.char = char;
			this.textFormat = textFormat;
			_tagObject = tagObject;
		}
		internal function initQuad(rect:Rectangle):void {
			const iFont:IFont = char.font;
			_quad = iFont.getCharQuad(char);
			_quad.x = x;
			_quad.y = y;
			_quad.scale = scale;
			initQuadColor(_quad);
			if (iFont.distanceFont) initCharQuadOutline();
		}
		private function initQuadColor(apertureQuad:ApertureQuad):void {
			var topLeftColor:uint, topRightColor:uint, bottomLeftColor:uint, bottomRightColor:uint;
			const colorA:Array = PoolEx.getArray();
			TagObject.getColor(colorA,_tagObject,textFormat);
			if (colorA.length == 1) topLeftColor = topRightColor = bottomLeftColor = bottomRightColor = colorA[0];
			else if (colorA.length == 2) {
				topLeftColor = topRightColor = colorA[0];
				bottomLeftColor = bottomRightColor = colorA[1];
			} else if (colorA.length == 4) {
				topLeftColor = colorA[0];
				topRightColor = colorA[1];
				bottomLeftColor = colorA[2];
				bottomRightColor = colorA[3];
			}
			apertureQuad.setCornerHex(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor,true);
			PoolEx.putArray(colorA);
		}
		private function initCharQuadOutline():void {
			const outlineColor:uint = TagObject.getOutlineColor(_tagObject,textFormat);
			const outlineWidth:Number = TagObject.getOutlineWidth(_tagObject,textFormat);
			setupOutline(outlineColor,outlineWidth);
		}
		public function setupOutline(outlineColor:uint,newWidth:Number):void {
			if (_quad) {
				if (_quad.style is DistanceFieldStyle) {
					const dfs:DistanceFieldStyle = _quad.style as DistanceFieldStyle;
					dfs.setupOutline(newWidth,outlineColor);
				} else if (_quad.style is ApertureDistanceFieldStyle) {
					const adfs:ApertureDistanceFieldStyle = _quad.style as ApertureDistanceFieldStyle;
					adfs.setupOutline(newWidth,outlineColor,1);
				}
			}
			setOuterArray(TextTag.STRIKETHROUGH,newWidth);
			setOuterArray(TextTag.UNDERLINE,newWidth);
			setOuterArray(TextTag.LINK,newWidth);
			colorOuterArray(outerStrikethroughA,outlineColor);
			colorOuterArray(outerUnderlineA,outlineColor);
			colorOuterArray(outerLinkA,outlineColor);
		}
		public function initItalic():void {
			if (_quad) {
				const iFont:IFont = char.font;
				var italicRadians:Number = iFont.italicRadians,
					sinItalicRadians:Number = iFont.sinItalicRadians;
				if (isNaN(italicRadians)) {
					italicRadians = Compositor.defaultItalicRadians;
					sinItalicRadians = Compositor.defaultSinItalicRadians;
				}
				_quad.alignPivot(Align.LEFT,Align.BOTTOM);
				_quad.x -= _quad.pivotY * sinItalicRadians / 2;
				_quad.y += _quad.pivotY * scale;
				_quad.skewX = italicRadians;
			}
		}
		public function get tagObject():TagObject {return _tagObject;}
		public function initStrikethrough(start_CL:CharLocation):void {
			const currentFont:IFont = char.font,
				formatFont:IFont = Compositor.getFont(textFormat.font);
			const fontHeight:Number = formatFont.lineHeight,
				formatSize:Number = textFormat.size,
				innerH:Number = getLineThickness(currentFont,_tagObject,formatSize),
				formatScale:Number = formatSize / formatFont.size;
			const baseY:Number = rowY
				+ getTagSizeOffsetY(fontHeight,formatScale,tagScale,currentFont)
				+ (fontHeight*scale - innerH) / 2;
			const outerH:uint = getOuterH(start_CL,innerH);
			if (start_CL == this) {
				innerStrikethroughA = PoolEx.getArray();
				if (outerH > 0) outerStrikethroughA = PoolEx.getArray();
			}
			const innerA:Array = start_CL.innerStrikethroughA,
				outerA:Array = start_CL.outerStrikethroughA;
			innerA[innerA.length] = getInnerLine(char.font,innerH,baseY,start_CL,x);
			if (outerA) outerA[outerA.length] = getOuterLine(char.font,outerH,start_CL);
		}
		public function testSingle(tagType:String):int {
			if (_tagObject.hasOwnProperty(tagType)) {
				const textTag:TextTag = _tagObject[tagType];
				if (textTag.startIndex == textTag.endIndex) return 1;
				else return 0;
			} return -1;
		}
		public function finiStrikethrough(start_CL:CharLocation,addToTextSprite:Function,rect:Rectangle):void {
			finiTextLine(start_CL.innerStrikethroughA,start_CL.outerStrikethroughA,addToTextSprite,rect);
		}
		private function finiTextLine(innerA:Array,outerA:Array,addToTextSprite:Function,rect:Rectangle):void {
			var charW:Number;
			if (char.width > 0) charW = char.width * scale;
			else charW = char.xAdvance * scale;
			const inner_AQ:ApertureQuad = innerA[innerA.length-1];
			const innerW:Number = x + charW - inner_AQ.x;
			inner_AQ.readjustSize(innerW,inner_AQ.localH);
			if (outerA) {
				const outer_AQ:ApertureQuad = outerA[outerA.length-1];
				setOuterLine(inner_AQ,outer_AQ);
				addTextLineArray(outerA,char.font,addToTextSprite,rect);
			}
			addTextLineArray(innerA,char.font,addToTextSprite,rect);
		}
		public function initUnderline(start_CL:CharLocation):void {
			const currentFont:IFont = char.font,
				formatFont:IFont = Compositor.getFont(textFormat.font);
			const fontHeight:Number = formatFont.lineHeight,
				formatSize:Number = textFormat.size,
				innerH:Number = getLineThickness(currentFont,_tagObject,formatSize),
				formatScale:Number = formatSize / formatFont.size;
			const outerH:uint = getOuterH(start_CL,innerH);
			const baseY:Number = rowY
				+ getTagSizeOffsetY(fontHeight,formatScale,tagScale,currentFont)
				+ formatSize * tagScale * Compositor.getUnderlineProportion(currentFont)
				+ getUnderlineOffsetY(outerH,innerH);
			if (start_CL == this) {
				innerUnderlineA = PoolEx.getArray();
				if (outerH > 0) outerUnderlineA = PoolEx.getArray();
			}
			const innerA:Array = start_CL.innerUnderlineA,
				outerA:Array = start_CL.outerUnderlineA;
			innerA[innerA.length] = getInnerLine(char.font,innerH,baseY,start_CL,x);
			if (outerA) outerA[outerA.length] = getOuterLine(char.font,outerH,start_CL);
		}
		public function finiUnderline(start_CL:CharLocation,addToTextSprite:Function,rect:Rectangle):void {
			finiTextLine(start_CL.innerUnderlineA,start_CL.outerUnderlineA,addToTextSprite,rect);
		}
		public function initLink(start_CL:CharLocation):TextLink {
			const currentFont:IFont = char.font,
				formatFont:IFont = Compositor.getFont(textFormat.font);
			const fontHeight:Number = formatFont.lineHeight,
				formatSize:Number = textFormat.size,
				underlineProportion:Number = Compositor.getUnderlineProportion(currentFont),
				innerH:Number = getLineThickness(currentFont,_tagObject,formatSize),
				formatScale:Number = formatSize / formatFont.size;
			const outerH:uint = getOuterH(start_CL,innerH);
			const baseY:Number = rowY
				+ getTagSizeOffsetY(fontHeight,formatScale,tagScale,currentFont)
				+ formatSize * tagScale * underlineProportion
				+ getUnderlineOffsetY(outerH,innerH);
			if (start_CL == this) {
				const size:Number = TagObject.getSize(_tagObject,textFormat.size);
				textLink = TextLink.getInstance(size,underlineProportion);
				innerLinkA = PoolEx.getArray();
				if (outerH > 0) outerLinkA = PoolEx.getArray();
			}
			const innerA:Array = start_CL.innerLinkA,
				outerA:Array = start_CL.outerLinkA;
			innerA[innerA.length] = getInnerLine(char.font,innerH,baseY,start_CL,x);
			if (outerA) outerA[outerA.length] = getOuterLine(char.font,outerH,start_CL);
			return textLink;
		}
		public function finiLink(start_CL:CharLocation,addToTextSprite:Function,rect:Rectangle):void {
			finiTextLine(start_CL.innerLinkA,start_CL.outerLinkA,addToTextSprite,rect);
		}
		public function initOffsetY():void {
			const offsetY:Number = TagObject.getOffsetY(_tagObject);
			if (_quad) _quad.y += offsetY;
			offsetLineArrayY(outerStrikethroughA,offsetY);
			offsetLineArrayY(innerStrikethroughA,offsetY);
			offsetLineArrayY(outerUnderlineA,offsetY);
			offsetLineArrayY(innerUnderlineA,offsetY);
			offsetLineArrayY(outerLinkA,offsetY);
			offsetLineArrayY(innerLinkA,offsetY);
		}
		private function offsetLineArrayY(lineA:Array,offsetY:Number):void {
			if (lineA) {
				const l:uint = lineA.length;
				for (var i:uint=0; i<l; i++) {
					const line_AQ:ApertureQuad = lineA[i];
					line_AQ.y += offsetY;
				}
			}
		}
		public function updateColor(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint):void {
			if (_quad) _quad.setCornerHex(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
			colorInnerArray(innerStrikethroughA,topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
			colorInnerArray(innerUnderlineA,topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
			colorInnerArray(innerLinkA,topLeftColor,topRightColor,bottomLeftColor,bottomRightColor);
		}
		private function setOuterArray(textLineType:String,newWidth:Number):void {
			var innerA:Array;
			var outerProperty:String;
			if (textLineType == TextTag.STRIKETHROUGH) {
				innerA = innerStrikethroughA;
				outerProperty = "outerStrikethroughA";
			} else if (textLineType == TextTag.UNDERLINE) {
				innerA = innerUnderlineA;
				outerProperty = "outerUnderlineA";
			} else if (textLineType == TextTag.LINK) {
				innerA = innerLinkA;
				outerProperty = "outerLinkA";
			}
			if (innerA && char.font.distanceFont) {
				const previousWidth:Number = getPreviousWidth(outerProperty);
				var l:uint, i:uint,
					innerH:uint, outerH:uint;
				var outerA:Array = this[outerProperty];
				var inner_AQ:ApertureQuad, outer_AQ:ApertureQuad;
				if (previousWidth == 0 && newWidth > 0) {
					l = innerA.length;
					for (i=0; i<l; i++) {
						inner_AQ = innerA[i];
						const innerParent_DOC:DisplayObjectContainer = inner_AQ.parent;
						const innerIndex:uint = innerParent_DOC.getChildIndex(inner_AQ);
						innerH = inner_AQ.localH;
						outerH = getOuterH(this,innerH);
						if (outerA == null) outerA = this[outerProperty] = PoolEx.getArray();
						outer_AQ = outerA[i] = getOuterLine(char.font,outerH,this);
						setOuterLine(inner_AQ,outer_AQ);
						innerParent_DOC.addChildAt(outer_AQ,innerIndex);
					}
				} else if (previousWidth > 0 && newWidth == 0) clearTextLineArray(outerA,char.font);
				else {
					l = innerA.length;
					for (i=0; i<l; i++) {
						inner_AQ = innerA[i];
						innerH = inner_AQ.localH;
						outerH = getOuterH(this,innerH);
						outer_AQ = outerA[i];
						outer_AQ.readjustSize(1,outerH);
						setOuterLine(inner_AQ,outer_AQ);
					}
				}
			}
		}
		private function getPreviousWidth(outerProperty:String):Number {
			var previousWidth:Number = 0;
			const outerA:Array = this[outerProperty];
			if (outerA && outerA.length > 0) {
				if (_quad) {
					if (_quad.style is DistanceFieldStyle) {
						const dfs:DistanceFieldStyle = _quad.style as DistanceFieldStyle;
						previousWidth = dfs.threshold - dfs.outerThreshold;
					} else if (_quad.style is ApertureDistanceFieldStyle) {
						const adfs:ApertureDistanceFieldStyle = _quad.style as ApertureDistanceFieldStyle;
						previousWidth = adfs.threshold - adfs.outerThreshold;
					}
				} else if (char.font.distanceFont) {
					const outlineWidth:Number = TagObject.getOutlineWidth(_tagObject,textFormat);
					previousWidth = outlineWidth;
				}
			}
			return previousWidth;
		}
		public function updateSoftness(softness:Number):void {
			if (_quad) {
				if (_quad.style is DistanceFieldStyle) {
					const dfs:DistanceFieldStyle = _quad.style as DistanceFieldStyle;
					dfs.softness = softness;
				} else if (_quad.style is ApertureDistanceFieldStyle) {
					const adfs:ApertureDistanceFieldStyle = _quad.style as ApertureDistanceFieldStyle;
					adfs.softness = softness;
				}
			}
		}
		public function updateOutlineColor(outlineColor:uint):void {
			if (_quad) {
				if (_quad.style is DistanceFieldStyle) {
					const dfs:DistanceFieldStyle = _quad.style as DistanceFieldStyle;
					dfs.outerColor = outlineColor;
				} else if (_quad.style is ApertureDistanceFieldStyle) {
					const adfs:ApertureDistanceFieldStyle = _quad.style as ApertureDistanceFieldStyle;
					adfs.setHex(outlineColor);
				}
			}
			colorOuterArray(outerStrikethroughA,outlineColor);
			colorOuterArray(outerUnderlineA,outlineColor);
			colorOuterArray(outerLinkA,outlineColor);
		}
		public function updateOutlineWidth(newWidth:Number):void {
			if (_quad) {
				var threshold:Number;
				if (_quad.style is DistanceFieldStyle) {
					const dfs:DistanceFieldStyle = _quad.style as DistanceFieldStyle;
					threshold = dfs.threshold;
					dfs.outerThreshold = MathUtil.clamp(threshold-newWidth,0,threshold);
				} else if (_quad.style is ApertureDistanceFieldStyle) {
					const adfs:ApertureDistanceFieldStyle = _quad.style as ApertureDistanceFieldStyle;
					threshold = adfs.threshold;
					adfs.outerThreshold = MathUtil.clamp(threshold-newWidth,0,threshold);
				}
			}
			setOuterArray(TextTag.STRIKETHROUGH,newWidth);
			setOuterArray(TextTag.UNDERLINE,newWidth);
			setOuterArray(TextTag.LINK,newWidth);
		}
		public function initShadow():void {
			if (_quad && !_shadowQuad) {
				const iFont:IFont = char.font;
				_shadowQuad = iFont.getCharQuad(char);
				_shadowQuad.texture = _quad.texture;
				if (_quad.style is ApertureDistanceFieldStyle) {
					const shadow_ADFS:ApertureDistanceFieldStyle = _shadowQuad.style as ApertureDistanceFieldStyle,
						source_ADFS:ApertureDistanceFieldStyle = _quad.style as ApertureDistanceFieldStyle;
					shadow_ADFS.setHex(0xffffff);
					shadow_ADFS.mode = source_ADFS.mode;
					shadow_ADFS.threshold = source_ADFS.threshold
					shadow_ADFS.outerThreshold = source_ADFS.outerThreshold;
					shadow_ADFS.outerAlphaStart = source_ADFS.outerAlphaStart;
					shadow_ADFS.outerAlphaEnd = source_ADFS.outerAlphaEnd;
				}
				_shadowQuad.readjustSize();
				_shadowQuad.scale = _quad.scale;
				_shadowQuad.pivotX = _quad.pivotX;
				_shadowQuad.pivotY = _quad.pivotY;
				_shadowQuad.skewX = _quad.skewX;
				_shadowQuad.x = _quad.x;
				_shadowQuad.y = _quad.y;
			}
			shadowLineArray(innerStrikethroughA,outerStrikethroughA,"shadowStrikethroughA");
			shadowLineArray(innerUnderlineA,outerUnderlineA,"shadowUnderlineA");
			shadowLineArray(innerLinkA,outerLinkA,"shadowLinkA");
		}
		private function shadowLineArray(innerA:Array,outerA:Array,shadowProperty:String):void {
			var sourceA:Array;
			if (outerA) sourceA = outerA;
			else if (innerA) sourceA = innerA;
			if (sourceA && this[shadowProperty] == null) {
				const shadowA:Array = this[shadowProperty] = PoolEx.getArray();
				const iFont:IFont = char.font;
				const l:uint = sourceA.length;
				for (var i:uint=0; i<l; i++) {
					const line_AQ:ApertureQuad = sourceA[i],
						shadow_AQ:ApertureQuad = iFont.getLineQuad(line_AQ.localW,line_AQ.localH);
					shadow_AQ.x = line_AQ.x;
					shadow_AQ.y = line_AQ.y;
					shadowA[shadowA.length] = shadow_AQ;
				}
			}
		}
		public function get quad():ApertureQuad {
			return _quad;
		}
		public function get shadowQuad():ApertureQuad {
			return _shadowQuad;
		}
		public function set visible(boolean:Boolean):void {
			if (_quad) _quad.visible = boolean;
			if (_shadowQuad) _shadowQuad.visible = boolean;
		}
		public function reset():void {
			scale = x = y = rowY = tagScale = NaN;
			const iFont:IFont = char.font;
			char = null;
			clearTextLineArray(outerStrikethroughA,iFont);
			PoolEx.putArray(outerStrikethroughA);
			clearTextLineArray(innerStrikethroughA,iFont);
			PoolEx.putArray(innerStrikethroughA);
			clearTextLineArray(shadowStrikethroughA,iFont);
			PoolEx.putArray(shadowStrikethroughA);
			clearTextLineArray(outerUnderlineA,iFont);
			PoolEx.putArray(outerUnderlineA);
			clearTextLineArray(innerUnderlineA,iFont);
			PoolEx.putArray(innerUnderlineA);
			clearTextLineArray(shadowUnderlineA,iFont);
			PoolEx.putArray(shadowUnderlineA);
			clearTextLineArray(outerLinkA,iFont);
			PoolEx.putArray(outerLinkA);
			clearTextLineArray(innerLinkA,iFont);
			PoolEx.putArray(innerLinkA);
			clearTextLineArray(shadowLinkA,iFont);
			PoolEx.putArray(shadowLinkA);
			outerStrikethroughA = innerStrikethroughA = shadowStrikethroughA =
				outerUnderlineA = innerUnderlineA = shadowUnderlineA =
				outerLinkA = innerLinkA = shadowLinkA = null;
			textLink = null;
			textFormat = null;
			_tagObject = null;
			if (_quad) {
				_quad.removeFromParent();
				iFont.putCharQuad(_quad);
			}
			if (_shadowQuad) {
				_shadowQuad.removeFromParent();
				iFont.putCharQuad(_shadowQuad);
			}
			_quad = _shadowQuad = null;
		}
		public function dispose():void {
			reset();
		}
	}

}
