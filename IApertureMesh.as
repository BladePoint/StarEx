// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

	public interface IApertureMesh {
		function applyVertexMult(vertexID:uint):void;
		function set color(value:uint):void;
		function get color():uint;
		function setVertexColor(vertexID:int,colorHex:uint):void;
	}

}