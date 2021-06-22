package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

class StoryModeSelectSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var menuItems:Array<String> = [];
	public static var curSelected:Int = 1;

	public function new()
	{
		super();
		for (i in 0...CoolUtil.difficultyArray.length) {
			menuItems.push(CoolUtil.difficultyArray[i]);
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var optionText:Alphabet = new Alphabet(0, (100 * i) + 240, menuItems[i], true, false);
			optionText.screenCenter(X);
			optionText.scrollFactor.set();
			grpMenuShit.add(optionText);
		}

		scoreText = new FlxText(0, 140, FlxG.width, "", 48);
		scoreText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.alpha = 0;
		scoreText.autoSize = false;
		scoreText.scrollFactor.set();
		scoreText.borderSize = 3;
		add(scoreText);
		FlxTween.tween(scoreText, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = 'BEST SCORE: ' + lerpScore;

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var back = controls.BACK;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (accepted)
		{
			PlayState.storyPlaylist = ['Bopico', 'Freshy-Nice', 'Blambattle'];
			PlayState.SONG = Song.loadFromJson(Highscore.formatSong('bopico', curSelected), 'bopico');
			PlayState.isStoryMode = true;
			PlayState.storyDifficulty = curSelected;

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			LoadingState.loadAndSwitchState(new PlayState());
		} else if(back) {
			MainMenuState.selectedSomethin = false;
			close();
		}
	}

	override function destroy()
	{
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;
		intendedScore = Highscore.getWeekScore(curSelected);

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
	}
}
