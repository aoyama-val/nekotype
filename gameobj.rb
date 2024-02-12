class GameObj
	def initialize()
		@age = 0	# 生まれてからのフレーム数
		@dead = false
	end

	def action()
		@age += 1
	end

	def draw()
	end

	# オブジェクト消滅
	def die()
		puts "die"
		@dead = true
	end

	def dead?()
		return @dead
	end

	
end

class ScoreDrawer < GameObj
	def initialize()
		super()

		@addPointAge = 0

		@oldScore = 0
		@score = 0
	end

	def draw(drawActualScore=false)
		pos_x = 350
		pos_y = 0

		if @addPointAge > 0
			if drawActualScore
				@displayingScore = @score
			else
				@displayingScore += (@score - @oldScore) / 45;
			end

			#$font.drawSolidUTF8($screen, sprintf("      " + "%8d", @addPoint), Game::SCREEN_X - 155, 40, 255, 255, 255);

			$font.drawSolidUTF8($screen, "Goal: " + Game::TARGET_SCORE.to_s, 5, pos_y, 255, 255, 255);

			$font.drawSolidUTF8($screen, "Score:" + sprintf("%8d", @displayingScore), pos_x, pos_y, 255, 255, 255);
		else

			$font.drawSolidUTF8($screen, "Goal: " + Game::TARGET_SCORE.to_s, 5, pos_y, 255, 255, 255);

			$font.drawSolidUTF8($screen, "Score:" + sprintf("%8d", @score), pos_x, pos_y, 255, 255, 255);
		end

	end

	def action()
		super()

		if @addPointAge > 0
			@addPointAge -= 1
		end
	end

	def setScore(score, addPoint)
		@addPoint = addPoint
		@oldScore = @score
		@score = score

		@addPointAge = 45
		@displayingScore = @oldScore
	end
end

class GameOver < GameObj
	def initialize()
		init()
	end

	def init()
		@age = 0
		@pos = 0
		@sign = 1
		@moveCount = 0

	end
	
	def action()
		super()

		if @age >  70
			return
		end

		@pos += @sign

		if @moveCount > 40
			@sign *= -1
			@moveCount = 0
		end

		@moveCount += 1 

		@pos = (Math.sin(@moveCount/40.0 * 2 * Math::PI) * 40) 
		return
	end

	def draw()
		$font2.drawSolidUTF8($screen, "GAME OVER", Game::SCREEN_X/2-90, Game::SCREEN_Y/2 + @pos, 255, 255, 0);
	end
	
end

class TitleDrawer < GameObj
	def initialize
		puts "new TitleDrawer"

		super()

		@pos = 0
		@moveCount = 0
		
	end

	def draw()
		$screen.put($image_title, 0, 20)
		$font2.drawSolidUTF8($screen, Game::TITLE, 250, 200, 255, 200, 150);

		$font.drawSolidUTF8($screen, "Press key to start", 450, 450 + @pos, 255, 230, 0);
	end

	def action()
		super()

		@moveCount += 1;
		@pos = (Math.sin(@moveCount/50.0 * 2 * Math::PI) * 7) 

	end
end
