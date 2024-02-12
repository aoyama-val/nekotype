require 'gameobj'

class Word < GameObj
	DIE_COUNT_MAX =25

	@@lastY = 0

	def initialize(word)
		super()


		puts "new word: " + word
		@word = word

		@x = 0
		@y = (25 + rand() * (Game::SCREEN_Y - 50)).to_i
		if (@y - @@lastY).abs <= 20
			if @y <= @@lastY
				@y -= 20
			else
				@y += 20
			end
			puts "補正した " + @word
		end
		if @y < 20
			@y = 20
		elsif @y > Game::SCREEN_Y - 25
			@y = Game::SCREEN_Y - 25
		end
		@@lastY = @y

		@dieCount = 0

		@w, @h = $font_word.text_size(word)
		puts "width = " + @w.to_s

=begin
		props = [
			[0.1, 1],
			[0.2, 2],
			[0.3, 3],
			[0.4, 4],
			[0.5, 5],
			[0.6, 5.5],
			[0.7, 6],
			[0.8, 7],
			[0.9, 8],
			[0.95, 10]
		]

		@speed = 1
		r = rand()
		props.each do |x|
			if r < x[0]
				@speed = x[1]
				break
			end
		end
=end
		@speed = 1
		puts "speed = " + @speed.to_s

		@matchedLength = 0	# 既にマッチした文字の長さ
	end

	def action()
		super()
		
		if @x > Game::SCREEN_X
			if isCurrentTarget()
				$sound.playSound($sound_break)
			end
			die()
			return
		end

		
		if @dieCount > 0
			@dieCount -= 1
			if @dieCount == 0
				die()
			end

			if @dieCount == DIE_COUNT_MAX - 1
				$game.lostCurrentWord()
			end

			return
		end

		if (not $game.isSetCurrentWord()) or isCurrentTarget()
			keys = $game.getKeys()
			keys.each do |k|
				tryKey(k, $game)
			end
		end

		if $game.isNearTimelimit()
			@x += @speed * 2
		else
			@x += @speed;
		end
	end

	def draw()
		super()

		matched = @word[0...@matchedLength]
		rest = @word[(@matchedLength)..-1]

		$font_word.drawSolidUTF8($screen, matched, @x, @y, 255, 255, 0)
		w, h = $font_word.text_size(matched)


		if rest != ""
			# truetype フォントの幅のずれを補正するためのダーティハック
			if matched[-1]
				lastChar = matched[-1].chr

				case lastChar
				when "f"
					w -= 2
				when "i"
					if rest[0] and "abcdefghiklmntvopqrsuvxyz".index(rest[0].chr)
						w -= 0
					else
						w -= 1
					end
				end
			end

			$font_word.drawSolidUTF8($screen, rest, @x + w, @y, 255, 255, 255)
		end
	end

	# 1キーが合っているかどうか試す
	def tryKey(key, game)
		#puts "tryKey " + key.to_s + " " + @word[@matchedLength].to_s

		if key == @word[@matchedLength]
			# カレントターゲットにする
			$game.setCurrentWord(self)

			@matchedLength += 1
			if @matchedLength == @word.length
				$sound.playCoin
				@dieCount = DIE_COUNT_MAX
				game.addScore(getPoint())

			end

		else
			#$sound.playFoot
		end
	end


	def getPoint()
		return @speed.to_i * @word.length * 100
	end

	def die()
		super()

		if isCurrentTarget()
			$game.lostCurrentWord()
		end
	end

	def isCurrentTarget()
		return $game.isCurrentTarget(self)
		#return @isCurrentTarget
	end

end
