package com.magicalhobo.mobile.proxy
{
	import flash.desktop.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.sensors.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;
	
	public class MobileClient extends Sprite
	{
		public var dialog:MovieClip;
		
		private var sharedObject:SharedObject;
		private var socket:Socket;
		private var accelerometer:Accelerometer;
		private var geolocation:Geolocation;
		private var snapshot:Bitmap;
		
		private var nextType:uint;
		private var nextLength:uint;
		private var lastScale:Number;
		
		public function MobileClient()
		{
			socket = new Socket();
			socket.addEventListener(Event.CONNECT,						 socketConnectHandler);
			socket.addEventListener(ProgressEvent.SOCKET_DATA,			 socketDataHandler);
			socket.addEventListener(Event.CLOSE,						 socketCloseHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR,				 socketErrorHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	 socketErrorHandler);
			
			snapshot = new Bitmap();
			
			accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE,	 accUpdateHandler);
			
			geolocation = new Geolocation();
			geolocation.addEventListener(GeolocationEvent.UPDATE,		 geoUpdateHandler);
			
			stage.addEventListener(TouchEvent.TOUCH_BEGIN,				 touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_MOVE,				 touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_END,				 touchHandler);
			stage.addEventListener(TouchEvent.TOUCH_TAP,				 touchHandler);
			
			dialog.button.addEventListener(MouseEvent.CLICK,			 clickHandler);
			dialog.input.label.addEventListener(FocusEvent.FOCUS_OUT,	 labelFocusOutHandler);
			
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, globalErrorHandler);
			
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			sharedObject = SharedObject.getLocal('settings');
			if(sharedObject.data['lastConnectionUrl'])
			{
				dialog.input.label.text = sharedObject.data['lastConnectionUrl'];
			}
			
			addChild(snapshot);
			showDialog(true);
		}
		
		private function globalErrorHandler(ev:UncaughtErrorEvent):void
		{
			try
			{
				ev.preventDefault();
				proxy(ProxyData.UNCAUGHT_ERROR, ev, ['type', 'error', 'errorID']);
			}
			catch(e:Error){}
		}
		
		private function clickHandler(ev:MouseEvent):void
		{
			var url:String = dialog.input.label.text;
			
			sharedObject.data['lastConnectionUrl'] = url;
			sharedObject.flush();
			
			var pieces:Array = url.split(':');
			if(pieces.length != 2)
			{
				return;
			}
			var host:String = pieces[0];
			var port:uint = pieces[1];
			
			showDialog(false);
			
			socket.connect(host, port);
		}
		
		private function labelFocusOutHandler(ev:FocusEvent):void
		{
			if(dialog.visible)
			{
				stage.focus = dialog.input.label;
			}
		}
		
		private function socketConnectHandler(ev:Event):void
		{
			showDialog(false);
		}
		
		private function socketDataHandler(ev:ProgressEvent):void
		{
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
						case ProxyData.STAGE_SNAPSHOT:
							info = socket.readObject();
							var scale:Number = info.scale;
							var bytes:ByteArray = info.bytes;
							bytes.uncompress();
							bytes.position = 0;
							
							if(scale != lastScale)
							{
								var snapshotWidth:int = stage.stageWidth * scale;
								var snapshotHeight:int = stage.stageHeight * scale;
								var bitmapData:BitmapData = new BitmapData(snapshotWidth, snapshotHeight, false, 0xFFFFFFFF);
								snapshot.bitmapData = bitmapData;
								snapshot.scaleX = 1/scale;
								snapshot.scaleY = 1/scale;
								lastScale = scale;
							}
							var bounds:Rectangle = new Rectangle(0, 0, snapshot.width, snapshot.height);
							snapshot.bitmapData.setPixels(bounds, bytes);
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
		
		private function socketCloseHandler(ev:Event):void
		{
			showDialog(true);
		}
		
		private function socketErrorHandler(ev:Event):void
		{
			if(!socket.connected)
			{
				showDialog(true);
			}
		}
		
		private function accUpdateHandler(ev:AccelerometerEvent):void
		{
			ev.stopPropagation();
			proxy(ProxyData.ACCELEROMETER_EVENT, ev, ['type',
													  'timestamp',
													  'accelerationX',
													  'accelerationY',
													  'accelerationZ']);
		}
		
		private function geoUpdateHandler(ev:GeolocationEvent):void
		{
			ev.stopPropagation();
			proxy(ProxyData.GEOLOCATION_EVENT, ev, ['type',
													'altitude',
													'heading',
													'latitude',
													'longitude',
													'speed',
													'timestamp',
													'horizontalAccuracy',
													'verticalAccuracy']);
		}
		
		private function touchHandler(ev:TouchEvent):void
		{
			ev.stopPropagation();
			proxy(ProxyData.TOUCH_EVENT, ev, ['type',
											  'touchPointID',
											  'isPrimaryTouchPoint',
											  'stageX',
											  'stageY']);
		}
		
		private function showDialog(visible:Boolean):void
		{
			if(visible)
			{
				dialog.visible = true;
				snapshot.visible = false;
				
				var label:TextField = TextField(dialog.input.label);
				label.setSelection(label.length, label.length);
				stage.focus = label;
			}
			else
			{
				dialog.visible = false;
				snapshot.visible = true;
			}
		}
		
		private function proxy(type:uint, object:Object, properties:Array):void
		{
			if(socket.connected)
			{
				var data:ProxyData = new ProxyData(type, object);
				data.write(properties, socket);
				socket.flush();
			}
		}
	}
}
