// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

    import starling.textures.Texture;
    import starEx.display.ApertureQuad;
    public class ApertureImage extends ApertureQuad implements IAperture, IApertureMesh {

        protected var visTexW:uint, visTexH:uint,
            totTexW:uint, totTexH:uint;
        protected var proportionW:Number, proportionH:Number;
        public function ApertureImage(texture:Texture,visibleTextureOffsetX:Number=0,visibleTextureOffsetY:Number=0,visibleTextureWidth:Number=-1,visibleTextureHeight:Number=-1,colorHex:uint=0xffffff) {
            totTexW = texture.width;
            totTexH = texture.height;
            super(totTexW,totTexH,colorHex);
            this.texture = texture;
            if (visibleTextureWidth > 0 && visibleTextureHeight > 0) {
                visTexW = visibleTextureWidth;
                visTexH = visibleTextureHeight;
            } else {
                visTexW = totTexW;
                visTexH = totTexH;
            }
            proportionW = visTexW / totTexW;
            proportionH = visTexH / totTexH;
            setPivot(visibleTextureOffsetX,visibleTextureOffsetY);
        }
        protected function setPivot(x:Number,y:Number):void {
            pivotX = x;
            pivotY = y;
        }
        override public function readjustSize(width:Number=-1,height:Number=-1):void {
            if (width <= 0) scaleX = 1;
            else this.width = width;
            if (height <= 0) scaleY = 1;
            else this.height = height;
        }
        public function readjustVisibleSize(width:Number=-1,height:Number=-1):void {
            if (width <= 0) scaleX = 1;
            else visibleWidth = width;
            if (height <= 0) scaleY = 1;
            else visibleHeight = height;
		}
        public function set visibleWidth(value:Number):void {
            width = value / proportionW;
        }
        public function get visibleWidth():Number {
            return width * proportionW;
        }
        public function set visibleHeight(value:Number):void {
            height = value / proportionH;
        }
        public function get visibleHeight():Number {
            return height * proportionH;
        }
    }

}