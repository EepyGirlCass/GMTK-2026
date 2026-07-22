extends TabContainer

enum SettingType {
	CHECKBOX,
	SLIDER,
	TEXTBOX,
}

enum SettingCategory {
	GRAPHICS,
	AUDIO,
	GAMEPLAY,
	CONTROLS,
}

enum SettingUpdate {
	IMMEDIATE,
	APPLY,
	APPLY_REVERT,
	RESTART,
}


class Setting:
	static var settings_dict: Dictionary[StringName, Setting] = {}
	
	@warning_ignore("shadowed_variable")
	func _init(
			internal_name: StringName,
			value_default: Variant,
			type: SettingType,
			category: SettingCategory,
			update: SettingUpdate = SettingUpdate.IMMEDIATE,
			display_name: String = "",
			tooltip: String = "",
			sort_order: int = 0 # higher numbers come first
		):
		self.name_internal = internal_name
		self.value = value_default
		self.value_default = value_default
		self.type = type
		self.category = category
		self.update = update
		self.name_display = display_name if display_name != "" else String(internal_name)
		self.tooltip = tooltip
		self.sort_order = sort_order
		
		settings_dict[name_internal] = self
	
	var name_display: String
	var name_internal: StringName
	var tooltip: String
	
	var value: Variant
	var value_default: Variant
	var sort_order: int
	
	var type: SettingType
	var category: SettingCategory
	var update: SettingUpdate


func _ready() -> void:
	Setting.new("sex1", 0, SettingType.SLIDER, SettingCategory.GRAPHICS)
	Setting.new("sex2", 0, SettingType.SLIDER, SettingCategory.GRAPHICS)
	Setting.new("sex3", 0, SettingType.SLIDER, SettingCategory.GRAPHICS)
	Setting.new("sex4", 0, SettingType.SLIDER, SettingCategory.GRAPHICS)
	
	# create the whole settings menu through code for some reason
	# start with categories/tabs
	# make the tabs
	for category_name in SettingCategory.keys():
		var category_number = SettingCategory[category_name]
		
		var tab = ScrollContainer.new()
		tab.name = str(category_number)
		add_child(tab)
		set_tab_title(category_number, category_name.to_pascal_case())
		
		var margins = MarginContainer.new()
		margins.name = "margins"
		tab.add_child(margins)
		
		var list = VBoxContainer.new()
		list.name = "list"
		margins.add_child(list)
		
		# place settings in categories
		for setting_name in Setting.settings_dict.keys():
			var setting = Setting.settings_dict[setting_name]
			#print(setting.category)
			if setting.category != category_number: continue
			
			var split = HBoxContainer.new()
			list.add_child(split)
			
			var label = Label.new()
			split.add_child(label)
			
			var input: Control
			match setting.type:
				SettingType.CHECKBOX:
					input = CheckBox.new()
					input.toggled.connect(func(val): setting.value = val)
				SettingType.SLIDER:
					input = HSlider.new()
					input.drag_ended.connect(func(): setting.value = input.value)
				SettingType.TEXTBOX:
					input = TextEdit.new()
					input.text_changed.connect(func(): setting.value = input.text)
			
			split.add_child(input)
