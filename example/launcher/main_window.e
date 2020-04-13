note
	description: "Main window of the command line launcher example."
	author: "Alexander Kogtenkov"
	copyright: "Copyright (c) 2020, Alexander Kogtenkov"
	license: "BSD 3-Clause License (https://spdx.org/licenses/BSD-3-Clause.html), see LICENSE document."

class
	MAIN_WINDOW

inherit
	EV_TITLED_WINDOW
		redefine
			create_interface_objects,
			initialize,
			is_in_default_state
		end

	EV_SHARED_APPLICATION
		undefine
			copy,
			default_create
		end

create
	default_create

feature {NONE} -- Initialization

	create_interface_objects
			-- <Precursor>
		do
				-- Create main container.
			create main_container

				-- Create a status bar and a status label.
			create standard_status_bar
			create standard_status_label.make_with_text ("No command has been run yet.")

				-- Create output controls.
			create text
			create command
			create running_commands
		end

	initialize
			-- Build the interface for this window.
		do
			Precursor {EV_TITLED_WINDOW}

			build_main_container
			extend (main_container)

				-- Create and add the status bar.
			build_standard_status_bar
			main_container.extend (standard_status_bar)
			main_container.disable_item_expand (standard_status_bar)


				-- Execute `request_close_window' when the user clicks
				-- on the cross in the title bar.
			close_request_actions.extend (agent request_close_window)

				-- Set the title of the window.
			set_title (Window_title)

				-- Set the initial size of the window.
			set_size (Window_width, Window_height)

				-- Set cursor to command when the window is shown.
			show_actions.extend (agent command.set_focus)
			show_actions.extend (agent text.set_minimum_width (0))
		end

	is_in_default_state: BOOLEAN
			-- Is the window in its default state?
			-- (as stated in `initialize')
		do
			Result := title ~ Window_title
		end

feature {NONE} -- StatusBar Implementation

	standard_status_bar: EV_STATUS_BAR
			-- Standard status bar for this window

	standard_status_label: EV_LABEL
			-- Label situated in the standard status bar.
			--
			-- Note: Call `standard_status_label.set_text (...)' to change the text
			--       displayed in the status bar.

	build_standard_status_bar
			-- Populate the standard toolbar.
		do
				-- Initialize the status bar.
			standard_status_bar.set_border_width (2)

				-- Populate the status bar.
			standard_status_label.align_text_left
			standard_status_bar.extend (standard_status_label)
			standard_status_label.set_font (font)
		end

feature {NONE} -- Close event

	request_close_window
			-- Process user request to close the window.
		do
				-- Destroy the window.
			destroy
				-- End the application.
			if attached shared_environment.application as a then
				a.destroy
			end
				-- Force exit because otherwise any active regions will continue running.
			{EXCEPTIONS}.die (0)
		end

feature {NONE} -- Implementation

	main_container: EV_VERTICAL_BOX
			-- Main container (contains all widgets displayed in this window).

	text: EV_RICH_TEXT
			-- Text widget for command output.

	command: EV_TEXT_FIELD
			-- A command to execute.

	running_commands: EV_VERTICAL_BOX
			-- A container for running commands.

	build_main_container
			-- Populate `main_container'.
		local
			l: EV_LABEL
			t: EV_TABLE
			v: EV_VERTICAL_BOX
			s: EV_HORIZONTAL_SPLIT_AREA
		do
			create s
			main_container.extend (s)
			s.set_second (running_commands)
			create l.make_with_text ({STRING_32} "Currently running:")
			l.set_font (font)
			l.set_tooltip ("A list of currently running commands will appear below")
			create t
			t.set_border_width (5)
			t.extend (l)
			running_commands.extend (t)
			running_commands.disable_item_expand (t)
			create v
			s.set_first (v)
				-- Setup command entry field.
			v.extend (command)
			v.disable_item_expand (command)
			command.return_actions.extend (agent launch)
			command.set_font (font)
			command.set_tooltip ("Enter a command to run")

				-- Setup command output text area.
			v.extend (text)
			text.set_font (font)
			text.set_current_format (output_format)
			text.set_minimum_width (500)
			text.disable_edit
		ensure
			main_container_created: main_container /= Void
		end

feature {NONE} -- Execution

	launch
		local
			kill_button: EV_BUTTON
			command_launcher: separate COMMAND_LAUNCHER
		do
				-- Clear command output.
			text.remove_text
				-- Setup a command launcher.
			create command_launcher.make
			create kill_button.make_with_text (command.text)
			kill_button.align_text_left
			running_commands.first.show
			running_commands.extend (kill_button)
			running_commands.disable_item_expand (kill_button)
			kill_button.select_actions.extend (agent (launcher: separate COMMAND_LAUNCHER) do launcher.terminate end (command_launcher))
				-- Setup and launch a command.
			separate command_launcher as launcher do
				launcher.set_arguments (<<command.text>>)
				launcher.set_output_writer
					(agent (create {CONSOLE_PUSH_READER}.make
						(agent (s: READABLE_STRING_32)
							do
									-- Indicate output channel.
								text.set_current_format (output_format)
									-- Update output.
								text.append_text (s)
									-- Position to the last line.
								text.set_caret_position (text.text_length + 1)
								text.scroll_to_end
							end)).process)
				launcher.set_error_writer
					(agent (create {CONSOLE_PUSH_READER}.make
						(agent (s: READABLE_STRING_32)
							do
								-- Indicate error channel.
								text.set_current_format (error_format)
									-- Update output.
								text.append_text (s)
									-- Position to the last line.
								text.scroll_to_end
								text.set_caret_position (text.text_length + 1)
							end)).process)
				launcher.set_successful_launch_handler (agent standard_status_label.set_text (command.text + " -- has started successfully."))
				launcher.set_failed_launch_handler (agent standard_status_label.set_text (command.text + " -- has failed to start."))
				launcher.set_terminate_handler (agent running_commands.prune (kill_button))
				launcher.set_exit_handler (agent (exit_code: INTEGER; b: EV_BUTTON)
					do
						standard_status_label.set_text (b.text + " -- has exited with " + exit_code.out + ".")
						running_commands.prune (b)
						b.destroy
					end (?, kill_button))
				launcher.execute_with_output
			end
		end

feature {NONE} -- Implementation / Constants

	Window_title: STRING = "Vision + SCOOP command-line launcher"
			-- Title of the window.

	Window_width: INTEGER = 400
			-- Initial width for this window.

	Window_height: INTEGER = 400
			-- Initial height for this window.

feature {NONE} -- Formatting

	output_format: EV_CHARACTER_FORMAT
			-- Format to be used for regular output.
		once
			create Result
			Result.set_font (font)
			Result.set_color (output_color)
		end

	error_format: EV_CHARACTER_FORMAT
			-- Format to be used for error output.
		once
			create Result
			Result.set_font (font)
			Result.set_color (error_color)
		end

	font: EV_FONT
		once
			create Result.make_with_values ({EV_FONT_CONSTANTS}.family_typewriter, {EV_FONT_CONSTANTS}.weight_regular, {EV_FONT_CONSTANTS}.shape_regular, 14)
			Result.preferred_families.extend ("Consolas")
			Result.preferred_families.extend ("Courier")
		end

	output_color: EV_COLOR
			-- Color to be used for regular output.
		do
			Result := (create {EV_STOCK_COLORS}).default_foreground_color
		end

	error_color: EV_COLOR
			-- Color to be used for error output.
		do
			Result := (create {EV_STOCK_COLORS}).red
		end

end
