extends Node

# Collision layer formula: 
# pow(2, layer - 1)
const Layers = {
	DEFAULT = 1,
	PLAYER_IGNORED = 2,
	BREAKABLE_GLASS = 4,
	TRIGGER = 8,
	PEER_PLAYER = 16
}
const peer_update_rate = 4

var start_message = ""
