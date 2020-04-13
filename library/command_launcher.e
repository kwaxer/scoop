note
	description: "A launcher of an external command."
	author: "Alexander Kogtenkov"
	copyright: "Copyright (c) 2020, Alexander Kogtenkov"
	license: "BSD 3-Clause License (https://spdx.org/licenses/BSD-3-Clause.html), see LICENSE document."

class
	COMMAND_LAUNCHER

create
	make

feature {NONE}

	make
			-- Initialize a new launcher with defaults.
		do
			create {STRING_32} command.make_empty
			create arguments.make (0)
			create {STRING_32} directory.make_empty
		end

feature -- Access

	command: READABLE_STRING_32
			-- A command to execute.

	arguments: ARRAYED_LIST [READABLE_STRING_32]
			-- Command arguments

	directory: READABLE_STRING_32
			-- A directory where the command has to be executed.

	output_writer: detachable separate PROCEDURE [separate SPECIAL [NATURAL_8]]
			-- An agent to be called for output intercepted from the command.

	error_writer: detachable separate PROCEDURE [separate SPECIAL [NATURAL_8]]
			-- An agent to be called for error intercepted from the command.

	successful_launch_handler: detachable separate PROCEDURE
			-- An agent to be called when the process is successfully started.

	failed_launch_handler: detachable separate PROCEDURE
			-- An agent to be called when the process has failed to start.

	terminate_handler: detachable separate PROCEDURE
			-- An agent to be called when the process is terminated.

	exit_handler: detachable separate PROCEDURE [INTEGER]
			-- An agent to be called when the process exits.

feature -- Modification

	set_command (c: separate like command)
			-- Set `command` to `c`.
		do
			create {STRING_32} command.make_from_separate (c)
		end

	set_arguments (a: separate ITERABLE [READABLE_STRING_32])
			-- Set `arguments` to `a`.
		local
			local_arguments: ARRAYED_LIST [READABLE_STRING_32]
		do
			create local_arguments.make (5)
			across
				a as argument
			loop
				local_arguments.extend (create {STRING_32}.make_from_separate (argument.item))
			end
			arguments := local_arguments
		end

	set_directory (d: separate like directory)
			-- Set `directory` to `d`.
		do
			create {STRING_32} directory.make_from_separate (d)
		end

	set_output_writer (w: like output_writer)
			-- Set `output_writer` to `w`.
		do
			output_writer := w
		end

	set_error_writer (w: like error_writer)
			-- Set `error_writer` to `w`.
		do
			error_writer := w
		end

	set_successful_launch_handler (h: like successful_launch_handler)
			-- Set `successful_launch_handler` to `h`.
		do
			successful_launch_handler := h
		end

	set_failed_launch_handler (h: like failed_launch_handler)
			-- Set `failed_launch_handler` to `h`.
		do
			failed_launch_handler := h
		end

	set_terminate_handler (h: like terminate_handler)
			-- Set `terminate_handler` to `h`.
		do
			terminate_handler := h
		end

	set_exit_handler (h: like exit_handler)
			-- Set `exit_handler` to `h`.
		do
			exit_handler := h
		end

feature -- Execution

	execute_with_output
			-- Execute a command `command` with arguments `arguments` in directory `directory`
			-- redirecting output to `text`.
		local
			p: BASE_PROCESS
			buffer: SPECIAL [NATURAL_8]
			c: LOCALIZED_PRINTER
			e: ENCODING
			real_command: like command
			real_arguments: like arguments
		do
			real_command := command
			real_arguments := arguments
			if command.is_empty then
					-- Use a default shell to run a command specified in the arguments.
				real_command := (create {EXECUTION_ENVIRONMENT}).default_shell
				if real_command.is_empty then
					real_command :=
						if {PLATFORM}.is_windows then
							{STRING_32} "cmd"
						else
							{STRING_32} "sh"
						end
				end
				if {PLATFORM}.is_windows then
					create real_arguments.make (real_arguments.count + 1)
					real_arguments.extend ({STRING_32} "/c")
					real_arguments.append (arguments)
				end
			end
			p := (create {BASE_PROCESS_FACTORY}).process_launcher (real_command, real_arguments, directory)
			process := p
			p.set_hidden (True)
			p.redirect_output_to_stream
			p.redirect_error_to_stream
			if attached successful_launch_handler as h then
				p.set_on_successful_launch_handler (agent (sh: attached like successful_launch_handler) do sh.call end (h))
			end
			if attached failed_launch_handler as h then
				p.set_on_fail_launch_handler (agent (sh: attached like failed_launch_handler) do sh.call end (h))
			end
			if attached exit_handler as h then
				p.set_on_exit_handler (agent (sh: attached like exit_handler; sp: attached separate like process) do
					sh (sp.exit_code)
				end (h, p))
			end
			if attached terminate_handler as h then
				p.set_on_terminate_handler (agent (sh: attached like terminate_handler) do sh.call end)
			end
			p.launch
			if p.launched then
--				if attached output_writer as w then
--					separate
--						create {separate PROCESS_OUTPUT_READER}.make
--							(agent (sp: attached separate like process): BOOLEAN
--								do
--									Result := not sp.has_output_stream_closed and then not sp.has_output_stream_error
--								end (p),
--							agent (buffer: separate SPECIAL [NATURAL_8]; sp: attached separate like process) do sp.read_output_to_special (buffer) end (?, p),
--							w) as output_processor
--					do
--						output_processor.process
--					end
--				end
--				if attached error_writer as w then
--					separate
--						create {separate PROCESS_OUTPUT_READER}.make
--							(agent (sp: attached separate like process): BOOLEAN
--								do
--									Result := not sp.has_error_stream_closed and then not sp.has_error_stream_error
--								end (p),
--							agent (buffer: separate SPECIAL [NATURAL_8]; sp: attached separate like process) do sp.read_error_to_special (buffer) end (?, p),
--							w) as output_processor
--					do
--						output_processor.process
--					end
--				end
				from
					create c
					e := (create {SYSTEM_ENCODINGS}).console_encoding
				until
					(p.has_output_stream_closed or else p.has_output_stream_error) and then
					(p.has_error_stream_closed or else p.has_error_stream_error)
				loop
					if
						not p.has_output_stream_closed and then
						not p.has_output_stream_error
					then
						create buffer.make_filled (0, 512)
						p.read_output_to_special (buffer)
						if buffer.count /= 0 and then attached output_writer as w then
							separate w as sw do sw (buffer) end
						end
					elseif
						not p.has_error_stream_closed and then
						not p.has_error_stream_error
					then
						create buffer.make_filled (0, 512)
						p.read_error_to_special (buffer)
						if buffer.count /= 0 and then attached error_writer as w then
							separate w as sw do sw (buffer) end
						end
					end
				end
				p.wait_for_exit
			end
		end

feature -- Control

	terminate
			-- Terminate the associated process (if any).
		do
			if attached process as p then
				p.terminate
			end
		end

feature {NONE} -- Access

	process: detachable BASE_PROCESS
			-- Associated process.

end
