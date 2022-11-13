// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

	import starling.display.Quad;
	import starling.utils.Color;
	import starEx.display.IAperture;
	import starEx.display.IApertureMesh;
	import starEx.styles.ApertureDistanceFieldStyle;
    import starEx.utils.ApertureObject;
	import starEx.utils.ApertureUtils;
    import starEx.utils.PoolEx;
	/* An ApertureQuad will have its colors modified when the parent ApertureSprite's color is modified. */
	public class ApertureQuad extends Quad implements IAperture, IApertureMesh {

		protected var _localW:Number, _localH:Number;
		protected var indexV:Vector.<uint>;
		protected var vertices:uint;
		private var trueA:Array, multA:Array;
		private var _apertureLock:Boolean;
		public function ApertureQuad(w:Number=1,h:Number=1,colorHex:uint=0xffffff) {
			super(w,h,colorHex);
			initLocal(w,h);
			initIndex();
			initApertureObject(colorHex);
		}
		private function initLocal(w:Number,h:Number):void {
			_localW = w;
			_localH = h;
		}
		public function get localW():Number {return _localW;}
		public function get localH():Number {return _localH;}
		protected function initIndex():void {
			indexV = PoolEx.getUintV(0,3);
			vertices = indexV.length;
		}
		private function initApertureObject(colorHex:uint):void {
			trueA = PoolEx.getArray();
			multA = PoolEx.getArray();
			const vertexV:Vector.<uint> = PoolEx.getUintV();
			for (var i:uint=0; i<vertices; i++) {
				const index:uint = indexV[i];
				trueA[index] = ApertureObject.getInstance(colorHex);
				multA[index] = ApertureObject.getInstance(colorHex);
				vertexV[vertexV.length] = index;
			}
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setHex(colorHex:uint=0xffffff):void {
			const vertexV:Vector.<uint> = PoolEx.getUintV();
			for (var i:uint=0; i<vertices; i++) {
				const index:uint = indexV[i];
				testTrueHex(index,colorHex,vertexV);
			}
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		protected function testTrueHex(i:uint,newHex:uint,vertexV:Vector.<uint>):void {
			var true_AO:ApertureObject = trueA[i];
			if (true_AO.hex != newHex) {
				true_AO.hex = newHex;
				if (vertexV) vertexV[vertexV.length] = i;
			}
		}
		public function getHex(index:uint=0):uint {
			return trueA[index].hex;
		}
		public function setRGB(r:uint=255,g:uint=255,b:uint=255):void {
			const vertexV:Vector.<uint> = PoolEx.getUintV();
			for (var i:uint=0; i<vertices; i++) {
				const index:uint = indexV[i];
				testTrueRGB(index,r,g,b,vertexV);
			}
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		protected function testTrueRGB(i:uint,newR:uint,newG:uint,newB:uint,vertexV:Vector.<uint>):void {
			var true_AO:ApertureObject = trueA[i];
			if (true_AO.r != newR || true_AO.g != newG || true_AO.b != newB) {
				true_AO.rgb(newR,newG,newB);
				if (vertexV) vertexV[vertexV.length] = i;
			}
		}
		public function getRGB(index:uint=0):Array {
			var returnA:Array = PoolEx.getArray();
			returnA[0] = trueA[index].r;
			returnA[1] = trueA[index].g;
			returnA[2] = trueA[index].b;
			return returnA;
		}
		public function setVertexHex(vertexID:uint,colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(vertexID,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setVertexRGB(vertexID:uint,r:uint,g:uint,b:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(vertexID,r,g,b,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setCornerHex(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(0,topLeftColor,vertexV);
			testTrueHex(1,topRightColor,vertexV);
			testTrueHex(2,bottomLeftColor,vertexV);
			testTrueHex(3,bottomRightColor,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setCornerRGB(topLeftR:uint,topLeftG:uint,topLeftB:uint,topRightR:uint,topRightG:uint,topRightB:uint,bottomLeftR:uint,bottomLeftG:uint,bottomLeftB:uint,bottomRightR:uint,bottomRightG:uint,bottomRightB:uint,apply:Boolean=true):void {
			const topLeftHex:uint = Color.rgb(topLeftR,topLeftG,topLeftB),
				topRightHex:uint = Color.rgb(topRightR,topRightG,topRightB),
				bottomLeftHex:uint = Color.rgb(bottomLeftR,bottomLeftG,bottomLeftB),
				bottomRightHex:uint = Color.rgb(bottomRightR,bottomRightG,bottomRightB);
			setCornerHex(topLeftHex,topRightHex,bottomLeftHex,bottomRightHex,apply);
		}
		public function setTopHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(0,colorHex,vertexV);
			testTrueHex(1,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setTopRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			const topHex:uint = Color.rgb(r,g,b);
			setTopHex(topHex,apply);
		}
		public function setBottomHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(2,colorHex,vertexV);
			testTrueHex(3,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setBottomRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			const bottomHex:uint = Color.rgb(r,g,b);
			setBottomHex(bottomHex,apply);
		}
		public function setLeftHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(0,colorHex,vertexV);
			testTrueHex(2,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setLeftRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			const leftHex:uint = Color.rgb(r,g,b);
			setLeftHex(leftHex,apply);
		}
		public function setRightHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(1,colorHex,vertexV);
			testTrueHex(3,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setRightRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			const rightHex:uint = Color.rgb(r,g,b);
			setRightHex(rightHex,apply);
		}
		public function setAperture(decimal:Number):void {
			if (decimal < 0 || decimal > 1) return;
			var roundInt:uint = Math.round(decimal*255);
			setRGB(roundInt,roundInt,roundInt);
		}
		public function set apertureLock(boolean:Boolean):void {_apertureLock = boolean;}
		public function get apertureLock():Boolean {return _apertureLock;}
		public function multiplyColor():void {
			ApertureUtils.multiplyVertex(this,indexV);
			if (style is IAperture) {
				const iAperture:IAperture = style as IAperture;
				iAperture.multiplyColor();
			}
		}
		protected function multiplyVertex(vertexV:Vector.<uint>):void {
			if (vertexV) ApertureUtils.multiplyVertex(this,vertexV);
		}
		public function calcMult(parentMult_AO:ApertureObject,index:uint=0):void {
			if (parentMult_AO) multA[index].hex = ApertureObject.multiply(trueA[index],parentMult_AO);
			else multA[index].hex = trueA[index].hex;
		}
		public function applyVertexMult(vertexID:uint):void {
			super.setVertexColor(vertexID,multA[vertexID].hex);
		}
		override public function set color(value:uint):void {
			setHex(value);
		}
		override public function get color():uint {
			return getHex(0);
		}
		override public function setVertexColor(vertexID:int,colorHex:uint):void {
			setVertexHex(vertexID,colorHex,true);
		}
		override public function readjustSize(width:Number=-1,height:Number=-1):void {
			_localW = width;
			_localH = height;
			super.readjustSize(width,height);
		}
		override public function dispose():void {
			for (var i:uint=0; i<vertices; i++) {
				const index:uint = indexV[i];
				ApertureObject.putInstance(trueA[index]);
				ApertureObject.putInstance(multA[index]);
			}
			PoolEx.putArray(trueA);
			PoolEx.putArray(multA);
			trueA = multA = null;
			PoolEx.putUintV(indexV);
			indexV = null;
			texture = null;
			if (style is ApertureDistanceFieldStyle) {
				const adfs:ApertureDistanceFieldStyle = style as ApertureDistanceFieldStyle;
				adfs.dispose();
			}
			super.dispose();
		}
	}

}
