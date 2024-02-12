class Sound
	def initialize()
		@played = false

	end

	def action()
		@played = false
	end

	def loadSounds()
		#$sound_foot = SDL::Mixer::Wave.load("sound/foot.wav")
		$sound_break = SDL::Mixer::Wave.load("sound/break.wav")
		$sound_coin = loadSound("sound/coin.wav")
		$sound_gameover = loadSound("sound/gameover.wav")
		$sound_clear = loadSound("sound/clear_nobomb.wav")
		$sound_limit = loadSound("sound/limit.wav")
		$sound_clearcat = loadSound("sound/cat.wav")
		@music = SDL::Mixer::Music.load("sound/mario-field.mid")   #読み込み
	end
	

	def playFoot()
		return
		if not @played
			SDL::Mixer.playChannel(-1, $sound_foot, 0)
			played = true
		end
	end

	def playCoin()
		begin
			SDL::Mixer.playChannel(-1, $sound_coin, 0)
		rescue
			puts "----------------------------------failed to playChannel"
		end
	end

	def playSound(sound)
		begin
			SDL::Mixer.playChannel(-1, sound, 0)
		rescue
			puts "----------------------------------failed to playChannel"
		end
	end

	def playBGM()
		SDL::Mixer.play_music(@music, -1)  #再生 (1は再生する回数、-1だと無限ループ)
	end

	def haltMusic()
		SDL::Mixer.halt_music           #ストップ
	end

	private

	def loadSound(filepath)
		sound = SDL::Mixer::Wave.load(filepath)
		if not sound
			puts "failed to load sound [#{filepath}]"
			exit
		end
		return sound
	end
end

