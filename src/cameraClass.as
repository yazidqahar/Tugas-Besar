    /**
     * @author	Kai Kajus Noack
     *             		http://media-it.blogspot.com
     * @version	0.1 (July 2008)
     * 
     * Copyright (c) 2008 Kai Kajus Noack. All rights reserved.
     * 
     * Licensed under the CREATIVE COMMONS Attribution-NonCommercial-ShareAlike 2.0 you may not use this
     * file except in compliance with the License. You may obtain a copy of the License at:
     * http://creativecommons.org/licenses/by-nc-sa/2.0/de/deed.en
     * 
     */

package {
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.media.Camera;
	import flash.media.Video;

	public class cameraClass extends Sprite {
		public var camVideo:Video;
		public var camera:Camera;

		public function cameraClass(width:int, height:int) {
			camera = Camera.getCamera("1");
			
			//camera.addEventListener(ActivityEvent.ACTIVITY,activated);
			if (camera != null) {
				camVideo = new Video(width, height);// camera.width * 2, camera.height * 2);
				camVideo.attachCamera(camera);
				//addChild(camVideo);
				camera.setMode(width, height, 15); // 15 FPS
			} else {
				trace("Please connect a camera to the computer.");
			}
		}
	}
}