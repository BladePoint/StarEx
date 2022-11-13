// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

	import starling.display.DisplayObject;
	import starEx.utils.ApertureObject;
	public interface IApertureContainer {
		function getMultHex():uint;
		function getMultRGB():Array;
		function getMultAO():ApertureObject;
		function addChild(child:DisplayObject):DisplayObject;
	}

}
