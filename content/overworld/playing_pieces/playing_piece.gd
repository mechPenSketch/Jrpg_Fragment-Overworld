@tool
@icon("playing_piece.svg")
class_name PlayingPiece extends Sprite2D

## A piece played on the board. Typically used for events.

## Emmited when the piece starts moving
signal moved(node, position)

## Emmited when the piece finishes moving
signal move_tween_finished(new_mapos)

## Ways the event can be triggered
enum Triggers {
	ACTION_BY_SIDE, ## Press Action when facing event.
	NONE, ## Nothing can trigger the event.
	STEPPED_ON, ## Pressing the direction into the event and walking in.
	ACTION_ON_SPOT, ## Press Action while being on the event.
	ABOUT_TO_WALK_IN, ## Pressing the direction into the event. It triggers before the player walks in.
}

## The timeline to be played when interracted.
@export_file("*.dtl") var timeline: String

## How the piece is to be interracted.
@export var trigger: Triggers

@export_group("Area")

## Checks whether this piece can block path.
@export var blocks_path: bool = true

## Measures how much more space does this piece cover.
@export var expands: Vector2

## Checks whether property Expands applies to
## the opposite side, too.
@export var symmetrically: bool = true

@export_group("Visual")

## If [param true], sets [member visible] to
## [param false] when the scene is played.
@export var hide_on_play: bool

## Checks whether the play is still walking.
var walking_in_progress: bool

func _ready():
	if hide_on_play and not Engine.is_editor_hint():
		hide()


## Returns the movement duration, which is typically
## gotten from the length of a walking animation.
##
## Not all playing pieces have [AnimationPlayer], so
## for those exceptions, the default is 0.8s.
func get_moving_duration(custom_track := "")-> float:
	if custom_track:
		var anim = $AnimationPlayer.get_animation(custom_track)
		return anim.get_length()
	else:
		return 0.8


## For moving the piece to the given direction,
## check whether it is blocked and
## what to do then.
func move_piece(v2i: Vector2i, custom_track := "act_walking"):
	var map_pos = get_parent().local_to_map(get_position())
	var target_mapos = map_pos + v2i
	
	if is_blocked(target_mapos):
		moving_when_blocked(custom_track)
	else:
		moving_when_unblocked(custom_track, map_pos, target_mapos)


## For additional effects when
## attempting to move is blocked.
func moving_when_blocked(_ct):
	pass


## For moving the piece now that
## the direction is unblocked.
func moving_when_unblocked(custom_track, map_pos, target_mapos):
	var final_pos = get_parent().map_to_local(target_mapos)
	
	get_parent().update_map_pos(self, map_pos, target_mapos)

	var tween = create_tween()
	var move_duration = get_moving_duration(custom_track)
	
	tween.tween_property(self, "position", final_pos, move_duration)
	walking_in_progress = true
	
	tween.tween_callback(func():
		walking_in_progress = false
		move_tween_finished.emit(target_mapos)
	)


## Checks whether the piece is blocked to
## the given direction.
func is_blocked(map_pos)-> bool:
	return is_blocked_by_playing_piece(map_pos) or is_blocked_by_terrain(map_pos)


## Checks whether the piece is blocked
## to the given direction,
## specifically by another piece.
func is_blocked_by_playing_piece(map_pos):
	var dict_playpieces = get_parent().children_by_mapos
	
	if map_pos in dict_playpieces:
		for playing_piece in dict_playpieces[map_pos]:
			if playing_piece.blocks_path:
				return true
	
	return false


## Checks whether the piece is blocked
## to the given direction,
## specifically by the terrain property.
func is_blocked_by_terrain(map_pos)-> bool:
	var tiledata = get_parent().get_cell_tile_data(1, map_pos)
	if tiledata:
		return tiledata.get_terrain_set() != 0
	else:
		return false


## Adds a new piece in the same position as it is in.
func spawn_new_piece(playing_piece):
	playing_piece.set_position(get_position())
	add_sibling(playing_piece)
