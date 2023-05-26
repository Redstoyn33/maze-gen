import rand
import term
import os
import strings
import time

struct MGen {
	size_x int
	size_y int
mut:
	s     [][]u8
	cur_x int
	cur_y int
}

fn main() {
	size_x := os.input('X size: ').int()
	size_y := os.input('Y size: ').int()
	if size_x <= 0 { exit(1) }
	if size_y <= 0 { exit(1) }
	// 0 - стены
	// 1 - проход
	// 2 - генерация
	// 4 - граница
	println('( ) simple gen')
	println('(p) gen process')
	println('(s) gen with start')
	println('(p) gen with path')
	mode := os.input('=')
	match mode {
		'с' {
			mut gen := gen_init(size_x, size_y)
			wait := os.input('millisecond on frame: ').int()
			gen.slide_show(wait * time.millisecond)
		}
		'н' {
			x := os.input('x: ').int()
			y := os.input('y: ').int()
			mut gen := gen_init_start(size_x, size_y, x, y)
			gen.gen()
			println(gen)
		}
		'п' {
			sx := os.input('start x: ').int()
			sy := os.input('start y: ').int()
			ex := os.input('end   x: ').int()
			ey := os.input('end   y: ').int()
			mut gen := gen_init_start(size_x, size_y, sx, sy)
			cords := gen.gen_path(ex, ey)
			println(gen.path_display(cords))
		}
		else {
			mut gen := gen_init(size_x, size_y)
			gen.gen()
			println(gen)
		}
	}
}

fn gen_init(size_x int, size_y int) MGen {
	mut space := [][]u8{len: size_y * 2 + 1, init: []u8{len: size_x * 2 + 1}}
	mut gen := MGen{
		size_x: size_x * 2 + 1
		size_y: size_y * 2 + 1
		cur_x: 1
		cur_y: 1
		s: space
	}
	gen.s[1][1] = 2
	return gen
}

fn gen_init_start(size_x int, size_y int, x int, y int) MGen {
	mut space := [][]u8{len: size_y * 2 + 1, init: []u8{len: size_x * 2 + 1}}
	mut gen := MGen{
		size_x: size_x * 2 + 1
		size_y: size_y * 2 + 1
		cur_x: x * 2 - 1
		cur_y: y * 2 - 1
		s: space
	}
	gen.s[gen.cur_y][gen.cur_x] = 2
	return gen
}

fn (mut g MGen) gen() {
	for {
		r := g.step_gen()
		if !r {
			break
		}
	}
}

fn (mut g MGen) gen_path(eex int, eey int) []Cord {
	mut cords := []Cord{}
	ex := eex * 2 - 1
	ey := eey * 2 - 1
	for {
		r := g.step_gen()
		if g.cur_x == ex && g.cur_y == ey {
			for y in 0 .. g.size_y {
				for x in 0 .. g.size_x {
					if g.s[y][x] == 2 {
						cords << Cord{x, y}
					}
				}
			}
		}
		if !r {
			break
		}
	}
	return cords
}

fn (mut g MGen) slide_show(wait time.Duration) {
	for {
		term.clear()
		r := g.step_gen()
		println(g)
		if !r {
			break
		}
		time.sleep(wait)
	}
}

fn (mut g MGen) step_gen() bool {
	if g.acord(0, 0) == 2 {
		if g.check_way() {
			x, y := g.rand_way()
			g.step_way(x, y)
		} else {
			g.setcolor(0, 0, 1)
		}
	}
	if g.acord(0, 0) == 1 {
		e, x, y := g.check_back()
		if e {
			g.step_back(x, y)
		} else {
			return false
		}
	}
	return true
}

fn (mut g MGen) check_way() bool {
	if g.acord(2, 0) == 0 {
		return true
	}
	if g.acord(-2, 0) == 0 {
		return true
	}
	if g.acord(0, 2) == 0 {
		return true
	}
	if g.acord(0, -2) == 0 {
		return true
	}
	return false
}

fn (mut g MGen) rand_way() (int, int) {
	for {
		d := rand.u8() % 2 == 0
		x := 2 * if d {
			if rand.u8() % 2 == 0 { 1 } else { -1 }
		} else {
			0
		}
		y := 2 * if !d {
			if rand.u8() % 2 == 0 { 1 } else { -1 }
		} else {
			0
		}
		if g.acord(x, y) == 0 {
			return x, y
		}
	}
	return 0, 0
}

fn (mut g MGen) check_back() (bool, int, int) {
	if g.acord(1, 0) == 2 {
		return true, 2, 0
	}
	if g.acord(-1, 0) == 2 {
		return true, -2, 0
	}
	if g.acord(0, 1) == 2 {
		return true, 0, 2
	}
	if g.acord(0, -1) == 2 {
		return true, 0, -2
	}
	return false, 0, 0
}

fn (mut g MGen) step_way(x int, y int) {
	if x != 0 {
		g.setcolor(x, 0, 2)
		g.setcolor(x / 2, 0, 2)
	} else if y != 0 {
		g.setcolor(0, y, 2)
		g.setcolor(0, y / 2, 2)
	}
	g.setcord(x, y)
}

fn (mut g MGen) step_back(x int, y int) {
	if x != 0 {
		g.setcolor(x / 2, 0, 1)
	} else if y != 0 {
		g.setcolor(0, y / 2, 1)
	}
	g.setcord(x, y)
}

[inline]
fn (mut g MGen) setcord(x int, y int) {
	g.cur_x += x
	g.cur_y += y
}

[inline]
fn (mut g MGen) setcolor(x int, y int, c u8) {
	g.s[g.cur_y + y][g.cur_x + x] = c
}

fn (mut g MGen) acord(ax int, ay int) u8 {
	x := g.cur_x + ax
	y := g.cur_y + ay
	if x < 0 || y < 0 || x >= g.size_x || y >= g.size_y {
		return 4
	}
	return g.s[y][x]
}

fn (g MGen) str() string {
	mut b := strings.new_builder(g.size_x * g.size_y + g.size_y)
	for y in 0 .. g.size_y {
		for x in 0 .. g.size_x {
			match g.s[y][x] {
				0 {
					b.write_rune(`#`)
				}
				1 {
					b.write_rune(` `)
				}
				2 {
					b.write_rune(`.`)
				}
				else {
					b.write_rune(`e`)
				}
			}
		}
		b.write_rune(`\n`)
	}
	return b.str()
}

fn (g MGen) path_display(cords []Cord) string {
	mut gc := g
	for c in cords {
		gc.s[c.y][c.x] = 2
	}
	return gc.str()
}

struct Cord {
	x int
	y int
}
