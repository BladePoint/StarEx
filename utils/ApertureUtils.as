// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.utils {

	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.errors.AbstractClassError;
	import starling.core.Starling;
	import starling.utils.Color;
    import starEx.animation.TweenEx;
    import starEx.display.IAperture;
	import starEx.display.IApertureMesh;
	import starEx.display.IApertureContainer;
    import starEx.styles.ApertureDistanceFieldStyle;
	import starEx.utils.PoolEx;
	public class ApertureUtils {
		static public function multiplyChildren(iApertureDOC:IApertureContainer):void {
			const iAperture:IAperture = iApertureDOC as IAperture;
			var parentMult_AO:ApertureObject;
			if (!iAperture.apertureLock) parentMult_AO = getParentMult(iApertureDOC as DisplayObject);
			iAperture.calcMult(parentMult_AO);
			const displayObjectContainer:DisplayObjectContainer = iApertureDOC as DisplayObjectContainer;
			const l:uint = displayObjectContainer.numChildren;
			for (var i:uint=0; i<l; i++) {
				multiplyChild(displayObjectContainer.getChildAt(i));
			}
		}
		static public function multiplyChild(displayObject:DisplayObject):void {
			if (displayObject is IAperture) {
				const iAperture:IAperture = displayObject as IAperture;
				if (!iAperture.apertureLock) iAperture.multiplyColor();
			}
		}
		static public function multiplyVertex(iApertureMesh:IApertureMesh,vertexV:Vector.<uint>):void {
			const iAperture:IAperture = iApertureMesh as IAperture;
			var parentMult_AO:ApertureObject;
			if (!iAperture.apertureLock) parentMult_AO = getParentMult(iApertureMesh as DisplayObject);
			const l:uint = vertexV.length;
			for (var i:uint=0; i<l; i++) {
				iAperture.calcMult(parentMult_AO,vertexV[i]);
				iApertureMesh.applyVertexMult(vertexV[i]);
			}
		}
		static public function multiplyStyle(style:ApertureDistanceFieldStyle):void {
			const iAperture:IAperture = style as IAperture;
			var parentMult_AO:ApertureObject;
			if (!iAperture.apertureLock) parentMult_AO = getParentMult(style.target);
			iAperture.calcMult(parentMult_AO);
		}
		static private function getParentMult(displayObject:DisplayObject):ApertureObject {
			var parentDOC:DisplayObjectContainer;
			if (displayObject) parentDOC = displayObject.parent;
			var parentMult_AO:ApertureObject;
			if (parentDOC is IApertureContainer) {
				const parentApertureDOC:IApertureContainer = parentDOC as IApertureContainer;
				parentMult_AO = parentApertureDOC.getMultAO();
			}
			return parentMult_AO;
		}
		static public function tweenApertureHex(iAperture:IAperture,colorHex:uint,duration:Number,transition:String=null,onComplete:Function=null,onCompleteApplyA:Array=null,onCompleteDelay:Number=0,juggler:Juggler=null):void {
			const r:uint = Color.getRed(colorHex),
				g:uint = Color.getGreen(colorHex),
				b:uint = Color.getBlue(colorHex);
			tweenApertureRGB(iAperture,r,g,b,duration,transition,onComplete,onCompleteApplyA,onCompleteDelay,juggler);
		}
		static public function tweenApertureRGB(iAperture:IAperture,finalR:uint,finalG:uint,finalB:uint,duration:Number,transition:String=null,onComplete:Function=null,onCompleteApplyA:Array=null,onCompleteDelay:Number=0,juggler:Juggler=null):void {
			if (transition == null) transition = Transitions.LINEAR;
			if (juggler == null) juggler = Starling.juggler;
			const initHex:uint = iAperture.getHex();
			const initR:uint = Color.getRed(initHex),
				initG:uint = Color.getGreen(initHex),
				initB:uint = Color.getBlue(initHex);
			const tween:TweenEx = TweenEx.getInstance(0,duration,transition);
			tween.animateEx(1);
			tween.onUpdate = updateTween;
			const updateA:Array = PoolEx.getArray();
			updateA[0] = iAperture;
			updateA[1] = tween;
			updateA[2] = initR;
			updateA[3] = initG;
			updateA[4] = initB;
			updateA[5] = finalR;
			updateA[6] = finalG;
			updateA[7] = finalB;
			tween.onUpdateArgs = updateA;
			tween.onComplete = completeTween;
			const completeA:Array = PoolEx.getArray();
			completeA[0] = tween;
			completeA[1] = onComplete;
			completeA[2] = onCompleteApplyA;
			completeA[3] = onCompleteDelay;
			completeA[4] = juggler;
			tween.onCompleteArgs = completeA;
			juggler.add(tween);
		}
		static private function updateTween(iAperture:IAperture,tween:TweenEx,initR:uint,initG:uint,initB:uint,finalR:uint,finalG:uint,finalB:uint):void {
			const complement:Number = 1 - tween.t;
			const r:uint = Math.round(initR*complement+finalR*tween.t),
				g:uint = Math.round(initG*complement+finalG*tween.t),
				b:uint = Math.round(initB*complement+finalB*tween.t);
			iAperture.setRGB(r,g,b);
		}
		static private var staticOnComplete:Function;
		static private var staticOnCompleteApplyA:Array;
		static private function completeTween(tween:TweenEx,onComplete:Function,onCompleteApplyA:Array,delay:Number,juggler:Juggler):void {
			TweenEx.putInstance(tween);
			if (onComplete != null) {
				staticOnComplete = onComplete;
				staticOnCompleteApplyA = onCompleteApplyA;
				juggler.delayCall(delayedOnComplete,delay);
			}
		}
		static private function delayedOnComplete():void {
			if (staticOnComplete) {
				if (staticOnCompleteApplyA) {
					staticOnComplete.apply(null,staticOnCompleteApplyA);
					PoolEx.putArray(staticOnCompleteApplyA);
					staticOnCompleteApplyA = null;
				} else staticOnComplete();
				staticOnComplete = null;
			}
		}
		static public function fadeToBlack(iAperture:IAperture,duration:Number=1,onComplete:Function=null,onCompleteApplyA:Array=null,onCompleteDelay:Number=0):void {
			tweenApertureRGB(iAperture,0,0,0,duration,null,onComplete,onCompleteApplyA,onCompleteDelay);
		}
		static public function fadeToWhite(iAperture:IAperture,duration:Number=1,onComplete:Function=null,onCompleteApplyA:Array=null,onCompleteDelay:Number=0):void {
			tweenApertureRGB(iAperture,255,255,255,duration,null,onComplete,onCompleteApplyA,onCompleteDelay);
		}
		static public function reverseInterpolate(startColor:uint,endColor:uint,ratio:Number):uint {
			return Color.interpolate(endColor,startColor,ratio);
		}

		public function ApertureUtils() {throw new AbstractClassError();}
	}

}
