// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.init {

    import flash.display.Stage;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import starling.core.Starling;
    import starling.events.Event;
    import starEx.display.RootSprite;
    import starEx.init.Main;
    import starEx.init.Root;
    public class MainStarling extends starEx.init.Main {

        private var starling:Starling;
        public function MainStarling() {}
        protected function get rootClass():Class {return null;}
        protected function get showStats():Boolean {return false;}
        override protected function setStage(stage:Stage):void {
            stage.stageFocusRect = stage.mouseChildren = false;
			stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            RootSprite.setFlashDimensions(stage.stageWidth,stage.stageHeight);
        }
        override protected function init():void {
			super.init();
            starling = new Starling(rootClass,stage);
            starling.showStatsAt("right");
            starling.showStats = showStats;
            starling.addEventListener(Event.ROOT_CREATED,onRoot);
            starling.start();
		}
        private function onRoot(event:Event,rootObject:Object):void {
			starling.removeEventListener(Event.ROOT_CREATED,onRoot);
            if (rootObject is starEx.init.Root) {
                const rootInstance:starEx.init.Root = rootObject as starEx.init.Root;
			    rootInstance.init();
                dispose();
            } else throw new Error("rootClass '" + rootClass + "' must be a subclass of starEx.init.Root.");
		}
        private function dispose():void {
            stage.removeChild(this);
			starling = null;
		}
    }

}
