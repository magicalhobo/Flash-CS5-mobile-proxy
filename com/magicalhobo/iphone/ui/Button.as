package com.magicalhobo.iphone.ui
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class Button extends Sprite
	{
		public static const TYPE_NORMAL:String = 'normal';
		public static const TYPE_CANCEL:String = 'cancel';
		
		public var label:TextField;
		public var background:MovieClip;
		public var cancelBackground:MovieClip;
		public var downBackground:MovieClip;
		
		public var type:String;
		
		public function Button()
		{
			background.visible = false;
			cancelBackground.visible = false;
			downBackground.visible = false;
			
			//addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			
			switch(type)
			{
				case TYPE_CANCEL:
					cancelBackground.visible = true;
					break;
				default:
					background.visible = true;
					break;
			}
		}
	}
}