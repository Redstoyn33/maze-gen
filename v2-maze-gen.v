import rand
import irishgreencitrus.raylibv as r

fn main() {
	// init
	mut sel := true
	mut screen_size := 1000
	mut size_x := 1
	mut size_y := 1
	mut size_m, mut size_t := update_size(size_x, size_y, screen_size)
	mut gen := ?&MGen(none)
	mut pr := false
	mut steps := 0
	mut speed := 0
	mut sn := 0

	r.init_window(screen_size, screen_size, 'Maze Generator'.str)

	screen_size = min(r.get_monitor_width(0),r.get_monitor_height(0))*4/5
	r.set_window_size(screen_size,screen_size)
	r.set_window_position(100,100)

	r.set_target_fps(60)
	for !r.window_should_close() {
		if r.is_key_pressed(r.key_w) {
			speed++
			sn = 0
		}
		if r.is_key_pressed(r.key_s) {
			speed--
			sn = 0
		}
		if sel {
			if r.is_key_pressed(r.key_enter) {
				sel = false
			}
			if r.is_key_pressed(r.key_up) {
				if size_y < screen_size / 10 {
					size_y++
					size_m, size_t = update_size(size_x, size_y, screen_size)
				}
			}
			if r.is_key_pressed(r.key_down) {
				if size_y > 1 {
					size_y--
					size_m, size_t = update_size(size_x, size_y, screen_size)
				}
			}
			if r.is_key_pressed(r.key_right) {
				if size_x < screen_size / 10 {
					size_x++
					size_m, size_t = update_size(size_x, size_y, screen_size)
				}
			}
			if r.is_key_pressed(r.key_left) {
				if size_x > 1 {
					size_x--
					size_m, size_t = update_size(size_x, size_y, screen_size)
				}
			}

			r.begin_drawing()
			r.clear_background(r.black)

			for x in 0 .. size_x {
				for y in 0 .. size_y {
					r.draw_rectangle(size_t + x * 2 * size_t, screen_size - size_t * 2 - y * 2 * size_t,
						size_t, size_t, r.white)
				}
			}

			if r.is_key_down(r.key_space) {
				r.draw_text('${size_x}:${size_y}\n${speed}'.str, 10, 10, screen_size / 10,
					r.green)
			}

			r.end_drawing()
		} else {
			if mut g := gen {
				if pr {
					if r.is_key_pressed(r.key_g) {
						g.gen()
					}
					if speed > 0 {
						for _ in 0 .. speed {
							pr = g.step_gen()
							steps++
						}
					} else {
						if sn == -speed {
							sn = 0
							pr = g.step_gen()
							steps++
						} else {
							sn++
						}
					}
				}
				r.begin_drawing()

				for x in 0 .. g.size_x {
					for y in 0 .. g.size_y {
						color := match g.s[y][x] {
							0 {
								r.black
							}
							1 {
								r.white
							}
							2 {
								r.blue
							}
							else {
								r.red
							}
						}
						r.draw_rectangle(x * size_t, screen_size - size_t - y * size_t, size_t, size_t, color)
					}
				}
				r.draw_rectangle(g.cur_x * size_t, screen_size - size_t - g.cur_y * size_t, size_t, size_t, r.gold)

				if r.is_key_down(r.key_space) {
					r.draw_text('${size_x}:${size_y}\n${speed}\n${pr}\n${steps}'.str,
						10, 10, screen_size / 10, r.green)
				}

				r.end_drawing()
				if r.is_key_pressed(r.key_r) {
					sel = true
					gen = none
				}
			} else {
				mut genn := gen_init(size_x, size_y)
				gen = &genn
				pr = true
				steps = 0
			}
		}
	}
	r.close_window()
}

[inline]
fn max(x int, y int) int {
	return if x > y { x } else { y }
}
[inline]
fn min(x int, y int) int {
	return if x < y { x } else { y }
}

fn update_size(x int, y int, size int) (int, int) {
	m := max(x, y)
	return m, size / (m * 2 + 1)
}

struct MGen {
	size_x int
	size_y int
mut:
	s     [][]u8
	cur_x int
	cur_y int
}

fn gen_init(size_x int, size_y int) MGen {
	mut space := [][]u8{len: size_y * 2 + 1, init: []u8{len: size_x * 2 + 1, init: 0}}
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

fn (mut g MGen) gen() {
	for {
		n := g.step_gen()
		if !n {
			break
		}
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
	g.cur_x += x
	g.cur_y += y
}

fn (mut g MGen) step_back(x int, y int) {
	if x != 0 {
		g.setcolor(x / 2, 0, 1)
	} else if y != 0 {
		g.setcolor(0, y / 2, 1)
	}
	g.cur_x += x
	g.cur_y += y
}

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
