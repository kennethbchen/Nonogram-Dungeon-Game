extends Node

class_name Util

const board_columns = 8
const board_rows = 8

const tile_size = 16
const tile_offset = Vector2(8,8)

# Map names to tileset IDs
const nono_blank = 0
const nono_color = 2
const nono_cross = 1
const nono_empty = 4
const nono_cursor = 5
const nono_verti_guide = 6
const nono_horiz_guide = 7



const world_wall = 3

# Map names to indicator tileset IDs

# ---- World ----
# Non entities
const indi_wall = 10

# Entities
const indi_player = 0
const indi_health = 1
const indi_energy = 2
const indi_door = 4
const indi_stairs = 5
const indi_enemy = 6
const indi_trap = 7

# ---- Nonogram Board ----
const indi_crossed = 8
const indi_colored = 9
