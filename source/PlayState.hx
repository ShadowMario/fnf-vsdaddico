package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.media.Video;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];
	private var psychicNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject; //Handles the new epic mega sexy cam code that i've done

	private static var prevCamFollow:FlxObject;
	private static var prevCamFollowPos:FlxObject;

	private var strumLineNotes:FlxTypedGroup<StrumNote>;
	private var playerStrums:FlxTypedGroup<StrumNote>;
	private var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:FlxSprite;
	private var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var endingSong:Bool = false;
	private var startingSong:Bool = false;
	public static var practiceMode:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var phillyBlack:FlxSprite;
	var phillyCityLightsEvent:FlxTypedGroup<FlxSprite>;
	var trainSound:FlxSound;

	var talking:Bool = true;
	var songScore:Int = 0;
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var scoreTxt:FlxText;
	var timeTxt:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var songLength:Float = 0;
	public static var displaySongName:String = "";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	override public function create()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		practiceMode = false;
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		// To avoid having duplicate images in Discord assets
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week 4";
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		
		// Updating Discord Rich Presence.
		var songName:String = SONG.song;
		displaySongName = StringTools.replace(songName, '-', ' ');
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad');
		#end

		//curStage = 'phillage';
		if(!ClientPrefs.lowQuality) {
			var bg:FlxSprite = new FlxSprite(-200, -100).loadGraphic(Paths.image('philly/sky'));
			bg.scrollFactor.set(0.1, 0.1);
			bg.antialiasing = ClientPrefs.globalAntialiasing;
			add(bg);
		}

		var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city'));
		city.scrollFactor.set(0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		city.antialiasing = ClientPrefs.globalAntialiasing;
		add(city);

		phillyCityLights = new FlxTypedGroup<FlxSprite>();
		add(phillyCityLights);

		for (i in 0...5)
		{
			var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i));
			light.scrollFactor.set(0.3, 0.3);
			light.visible = false;
			light.setGraphicSize(Std.int(light.width * 0.85));
			light.updateHitbox();
			light.antialiasing = ClientPrefs.globalAntialiasing;
			phillyCityLights.add(light);
		}

		if(!ClientPrefs.lowQuality) {
			var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain'));
			streetBehind.antialiasing = ClientPrefs.globalAntialiasing;
			add(streetBehind);
		}

		phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train'));
		phillyTrain.antialiasing = ClientPrefs.globalAntialiasing;
		add(phillyTrain);

		trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
		CoolUtil.precacheSound('train_passes');
		FlxG.sound.list.add(trainSound);

		if(!ClientPrefs.lowQuality) {
			var street:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/street'));
			add(street);
		}

		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = ClientPrefs.globalAntialiasing;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		add(stageFront);

		if(!ClientPrefs.lowQuality) {
			var stageCurtains:FlxSprite = new FlxSprite(-300, -220).loadGraphic(Paths.image('stagecurtains'));
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.8));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = ClientPrefs.globalAntialiasing;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;
			add(stageCurtains);
		}

		phillyBlack = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
		phillyBlack.alpha = 0;
		add(phillyBlack);

		phillyCityLightsEvent = new FlxTypedGroup<FlxSprite>();
		add(phillyCityLightsEvent);
		for (i in 0...5)
		{
			var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i));
			light.scrollFactor.set(0.3, 0.3);
			light.visible = false;
			light.setGraphicSize(Std.int(light.width * 0.85));
			light.updateHitbox();
			light.antialiasing = ClientPrefs.globalAntialiasing;
			phillyCityLightsEvent.add(light);
		}

		gf = new Character(400, 130, 'gf');
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 410, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x + 600, dad.getGraphicMidpoint().y - 310);

		boyfriend = new Boyfriend(770, 450, 'bf');
		add(gf);
		add(dad);
		add(boyfriend);

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(strumLine.x + (strumLine.width / 2) - 248, strumLine.y - 30, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 45;

		timeBarBG = new FlxSprite(timeTxt.x, timeTxt.y + (timeTxt.height / 4)).loadGraphic(Paths.image('timeBar'));
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		add(timeBar);
		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.89).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		add(scoreTxt);

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		startCountdown();
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');
		super.create();
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (curBeat % gfSpeed == 0)
			{
				gf.dance();
			}
			if(curBeat % 2 == 0) {
				if (!boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.specialAnim)
				{
					boyfriend.dance();
				}
				if (!dad.animation.curAnim.name.startsWith('sing'))
				{
					dad.dance();
				}
			}
			else if(dad.curCharacter == 'spooky' && !dad.animation.curAnim.name.startsWith("sing"))
			{
				dad.dance();
			}

			var introAlts:Array<String> = ['ready', 'set', 'go'];
			var antialias:Bool = ClientPrefs.globalAntialiasing;
			var altSuffix:String = "";

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					ready.screenCenter();
					ready.antialiasing = antialias;
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					set.screenCenter();
					set.antialiasing = antialias;
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					go.updateHitbox();

					go.screenCenter();
					go.antialiasing = antialias;
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;
	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad', true, songLength);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		#if sys
		try {
			var songName:String = SONG.song.toLowerCase();
			if(sys.FileSystem.exists('assets/data/' + songName + '/events.json')) {
				trace('Events file found!');
				var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
				for (section in eventsData)
				{
					for (songNotes in section.sectionNotes)
					{
						if(songNotes[1] < 0) {
							psychicNotes.push(songNotes);
						}
					}
				}
			}
		} catch(e:String) {
			trace('An error occured: ' + e);
		}
		#else //Hardcodes shit since HTML doesn't support sys and idk what to do :(
		var eventsData:Array<SwagSection> = Song.loadFromJson('events', SONG.song.toLowerCase()).notes;
		for (section in eventsData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] < 0) {
					psychicNotes.push(songNotes);
				}
			}
		}
		#end

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);

					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.sustainLength = songNotes[2];
					swagNote.altAnim = songNotes[3];
					swagNote.heyNote = songNotes[4];
					swagNote.scrollFactor.set(0, 0);

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					for (susNote in 0...Math.floor(susLength))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						sustainNote.mustPress = gottaHitNote;

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
					}

					swagNote.mustPress = gottaHitNote;

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else {}
				} else { //Event Notes
					psychicNotes.push(songNotes);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(psychicNotes.length > 1) { //No need to sort if there's a single one or none at all
			psychicNotes.sort(sortByTime);
		}
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:StrumNote = new StrumNote(STRUM_X, strumLine.y, i);

			babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.antialiasing = ClientPrefs.globalAntialiasing;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (Math.abs(i))
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}

			babyArrow.playAnim('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad', true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad');
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad', true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad');
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", 'dad');
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}

		if (trainMoving)
		{
			trainFrameTiming += elapsed;

			if (trainFrameTiming >= 1 / 24)
			{
				updateTrainPos();
				trainFrameTiming = 0;
			}
		}
		phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);

		if(ratingString == '?') {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingString;
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingString + ' (' + Math.floor(ratingPercent * 100) + '%)';
		}

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", 'dad');
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				var curTime:Float = FlxG.sound.music.time;
				if(curTime < 0) curTime = 0;
				songPercent = (curTime / songLength);

				if(!endingSong) {
					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					var minutesRemaining:Int = Math.floor(secondsTotal / 60);
					var secondsRemaining:String = '' + secondsTotal % 60;
					if(secondsRemaining.length < 2) secondsRemaining = '0' + secondsRemaining; //Dunno how to make it display a zero first in Haxe lol
					timeTxt.text = minutesRemaining + ':' + secondsRemaining;
				} else if(timeTxt != null) {
					timeTxt.text = '0:00';
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong)
		{
			moveCamera(Std.int(curStep / 16));
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);


		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}

		if (health <= 0 && !practiceMode)
		{
			boyfriend.stunned = true;
			deathCounter++;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, displaySongName + " (" + storyDifficultyText + ")", 'dad');
			#end
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				// i am so fucking sorry for this if condition
				var check:Float = strumLine.y + Note.swagWidth / 2;
				if (ClientPrefs.downScroll) {
					daNote.y = (strumLine.y + 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));
					if (daNote.isSustainNote) {
						if (daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null) {
							daNote.y += daNote.prevNote.height;
						} else {
							daNote.y += daNote.height / 2;
						}

						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= check
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (check - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				} else {
					daNote.y = (strumLine.y - 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));

					if (daNote.isSustainNote
						&& daNote.y + daNote.offset.y * daNote.scale.y <= check
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (check - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var isAlt:Bool = false;

					if(daNote.heyNote) {
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = 0.6;
					} else {
						var altAnim:String = "";

						if (SONG.notes[Math.floor(curStep / 16)] != null)
						{
							if (SONG.notes[Math.floor(curStep / 16)].altAnim || daNote.altAnim ||
							(daNote.isSustainNote && dad.curCharacter == 'psychic')) {
								altAnim = '-alt';
								isAlt = true;
							}
						}

						var animToPlay:String = '';
						switch (Math.abs(daNote.noteData))
						{
							case 0:
								animToPlay = 'singLEFT';
							case 1:
								animToPlay = 'singDOWN';
							case 2:
								animToPlay = 'singUP';
							case 3:
								animToPlay = 'singRIGHT';
						}

						if(altAnim == '' && dad.curCharacter == 'psychic' && dad.animation.curAnim.name.startsWith(animToPlay)) {
							altAnim = '-alt';
						}
						dad.playAnim(animToPlay + altAnim, true);
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					var time:Float = 0.15;
					if(daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
						time += 0.15;
					}
					DadStrumPlayAnim(daNote.noteData % 4, time);

					FlxTween.cancelTweensOf(daNote);
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				var doKill:Bool = daNote.y < -daNote.height;
				if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.tooLate || !daNote.wasGoodHit)
					{
						if(!endingSong) {
							health -= 0.0475; //For testing purposes
							songMisses++;
						}
						vocals.volume = 0;
						RecalculateRating();
					}

					daNote.active = false;
					daNote.visible = false;

					FlxTween.cancelTweensOf(daNote);
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}


		while(psychicNotes.length > 0) {
			if(Conductor.songPosition < psychicNotes[0][0]) {
				break;
			}

			var value1:String = '';
			if(psychicNotes[0][3] != null)
				value1 = psychicNotes[0][3];

			var value2:String = '';
			if(psychicNotes[0][4] != null)
				value2 = psychicNotes[0][4];

			switch(psychicNotes[0][2]) {
				case 'Hey!':
					var value:Int = Std.parseInt(value1);
					if(value != 0) {
						if(dad.curCharacter == 'gf') { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = 0.6;
						} else {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = 0.6;
						}
					}
					if(value != 1) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

				case 'Set GF Speed':
					var value:Int = Std.parseInt(value1);
					if(Math.isNaN(value)) value = 1;
					gfSpeed = value;

				case 'Blammed Lights':
					var lightId:Int = Std.parseInt(value1);
					if(Math.isNaN(lightId)) lightId = 0;

					if(lightId > 0 && curLightEvent != lightId) {
						if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

						var color:Int = 0xffffffff;
						switch(lightId) {
							case 1: //Blue
								color = 0xff31a2fd;
							case 2: //Green
								color = 0xff31fd8c;
							case 3: //Pink
								color = 0xfff794f7;
							case 4: //Red
								color = 0xfff96d63;
							case 5: //Orange
								color = 0xfffba633;
						}
						curLightEvent = lightId;

						if(phillyBlack.alpha != 1) {
							FlxTween.cancelTweensOf(phillyBlack);
							FlxTween.tween(phillyBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut});
							FlxTween.color(dad, 1, 0xffffffff, color, {ease: FlxEase.quadInOut});
							FlxTween.color(boyfriend, 1, 0xffffffff, color, {ease: FlxEase.quadInOut});
							FlxTween.color(gf, 1, 0xffffffff, color, {ease: FlxEase.quadInOut});
						} else {
							dad.color = color;
							boyfriend.color = color;
							gf.color = color;
						}

						phillyCityLightsEvent.forEach(function(spr:FlxSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.members[lightId - 1].visible = true;
						phillyCityLightsEvent.members[lightId - 1].alpha = 1;
					} else {
						if(phillyBlack.alpha != 0) {
							FlxTween.cancelTweensOf(phillyBlack);
							FlxTween.tween(phillyBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
						}

						phillyCityLights.forEach(function(spr:FlxSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:FlxSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							FlxTween.tween(memb, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
						}

						FlxTween.color(dad, 1, dad.color, 0xffffffff, {ease: FlxEase.quadInOut});
						FlxTween.color(boyfriend, 1, boyfriend.color, 0xffffffff, {ease: FlxEase.quadInOut});
						FlxTween.color(gf, 1, gf.color, 0xffffffff, {ease: FlxEase.quadInOut});

						curLight = 0;
						curLightEvent = 0;
					}
			}
			psychicNotes.shift();
		}
		keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE && !endingSong && !startingSong)
			FlxG.sound.music.onComplete();
		#end
	}

	function moveCamera(?id:Int = 0):Void {
		if (SONG.notes[id] != null && camFollow.x != dad.getMidpoint().x + 150 && !SONG.notes[id].mustHitSection)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
		}

		if (SONG.notes[id] != null && SONG.notes[id].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
		}
	}

	function endSong():Void
	{
		canPause = false;
		endingSong = true;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		camZooming = false;

		deathCounter = 0;
		seenCutscene = false;

		FlxTween.tween(timeBarBG, {alpha: 0}, 0.4, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 0}, 0.4, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 0}, 0.4, {ease: FlxEase.circOut});
		KillNotes();

		if (SONG.validScore)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignMisses += songMisses;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new MainMenuState());

				// if ()
				if (SONG.validScore)
				{
					Highscore.saveWeekScore(campaignScore, storyDifficulty);
				}
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;
				prevCamFollowPos = camFollowPos;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
	}

	private function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			FlxTween.cancelTweensOf(daNote);
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		psychicNotes = [];
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
		}

		if(daRating == 'sick' && ClientPrefs.noteSplashes && note != null)
		{
			var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			splash.setupNoteSplash(note.x, note.y, note.noteData);
			grpNoteSplashes.add(splash);
		}

		if(!practiceMode) {
			songScore += score;
			songHits++;
			RecalculateRating();
			FlxTween.cancelTweensOf(scoreTxt.scale);
			scoreTxt.scale.x = 1.1;
			scoreTxt.scale.y = 1.1;
			FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		rating.loadGraphic(Paths.image(daRating));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('combo'));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('num' + Std.int(i)));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.antialiasing = ClientPrefs.globalAntialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;

		var upP = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP = controls.NOTE_DOWN_P;
		var leftP = controls.NOTE_LEFT_P;

		var upR = controls.NOTE_UP_R;
		var rightR = controls.NOTE_RIGHT_R;
		var downR = controls.NOTE_DOWN_R;
		var leftR = controls.NOTE_LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
		var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			if((left || down || up || right) && !endingSong) {
				notes.forEachAlive(function(daNote:Note) {
					if(daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress) {
						goodNoteHit(daNote);
					}
				});
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.004 && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}

			if((leftP || downP || upP || rightP) && !endingSong) {
				boyfriend.holdTimer = 0;
				var notesHitArray:Array<Note> = [];
				var notesDatas:Array<Int> = [];
				var sickNotes:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note) {
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
						if (notesDatas.indexOf(daNote.noteData) != -1) {
							for (i in 0...notesHitArray.length) {
								var prevNote = notesHitArray[i];
								if (prevNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - prevNote.strumTime) < 10) {
									sickNotes.push(daNote);
								} else if (prevNote.noteData == daNote.noteData && daNote.strumTime < prevNote.strumTime) {
									notesHitArray.remove(prevNote);
									notesHitArray.push(daNote);
								}
							}
						} else {
							notesHitArray.push(daNote);
							notesDatas.push(daNote.noteData);
						}
					}
				});

				for (i in 0...sickNotes.length) {
					var daNote = sickNotes[i];
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				notesHitArray.sort(sortByShit);

				if (perfectMode)
					goodNoteHit(notesHitArray[0]);
				else if (notesHitArray.length > 0) {
					for (i in 0...controlArray.length) {
						if(controlArray[i] && notesDatas.indexOf(i) == -1) badNoteHit();
					}
					for (i in 0...notesHitArray.length) {
						var daNote = notesHitArray[i];
						if(controlArray[daNote.noteData]) goodNoteHit(daNote);
					}
				} else
					badNoteHit();
			}
		}

		playerStrums.forEach(function(spr:StrumNote)
		{
			if(controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.playAnim('pressed');
			if(controlReleaseArray[spr.ID])
				spr.playAnim('static');
		});
	}

	function badNoteHit():Void {
		var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
		for (i in 0...controlArray.length) {
			if(controlArray[i]) noteMiss(i);
		}
	}

	function noteMiss(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.04;
			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) songMisses++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP = controls.NOTE_DOWN_P;
		var leftP = controls.NOTE_LEFT_P;

		if (leftP)
			noteMiss(0);
		if (downP)
			noteMiss(1);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
		{
			badNoteCheck();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			if(note.heyNote) {
				boyfriend.playAnim('hey', true);
				boyfriend.specialAnim = true;
				boyfriend.heyTimer = 0.6;

				gf.playAnim('cheer', true);
				gf.specialAnim = true;
				gf.heyTimer = 0.6;
			} else {
				switch (note.noteData)
				{
					case 0:
						boyfriend.playAnim('singLEFT', true);
					case 1:
						boyfriend.playAnim('singDOWN', true);
					case 2:
						boyfriend.playAnim('singUP', true);
					case 3:
						boyfriend.playAnim('singRIGHT', true);
				}
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				FlxTween.cancelTweensOf(note);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && !gf.stunned)
		{
			gf.dance();
		}

		if(curBeat % 2 == 0) {
			if (!boyfriend.animation.curAnim.name.startsWith("sing") && !boyfriend.specialAnim)
			{
				boyfriend.dance();
			}
			if (!dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
		} else if(dad.curCharacter == 'spooky' && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned) {
			dad.dance();
		}

		if (!trainMoving)
			trainCooldown += 1;

		if (curBeat % 4 == 0)
		{
			phillyCityLights.forEach(function(light:FlxSprite)
			{
				light.visible = false;
			});

			curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

			phillyCityLights.members[curLight].visible = true;
			phillyCityLights.members[curLight].alpha = 1;
		}

		if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
		{
			trainCooldown = FlxG.random.int(-4, 0);
			trainStart();
		}
	}

	var ratingString:String;
	var ratingPercent:Float;
	function RecalculateRating() {
		ratingPercent = songScore / ((songHits + songMisses) * 350);
		if(!Math.isNaN(ratingPercent) && ratingPercent < 0) ratingPercent = 0;

		if(Math.isNaN(ratingPercent)) {
			ratingString = '?';
		} else if(ratingPercent >= 1) {
			ratingString = CoolUtil.ratingStuff[CoolUtil.ratingStuff.length-1][0]; //Uses last string
		} else {
			for (i in 0...CoolUtil.ratingStuff.length-1) {
				if(ratingPercent < CoolUtil.ratingStuff[i][1]) {
					ratingString = CoolUtil.ratingStuff[i][0];
					break;
				}
			}
		}
	}

	function DadStrumPlayAnim(id:Int, time:Float) {
		var spr:StrumNote = strumLineNotes.members[id];
		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
