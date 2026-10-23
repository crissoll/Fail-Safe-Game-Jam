@tool
class_name CloudWallSkin
extends Resource
## Set di texture per disegnare un muro a nuvola: bordo sinistro, centro
## (ripetuto) e bordo destro. Se ci sono più varianti ne sceglie una a caso.

@export var left: Array[Texture2D] = []
@export var middle: Array[Texture2D] = []
@export var right: Array[Texture2D] = []


static func from_paths(lefts: PackedStringArray, middles: PackedStringArray,
		rights: PackedStringArray) -> CloudWallSkin:
	var skin := CloudWallSkin.new()
	for p in lefts:
		skin.left.append(load(p))
	for p in middles:
		skin.middle.append(load(p))
	for p in rights:
		skin.right.append(load(p))
	return skin


## Variante scelta in modo deterministico (stesso tratto = stessa variante).
static func pick(list: Array[Texture2D], variant: int) -> Texture2D:
	if list.is_empty():
		return null
	return list[absi(variant) % list.size()]


func is_valid() -> bool:
	return not (left.is_empty() or middle.is_empty() or right.is_empty())


func signature() -> String:
	var paths: Array = []
	for list in [left, middle, right]:
		paths.append(list.map(func(t): return t.resource_path if t else ""))
	return var_to_str(paths)
