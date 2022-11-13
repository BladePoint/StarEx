// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.init {

	import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    public class Main extends Sprite {

        public function Main() {
            if (stage == null) addEventListener(Event.ADDED_TO_STAGE,addedToStage);
			else init();
        }
        private function addedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			init();
		}
        protected function init():void {
			setStage(stage);
		}
        protected function setStage(stage:Stage):void {}
    }

}