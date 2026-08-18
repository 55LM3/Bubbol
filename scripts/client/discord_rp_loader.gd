extends Node

func _ready():
	DiscordRPC.app_id = 1525911225651822714
	DiscordRPC.details = "In the menus..."
	DiscordRPC.state = "Nothing here!!"
	DiscordRPC.large_image = "logo"
	DiscordRPC.large_image_text = "Bubbol!"
	DiscordRPC.start_timestamp = Time.get_unix_time_from_system()

	DiscordRPC.refresh()
