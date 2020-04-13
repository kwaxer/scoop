note
	description: "An example of simulteneously executed commands in SCOOP mode."
	author: "Alexander Kogtenkov"
	copyright: "Copyright (c) 2020, Alexander Kogtenkov"
	license: "BSD 3-Clause License (https://spdx.org/licenses/BSD-3-Clause.html), see LICENSE document."

class
	APPLICATION

create
	make_and_launch

feature {NONE} -- Initialization

	make_and_launch
		local
			application: EV_APPLICATION
		do
			create application
				-- Create, initialize and show the main window.
			;(create {MAIN_WINDOW}).show
				-- The next instruction launches GUI message processing.
				-- It should be the last instruction of a creation procedure
				-- that initializes GUI objects. Any other processing should
				-- be done either by agents associated with GUI elements
				-- or in a separate processor.
			application.launch
				-- No code should appear here,
				-- otherwise GUI message processing will be stuck in SCOOP mode.
		end

end
