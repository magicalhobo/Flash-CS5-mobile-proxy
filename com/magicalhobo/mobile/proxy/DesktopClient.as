package com.magicalhobo.mobile.proxy
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.sensors.*;
	import flash.utils.*;
	
	public class DesktopClient
	{
		private var stage:Stage;
		private var host:String;
		private var port:int;
		private var snapshotInterval:Number;
		private var snapshotScale:Number;
		
		private var server:ServerSocket;
		private var client:Socket;
		private var frameCounter:int;
		private var accelerometer:Accelerometer;
		private var geolocation:Geolocation;
		
		private var nextType:uint;
		private var nextLength:uint;
		
		public function DesktopClient(stage:Stage, accelerometer:Accelerometer, geolocation:Geolocation,
			  host:String = '192.168.2.2', port:int = 8087, snapshotInterval:Number = 0.5, snapshotScale:Number = 0.5)
		{
			this.stage = stage;
			this.accelerometer = accelerometer;
			this.geolocation = geolocation;
			this.host = host;
			this.port = port;
			this.snapshotInterval = snapshotInterval;
			this.snapshotScale = snapshotScale;
			
			frameCounter = 0;
			server = new ServerSocket();
			
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			server.addEventListener(ServerSocketConnectEvent.CONNECT, connectHandler);
			server.addEventListener(Event.CLOSE, closeHandler);
			
			server.bind(port, host);
			server.listen();
		}
		
		private function enterFrameHandler(ev:Event):void
		{
			if(client && client.connected)
			{
				frameCounter++;
				if(frameCounter >= stage.frameRate * snapshotInterval)
				{
					var snapshotWidth:Number = stage.stageWidth * snapshotScale;
					var snapshotHeight:Number = stage.stageHeight * snapshotScale;
					var bitmapData:BitmapData = new BitmapData(snapshotWidth, snapshotHeight, false, 0xFFFFFFFF);
					var transform:Matrix = new Matrix();
					transform.scale(snapshotScale, snapshotScale);
					bitmapData.draw(stage, transform);
					var bytes:ByteArray = bitmapData.getPixels(new Rectangle(0, 0, snapshotWidth, snapshotHeight));
					bytes.compress();
					
					if(client)
					{
						var data:ProxyData = new ProxyData(ProxyData.STAGE_SNAPSHOT, {scale: snapshotScale, bytes: bytes});
						data.write(['scale', 'bytes'], client);
						client.flush();
					}
					
					frameCounter = 0;
				}
			}
		}
		
		private function connectHandler(ev:ServerSocketConnectEvent):void
		{
			if(client)
			{
				client.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
				try
				{
					client.close();
				}
				catch(e:Error){}
			}
			client = ev.socket;
			client.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}
		
		private function closeHandler(ev:Event):void
		{
			client = null;
		}
		
		private function socketDataHandler(ev:ProgressEvent):void
		{
			var socket:Socket = ev.currentTarget as Socket;
			
			while(socket.bytesAvailable > 0)
			{
				if(!nextType && socket.bytesAvailable >= 1)
				{
					nextType = socket.readUnsignedByte();
				}
				if(!nextLength && socket.bytesAvailable >= 4)
				{
					nextLength = socket.readUnsignedInt();
				}
				if(nextLength && socket.bytesAvailable >= nextLength)
				{
					var info:Object;
					
					switch(nextType)
					{
						case ProxyData.ACCELEROMETER_EVENT:
							info = socket.readObject();
							simulateAccelerometer(info.type,
												  info.timestamp,
												  info.accelerationX,
												  info.accelerationY,
												  info.accelerationZ);
							break;
						case ProxyData.GEOLOCATION_EVENT:
							info = socket.readObject();
							simulateGeolocation(info.type,
												info.latitude,
												info.longitude,
												info.altitude,
												info.horizontalAccuracy,
												info.verticalAccuracy,
												info.speed,
												info.heading,
												info.timestamp);
							break;
						case ProxyData.TOUCH_EVENT:
							info = socket.readObject();
							simulateTouch(info.type,
										  info.touchPointID,
										  info.isPrimaryTouchPoint,
										  info.stageX,
										  info.stageY);
							break;
						case ProxyData.UNCAUGHT_ERROR:
						default:
							var byteArray:ByteArray = new ByteArray();
							socket.readBytes(byteArray, 0, nextLength);
							break;
					}
					
					nextType = 0;
					nextLength = 0;
				}
				else
				{
					break;
				}
			}
		}
		
		public function simulateAccelerometer(type:String, timestamp:Number, accX:Number, accY:Number, accZ:Number):void
		{
			accelerometer.dispatchEvent(new AccelerometerEvent(type, false, false, timestamp, accX, accY, accZ));
		}
		
		public function simulateGeolocation(type:String, latitude:Number, longitude:Number, altitude:Number, hAccuracy:Number,
											vAccuracy:Number, speed:Number, heading:Number, timestamp:Number):void
		{
			geolocation.dispatchEvent(new GeolocationEvent(type, false, false, latitude, longitude, altitude, hAccuracy, vAccuracy, speed, heading, timestamp));
		}
		
		public function simulateTouch(type:String, touchPointID:int, isPrimaryTouchPoint:Boolean, stageX:Number, stageY:Number):void
		{
			var hitObjects:Array = stage.getObjectsUnderPoint(new Point(stageX, stageY));
			var target:InteractiveObject;
			while(hitObjects.length > 0 && !target)
			{
				target = hitObjects.pop() as InteractiveObject;
			}
			if(!target)
			{
				target = stage;
			}
			var local:Point = target.globalToLocal(new Point(stageX, stageY));
			target.dispatchEvent(new TouchEvent(type, true, false, touchPointID, isPrimaryTouchPoint, local.x, local.y));
		}
	}
}
