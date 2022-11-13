// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.display {

    import flash.geom.Rectangle;
    import starling.rendering.VertexData;
    import starling.textures.Texture;
    import starling.utils.Color;
    import starling.utils.MathUtil;
    import starling.utils.Pool;
    import starEx.display.ApertureImage;
    import starEx.display.IAperture;
    import starEx.display.IApertureMesh;
    import starEx.utils.ApertureUtils;
    import starEx.utils.PoolEx;
    //The Aperture version of an Image with a scale9Grid. Some of this code is appropriated from starling.display.Image.
    public class ApertureScale9 extends ApertureImage implements IAperture, IApertureMesh {
        private const index9QuadV:Vector.<uint> = new <uint>[
             0, 1, 4, 5, 8, 9,
             2, 3, 6, 7,10,11,
            12,13,16,17,20,21,
            14,15,18,19,22,23,
            24,25,28,29,32,33,
            26,27,30,31,34,35
        ];
        private var sBasCols:Vector.<Number> = new Vector.<Number>(3,true);
        private var sBasRows:Vector.<Number> = new Vector.<Number>(3,true);
        private var sPosCols:Vector.<Number> = new Vector.<Number>(3,true);
        private var sPosRows:Vector.<Number> = new Vector.<Number>(3,true);
        private var sTexCols:Vector.<Number> = new Vector.<Number>(3,true);
        private var sTexRows:Vector.<Number> = new Vector.<Number>(3,true);
        internal static function setupScale9GridAttributes(vertexData:VertexData,texture:Texture,startX:Number,startY:Number,posCols:Vector.<Number>,posRows:Vector.<Number>,texCols:Vector.<Number>,texRows:Vector.<Number>):int {
            const posAttr:String = "position";
            const texAttr:String = "texCoords";
            var row:int, col:int;
            var colWidthPos:Number, rowHeightPos:Number;
            var colWidthTex:Number, rowHeightTex:Number;
            var currentX:Number = startX;
            var currentY:Number = startY;
            var currentU:Number = 0.0;
            var currentV:Number = 0.0;
            var vertexID:int = 0;
            for (row=0; row<3; ++row) {
                rowHeightPos = posRows[row];
                rowHeightTex = texRows[row];
                if (rowHeightPos > 0) {
                    for (col = 0; col < 3; ++col) {
                        colWidthPos = posCols[col];
                        colWidthTex = texCols[col];
                        if (colWidthPos > 0) {
                            vertexData.setPoint(vertexID,posAttr,currentX,currentY);
                            texture.setTexCoords(vertexData,vertexID,texAttr,currentU,currentV);
                            vertexID++;
                            vertexData.setPoint(vertexID,posAttr,currentX + colWidthPos,currentY);
                            texture.setTexCoords(vertexData,vertexID,texAttr,currentU + colWidthTex,currentV);
                            vertexID++;
                            vertexData.setPoint(vertexID,posAttr,currentX,currentY + rowHeightPos);
                            texture.setTexCoords(vertexData,vertexID,texAttr,currentU,currentV + rowHeightTex);
                            vertexID++;
                            vertexData.setPoint(vertexID,posAttr,currentX + colWidthPos,currentY + rowHeightPos);
                            texture.setTexCoords(vertexData,vertexID,texAttr,currentU + colWidthTex,currentV + rowHeightTex);
                            vertexID++;
                            currentX += colWidthPos;
                        }
                        currentU += colWidthTex;
                    }
                    currentY += rowHeightPos;
                }
                currentX = startX;
                currentU = 0.0;
                currentV += rowHeightTex;
            }
            return vertexID;
        }

        private var _invisibleSideQuads:Boolean;
        private var scale9Grid:Rectangle;
        private var visTexOffsetX:Number, visTexOffsetY:Number;
        private var col0_1:Number, col1_2:Number, row0_1:Number, row1_2:Number;
        public function ApertureScale9(rectX:uint,rectY:uint,rectW:uint,rectH:uint,texture:Texture,visibleTextureOffsetX:Number=0,visibleTextureOffsetY:Number=0,visibleTextureWidth:Number=-1,visibleTextureHeight:Number=-1,colorHex:uint=0xffffff,invisibleSideQuads:Boolean=false) {
            _invisibleSideQuads = invisibleSideQuads;
			super(texture,visibleTextureOffsetX,visibleTextureOffsetY,visibleTextureWidth,visibleTextureHeight,colorHex);
            initRectangle(rectX,rectY,rectW,rectH);
            visTexOffsetX = visibleTextureOffsetX;
            visTexOffsetY = visibleTextureOffsetY;
            x = y = 0;
		}
        override protected function initIndex():void {
            var minIndex:uint, maxIndex:uint;
            if (_invisibleSideQuads) {
                minIndex = 16;
                maxIndex = 19;
            } else {
                minIndex = 0;
                maxIndex = 35;
            }
            indexV = PoolEx.getUintV(minIndex,maxIndex);
			vertices = indexV.length;
		}
        override protected function setPivot(x:Number,y:Number):void {}
        private function initRectangle(x:uint,y:uint,w:uint,h:uint):void {
            scale9Grid = Pool.getRectangle();
            scale9Grid.setTo(x,y,w,h);
            if (scale9Grid.width == 0 || scale9Grid.height == 0 ||
                scale9Grid.x == 0 || scale9Grid.y == 0 ||
                scale9Grid.right >= totTexW || scale9Grid.bottom >= totTexH
               ) throw new Error("Rectangle must have non-zero width and height and be positioned within borders of texture.")
            setupScale9Grid();
        }
        private function setupScale9Grid():void {
            var absScaleX:Number = scaleX > 0 ? scaleX : -scaleX;
            var absScaleY:Number = scaleY > 0 ? scaleY : -scaleY;
            if (absScaleX == 0.0 || absScaleY == 0) return;
            var invScaleX:Number = 1.0 / absScaleX;
            var invScaleY:Number = 1.0 / absScaleY;

            var textureBounds:Rectangle = Pool.getRectangle();
            textureBounds.setTo(0,0,totTexW,totTexH);
            sBasRows[0] = scale9Grid.y;
            sBasRows[1] = scale9Grid.height;
            sBasRows[2] = textureBounds.bottom - scale9Grid.bottom;
            sBasCols[0] = scale9Grid.x;
            sBasCols[1] = scale9Grid.width;
            sBasCols[2] = textureBounds.right - scale9Grid.right;

            sPosCols[0] = sBasCols[0] * invScaleX;
            sPosCols[2] = sBasCols[2] * invScaleX;
            sPosCols[1] = textureBounds.width - sPosCols[0] - sPosCols[2];
            sPosRows[0] = sBasRows[0] * invScaleY;
            sPosRows[2] = sBasRows[2] * invScaleY;
            sPosRows[1] = textureBounds.height - sPosRows[0] - sPosRows[2];

            col0_1 = sPosCols[0] / totTexW;
            col1_2 = (sPosCols[0] + sPosCols[1]) / totTexW;
            row0_1 = sPosRows[0] / totTexH;
            row1_2 = (sPosRows[0] + sPosRows[1]) / totTexH;

            sTexRows[0] = sBasRows[0] / textureBounds.height;
            sTexRows[2] = sBasRows[2] / textureBounds.height;
            sTexRows[1] = 1.0 - sTexRows[0] - sTexRows[2];
            sTexCols[0] = sBasCols[0] / textureBounds.width;
            sTexCols[2] = sBasCols[2] / textureBounds.width;
            sTexCols[1] = 1.0 - sTexCols[0] - sTexCols[2];

            var numVertices:int = setupScale9GridAttributes(vertexData,texture,0,0,sPosCols,sPosRows,sTexCols,sTexRows);
            var numQuads:int = numVertices / 4;
            vertexData.numVertices = numVertices;
            indexData.numIndices = 0;
            for (var i:int=0; i<numQuads; ++i) indexData.addQuad(i*4, i*4 + 1, i*4 + 2, i*4 + 3);
            Pool.putRectangle(textureBounds);
            setRequiresRedraw();
        }
        override public function set x(value:Number):void {
            super.x = value - visTexOffsetX;
        }
        override public function set y(value:Number):void {
            super.y = value - visTexOffsetY;
        }
        override public function set scaleX(value:Number):void {
            value = MathUtil.max(1,value);
            super.scaleX = value;
            setupScale9Grid();
        }
        override public function set scaleY(value:Number):void {
            value = MathUtil.max(1,value);
            super.scaleY = value;
            setupScale9Grid();
        }
        public function set scaleVisibleX(value:Number):void {
            if (visTexOffsetX > 0) {
                const scaledTotalW:Number = value * visTexW + (totTexW - visTexW);
                super.scaleX = MathUtil.max(1,scaledTotalW/totTexW);
            } else scaleX = MathUtil.max(1,value);
            setupScale9Grid();
        }
        public function get scaleVisibleX():Number {
            if (visTexOffsetX > 0) {
                const scaledVisibleW:Number = super.scaleX * totTexW - (totTexW - visTexW);
                return scaledVisibleW / visTexW;
            } else return scaleX;
        }
        public function set scaleVisibleY(value:Number):void {
            if (visTexOffsetY > 0) {
                const scaledTotalH:Number = value * visTexH + (totTexH - visTexH);
                super.scaleY = MathUtil.max(1,scaledTotalH/totTexH);
            } else scaleY = MathUtil.max(1,value);
            setupScale9Grid();
        }
        public function get scaleVisibleY():Number {
            if (visTexOffsetY > 0) {
                const scaledVisibleH:Number = super.scaleY * totTexH - (totTexH - visTexH);
                return scaledVisibleH / visTexH;
            } else return scaleY;
        }
        override public function set visibleWidth(value:Number):void {
            if (visTexOffsetX > 0) super.width = value + (totTexW - visTexW);
            else super.width = value;
        }
        override public function get visibleWidth():Number {
            return width - (totTexW - visTexW);
        }
        override public function set visibleHeight(value:Number):void {
            if (visTexOffsetY > 0) super.height = value + (totTexH - visTexH);
            else super.height = value;
        }
        override public function get visibleHeight():Number {
            return height - (totTexH - visTexH);
        }
        override public function setCornerHex(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
            if (vertices == 4) {
                testTrueHex(16,topLeftColor,vertexV);
                testTrueHex(17,topRightColor,vertexV);
                testTrueHex(18,bottomLeftColor,vertexV);
                testTrueHex(19,bottomRightColor,vertexV);
            } else {
                const p1_4:uint = Color.interpolate(topLeftColor,topRightColor,col0_1),
                    p5_8:uint = Color.interpolate(topLeftColor,topRightColor,col1_2),
                    p27_30:uint = Color.interpolate(bottomLeftColor,bottomRightColor,col0_1),
                    p31_34:uint = Color.interpolate(bottomLeftColor,bottomRightColor,col1_2),
                    
                    p2_12:uint = Color.interpolate(topLeftColor,bottomLeftColor,row0_1),
                    p14_24:uint = Color.interpolate(topLeftColor,bottomLeftColor,row1_2),

                    p11_21:uint = Color.interpolate(topRightColor,bottomRightColor,row0_1),
                    p23_33:uint = Color.interpolate(topRightColor,bottomRightColor,row1_2),

                    p3_6_13_16:uint = Color.interpolate(p1_4,p27_30,row0_1),
                    p15_18_25_28:uint = Color.interpolate(p1_4,p27_30,row1_2),
                    p7_10_17_20:uint = Color.interpolate(p5_8,p31_34,row0_1),
                    p19_22_29_32:uint = Color.interpolate(p5_8,p31_34,row1_2);
                testTrueHex(0,topLeftColor,vertexV);
                testTrueHex(1,p1_4,vertexV);
                testTrueHex(4,p1_4,vertexV);
                testTrueHex(5,p5_8,vertexV);
                testTrueHex(8,p5_8,vertexV);
                testTrueHex(9,topRightColor,vertexV);

                testTrueHex(26,bottomLeftColor,vertexV);
                testTrueHex(27,p27_30,vertexV);
                testTrueHex(30,p27_30,vertexV);
                testTrueHex(31,p31_34,vertexV);
                testTrueHex(34,p31_34,vertexV);
                testTrueHex(35,bottomRightColor,vertexV);

                testTrueHex(2,p2_12,vertexV);
                testTrueHex(12,p2_12,vertexV);
                testTrueHex(14,p14_24,vertexV);
                testTrueHex(24,p14_24,vertexV);

                testTrueHex(11,p11_21,vertexV);
                testTrueHex(21,p11_21,vertexV);
                testTrueHex(23,p23_33,vertexV);
                testTrueHex(33,p23_33,vertexV);

                testTrueHex(3,p3_6_13_16,vertexV);
                testTrueHex(6,p3_6_13_16,vertexV);
                testTrueHex(13,p3_6_13_16,vertexV);
                testTrueHex(16,p3_6_13_16,vertexV);

                testTrueHex(15,p15_18_25_28,vertexV);
                testTrueHex(18,p15_18_25_28,vertexV);
                testTrueHex(25,p15_18_25_28,vertexV);
                testTrueHex(28,p15_18_25_28,vertexV);

                testTrueHex(7,p7_10_17_20,vertexV);
                testTrueHex(10,p7_10_17_20,vertexV);
                testTrueHex(17,p7_10_17_20,vertexV);
                testTrueHex(20,p7_10_17_20,vertexV);

                testTrueHex(19,p19_22_29_32,vertexV);
                testTrueHex(22,p19_22_29_32,vertexV);
                testTrueHex(29,p19_22_29_32,vertexV);
                testTrueHex(32,p19_22_29_32,vertexV);
            }
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		override public function setTopHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
            if (vertices == 4) {
                testTrueHex(16,colorHex,vertexV);
			    testTrueHex(17,colorHex,vertexV);
            } else gradientSide9Quad(colorHex,true,true,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
        private function gradientSide9Quad(sameColor:uint,vertical:Boolean,descending:Boolean,testV:Vector.<uint>):void {
            var sameAddend:uint, oppositeAddend:uint,
                outerMult:uint, innerMult:uint;
            var ratio1:Number, ratio2:Number;
            var interpolate:Function;
            if (vertical) {
                outerMult = 1;
                innerMult = 6;
                ratio1 = row0_1;
                ratio2 = row1_2;
            } else {
                outerMult = 6;
                innerMult = 1;
                ratio1 = col0_1;
                ratio2 = col1_2;
            }
            if (descending) {
                interpolate = Color.interpolate;
                if (vertical) oppositeAddend = 30;
                else oppositeAddend = 5;
            } else {
                interpolate = ApertureUtils.reverseInterpolate;
                if (vertical) sameAddend = 30;
                else sameAddend = 5;
            }
            for (var i:uint=0; i<6; i++) {
                const sameIndex:uint = i * outerMult + sameAddend;
                testTrueHex(index9QuadV[sameIndex],sameColor,testV);
                const oppositeIndex:uint = i * outerMult + oppositeAddend;
                var oppositeColor:uint = getHex(index9QuadV[oppositeIndex]);
                for (var j:uint=1; j<=4; j++) {
                    const innerIndex:uint = i*outerMult + j*innerMult;
                    const ratio:Number = j < 3 ? ratio1 : ratio2;
                    testTrueHex(index9QuadV[innerIndex],interpolate(sameColor,oppositeColor,ratio),testV);
                }
            }
        }
		override public function setBottomHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
            if (vertices == 4) {
                testTrueHex(18,colorHex,vertexV);
			    testTrueHex(19,colorHex,vertexV);
            } else gradientSide9Quad(colorHex,true,false,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		override public function setLeftHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
            if (vertices == 4) {
                testTrueHex(16,colorHex,vertexV);
			    testTrueHex(18,colorHex,vertexV);
            } else gradientSide9Quad(colorHex,false,true,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		override public function setRightHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
            if (vertices == 4) {
                testTrueHex(17,colorHex,vertexV);
			    testTrueHex(19,colorHex,vertexV);
            } else gradientSide9Quad(colorHex,false,false,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
        override public function dispose():void {
            Pool.putRectangle(scale9Grid);
            scale9Grid = null;
            super.dispose();
        }
    }

}
