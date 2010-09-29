package
{
	import com.magicalhobo.mobile.proxy.*;
	import flash.display.*;
	import flash.events.*;
	import flash.sensors.*;
	
	public class Painting extends MovieClip
	{
		private var canvas:MovieClip;
		private var ballContainer:MovieClip;
		private var ball:Sprite;
		
		private var isDragging:Boolean;
		private var ballSize:Number = 20;
		
		private var ioProxy:DesktopClient;
		private var accelerometer:Accelerometer;
		private var geolocation:Geolocation;
		
		public function Painting()
		{
			canvas = new MovieClip();
			addChild(canvas);
			
			ballContainer = new MovieClip();
			addChild(ballContainer);
			
			ball = new Sprite();
			ball.graphics.beginFill(0x000000);
			ball.graphics.drawCircle(ballSize, ballSize, ballSize);
			ball.graphics.endFill();
			ballContainer.addChild(ball);
			
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler);
			stage.addEventListener(TouchEvent.TOUCH_TAP, touchTapHandler);
			
			accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE, accUpdateHandler);
			
			geolocation = new Geolocation();
			geolocation.addEventListener(GeolocationEvent.UPDATE, geoUpdateHandler);
			
			//Not sure how to test this
			var runningOnDesktop:Boolean = true;
			
			if(runningOnDesktop)
			{
				ioProxy = new DesktopClient(stage, accelerometer, geolocation, '192.168.2.2', 8087, 0.1, .5);
			}
		}
		private function accUpdateHandler(ev:AccelerometerEvent):void
		{
			if(!isDragging)
			{
				ball.x += ev.accelerationX * 10;
				ball.y -= ev.accelerationY * 10;
				ball.x = Math.max(0, Math.min(ball.x, stage.stageWidth - ballSize * 2));
				ball.y = Math.max(0, Math.min(ball.y, stage.stageHeight - ballSize * 2));
			}
		}
		private function geoUpdateHandler(ev:GeolocationEvent):void
		{
			trace('GeolocationEvent: '+ev);
		}
		private function touchBeginHandler(ev:TouchEvent):void
		{
			isDragging = true;
			canvas.graphics.lineStyle(2, Math.floor(Math.random() * 0xFFFFFF));
			canvas.graphics.moveTo(ev.stageX, ev.stageY);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler);
			stage.addEventListener(TouchEvent.TOUCH_END, touchEndHandler);
		}
		private function touchMoveHandler(ev:TouchEvent):void
		{
			ball.x = ev.stageX - ball.width/2;
			ball.y = ev.stageY - ball.height/2;
			canvas.graphics.lineTo(ev.stageX, ev.stageY);
		}
		private function touchEndHandler(ev:TouchEvent):void
		{
			stage.removeEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler);
			stage.removeEventListener(TouchEvent.TOUCH_END, touchEndHandler);
			isDragging = false;
		}
		private function touchTapHandler(ev:TouchEvent):void
		{
			canvas.graphics.beginFill(0x000000);
			canvas.graphics.drawCircle(ev.stageX, ev.stageY, 4);
			canvas.graphics.endFill();
		}
	}
}
