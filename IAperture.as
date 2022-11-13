// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

	import starEx.utils.ApertureObject;
	public interface IAperture {
		function setHex(colorHex:uint=0xffffff):void;
		function getHex(index:uint=0):uint;
		function setRGB(r:uint=255,g:uint=255,b:uint=255):void;
		function getRGB(index:uint=0):Array;
		function setAperture(decimal:Number):void;
		function set apertureLock(boolean:Boolean):void;
		function get apertureLock():Boolean;
		function multiplyColor():void;
		function calcMult(parentMult_AO:ApertureObject,index:uint=0):void;
	}

}