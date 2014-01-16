// Edge Detection in ActionScript 3
// Author: Alex Petrescu (alex.petrescu@gmail.com)
// http://www.Kilometer0.com
// Based on techniques from Canny Edge Detection Tutorial at http://www.pages.drexel.edu/~weg22/can_tut.html
// No Usage or Copy Restriction, just let me know if you found it helpful.


var myGausianFilter:ConvolutionFilter = new ConvolutionFilter(5,5,
[ 2,4,5,4,2,
  4,9,12,9,4,
  5,12,15,12,5,
  4,9,12,9,4,
  2,4,5,4,2],115);

// Original Data
var ourData:BitmapData;

// Edge Data
var ourEdgeData:BitmapData

// myLinkage is a string that represents a BitmapData class (the linkage name of your bitmap in your library)
function findEdges(myLinkage:String):void
{	
	var myClass:Class = flash.utils.getDefinitionByName(myLinkage) as Class;
	ourData = new myClass(0,0);
	
	//Apply Smoothing Filter
	ourData.applyFilter(ourData,ourData.rect,new Point(0,0),myGausianFilter);
	
	//Create New Bitmap to hold edge data
	ourEdgeData = new BitmapData(ourData.width, ourData.height, false);
	
	//Loop through original data and calculate edges
	for(var w:int = 0; w<ourData.width; w++)
	{
		for(var h:int = 0; h<ourData.height; h++)
		{
			var pixelValue0:uint = getGray(ourData.getPixel(w, h-1));
			var pixelValue45:uint = getGray(ourData.getPixel(w+1, h-1));
			var pixelValue90:uint = getGray(ourData.getPixel(w+1, h));
			var pixelValue135:uint = getGray(ourData.getPixel(w+1, h+1));
			var pixelValue180:uint = getGray(ourData.getPixel(w, h+1));
			var pixelValue225:uint = getGray(ourData.getPixel(w-1, h+1));
			var pixelValue270:uint = getGray(ourData.getPixel(w-1, h));			
			var pixelValue315:uint = getGray(ourData.getPixel(w-1, h-1));		
			
			// Applying the following convolution mask matrix to the pixel
			//    GX        GY  
			// -1, 0, 1   1, 2, 1
			// -2, 0, 2   0, 0, 0
			// -1, 0, 1  -1,-2,-1
			
			var gx:int = (pixelValue45 + (pixelValue90 * 2) + pixelValue135)-(pixelValue315 + (pixelValue270 * 2) + pixelValue225);
			var gy:int = (pixelValue315 + (pixelValue0 * 2) + pixelValue45)-(pixelValue225 + (pixelValue180 * 2 ) + pixelValue135);
						
			var gray:uint = Math.abs(gx) + Math.abs(gy);
			
			// Decrease the grays a little or else its all black and white.
			// You can play with this value to get harder or softer edges.
			gray *= .5;
			
			// Check to see if values aren't our of bounds
			if(gray > 255)
				gray = 255;
				
			if(gray < 0)
				gray = 0;
	
			// Build New Pixel
			var newPixelValue:uint = (gray << 16) + (gray << 8) + (gray);
			
			// Copy New Pixel Into Edge Data Bitmap
			ourEdgeData.setPixel(w,h,newPixelValue);	
		}	
	}
}


function getGray(pixelValue:uint):uint
{
	var red:uint = (pixelValue >> 16 & 0xFF) * 0.30;
	var green:uint = (pixelValue >> 8 & 0xFF) * 0.59;
	var blue:uint = (pixelValue & 0xFF) * 0.11;

	return (red + green + blue);
}