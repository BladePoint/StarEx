// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.utils {

	import flash.display.Bitmap;
    import flash.display.BitmapData;
	import flash.geom.ColorTransform;
    import starling.errors.AbstractClassError;
    import starling.utils.Color;
	public class BitmapUtils {
        static public const transparentGreenHex:uint = 0x0000ff00;
		static public function newBitmapData(w:uint,h:uint):BitmapData {
			return new BitmapData(w,h,true,transparentGreenHex);
		}
        static public function getWhiteTransform():ColorTransform {
            return new ColorTransform(0,0,0,1,255,255,255,0);
        }
        static public function getDistanceFieldSquare9x9():BitmapData {
            var bitmapData:BitmapData = newBitmapData(9,9);
            var x:int, y:int;
            var row:Array;
            var color:uint, mirror:uint;
            const hexA:Array = [[0xff151515,0xff401515,0xff6a1515,0xff951515,0xffc01515],
                                [0xff154015,0xff404040,0xff6a4040,0xff954040,0xffc04040],
                                [0xff156a15,0xff406a40,0xff6a6a6a,0xff956a6a,0xffc06a6a],
                                [0xff159515,0xff409540,0xff6a956a,0xff959595,0xffc09595],
                                [0xff15c015,0xff40c040,0xff6ac06a,0xff95c095,0xffc0c0c0]];
            for (y=3; y>=0; y--) {
                row = hexA[y];
                const newRow:Array = [];
                for (x=0; x<5; x++) {
                    color = row[x];
                    if (x > 0) {
                        const a:int = Color.getAlpha(color),
                            r:int = Color.getRed(color),
                            g:int = Color.getGreen(color),
                            b:int = Color.getBlue(color);
                        mirror = Color.argb(a,b,g,r);
                    } else mirror = color;
                    newRow[newRow.length] = mirror;
                }
                hexA[hexA.length] = newRow;
            }
            for (y=0; y<9; y++) {
                row = hexA[y];
                for (x=3; x>=0; x--) {
                    color = row[x];
                    row[row.length] = color;
                }
            }
            for (y=0; y<9; y++) {
                row = hexA[y];
                for (x=0; x<9; x++) {
                    color = row[x];
                    bitmapData.setPixel32(x,y,color);
                }
            }
            return bitmapData;
        }
        static public function getSquare1x1():BitmapData {
            return new BitmapData(1,1,false,0xffffff);
        }
        static public function bitmapDataFromClass(BitmapClass:Class):BitmapData {
			const bitmap:Bitmap = new BitmapClass();
			const bitmapData:BitmapData = bitmap.bitmapData;
			bitmap.bitmapData = null;
			return bitmapData;
		}

		public function BitmapUtils() {throw new AbstractClassError();}
	}

}