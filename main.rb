#!/usr/bin/env ruby

require 'sdl'
require 'word'
require 'sound'
require 'getopts'


class Game
	TITLE = "Neko-type"
	SCREEN_X = 640
	SCREEN_Y = 480
	FPS = 30
	TIME_POS_X = SCREEN_X - 105

	#--------------------------
	TIMELIMIT = FPS * 60
	TARGET_SCORE = 10000
	#TIMELIMIT = 1
	#TARGET_SCORE = 0

	@@isFullscreen = false

	def initialize()
		@objs = []
		@age = 0	 # 現在のステートになってからのフレーム数
		@lastTime = 0 
		@screen = nil
		$sound = Sound.new

		@score = 0
		@keys = []

		@newState = nil

		@gameFrame = 0

		@clearImageIndex = (rand() * 3).to_i
		@currentWord = nil
	end

	def init()
		parseArgs

		f = open("words")
		$dict = f.readlines()
		f.close
		puts "Loaded " + $dict.length.to_s + " words."

		puts "init"
		initSDL()

		$image_title = SDL::Surface.loadBMP("image/title.bmp")

		$sound.loadSounds
	end

	def initGame()
		@objs = []
		@score = 0
		@gameFrame = 0
		@scoreDrawer = ScoreDrawer.new()
		@createWait = 45
		@isNearTimelimit = false

		@currentWord = nil

		@clearImageIndex += 1
		if @clearImageIndex >= 3
			@clearImageIndex = 0
		end
		$image_clear = SDL::Surface.loadBMP(sprintf("image/clear%02d.bmp", @clearImageIndex))
	end

	def start()
		puts "start"

		@gameOver = GameOver.new()
		@titleDrawer = TitleDrawer.new()

		

		@state = :title
		mainLoop()
	end

	def addScore(point)
		@score += point
		@scoreDrawer.setScore(@score, point)
	end

	def addGameObj(gameObj)
		@objs.push(gameObj)
	end

	def getKeys()
		return @keys
	end

	def setCurrentWord(word)
		if @currentWord == nil
			@currentWord = word
		end
	end

	def lostCurrentWord()
		puts "lostCurrentWord"
		@currentWord = nil
	end

	def isSetCurrentWord()
		return @currentWord != nil
	end

	def isCurrentTarget(word)
		return @currentWord == word
	end

	def isNearTimelimit()
		return @isNearTimelimit
	end

	private
	
	def initSDL
		puts "initSDL"

		SDL.init( SDL::INIT_VIDEO | SDL::INIT_AUDIO )

		if @@isFullscreen
			@screen = SDL::setVideoMode(Game::SCREEN_X, Game::SCREEN_Y, 16, SDL::SWSURFACE|SDL::DOUBLEBUF | SDL::FULLSCREEN)
		else
			@screen = SDL::setVideoMode(Game::SCREEN_X, Game::SCREEN_Y, 16, SDL::SWSURFACE|SDL::DOUBLEBUF)
		end
		$screen = @screen

		SDL::Mouse.hide

		SDL::WM::setCaption TITLE, TITLE

		SDL::Mixer.open(22010,SDL::Mixer::FORMAT_S8,1,1024) #22kHz,8bit,monoral

		#init font
		SDL::TTF.init
		$font = SDL::TTF.open('font/boxfont2.ttf',20)
		$font2 = SDL::TTF.open('font/boxfont2.ttf',40)
		$font_word = SDL::TTF.open('font/tahoma.ttf',20)

		#@kanji = SDL::Kanji.open("english.bdf", 14)

		#if not @kanji
			#puts "failed to load kanji"
			#exit
		#end

	end

	def action()
		keys = getKeys()

		if @newState
			@state = @newState
			@newState = nil
			@age = 0

			# ステート開始
			case @state
			when :game
				$sound.playBGM()
				initGame()

			when :gameover
				@gameOver.init()
				$sound.haltMusic()
				$sound.playSound($sound_gameover)

			when :clear
				$sound.haltMusic()
				$sound.playSound($sound_clear)
			end

		end

		case @state
		when :title
			@titleDrawer.action()
			if keys.length > 0
				@newState = :game
			end

		when :game
			if @gameFrame == Game::TIMELIMIT
				if @score < TARGET_SCORE
					@newState = :gameover
				else
					@newState = :clear
				end
				return
			end

			if @gameFrame == Game::TIMELIMIT - Game::FPS * 10
				$sound.playSound($sound_limit)
				@isNearTimelimit = true
			end


			@objs.delete_if {|x| x.dead? }

			@objs.each do |x|
				x.action()
			end

			createNewWordRandom()

			@scoreDrawer.action()

			@gameFrame += 1

		when :gameover
			@gameOver.action()
			@scoreDrawer.action()

			if @age > FPS * 3 and keys.length > 0
				@newState = :title
			end

		when :clear
			@scoreDrawer.action()

			if @age == 245
				$sound.playSound($sound_clearcat)
			end

			if @age > FPS * 8 and keys.length > 0
				@newState = :title
			end
		end

		@age += 1
	end

	def draw()
		case @state
		when :title
			@screen.fillRect(0, 0, SCREEN_X, SCREEN_Y,0)
			@titleDrawer.draw()
			@screen.flip

		when :game
			@screen.fillRect(0, 0, SCREEN_X, SCREEN_Y,0)
			#
			#puts "draw kanji"
			#@kanji.put(@screen, "hoge", 100, 100, 255, 255, 0)
			#return

			@objs.each do |x|
				x.draw()
			end

			@scoreDrawer.draw(true)

			
			drawTime(time = (TIMELIMIT - @gameFrame - 1) / FPS + 1)
			
			@screen.flip

		when :gameover
			@screen.fillRect(0, 0, SCREEN_X, SCREEN_Y,0)
			@gameOver.draw()
			drawTime(0)
			@scoreDrawer.draw(true)
			@screen.flip

		when :clear
			if @age > 250
				@screen.fillRect(0, 0, SCREEN_X, SCREEN_Y,0)

				$screen.put($image_clear, 190, 130)
				$font.drawSolidUTF8(@screen, "Congraturations!", 230, 350, 255, 200, 150);

				$font.drawSolidUTF8(@screen, "Time: " + sprintf("%3d", time), TIME_POS_X, 0, 255, 255, 255);

				drawTime(0)
				@scoreDrawer.draw(true)

				@screen.flip
			end
		end
	end

	def mainLoop()
		while true
			time = SDL.getTicks
			if time - @lastTime < 1000 / Game::FPS
				SDL.delay(1000 / Game::FPS - (time - @lastTime))
			end
			@lastTime = SDL.getTicks

			@buttonState = updateKeys()
			if !@buttonState
				exit
			end

			action()
			draw()
		end
	end

	def updateKeys()
		@keys = []

    while (event=SDL::Event2.poll)
			case event
			when SDL::Event2::Quit
				return nil
			when SDL::Event2::KeyDown
				case event.sym
				when SDL::Key::ESCAPE
					return nil #exit
				end

				key = event.sym
				@keys.push(key)

			end
		end
		return true
	end

	def createNewWordRandom()

		if @createWait <= 0
			doCreateNewWord

			intervals = [
				[10, 3],
				[20, 2.4],
				[30, 1.9],
				[40, 1.7],
				[50, 1.5],
				[60, 1]
			]

			interval = FPS
			intervals.each do |x|
				if (@age/FPS) < x[0]
					interval = (x[1] * FPS).to_i
					break
				end
			end

			@createWait = interval
		end

		@createWait -= 1
	end

=begin
	def doCreateNewWord
		puts "doCreateNewWord"

		chars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
		str = ""
		length = (rand() * 10).to_i
		length.times do
			str += chars[(rand() * chars.length).to_i]
		end

		word = Word.new(str)
		@objs.push(word)

		#$sound.playFoot()
	end
=end

	def doCreateNewWord
		r = (rand() * $dict.length).to_i
		str = $dict[r].chomp()
		#str = "wixiyizi"
		word = Word.new(str)
		@objs.push(word)
	end


	def drawTime(time)
		$font.drawSolidUTF8(@screen, "Time: " + sprintf("%3d", time), TIME_POS_X, 0, 255, 255, 255);
	end

	def parseArgs
		getopts("fh", "help")
		if $OPT_help || $OPT_h
			puts TITLE
			puts "usage: ruby main.rb [options]"
			puts "options:"
			puts "    -f, --fullscreen"
			puts "    -h, --help"
			exit
		end

		if $OPT_f
			@@isFullscreen = true
		end
	end
end


$game = Game.new
$game.init
$game.start()
