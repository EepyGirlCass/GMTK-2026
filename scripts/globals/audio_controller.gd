extends Node

enum AudioChannel {
	MUSIC,
	EFFECTS,
	PLAYER,
	ENEMY,
	ENVIRONMENT,
	MISC,
}

var _pause_positions: Array[float] # TODO: use stream_paused instead
@onready var filter_low_pass := AudioEffectLowPassFilter.new()

func _ready() -> void:
	_pause_positions.resize(AudioChannel.size())
	_pause_positions.fill(0.0)
	
	for channel: String in AudioChannel:
		var audio_player := AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayerChannel" + channel.to_pascal_case()
		add_child(audio_player)
		
	for channel_idx: AudioChannel in AudioChannel.values():
		set_effects(channel_idx, [filter_low_pass])
	filter_low_pass.cutoff_hz = 20_000

func _physics_process(_delta: float) -> void:
	for channel_idx: AudioChannel in AudioChannel.values():
		if channel_idx == AudioChannel.MUSIC: continue
		var channel = get_audio_stream_player(channel_idx)
		channel.pitch_scale = GameTime.time_scale
	
	if GameTime.paused:
		filter_low_pass.cutoff_hz = 2_000
	else:
		filter_low_pass.cutoff_hz = 20_000 * clampf(pow(GameTime.time_scale * GameTime.time_scale_timer, 6), 0, 1)


func play_sound(
		channel: AudioChannel,
		sound: AudioStream,
		starting_position_seconds: float = 0.0
):
	var audio_player := get_audio_stream_player(channel)
	audio_player.stream = sound
	audio_player.play(starting_position_seconds)
	
	_pause_positions[channel] = 0.0


func set_volume(channel: AudioChannel, volume: float, linear := true) -> void:
	var audio_player := get_audio_stream_player(channel)
	if linear:
		audio_player.volume_linear = volume
	else:
		audio_player.volume_db = volume


func set_looping(channel: AudioChannel, enable: bool) -> void:
	var audio_player := get_audio_stream_player(channel)
	if enable:
		audio_player.finished.connect(_loop.bind(audio_player))
	elif audio_player.finished.is_connected(_loop):
		audio_player.finished.disconnect(_loop)


func is_looping(channel: AudioChannel) -> bool:
	return get_audio_stream_player(channel).finished.is_connected(_loop)


func is_playing(channel: AudioChannel) -> bool:
	return get_audio_stream_player(channel).playing


func is_paused(channel: AudioChannel) -> bool:
	return _pause_positions[channel] != 0.0


func pause(channel: AudioChannel) -> void:
	var audio_player := get_audio_stream_player(channel)
	
	if not audio_player.playing:
		return
	
	_pause_positions[channel] = audio_player.get_playback_position()
	audio_player.stop()


func resume(channel: AudioChannel) -> void:
	#if _pause_positions[AudioChannel] == 0.0:
		#push_warning(
				#"Attempted to resume audio channel that was not paused! "
				#+ "(channel " + AudioChannel.keys()[channel] + ")"
		#)
	
	get_audio_stream_player(channel).play(_pause_positions[channel])
	_pause_positions[channel] = 0.0


func set_effects(channel: AudioChannel, effects: Array[AudioEffect]) -> void:
	var audio_player := get_audio_stream_player(channel)
	var bus_name: String = AudioChannel.keys()[channel].to_pascal_case()
	if effects.is_empty():
		AudioServer.remove_bus(
				AudioServer.get_bus_index(
					bus_name
				)
		)
		audio_player.bus = &"Master"
	else:
		var id := AudioServer.get_bus_index(bus_name)
		if id == -1:
			AudioServer.add_bus()
			id = AudioServer.bus_count - 1
			AudioServer.set_bus_name(id, bus_name)
			AudioServer.set_bus_send(id, "Master")
			audio_player.bus = bus_name
		else:
			for effect_id in range(AudioServer.get_bus_effect_count(id)):
				AudioServer.remove_bus_effect(id, effect_id)
		for effect in effects:
			AudioServer.add_bus_effect(id, effect)


func get_audio_stream_player(channel: AudioChannel) -> AudioStreamPlayer:
	return get_node(
			"AudioStreamPlayerChannel"
			+ AudioChannel.keys()[channel].to_pascal_case()
	)


func _loop(audio_player: AudioStreamPlayer):
	audio_player.play()
