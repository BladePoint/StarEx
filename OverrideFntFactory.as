// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.assets {

    import flash.utils.ByteArray;
    import starling.assets.AssetFactory;
    import starling.assets.AssetFactoryHelper;
    import starling.assets.AssetReference;
    import starEx.utils.PoolEx;
    //This AssetFactory overrides the default handling of FNT files.
    public class OverrideFntFactory extends AssetFactory {

        public function OverrideFntFactory() {
            addExtensions("fnt");
            addMimeTypes("application/xml","text/xml");
        }
        override public function canHandle(reference:AssetReference):Boolean {
            var extension:String = reference.extension;
            var extensions:Vector.<String> = PoolEx.getStringV();
            getExtensions(extensions);
            const boolean:Boolean = reference.data is ByteArray && extension && extensions.indexOf(extension.toLowerCase()) != -1
            PoolEx.putStringV(extensions);
            return boolean;
        }
         /** Creates the XML asset and passes it to 'onComplete'. */
        override public function create(reference:AssetReference,helper:AssetFactoryHelper,onComplete:Function,onError:Function):void {
            var xml:XML = reference.data as XML;
            var bytes:ByteArray = reference.data as ByteArray;
            if (bytes) {
                try {
                    xml = new XML(bytes);
                } catch (e:Error) {
                    onError("Could not parse XML: " + e.message);
                    return;
                }
            }
            onComplete(reference.name,xml);
            reference.data = bytes = null; //prevent closures from keeping references
        }
    }

}