// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

	import flash.display.NativeWindow;
	import flash.display.NativeWindowDisplayState;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.FullScreenEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.NativeWindowDisplayStateEvent;
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import starling.utils.MathUtil;
	import starEx.display.BlockSprite;
	import starEx.utils.Utils;
	public class RootSprite extends BlockSprite {
		static public var pixelPerfect:Boolean;
		static private var _flashWidth:uint, _flashHeight:uint,
			aspectWidth:uint, aspectHeight:uint,
			systemChromeWidth:uint, systemChromeHeight:uint;
		static private var _minWidth:int, _minHeight:int;
		static private var stageRect:Rectangle;
		static public function setFlashDimensions(w:uint,h:uint,resizeNativeStage:Boolean=false):void {
			_flashWidth = w;
			_flashHeight = h;
			const gcd:uint = Utils.greatestCommonDivisor(_flashWidth,_flashHeight);
			aspectWidth = _flashWidth / gcd;
			aspectHeight = _flashHeight / gcd;
			//trace("aspect ratio " + aspectWidth +":"+ aspectHeight);
			stageRect = new Rectangle(0,0,_flashWidth,_flashHeight);
		}
		static public function get flashWidth():uint {return _flashWidth;}
		static public function get flashHeight():uint {return _flashHeight;}
		static public function setFlashMinWidth(minWidth:uint):uint {
			const difference:uint = _flashWidth - minWidth,
				dividend:uint = Math.round(difference / aspectWidth);
			_minWidth = _flashWidth - (dividend * aspectWidth);
			_minHeight = _minWidth * aspectHeight / aspectWidth;
			//trace("min: " + _minWidth + "," + _minHeight);
			return _minWidth;
		}
		static public function setFlashMinHeight(minHeight:uint):uint {
			const difference:uint = _flashHeight - minHeight,
				dividend:uint = Math.round(difference / aspectHeight);
			_minHeight = _flashHeight - (dividend * aspectHeight);
			_minWidth = _minHeight * aspectWidth / aspectHeight;
			//trace("min: " + _minWidth + "," + _minHeight);
			return _minWidth;
		}

		private var nativeStage:Stage;
		private var nativeWindow:NativeWindow;
		public function RootSprite() {
			super(_flashWidth,_flashHeight,0x000000,0);
			nativeStage = Starling.current.nativeStage;
			nativeStage.addEventListener(FullScreenEvent.FULL_SCREEN,onFullScreen);
			nativeWindow = nativeStage.nativeWindow;
			nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING,onResizing);
			nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGE,onDisplayStateChange);
			systemChromeWidth = nativeWindow.width - _flashWidth;
			systemChromeHeight = nativeWindow.height - _flashHeight;
		}
		public function toggleFullScreen():void {
			if (nativeStage.displayState == StageDisplayState.NORMAL) nativeStage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			else nativeStage.displayState = StageDisplayState.NORMAL;
		}
		private function onFullScreen(fullScreenEvent:FullScreenEvent):void {
			if (fullScreenEvent.fullScreen) {
				const nativeHeight:uint = nativeStage.fullScreenHeight,
					nativeWidth:uint = nativeStage.fullScreenWidth;
				var	stageHeight:uint = getStageHeight(nativeHeight),
					stageWidth:uint = getWidthFromHeight(stageHeight);
				if (stageWidth > nativeWidth) {
					stageWidth = getStageWidth(nativeWidth);
					stageHeight = getHeightFromWidth(stageWidth);
				}
				stageRect.width = stageWidth;
				stageRect.height = stageHeight;
				const verticalBarHeight:uint = nativeWidth - stageWidth,
					horizontalBarWidth:uint = nativeHeight - stageHeight;
				stageRect.x = verticalBarHeight / 2;
				stageRect.y = horizontalBarWidth / 2;
				Starling.current.viewPort = stageRect;
			} else onNormal();
		}
		private function fullScreenAccepted(fullScreenEvent:FullScreenEvent):void {
			nativeStage.removeEventListener(FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED,fullScreenAccepted);
			unlockGame();
		}
		private function onResizing(event:NativeWindowBoundsEvent):void {
			event.preventDefault();
			const beforeBounds:Rectangle = event.beforeBounds,
				afterBounds:Rectangle = event.afterBounds;
			const widthDelta:int = afterBounds.width - beforeBounds.width,
				heightDelta:int = afterBounds.height - beforeBounds.height,
				xDelta:int = afterBounds.x - beforeBounds.x,
				yDelta:int = afterBounds.y - beforeBounds.y;
			var stageWidth:uint, stageHeight:uint;
			if (widthDelta != 0) {
				stageWidth = getStageWidth(afterBounds.width - systemChromeWidth);
				stageHeight = getHeightFromWidth(stageWidth);
			} else if (heightDelta != 0) {
				stageHeight = getStageHeight(afterBounds.height - systemChromeHeight);
				stageWidth = getWidthFromHeight(stageHeight);
			}
			stageRect.width = stageWidth;
			stageRect.height = stageHeight;
			Starling.current.viewPort = stageRect;
			nativeWindow.width = stageWidth + systemChromeWidth;
			nativeWindow.height = stageHeight + systemChromeHeight;
			if (xDelta != 0) nativeWindow.x = afterBounds.x;
			if (yDelta != 0) nativeWindow.y = afterBounds.y;
		}
		private function getStageWidth(stageWidth:uint):uint {
			var remainder:uint;
			if (pixelPerfect) remainder = stageWidth % aspectWidth;
			return MathUtil.max(_minWidth,stageWidth-remainder);
		}
		private function getStageHeight(stageHeight:uint):uint {
			var remainder:uint;
			if (pixelPerfect) remainder = stageHeight % aspectHeight;
			return MathUtil.max(_minHeight,stageHeight-remainder);
		}
		private function getHeightFromWidth(width:uint):uint {
			return Math.round(width * aspectHeight / aspectWidth);
		}
		private function getWidthFromHeight(height:uint):uint {
			return Math.round(height * aspectWidth / aspectHeight);
		}
		private function onDisplayStateChange(event:NativeWindowDisplayStateEvent):void {
			if (event.afterDisplayState == NativeWindowDisplayState.MINIMIZED) onMinimize();
			else if (event.afterDisplayState == NativeWindowDisplayState.MAXIMIZED) onMaximize();
			else onNormal();
		}
		protected function onMinimize():void {}
		protected function onMaximize():void {
			const nativeHeight:uint = nativeWindow.height,
				nativeWidth:uint = nativeWindow.width;
			var	stageHeight:uint = getStageHeight(nativeHeight - systemChromeHeight),
				stageWidth:uint = getWidthFromHeight(stageHeight);
			if (stageWidth + systemChromeWidth > nativeWidth) {
				stageWidth = getStageWidth(nativeWidth - systemChromeWidth);
				stageHeight = getHeightFromWidth(stageWidth);
			}
			stageRect.width = stageWidth;
			stageRect.height = stageHeight;
			const verticalBarHeight:uint = nativeWidth - systemChromeWidth - stageWidth,
				horizontalBarWidth:uint = nativeHeight - systemChromeHeight - stageHeight;
			stageRect.x = verticalBarHeight / 2;
			stageRect.y = horizontalBarWidth / 2;
			Starling.current.viewPort = stageRect;
		}
		protected function onNormal():void {
			stageRect.width = getStageWidth(nativeWindow.width - systemChromeWidth);
			stageRect.height = getHeightFromWidth(stageRect.width);
			stageRect.x = stageRect.y = 0;
			Starling.current.viewPort = stageRect;
		}
		private function lockGame():void {
			brightness = .6;
			touchable = false;
		}
		private function unlockGame():void {
			brightness = 1;
			touchable = true;
		}
		override public function dispose():void {
			nativeStage.removeEventListener(FullScreenEvent.FULL_SCREEN,onFullScreen);
			nativeWindow.removeEventListener(NativeWindowBoundsEvent.RESIZING,onResizing);
			nativeWindow.removeEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGE,onDisplayStateChange);
			nativeStage = null;
			nativeWindow = null;
			super.dispose();
		}
	}

}
