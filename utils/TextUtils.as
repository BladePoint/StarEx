// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.utils {

	import flash.utils.Dictionary;
	import starling.errors.AbstractClassError;
	public class TextUtils {
		static private var capFirstCache:Dictionary;
		static public function capitalizeFirst(string:String):String {
			if (capFirstCache == null) capFirstCache = new Dictionary();
			var result:String = capFirstCache[string];
			if (result == null) {
				result = string.charAt(0).toUpperCase() + string.slice(1);
				capFirstCache[string] = result;
			}
			return result;
		}
		static private var lowercaseCache:Dictionary;
		static public function convertToLowerCase(string:String):String {
			if (lowercaseCache == null) lowercaseCache = new Dictionary();
			var result:String = lowercaseCache[string];
			if (result == null) {
				result = string.toLowerCase();
				lowercaseCache[string] = result;
			}
			return result;
		}
		static public function dropCap(dropCapStartTags:String,dropCapEndTags:String,string:String):String {
			return dropCapStartTags + string.charAt(0) + dropCapEndTags + string.substr(1);
		}
		static public function testSpaceAfter(text:String):Boolean {
			const length:uint = text.length;
			const lastCharacter:String = text.charAt(length-1);
			if (testPunctuation(lastCharacter)) return true;
			else return false;
		}
		static private const punctuationA:Array = [".","?","!",",",";",":",'"'];
		static private function testPunctuation(lastCharacter:String):Boolean {
			const index:int = punctuationA.indexOf(lastCharacter);
			if (index != -1) return true;
			else return false;
		}
		static public function spaceAfter(string:String):String {
			return string + " ";
		}
		static public function newLine(string:String):String {
			return string + "\n";
		}
		static public function italicize(string:String):String {
			return "[italic]" + string + "[/italic]";
		}

		public function TextUtils() {throw new AbstractClassError();}
	}

}
