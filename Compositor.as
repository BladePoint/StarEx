// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.core.Starling;
	import starling.errors.AbstractClassError;
	import starling.utils.Align;
	import starling.utils.Pool;
	import starling.utils.StringUtil;
	import starEx.text.Char;
	import starEx.text.CharLocation;
	import starEx.text.IFont;
	import starEx.text.TagObject;
	import starEx.text.TextFieldEx;
	import starEx.text.TextFormatEx;
	import starEx.text.TextLink;
	import starEx.text.TextOptionsEx;
	import starEx.text.TextTag;
    import starEx.utils.PoolEx;
	import starEx.utils.TextUtils;
	/* Compositor arranges the letters in a TextFieldEx. */
	public class Compositor {
		static public const ALPHA_NUMERIC:String = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz 0123456789";
		static public const defaultItalicRadians:Number = 0.2617993877991494, //15 degrees
			defaultSinItalicRadians:Number = 0.25881904510252074, 
			defaultThreshold:Number = .5,
			defaultLineThicknessProportion:Number = .044,
			defaultBaselineProportion:Number = .76,
			defaultUnderlineProportion:Number = .88;
		static private const FONT_DATA_NAME:String = "starEx.text.Compositor.fonts";
		static private function get fonts():Dictionary {
			var fonts:Dictionary = Starling.painter.sharedData[FONT_DATA_NAME] as Dictionary;
			if (fonts == null) {
				fonts = new Dictionary();
				Starling.painter.sharedData[FONT_DATA_NAME] = fonts;
			}
			return fonts;
		}
		/* Font names may only consist of the following characters: a-z, A-Z, 0-9, comma(,) period(.) hyphen(-). */
		static public function registerFont(iFont:IFont,fontName:String):void {
			if (fontName == null) throw new ArgumentError("fontName must not be null");
			fonts[TextUtils.convertToLowerCase(fontName)] = iFont;
		}
		static public function unregisterFont(fontName:String,dispose:Boolean=true):void {
			fontName = TextUtils.convertToLowerCase(fontName);
			if (dispose && fonts[fontName] != undefined) fonts[fontName].dispose();
			delete fonts[fontName];
		}
		static public function getFont(fontName:String):IFont {
			const font:IFont = fonts[TextUtils.convertToLowerCase(fontName)];
			if (font == null) throw new ArgumentError("'" + fontName + "' is not a registered font.");
			return font;
		}
		static public const CHAR_MISSING:int = 0,
			CHAR_TAB:int = 9,
			CHAR_NEWLINE:int = 10,
			CHAR_CARRIAGE_RETURN:int = 13,
			CHAR_SPACE:int = 32,
			CHAR_NON:int = -1;
		static private function testCharQuad(charLocation:CharLocation):Boolean {
			const charID:int = charLocation.char.charID;
			if (charID == CHAR_MISSING || charID == CHAR_TAB || charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN || charID == CHAR_SPACE || charID == CHAR_NON) return false;
			else return true;
		}
		static public function getBaselineProportion(iFont:IFont):Number {
			var baselineProportion:Number = iFont.baselineProportion;
			if (isNaN(baselineProportion)) baselineProportion = defaultBaselineProportion;
			return baselineProportion;
		}
		static public function getUnderlineProportion(iFont:IFont):Number {
			var underlineProportion:Number = iFont.underlineProportion;
			if (isNaN(underlineProportion)) underlineProportion = defaultUnderlineProportion;
			return underlineProportion;
		}
		static public function fillContainer(textField:TextFieldEx,width:Number,height:Number):Array {
			const text:String = textField.text;
			const textFormat:TextFormatEx = textField.format;
			const options:TextOptionsEx = textField.options;
			const addToTextSprite:Function = textField.addToTextSprite;
			const arrangeA:Array = arrangeLocations(textField,text,textFormat,options,width,height);
			const lineA:Array = arrangeA[0];
			const rectA:Array = arrangeA[2] = initRectArray(lineA);
			const fontO:Object = PoolEx.getObject();
			const formatFont:IFont = getFont(textFormat.font);
			var currentIndex:uint = 0;
			var strikethroughSplit:Boolean,
				underlineSplit:Boolean,
				linkSplit:Boolean;
			var textLink:TextLink;
			const al:uint = lineA.length;
			for (var i:uint=0; i<al; i++) {
				const line:Vector.<CharLocation> = lineA[i];
				const rect:Rectangle = rectA[i];
				const ll:uint = line.length;
				for (var j:uint=0; j<ll; j++) {
					const current_CL:CharLocation = line[j];
					const currentFont:IFont = current_CL.char.font;
					if (fontO[currentFont.name] == null) {
						currentFont.initFormat(textFormat);
						fontO[currentFont.name] = currentFont;
					}
					if (testCharQuad(current_CL)) {
						current_CL.initQuad(rect);
						current_CL.initOffsetY();
						textField.addToTextSprite(current_CL.quad,rect);
					}
					const tagObject:TagObject = current_CL.tagObject;
					if (tagObject) {
						const endOfLine:Boolean = testEndOfLine(j,ll);
						var strikethrough_CL:CharLocation,
							underline_CL:CharLocation,
							link_CL:CharLocation;
						if (tagObject.testAny(TextTag.ITALIC,currentIndex)) current_CL.initItalic();
						const strikethroughStart:int = tagObject.testStart(TextTag.STRIKETHROUGH,currentIndex),
							strikethroughMiddle:int = tagObject.testMiddle(TextTag.STRIKETHROUGH,currentIndex),
							strikethroughEnd:int = tagObject.testEnd(TextTag.STRIKETHROUGH,currentIndex);
						if (strikethroughMiddle == 1) {
							if (strikethroughSplit) current_CL.initStrikethrough(strikethrough_CL);
							if (endOfLine) {
								strikethroughSplit = true;
								current_CL.finiStrikethrough(strikethrough_CL,addToTextSprite,rect);
							} else strikethroughSplit = false;
						} else {
							if (strikethroughStart == 1) {
								strikethrough_CL = current_CL;
								current_CL.initStrikethrough(strikethrough_CL);
								if (endOfLine && current_CL.testSingle(TextTag.STRIKETHROUGH) == 0) {
									strikethroughSplit = true;
									current_CL.finiStrikethrough(strikethrough_CL,addToTextSprite,rect);
								} else strikethroughSplit = false;
							}
							if (strikethroughEnd == 1) {
								current_CL.finiStrikethrough(strikethrough_CL,addToTextSprite,rect);
								strikethroughSplit = false;
							}
						}
						const underlineStart:int = tagObject.testStart(TextTag.UNDERLINE,currentIndex),
							underlineMiddle:int = tagObject.testMiddle(TextTag.UNDERLINE,currentIndex),
							underlineEnd:int = tagObject.testEnd(TextTag.UNDERLINE,currentIndex);
						if (underlineMiddle == 1) {
							if (underlineSplit) current_CL.initUnderline(underline_CL);
							if (endOfLine) {
								underlineSplit = true;
								current_CL.finiUnderline(underline_CL,addToTextSprite,rect);
							} else underlineSplit = false;
						} else {
							if (underlineStart == 1) {
								underline_CL = current_CL;
								current_CL.initUnderline(underline_CL);
								if (endOfLine && current_CL.testSingle(TextTag.UNDERLINE) == 0) {
									underlineSplit = true;
									current_CL.finiUnderline(underline_CL,addToTextSprite,rect);
								} else underlineSplit = false;
							}
							if (underlineEnd == 1) {
								current_CL.finiUnderline(underline_CL,addToTextSprite,rect);
								underlineSplit = false;
							}
						}
						const linkStart:int = tagObject.testStart(TextTag.LINK,currentIndex),
							linkMiddle:int = tagObject.testMiddle(TextTag.LINK,currentIndex),
							linkEnd:int = tagObject.testEnd(TextTag.LINK,currentIndex);
						if (linkMiddle == 1) {
							if (linkSplit) current_CL.initLink(link_CL);
							if (endOfLine) {
								linkSplit = true;
								current_CL.finiLink(link_CL,addToTextSprite,rect);
							} else linkSplit = false;
							textLink.addCharLocation(current_CL);
						} else {
							if (linkStart == 1) {
								link_CL = current_CL;
								textLink = current_CL.initLink(link_CL);
								textField.addTextLink(textLink);
								if (endOfLine && current_CL.testSingle(TextTag.LINK) == 0) {
									linkSplit = true;
									current_CL.finiLink(link_CL,addToTextSprite,rect);
								} else linkSplit = false;
								textLink.addCharLocation(current_CL);
							}
							if (linkEnd == 1) {
								current_CL.finiLink(link_CL,addToTextSprite,rect);
								linkSplit = false;
								textLink.addCharLocation(current_CL,true);
							}
						}
					}
					currentIndex++;
				}
			}
			PoolEx.putObject(fontO);
			return arrangeA;
		}
		static private function testEndOfLine(j:uint,ll:uint):Boolean {
			if (j + 1 == ll) return true;
			else return false;
		}
		static public function arrangeLocations(textField:TextFieldEx,text:String,textFormat:TextFormatEx,options:TextOptionsEx,width:Number,height:Number):Array {
			const returnA:Array = PoolEx.getArray();
			const sLines:Array = returnA[0] = PoolEx.getArray();
			const finalLocations:Vector.<CharLocation> = returnA[1] = CharLocation.getVector();
			if (text == null || text.length == 0) return returnA;
			const formatFont:IFont = getFont(textFormat.font);
			const fontSize:Number = formatFont.size,
				padding:Number = formatFont.padding,
				formatSize:Number = textFormat.size,
				leading:Number = textFormat.leading,
				spacing:Number = textFormat.letterSpacing,
				formatFontLineHeight:Number = formatFont.lineHeight,
				formatFontOffsetX:Number = formatFont.offsetX,
				formatFontOffsetY:Number = formatFont.offsetY;
			var scale:Number, containerWidth:Number, containerHeight:Number;
			const kerning:Boolean = textFormat.kerning,
				autoScale:Boolean = options.autoScale;
			var finished:Boolean = false;
			const hAlign:String = textFormat.horizontalAlign,
				vAlign:String = textFormat.verticalAlign;
			var current_CL:CharLocation;
			var numChars:int, i:int, j:int;
			var autoScaleSizeReduction:uint;
			while (!finished) {
				sLines.length = 0;
				scale = (formatSize - autoScaleSizeReduction) / fontSize;
				containerWidth  = (width  - 2 * padding) / scale;
				containerHeight = (height - 2 * padding) / scale;
				if (fontSize <= containerHeight) {
					var lastWhiteSpace:int = -1,
						lastCharID:int = -1;
					var currentX:Number = 0,
						currentY:Number = 0;
					var currentLine:Vector.<CharLocation> = CharLocation.getVector();
					numChars = text.length;
					for (i=0; i<numChars; ++i) {
						const tagObject:TagObject = textField.getTagObject(i);
						const tagSize:Number = TagObject.getSize(tagObject,formatSize),
							tagScale:Number = tagSize / formatSize;
						const iFont:IFont = TagObject.getFont(tagObject,formatFont);
						var lineFull:Boolean = false;
						const charID:int = text.charCodeAt(i);
						var char:Char;
						if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN) {
							lineFull = true;
							char = iFont.getChar(CHAR_NON);
						} else if (charID == CHAR_SPACE || charID == CHAR_TAB) {
							lastWhiteSpace = i;
							char = testID(iFont,charID,text,i);
						} else char = testID(iFont,charID,text,i);
						if (kerning) currentX += char.getKerning(lastCharID) * tagScale;
						current_CL = CharLocation.getInstance(char,textFormat,tagObject);
						current_CL.x = currentX + char.xOffset * tagScale;
						current_CL.y = currentY + char.yOffset * tagScale + formatFontLineHeight * (1-tagScale) * getBaselineProportion(iFont);
						current_CL.rowY = currentY;
						current_CL.scale = current_CL.tagScale = tagScale;
						currentLine[currentLine.length] = current_CL;
						currentX += char.xAdvance * tagScale;
						if (char.charID != CHAR_NON && char.charID != CHAR_MISSING) currentX += spacing;
						lastCharID = charID;
						if (current_CL.x + char.width > containerWidth) {
							if (options.wordWrap) {
								if (autoScale && lastWhiteSpace == -1) {//when autoscaling, we must not split a word in half -> restart
									CharLocation.putVector(currentLine,true);
									break;
								}
								const numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace; // remove characters and add them again to next line
								for (j=0; j<numCharsToRemove; ++j) CharLocation.putInstance(currentLine.pop());
								if (currentLine.length == 0) {
									CharLocation.putVector(currentLine,true);
									break;
								}
								i -= numCharsToRemove;
							} else {
								if (autoScale) {
									CharLocation.putVector(currentLine,true);
									break;
								}
								CharLocation.putInstance(currentLine.pop());
								while (i < numChars - 1 && text.charCodeAt(i) != CHAR_NEWLINE) ++i; // continue with next line, if there is one
							}
							lineFull = true;
						}
						if (i == numChars - 1) {
							sLines[sLines.length] = currentLine;
							finished = true;
						} else if (lineFull) {
							sLines[sLines.length] = currentLine;
							if (currentY + formatFontLineHeight + leading + fontSize <= containerHeight) {
								currentLine = CharLocation.getVector();
								currentX = 0;
								currentY += formatFontLineHeight + leading;
								lastWhiteSpace = -1;
								lastCharID = -1;
							} else {
								CharLocation.putVector(currentLine,true);
								break;
							}
						}
					} // for each char
				} // if (_lineHeight <= containerHeight)
				if (autoScale && !finished && formatSize - autoScaleSizeReduction > 3) autoScaleSizeReduction += 1;
				else finished = true; 
			} // while (!finished)
			const numLines:int = sLines.length;
			const bottom:Number = currentY + formatFontLineHeight;
			var yOffset:int = 0;
			if (vAlign == Align.BOTTOM)      yOffset =  containerHeight - bottom;
			else if (vAlign == Align.CENTER) yOffset = (containerHeight - bottom) / 2;
			for (var lineID:int=0; lineID<numLines; ++lineID) {
				const line:Vector.<CharLocation> = sLines[lineID];
				numChars = line.length;
				if (numChars == 0) continue;
				var xOffset:int = 0;
				const lastLocation:CharLocation = line[line.length-1];
				const right:Number = lastLocation.x - lastLocation.char.xOffset 
					+ lastLocation.char.xAdvance;
				if (hAlign == Align.RIGHT)		 xOffset =  containerWidth - right;
				else if (hAlign == Align.CENTER) xOffset = (containerWidth - right) / 2;
				for (var c:int=0; c<numChars; ++c) {
					current_CL = line[c];
					current_CL.x = scale * (current_CL.x + xOffset + formatFontOffsetX) + padding;
					current_CL.y = scale * (current_CL.y + yOffset + formatFontOffsetY) + padding;
					current_CL.rowY = scale * (current_CL.rowY + yOffset + formatFontOffsetY) + padding;
					current_CL.scale *= scale;
					finalLocations[finalLocations.length] = current_CL;
				}
			}
			return returnA;
		}
		static private function testID(iFont:IFont,charID:int,text:String,i:uint):Char {
			var char:Char = iFont.getChar(charID);
			if (char == null) {
				trace(StringUtil.format("[Starling] Character '{0}' (id: {1}) not found in '{2}'",text.charAt(i),charID,iFont.name));
				char = iFont.getChar(CHAR_MISSING);
			}
			return char;
		}
		static private function initRectArray(lineA:Array):Array {
			const rectA:Array = PoolEx.getArray();
			const l:uint = lineA.length;
			for (var i:uint=0; i<l; i++) {
				rectA[rectA.length] = Pool.getRectangle(NaN,NaN,0,0);
			}
			return rectA;
		}
		static public function fillShadow(charLocationV:Vector.<CharLocation>):void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const current_CL:CharLocation = charLocationV[i];
				current_CL.initShadow();
			}
		}
		
		public function Compositor() {throw new AbstractClassError();}
	}
}