class_name Surface
extends RefCounted
## What a hit landed on: decides which impact effect plays.
##   ORGANIC      bugs (ichor, chitin bits)
##   METAL        turrets, armour, metal props (hot sparks)
##   SHIELD       energy shields, the Shield Bug's front (hex ripple)
##   ENVIRONMENT  walls, floors, crates (dust, debris)
## Anything can declare its surface with a `surface_kind` property or a
## "surface" meta (one of the names below); the default is ENVIRONMENT.

enum Kind { ORGANIC, METAL, SHIELD, ENVIRONMENT }
const NAMES := ["organic", "metal", "shield", "environment"]


static func of(obj: Object) -> int:
	if obj == null:
		return Kind.ENVIRONMENT
	if "surface_kind" in obj:
		return int(obj.get("surface_kind"))
	if obj.has_meta("surface"):
		return maxi(NAMES.find(String(obj.get_meta("surface"))), 0)
	return Kind.ENVIRONMENT
