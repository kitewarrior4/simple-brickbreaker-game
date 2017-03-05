all: sample2D

sample2D: game.cpp glad.c
	g++ -o run game.cpp glad.c -lGL -lglfw -ldl

clean:
	rm run
