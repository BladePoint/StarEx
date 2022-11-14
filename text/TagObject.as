// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

    import starEx.text.Compositor;
	import starEx.text.TextFormatEx;
	import starEx.text.TextTag;
	import starEx.utils.Utils;
	/* For each character in an ApertureTextField, a TagObject is used to store TextTag formatting information. */
	public class TagObject {
		static private const tagObjectV:Vector.<TagObject> = new <TagObject>[];
		static public function getInstance():TagObject {
			if (tagObjectV.length == 0) return new TagObject();
			else return tagObjectV.pop();
		}
		static public function putInstance(tagObject:TagObject):void {
			if (tagObject) {
				tagObject.reset();
				tagObjectV[tagObjectV.length] = tagObject;
			}
		}
		static public function getSize(tagObject:TagObject,formatSize:Number):Number {
			var returnSize:Number;
			var tagValue:*;
			if (tagObject) tagValue = tagObject.getValue(TextTag.SIZE);
			if (tagValue != null) returnSize = tagValue as Number;
			else returnSize = formatSize;
			return returnSize;
		}
		static public function getFont(tagObject:TagObject,formatFont:IFont):IFont {
			var returnFont:IFont;
			var tagValue:*;
			if (tagObject) tagValue = tagObject.getValue(TextTag.FONT);
			if (tagValue != null) {
				const fontString:String = tagValue as String;
				returnFont = Compositor.getFont(fontString);
			}
			if (returnFont == null) returnFont = formatFont;
			return returnFont;
		}
		static public function getColor(returnA:Array,tagObject:TagObject,textFormat:TextFormatEx):Array {
			var tagValue:*;
			if (tagObject) tagValue = tagObject.getValue(TextTag.COLOR);
			if (tagValue != null) {
				const tagColorA:Array = tagValue as Array;
				Utils.copyArray(tagColorA,returnA);
			} else {
				returnA[0] = textFormat.topLeftColor;
				returnA[1] = textFormat.topRightColor;
				returnA[2] = textFormat.bottomLeftColor;
				returnA[3] = textFormat.bottomRightColor;
			}
			return returnA;
		}
		static public function getOutlineColor(tagObject:TagObject,textFormat:TextFormatEx):uint {
			var outlineColor:uint;
			var tagValue:*;
			if (tagObject) tagValue = tagObject.getValue(TextTag.OUTLINE_COLOR);
			if (tagValue != null) outlineColor = tagValue as uint;
			else outlineColor = textFormat.outlineColor;
			return outlineColor;
		}
		static public function getOutlineWidth(tagObject:TagObject,textFormat:TextFormatEx):Number {
			var outlineWidth:Number;
			var tagValue:*;
			if (tagObject) tagValue = tagObject.getValue(TextTag.OUTLINE_WIDTH); 
			if (tagValue != null) outlineWidth = tagValue as Number;
			else outlineWidth = textFormat.outlineWidth;
			return outlineWidth;
		}
		static public function getOffsetY(tagObject:TagObject):Number {
			var offsetY:Number;
			var tagValue:*;
			if (tagObject) tagValue = tagObject.getValue(TextTag.OFFSET_Y); 
			if (tagValue != null) offsetY = tagValue as Number;  
			else offsetY = 0;
			return offsetY;
		}

		public var font:TextTag, size:TextTag, offsetY:TextTag, color:TextTag, outlineColor:TextTag, outlineWidth:TextTag, italic:TextTag, underline:TextTag, strikethrough:TextTag, link:TextTag;
		public function TagObject() {}
		public function testAny(tagType:String,index:uint):Boolean {
			const textTag:TextTag = this[tagType];
			if (textTag && index >= textTag.startIndex && index <= textTag.endIndex) return true;
			else return false;
		}
		public function testStart(tagType:String,index:uint):int {
			const textTag:TextTag = this[tagType];
			if (textTag) {
				if (index == textTag.startIndex) return 1;
				else return 0;
			} else return -1;
		}
		public function testMiddle(tagType:String,index:uint):int {
			const textTag:TextTag = this[tagType];
			if (textTag) {
				if (index > textTag.startIndex && index < textTag.endIndex) return 1;
				else return 0;
			} else return -1;
		}
		public function testEnd(tagType:String,index:uint):int {
			const textTag:TextTag = this[tagType];
			if (textTag) {
				if (index == textTag.endIndex) return 1;
				else return 0;
			} else return -1;
		}
		public function getValue(tagType:String):* {
			var returnValue:*;
			const textTag:TextTag = this[tagType];
			if (textTag) returnValue = textTag.value;
			return returnValue;
		}
		public function reset():void {
			font = size = offsetY = color = outlineColor = outlineWidth = italic = underline = strikethrough = link = null;
		}
		public function dispose():void {
			reset();
		}
	}

}