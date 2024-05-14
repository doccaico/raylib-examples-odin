package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

// How to run.
// odin run rain.odin -file

// A port of https://github.com/epsilon-phase/raylib-experiments/blob/canon/src/rain/main.c

SCREEN_TITLE :: "Rain"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

MIN_ANGLE :: -10
MAX_ANGLE :: 10
MAX_MAGNITUDE :: 15.0
MIN_MAGNITUDE :: 5.0
MAX_SPEED :: 5.0
MIN_SPEED :: 3.0
MAX_VERTICAL_SPAWN :: 40
RAINDROP_COUNT :: 250

raindrop_colors := [?]rl.Color {rl.DARKBLUE, rl.DARKGRAY, rl.BLUE, rl.GREEN}
raindrop_color := 0
background_colors := [?]rl.Color {rl.RAYWHITE, rl.LIGHTGRAY, rl.GRAY, rl.BLACK}
background_color := 0


Raindrop :: struct {
	start: rl.Vector2,
	pos: rl.Vector2,
	motion: rl.Vector2,
	speed: f32,
}

Dir :: enum {
	Prev = -1,
	Next = 1,
}

cycle_raindrop_color :: proc(dir: Dir) {
	if raindrop_color == 0 && dir == .Prev {
		raindrop_color = len(raindrop_colors) - 1
		return
	}
	raindrop_color = (raindrop_color + int(dir)) % len(raindrop_colors)
}

cycle_background_color :: proc(dir: Dir) {
	background_color = (background_color + int(dir)) % len(background_colors)
}

init_raindrop :: proc() -> (rd: Raindrop) {
	rd.start = {rand.float32_range(0.0, SCREEN_WIDTH), 0.0 - rand.float32_range(0.0, MAX_VERTICAL_SPAWN)}
	rd.motion = {0, rand.float32_range(MIN_MAGNITUDE, MAX_MAGNITUDE)}
	rd.motion = rl.Vector2Rotate(rd.motion, rand.float32_range(MIN_ANGLE, MAX_ANGLE) * rl.DEG2RAD)
	rd.speed = rand.float32_range(MIN_SPEED, MAX_SPEED)
	rd.pos = rd.start
	return
}

step_raindrop :: proc(rd: ^Raindrop) {
	if outside_window(rd) do reset_raindrop(rd)
	rd.pos = rd.pos + (rl.Vector2Normalize(rd.motion) * rd.speed)
}

outside_window :: proc(rd: ^Raindrop) -> bool {
	start :=  rd.pos
	end := rd.pos + (rd.motion * rd.speed)
	return (start.x < 0 && end.x < 0) ||
	(start.x > SCREEN_WIDTH && end.x > SCREEN_WIDTH) ||
	(start.y > SCREEN_HEIGHT && end.y > SCREEN_HEIGHT)
}

reset_raindrop :: #force_inline proc(rd: ^Raindrop) {
	rd.pos = rd.start
}

draw_raindrop :: #force_inline proc(rd: ^Raindrop) {
	rl.DrawLineEx(rd.pos, rd.pos + rd.motion, 2, raindrop_colors[raindrop_color])
}

main :: proc() {

	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE)
	defer rl.CloseWindow()

	ballPosition: rl.Vector2 = {f32(SCREEN_WIDTH / 2), f32(SCREEN_HEIGHT / 2)}
	ballSpeed: rl.Vector2 = {5.0, 4.0}
	ballRadius := 20

	pause := false
	framesCounter := 0

	rl.SetTargetFPS(60)

	rain := [RAINDROP_COUNT]Raindrop {}
	for &r in rain {
		r = init_raindrop()
	}

	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(.SPACE) do pause = !pause
		if rl.IsKeyPressed(.RIGHT) do cycle_raindrop_color(.Next)
		if rl.IsKeyPressed(.LEFT) do cycle_raindrop_color(.Prev)
		if rl.IsKeyPressed(.B) do cycle_background_color(.Next)
		if rl.IsKeyPressed(.R) {
			for &r in rain {
				r = init_raindrop()
			}
		}

		if !pause {
			for &r in rain {
				step_raindrop(&r)
			}
		} else {
			framesCounter += 1
		}

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(background_colors[background_color])

			for &r in rain {
				draw_raindrop(&r)
			}

			if pause && (framesCounter / 30 % 2) == 0 {
				rl.DrawText("PAUSED", 350, 200, 30, rl.GRAY)
			}

			rl.DrawFPS(10, 10)
		}
	}
}
