package com.magicalhobo.mobile.proxy
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.describeType;

	public class ProxyData
	{
		public static const ACCELEROMETER_EVENT:uint	 = 1;
		public static const GEOLOCATION_EVENT:uint		 = 2;
		public static const TOUCH_EVENT:uint			 = 3;
		
		public static const STAGE_SNAPSHOT:uint			 = 101;
		
		public static const UNCAUGHT_ERROR:uint			 = 201;
		
		private var type:uint;
		private var object:*;
		
		public function ProxyData(type:uint, object:*)
		{
			this.type = type;
			this.object = object;
		}
		
		public function write(properties:Array, socket:Socket):void
		{
			var serialized:Object = new Object();
			
			for each(var property:String in properties)
			{
				serialized[property] = object[property];
			}
			
			var buffer:ByteArray = new ByteArray();
			buffer.writeObject(serialized);
			
			socket.writeByte(type);
			socket.writeUnsignedInt(buffer.length);
			socket.writeBytes(buffer);
		}
	}
}