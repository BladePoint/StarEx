// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.text {

    import starling.textures.Texture;
    import starEx.display.ApertureSprite;
    import starEx.display.ApertureScale9;
    import starEx.display.IAperture;
    import starEx.display.IApertureMesh;
    import starEx.styles.ApertureDistanceFieldStyle;
    public class TextLine extends ApertureSprite implements IAperture, IApertureMesh {

        private var apertureScale9:ApertureScale9;
        private var _thickness:Number;
        private var adfs:ApertureDistanceFieldStyle;
        public function TextLine(squareTexture:Texture,thickness:Number) {
            apertureScale9 = new ApertureScale9(3,3,3,3,squareTexture,3,3,3,3,0xffffff,true);
            addChild(apertureScale9);
            this.thickness = thickness;
            //adfs = apertureScale9.style as ApertureDistanceFieldStyle;
        }
        internal function set thickness(value:Number):void {
            if (_thickness != value) {
                _thickness = value;
                scale = value / 3;
            }
        }
        internal function get thickness():Number {return _thickness;}
        internal function setCornerHex(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint,apply:Boolean=true):void {
            apertureScale9.setCornerHex(topLeftColor,topRightColor,bottomLeftColor,bottomRightColor,apply);
        }
        public function get texture():Texture {
            return apertureScale9.texture;
        }
        public function get style():ApertureDistanceFieldStyle {
            return adfs;
        }
        public function test():void {
            //apertureScale9.style["multiChannel"] = false;
            //apertureScale9.textureSmoothing = "none";
            import starling.styles.MeshStyle;
            apertureScale9.style = new MeshStyle();
            //apertureScale9.textureSmoothing = "none";
            //import starEx.display.ApertureQuad;
            //const aq:ApertureQuad = new ApertureQuad();
            const s:ApertureDistanceFieldStyle = new ApertureDistanceFieldStyle(0);
            s.multiChannel = true;
            s.setupOutline(.4,0xff0000);
            apertureScale9.style = s;
            //s.copyFrom(apertureScale9.style);
            //aq.style = s;
            //aq.texture = apertureScale9.texture;
            //aq.textureSmoothing = "none";
            //aq.readjustSize(apertureScale9.visibleWidth,apertureScale9.visibleWidth);
            //aq.scale = 20;
            //aq.x = textLine.x;
            //aq.y = textLine.y;
            //addChild(aq);
        }
        override public function set width(value:Number):void {
            apertureScale9.visibleWidth = value / scale;
        }
        override public function get width():Number {
            return apertureScale9.visibleWidth * scale;
        }
        override public function set height(value:Number):void {
            thickness = value;
        }
        override public function get height():Number {
            return _thickness;
        }
        public function setOutlineHex(outlineColor:uint,apply:Boolean):void {
            const adfs:ApertureDistanceFieldStyle = apertureScale9.style as ApertureDistanceFieldStyle;
            adfs.setHex(outlineColor);
        }
        public function setOutlineWidth(width:Number):void {
            const adfs:ApertureDistanceFieldStyle = apertureScale9.style as ApertureDistanceFieldStyle;
            ApertureDistanceFieldStyle.setStyleWidth(adfs,width);
        }
        public function setupOutline(outlineColor:uint,width:Number,apply:Boolean):void {
            const adfs:ApertureDistanceFieldStyle = apertureScale9.style as ApertureDistanceFieldStyle;
            adfs.setupOutline(width,color,1);
        }
        public function applyVertexMult(vertexID:uint):void {
			apertureScale9.applyVertexMult(vertexID);
		}
        public function set color(value:uint):void {
			apertureScale9.setHex(value);
		}
		public function get color():uint {
			return apertureScale9.getHex(0);
		}
        public function setVertexColor(vertexID:int,colorHex:uint):void {
            apertureScale9.setVertexColor(vertexID,colorHex);
        }
    }

}