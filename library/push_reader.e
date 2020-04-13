note
	description: "[
			Push reader.
			Its feature `process` is called by the stream generator that wants the data to be processed in a particular way.
			The reader may have an outgoing reader(s) that will process the data further thus allowing for chained processing.
		]"
	author: "Alexander Kogtenkov"
	copyright: "Copyright (c) 2020, Alexander Kogtenkov"
	license: "BSD 3-Clause License (https://spdx.org/licenses/BSD-3-Clause.html), see LICENSE document."

deferred class
	PUSH_READER

feature -- Processing

	process (data: separate SPECIAL [NATURAL_8])
			-- Process incoming data `data`.
			-- There are no guarantees that `data` will not be modified before the next call, so any intermediate data should be explicitly recorded for processing.
		deferred
		end

end
