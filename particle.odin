package main

import "core:math/rand"
import rl "vendor:raylib"
import cb "utils/circular_buffer"

// How to run.
// odin run particle.odin -file

// (WIP) A port of https://github.com/epsilon-phase/raylib-experiments/blob/canon/src/particle/main.c

SCREEN_TITLE :: "Particle"
SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 640

PARTICLE_MAX_SIZE :: 20
PARTICLE_MAX_SPEED :: 4.0

Particle :: struct {
	position: rl.Vector2,
	lifetime_remaining: int,
	size: f32,
	color: rl.Color,
}

Particle_Emitter :: struct {
	position: rl.Vector2,
	lifetime_max: int,
	particle_count: int,
	wheel_house: []Particle,
}

colors := [?]rl.Color {
	{255, 0, 0, 255},  // Red
	{0, 255, 0, 255},  // green
	{0, 0, 255, 255},  // Blue
	{55, 55, 55, 255}, // Darkish gray
}

particle_emitter_init :: proc(x, y, particle_count, lifetime_max: int) -> ^Particle_Emitter {
	result := new(Particle_Emitter)
	result.particle_count = particle_count
	result.position.x = f32(x)
	result.position.y = f32(y)
	result.lifetime_max = lifetime_max
	result.wheel_house = make([]Particle, particle_count)
	return result
}

particle_emitter_step :: proc(e: ^Particle_Emitter) {
	for i in 0..< e.particle_count {
		particle_step(e, &e.wheel_house[i])
	}
}

particle_step :: proc(e: ^Particle_Emitter, p: ^Particle) {
	p.position = e.position

	if p.lifetime_remaining <= 0 {
		p.color = colors[rand.int_max(len(colors))]
		p.lifetime_remaining = rand.int_max(e.lifetime_max)
		p.size = rand.float32_range(1, PARTICLE_MAX_SIZE)
		return
	}

	p.lifetime_remaining -= 1
	p.size = f32(clamp(PARTICLE_MAX_SIZE * p.lifetime_remaining / e.lifetime_max, 1.0, PARTICLE_MAX_SIZE))
}

draw_particle :: #force_inline proc(p: ^Particle) {
	rl.DrawCircle(i32(p.position.x), i32(p.position.y), p.size, p.color)
}

draw_emitter :: proc(e: ^Particle_Emitter) {
	rl.DrawCircle(i32(e.position.x), i32(e.position.y), 3.0, rl.BLACK)
	for i in 0..< e.particle_count {
		draw_particle(&e.wheel_house[i])
	}
}

main :: proc() {

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	emitters := cb.Circular_Buffer(150, ^Particle_Emitter){}

	for !rl.WindowShouldClose() {

		if rl.IsMouseButtonDown(.LEFT) {
			cursor_pos := rl.GetMousePosition()
			// occurs a memory leak because I don't free memory (- _ -)
			cb.append(&emitters, particle_emitter_init(int(cursor_pos.x), int(cursor_pos.y), 50, 100))
		}

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.RAYWHITE)

			for i in 0..<emitters.len {
				draw_emitter(emitters.data[i])
			}

			rl.DrawFPS(10, 10)
		}

		for i in 0..<emitters.len {
			particle_emitter_step(emitters.data[i])
		}

	}
}
