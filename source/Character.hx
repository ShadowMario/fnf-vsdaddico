package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSort;
import Section.SwagSection;

using StringTools;

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		var library:String = null;
		switch (curCharacter)
		{
			case 'gf':
				// GIRLFRIEND CODE
				frames = Paths.getSparrowAtlas('characters/GF_assets');
				quickAnimAdd('cheer', 'GF Cheer');
				quickAnimAdd('singLEFT', 'GF left note');
				quickAnimAdd('singRIGHT', 'GF Right Note');
				quickAnimAdd('singUP', 'GF Up Note');
				quickAnimAdd('singDOWN', 'GF Down Note');
				animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
				animation.addByPrefix('scared', 'GF FEAR', 24);

				playAnim('danceRight');

			case 'pico':
				frames = Paths.getSparrowAtlas('characters/Daddico');
				quickAnimAdd('idle', "Pico Idle Dance");
				quickAnimAdd('singUP', 'pico Up note0');
				quickAnimAdd('singDOWN', 'Pico Down Note0');
				if (isPlayer)
				{
					quickAnimAdd('singLEFT', 'Pico NOTE LEFT0');
					quickAnimAdd('singRIGHT', 'Pico Note Right0');
				}
				else
				{
					// Need to be flipped! REDO THIS LATER!
					quickAnimAdd('singLEFT', 'Pico Note Right0');
					quickAnimAdd('singRIGHT', 'Pico NOTE LEFT0');
				}

				quickAnimAdd('singUPmiss', 'pico Up note miss');
				quickAnimAdd('singDOWNmiss', 'Pico Down Note MISS');

				playAnim('idle');

				flipX = true;

			case 'bf':
				frames = Paths.getSparrowAtlas('characters/BOYFRIEND', 'preload');
				quickAnimAdd('idle', 'BF idle dance');
				quickAnimAdd('singUP', 'BF NOTE UP0');
				quickAnimAdd('singLEFT', 'BF NOTE LEFT0');
				quickAnimAdd('singRIGHT', 'BF NOTE RIGHT0');
				quickAnimAdd('singDOWN', 'BF NOTE DOWN0');
				quickAnimAdd('singUPmiss', 'BF NOTE UP MISS');
				quickAnimAdd('singLEFTmiss', 'BF NOTE LEFT MISS');
				quickAnimAdd('singRIGHTmiss', 'BF NOTE RIGHT MISS');
				quickAnimAdd('singDOWNmiss', 'BF NOTE DOWN MISS');
				quickAnimAdd('hey', 'BF HEY');

				quickAnimAdd('firstDeath', "BF dies");
				animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
				quickAnimAdd('deathConfirm', "BF Dead confirm");

				animation.addByPrefix('scared', 'BF idle shaking', 24, true);

				playAnim('idle');
				library = 'preload';

				flipX = true;
		}
		loadOffsetFile(curCharacter, library);

		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}
	}

	override function update(elapsed:Float)
	{
		if(!debugMode)
		{
			if(heyTimer > 0) {
				heyTimer -= elapsed;
				if(heyTimer <= 0) {
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer') {
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished) {
				specialAnim = false;
				dance();
			}
		}

		if (!curCharacter.startsWith('bf') || !isPlayer)
		{
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (curCharacter == 'pico')
				dadVar = 6.1;
			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
			{
				dance();
				holdTimer = 0;
			}
		}

		switch (curCharacter)
		{
			case 'gf':
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playAnim('danceRight');
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !specialAnim)
		{
			switch (curCharacter)
			{
				case 'gf':
					if (!animation.curAnim.name.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				default:
					playAnim('idle');
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	function loadOffsetFile(fileName:String, library:String = null)
	{
		var file:Array<String> = CoolUtil.coolTextFile(Paths.getPath('images/characters/' + fileName + 'Offsets.txt', TEXT, library));
		for (i in 0...file.length) {
			var offset:Array<String> = file[i].split(' ');
			addOffset(offset[0], Std.parseInt(offset[1]), Std.parseInt(offset[2]));
		}
	}
}