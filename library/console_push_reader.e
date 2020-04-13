note
	description: "A converter of raw byte stream into a string stream using current console encoding."
	author: "Alexander Kogtenkov"
	copyright: "Copyright (c) 2020, Alexander Kogtenkov"
	license: "BSD 3-Clause License (https://spdx.org/licenses/BSD-3-Clause.html), see LICENSE document."

class
	CONSOLE_PUSH_READER

inherit
	PUSH_READER

create
	make

feature {NONE} -- Creation

	make (r: like next_reader)
			-- Initialize the reader with a next reader in the chain `r`.
		do
			next_reader := r
		ensure
			next_reader_set: next_reader = r
		end

feature -- Access

	next_reader: PROCEDURE [READABLE_STRING_32]
			-- The next reader in the chain of push readers.

feature -- Processing

	process (data: separate SPECIAL [NATURAL_8])
			-- <Precursor>
		local
			s: STRING_32
		do
			s := converter.console_encoding_to_utf32 (console_encoding, create {STRING_8}.make_from_c_substring ($data, 1, data.count))
			s.prune_all ({CHARACTER_32} '%R')
			next_reader (s)
		end

feature {NONE} -- Code page conversion

	converter: LOCALIZED_PRINTER
			-- Converter of the input data into Unicode.
		once
			create Result
		end

	console_encoding: ENCODING
			-- Current console encoding.
		once
			Result := (create {SYSTEM_ENCODINGS}).console_encoding
		end

end
