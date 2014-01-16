    /**
     * @author	Kai Kajus Noack
     * http://media-it.blogspot.com
	 * 
     * @version	0.1 (July 2009)
     * 
     * Licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 
	 * You may not use this file except in compliance with the License:
	 * http://creativecommons.org/licenses/by-nc-sa/3.0/
     * 
     */
	
package 
{
	import com.flashandmath.bitmaps.BitmapTransformer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ActivityEvent; 
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.ObjectEncoding;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
	import flash.events.NetStatusEvent;
	import flash.net.URLLoader;
	import flash.display.SimpleButton;
	
	import jp.maaash.ObjectDetection.ObjectDetector;
	import jp.maaash.ObjectDetection.ObjectDetectorEvent;
	import jp.maaash.ObjectDetection.ObjectDetectorOptions;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.objects.parsers.Collada;
	import org.papervision3d.render.BasicRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	
	
	
	
	//swf-data
	[SWF(width="640", height="480", frameRate="15")]
	 
	public class Main extends Sprite 
	{
		private var scene:Scene3D;
		private var sceneWidth:int;
		private var sceneHeight:int;
		private var vp:Viewport3D;
		private var cam:Camera3D;
		private var bre:BasicRenderEngine;
		private var collada:Collada;
		private var webcam:cameraClass;
		private var video:Video;
		private var bmpdFromVideo:BitmapData;
		private var bmpFromVideo:Bitmap;
		private var intervallToFetch:int; // in milliseconds
		
		// detector objects
		private var detector:ObjectDetector;
		private var options:ObjectDetectorOptions;
		private var detectionMap:BitmapData;
		private var drawMatrix:Matrix;
		private var scaleFactor:int = 4; // scales video-image which is processed by marilena
		private var faceRectContainer:Sprite;
		private var graph:Graphics;
		
		private var HeadCenterX:Number;
		private var HeadCenterY:Number;

		private var rollEnabled:Boolean;
		
		private var view :Sprite;
		//Embed(source='..\bin\japanes.png')
		private var pigNose:Class;
		private var pigBMP:Bitmap;
		var myLoader:Loader = new Loader();
		var myText:TextField = new TextField();
		var lastWidth:Number = 0;
		var gagal:Number = 0;
		var fileRequest:URLRequest;
		var dataText:String;
		var xRef:Number;
		var yRef:Number;
		var widthRef:Number;
		var heightRef:Number;
		
		public function Main():void 
		{
			xRef = 75; 
			yRef = 250;
			widthRef = 447;
			heightRef = 393;
			
			sceneWidth = 640;
			sceneHeight = 480;
			intervallToFetch = 1; // about 15fps
			faceRectContainer = new Sprite;
			rollEnabled = false;
			
			// webcamera + video
			webcam = new cameraClass(sceneWidth, sceneHeight);
			video = webcam.camVideo;
			
			if(video == null) {
				// no webcam found
				trace("NO WEBCAM!!");
				var myText:TextField = new TextField();
				myText.text = "Please CONNECT your WEBCAM and TRY AGAIN";
				myText.width = 350;
				myText.height = 100;
				myText.x = 180;
				myText.y = 220;
				myText.selectable = false;
				addChild(myText);
			}
			else {
				// webcam available
				video.addEventListener(Event.ACTIVATE, initWebcam);
				video.x = video.y = 0;
				addChild(video);
				
				
				// bitmap for processing the video image
				bmpdFromVideo = new BitmapData(video.width, video.height, false);
				///bmpFromVideo = new Bitmap(bmpdFromVideo);
				///bmpFromVideo.x = 10; bmpFromVideo.y = 30;
				// initiate the image-processing-class, pass video-data for special processings
				// var imgProc:imageClassOpt = new imageClassOpt(video.width, video.height);
				
				//detection stuff
				detectionMap = new BitmapData(sceneWidth/scaleFactor, sceneHeight/scaleFactor, false, 0);
				drawMatrix = new Matrix(1/scaleFactor, 0, 0, 1/scaleFactor);
				initDetector();
				
				var update:URLRequest = new URLRequest("update.png");
				var updateLoader:Loader = new Loader();
				updateLoader.load(update);
				updateLoader.addEventListener(MouseEvent.CLICK,changeData);
				addChild(updateLoader);
				
				

				fileRequest = new URLRequest("europe.png");
				myLoader.load(fileRequest);
				addChild(myLoader);
				
				addChild(faceRectContainer);
				
				
				setupPV3D();
				/*
				addCollada();
				
				addEventListener(Event.ENTER_FRAME, loop);
				
				addEventListener(MouseEvent.CLICK, mouseClicked);
				*/
				
				//collada = new Collada("cow.dae"); 
				//scene.addChild(collada);
				
				addEventListener(Event.ENTER_FRAME, loop);
				
				//addEventListener(MouseEvent.CLICK, mouseClicked);
				
			}
		}
		
		private function changeData(e:MouseEvent):void{
			var my_req:URLRequest = new URLRequest("conf.txt");
			var my_loader:URLLoader = new URLLoader();
			
			my_loader.addEventListener(Event.COMPLETE, loadText);
			my_loader.load(my_req);
			function loadText(event:Event):void {
				dataText = my_loader.data;
				var tempArray:Array = dataText.split(";");
				fileRequest = new URLRequest(tempArray[4]);
				myLoader.load(fileRequest);
				addChild(myLoader);
				xRef = tempArray[0]; 
				yRef = tempArray[1];
				widthRef = tempArray[2];
				heightRef = tempArray[3];
				dataText += " | x : " + tempArray[0] + " | y : " + tempArray[1] + " | width : " + tempArray[2] + " | height : " + tempArray[3];
			}
			
			
			
		}
		
		private function initDetector():void {
			detector = new ObjectDetector();
			var options:ObjectDetectorOptions = new ObjectDetectorOptions();
			options.min_size  = 30;
			detector.options = options;
			detector.addEventListener(ObjectDetectorEvent.DETECTION_COMPLETE, detectionHandler);
		}

		private function detectionHandler(e:ObjectDetectorEvent):void {
			e.rects.forEach( function( r:Rectangle, idx :int, arr :Array ) :void {
				if(Math.abs(r.width - lastWidth) < 5  || lastWidth == 0 || gagal > 10){
					gagal = 0;
					// clear current face rectangle on screen
					graph = faceRectContainer.graphics;
					graph.clear();
					
					//removeChild(myText);
					// get detected face as rectangle/s from ObjectDetectorEvent
					if( e.rects ){
						graph.lineStyle(2, 128);
						// iterate over face rectangles
						e.rects.forEach( function( r:Rectangle, idx :int, arr :Array ) :void {
							lastWidth = r.width;
							// draw rectangle around detected face (mirrored)
							
							/*
							// get head center
							HeadCenterX = sceneWidth-(r.width / 2  + r.x) * scaleFactor;
							HeadCenterY = (r.height / 2 + r.y) * scaleFactor;
							// position collada object in center of face (mirrored)
							//myLoader.x = -sceneWidth / 2 + HeadCenterX;
							// 40 to position cow on user's eyes, last value should be calculated by height of collada-object
							//myLoader.y = sceneHeight / 2 - HeadCenterY - 40;
							
							myLoader.x = sceneWidth-(r.width+r.x)*scaleFactor-35;
							myLoader.y = (r.y*scaleFactor)-125;
							myLoader.width = r.width * scaleFactor + 70;
							myLoader.height = r.height*scaleFactor;
							*/
							
							//r.x = 50; r.y = 50; r.width = 75.75; r.height = 75.75
							graph.drawRect(sceneWidth-(r.width+r.x)*scaleFactor, r.y*scaleFactor, r.width*scaleFactor, r.height*scaleFactor);
							//myText.text = "r.x = "+(sceneWidth-(r.width+r.x)*scaleFactor) + " | r.y = "+(r.y*scaleFactor)+" | r.width = "+(r.width * scaleFactor)+" | r.height = "+(r.height * scaleFactor);
							myText.width = 350;
							myText.height = 100;
							myText.x = 180;
							myText.y = 220;
							myText.selectable = false;
							
							
							/* var MaskSX:Number = (r.width * scaleFactor)*2
							var MaskSY:Number = (r.height * scaleFactor)*2
							var MaskX:Number = 0
							var MaskY:Number = 0
							var HeadCenterX:Number = ((r.width / 2 )* scaleFactor) + (r.x * scaleFactor)
							var HeadCenterY:Number = ((r.height / 2 )* scaleFactor) + (r.y * scaleFactor)
							myLoader.x = HeadCenterX - (MaskSX / 2)
							myLoader.y = HeadCenterY - (MaskSY / 2)
							myLoader.width = MaskSX/2
							myLoader.height = MaskSY/2;*/
							
							var lebarPatung = 303;
							var kalibrasiX:Number = xRef * ((r.width * scaleFactor)/lebarPatung);
							var kalibrasiY:Number = yRef * ((r.width * scaleFactor)/lebarPatung);
							//myText.text += " | kalibrasiX = " + kalibrasiX + " | kalibrasiY = " + kalibrasiY;
							myLoader.x = (sceneWidth-(r.width+r.x)*scaleFactor)-(kalibrasiX);
							myLoader.y = (r.y*scaleFactor)-(kalibrasiY);
							myLoader.width = widthRef * ((r.width * scaleFactor)/lebarPatung);//r.width * scaleFactor + (kalibrasiX*2);
							myLoader.height = heightRef * ((r.width * scaleFactor)/lebarPatung);//r.height*scaleFactor;						
							myText.text = " | kalibrasiX = " + kalibrasiX + " | kalibrasiY = " + kalibrasiY;
							//addChild(myText);
						});
					}
					// mouse rotation for collada-object
					collada.rotationY = 155 - ((mouseX / stage.width) * 140); //Rotation //*360
					// additional roll of collada-object (enabled by mouseclick on object)
					if (rollEnabled) {
						collada.roll(20 - ((mouseY / stage.height) * 60));
					}
				}else {
					gagal++;
				}
			});
			
		}
		
		private function initWebcam(e:Event):void {
			trace("#INIT\nVideo started:",e,"\n");
			video.removeEventListener(Event.ACTIVATE, init);
			webcam.camera.addEventListener(ActivityEvent.ACTIVITY, activated);
			
			// mirror the video
			var ma:Matrix = video.transform.matrix;
			// flip horizontal assuming that scaleX is currently 1
			ma.a = -1;
			// apply the mirror matrix to the display object
			ma.tx = video.width;// +video.x;
			video.transform.matrix = ma;
		}

		private function activated(e:Event):void {
			if (e.type == "activity") {
				webcam.camera.removeEventListener(ActivityEvent.ACTIVITY, activated);
				// timer that fetches the webcam image for processing
				startTimer();
			}
		}
		
		private function startTimer():void {
			var myTimer:Timer = new Timer(intervallToFetch);
			myTimer.addEventListener("timer", getAndDetectCamImage);
			myTimer.start();
		}
		
		private function getAndDetectCamImage(e:Event):void {
			// receive bitmapdata from video
			bmpdFromVideo.draw(video);
			// pass data to detector
			detectionMap.draw(bmpdFromVideo,drawMatrix,null,"normal",null,true);
			detector.detect(detectionMap);
		}
		
		private function addCollada():void 
		{
			// load collada object and add it to scene
			collada = new Collada("cow.dae"); 
			
			scene.addChild(collada);
		}
		
		private function loop(e:Event):void 
		{
			// rendering of 3d scene
			bre.renderScene(scene,cam,vp);
		}

		private function mouseClicked(m:MouseEvent):void 
		{
			rollEnabled = !rollEnabled;
		}
		
		private function setupPV3D():void 
		{
			// Papervision 3D inits
			scene = new Scene3D();
			cam = new Camera3D();
			cam.z = -400;
			vp = new Viewport3D();
			bre = new BasicRenderEngine();
			addChild(vp);
		}
		
	}
	
}
