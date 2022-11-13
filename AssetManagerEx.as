// starEx - https://github.com/BladePoint/starEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/starEx/blob/main/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starEx.assets {

    import flash.filesystem.File;
    import starling.assets.AssetManager;
    import starling.assets.AssetType;
    import starling.events.Event;
    import starEx.utils.Utils;
    public class AssetManagerEx extends AssetManager {
        static public const JSON:String = "json",
            IAA:String = "iaa",
            MP3:String = "mp3";
        /*static private function manifestHandler(assetManager:AssetManager,manifestName:String):void {
            const manifestO:Object = assetManager.getObject(manifestName);
            for (var property:String in manifestO) {
                assetManager.enqueue(File.applicationDirectory.resolvePath("Assets/" + property));
                delete manifestO[property];
            }
            assetManager.removeObject(manifestName);
        }*/

        /*public var manifestPrepend:String,
            manifestAppend:String,
            manifestExtension:String;
        public var manifestHandler:Function;
        private var manifestName:String;
        private var manifestComplete:Function;*/
        public function AssetManagerEx(scaleFactor:Number=1) {
            super(scaleFactor);
        }
        /*public function loadManifest(name:String,onComplete:Function,onError:Function=null):void {
            manifestName = name;
            manifestComplete = onComplete;
            var url:String = manifestName + manifestExtension;
            if (manifestPrepend) url = manifestPrepend + url;
            if (manifestAppend) url = url + manifestAppend;
            enqueue(File.applicationDirectory.resolvePath(url));
            loadQueue(onLoadedManifest);
        }
        private function onLoadedManifest():void {
            manifestHandler(this,manifestName);
            manifestName = null;
            const onComplete:Function = manifestComplete;
            manifestComplete = null;
            loadQueue(onComplete);
        }*/
        public function typeFromExtension(filename:String):String {
            var type:String;
            const extension:String = getExtensionFromUrl(filename).toLowerCase();
            if (extension == MP3) return AssetType.SOUND;
            return type;
        }
        
    }

}