gen::add_generator "IEC 61131-3 ST" gen_st::generate

# Code generator for IEC 61131-3 Structured Text (ST).
#
# Diagram conventions:
#
# The text of the formal parameters icon (next to the diagram header)
# is parsed line by line:
#   program                  Generate a PROGRAM.
#   function_block (or fb)   Generate a FUNCTION_BLOCK.
#   returns <TYPE>           Return type; implies FUNCTION (the default).
#   in / out / in_out / var  Switch the section for the following
#                            declarations: VAR_INPUT (default),
#                            VAR_OUTPUT, VAR_IN_OUT, VAR.
#   <name> : <TYPE>          A declaration for the current section.
#                            An initializer is allowed: n : INT := 5
#
# Action icons contain plain ST statements; write the semicolons yourself:
#   x := x + 1;
# If icons contain ST boolean expressions (no semicolon).
# Loop start icons support:
#   for i = 1 to 10          (optionally: for i = 10 to 2 by -2)
#   i := 1; i <= 10; i := i + 1
# The foreach loop is not supported.
#
# Sections === header === and === footer === of the file description
# are copied verbatim to the top and bottom of the output file.

namespace eval gen_st {

variable closers {}
variable decl_marker "@STDECL@"

# --- plumbing: block nesting -------------------------------------------
# The framework closes IF and WHILE blocks through the same block_close
# callback. ST needs END_IF; or END_WHILE; so openers push the matching
# closer on a stack and block_close pops it. Openers and closers are
# generated strictly nested, so a stack is sufficient.

proc push_closer { closer } {
	variable closers
	lappend closers $closer
}

proc if_start { } {
	push_closer "END_IF;"
	return "IF "
}

proc if_end { } {
	return " THEN"
}

proc elseif_start { } {
	return "ELSIF "
}

proc else_start { } {
	return "ELSE"
}

proc while_start { } {
	push_closer "END_WHILE;"
	return "WHILE TRUE DO"
}

proc block_close { output depth } {
	variable closers
	upvar 1 $output result
	if { [ llength $closers ] == 0 } {
		set closer "END_IF;"
	} else {
		set closer [ lindex $closers end ]
		set closers [ lrange $closers 0 end-1 ]
	}
	set line [ gen::make_indent $depth ]
	append line $closer
	lappend result $line
}

# --- small language callbacks ------------------------------------------

proc commentator { text } {
	return "// $text"
}

proc assign { variable value } {
	return "$variable := $value;"
}

proc compare { variable constant } {
	return "$variable = $constant"
}

proc bad_case { switch_var select_icon_number } {
	return "; // Unexpected choice value: $switch_var (item $select_icon_number)"
}

proc declare { type name value } {
	variable decl_marker
	set st_type [ map_type $type ]
	if { $value == "" } {
		return "$decl_marker $name : $st_type;"
	} else {
		return "$decl_marker $name : $st_type := $value;"
	}
}

proc map_type { type } {
	switch -- [ string tolower $type ] {
		int { return "DINT" }
		default { return $type }
	}
}

proc p.and { left right } {
	return "($left) AND ($right)"
}

proc p.or { left right } {
	return "($left) OR ($right)"
}

proc p.not { operand } {
	return "NOT ($operand)"
}

proc pass { } {
	return ";"
}

proc return_none { } {
	return "RETURN;"
}

proc shelf { primary secondary } {
	return "$secondary := $primary;"
}

proc goto { text } {
	error "GOTO is not available in Structured Text."
}

proc tag { text } {
	error "Labels are not available in Structured Text."
}

proc enforce_nogoto { name } {
	error "Diagram '$name' is too complex to be generated as structured code.\nSimplify the diagram: Structured Text has no GOTO."
}

proc generate_body { gdb diagram_id start_item node_list items incoming } {
	set name [ $gdb onecolumn {
		select name from diagrams where diagram_id = :diagram_id } ]
	enforce_nogoto $name
}

# --- select / case ------------------------------------------------------

proc select { header_text } {
	return "CASE $header_text OF"
}

proc case_value { text } {
	return "$text :"
}

proc case_else { } {
	return "ELSE"
}

proc case_end { next_text } {
	return ""
}

proc select_end { } {
	return "END_CASE;"
}

# --- loops ---------------------------------------------------------------

proc foreach_error { item_id } {
	error "The foreach loop is not supported for Structured Text (item $item_id).\nUse: for i = 1 to 10"
}

proc foreach_init { item_id first second } {
	foreach_error $item_id
}

proc foreach_check { item_id first second } {
	foreach_error $item_id
}

proc foreach_current { item_id first second } {
	foreach_error $item_id
}

proc foreach_incr { item_id first second } {
	foreach_error $item_id
}

proc foreach_declare { item_id first second } {
	foreach_error $item_id
}

# Rewrites "for i = 1 to 10 [by 2]" loop headers into the
# "init; condition; increment" form the framework understands.
proc rewire_for_loops { gdb diagram_id } {
	set starts [ $gdb eval {
		select vertex_id
		from vertices
		where type = 'loopstart'
			and text like 'for %'
			and diagram_id = :diagram_id
	} ]
	foreach vertex_id $starts {
		unpack [ $gdb eval {
			select text, item_id
			from vertices
			where vertex_id = :vertex_id
		} ] text item_id
		set new_text [ parse_for $item_id $text ]
		$gdb eval {
			update vertices
			set text = :new_text
			where vertex_id = :vertex_id
		}
	}
}

proc parse_for { item_id text } {
	set pattern {^for\s+([A-Za-z_][A-Za-z0-9_]*)\s*:?=\s*(.+?)\s+to\s+(.+?)(?:\s+by\s+(.+?))?\s*$}
	if { ![ regexp -nocase $pattern $text -> var start end step ] } {
		error "Wrong 'for' syntax in item $item_id: $text\nExpected: for i = 1 to 10 \[by 2\]"
	}
	if { $step == "" } {
		set step 1
	}
	if { [ string match "-*" [ string trim $step ] ] } {
		set check "$var >= $end"
	} else {
		set check "$var <= $end"
	}
	return "$var := $start; $check; $var := $var + $step"
}

# --- signature -----------------------------------------------------------

proc extract_signature { text name } {
	array set props { type function access public returns "" }
	set error_message ""
	set parameters {}

	set lines [ gen::separate_from_comments $text ]
	set section "in"
	set first 1

	foreach pair $lines {
		set line [ string trim [ lindex $pair 0 ] ]
		set lower [ string tolower $line ]

		if { $first && $line == "#comment" } {
			set props(type) "comment"
			break
		}
		set first 0

		set return_type [ gen::extract_return_type $line ]

		if { $lower == "program" } {
			set props(type) "program"
		} elseif { $lower == "function_block" || $lower == "fb" } {
			set props(type) "function_block"
		} elseif { $lower == "function" } {
			set props(type) "function"
		} elseif { $return_type != "" } {
			set props(returns) $return_type
		} elseif { $lower == "in" } {
			set section "in"
		} elseif { $lower == "out" } {
			set section "out"
		} elseif { $lower == "in_out" || $lower == "inout" } {
			set section "in_out"
		} elseif { $lower == "var" || $lower == "local" } {
			set section "var"
		} else {
			if { [ string first ":" $line ] == -1 } {
				set error_message "Bad declaration in diagram '$name': $line\nExpected: <name> : <TYPE>"
				break
			}
			if { ![ string match "*;" $line ] } {
				append line ";"
			}
			lappend parameters [ list $section $line ]
		}
	}

	set prop_list [ array get props ]
	return [ list $error_message \
		[ gen::create_signature $props(type) $prop_list $parameters $props(returns) ] ]
}

# --- output --------------------------------------------------------------

proc make_callbacks { } {
	set callbacks {}

	gen::put_callback callbacks assign        gen_st::assign
	gen::put_callback callbacks compare       gen_st::compare
	gen::put_callback callbacks compare2      gen_st::compare
	gen::put_callback callbacks bad_case      gen_st::bad_case
	gen::put_callback callbacks declare       gen_st::declare

	gen::put_callback callbacks body          gen_st::generate_body
	gen::put_callback callbacks signature     gen_st::extract_signature
	gen::put_callback callbacks and           gen_st::p.and
	gen::put_callback callbacks or            gen_st::p.or
	gen::put_callback callbacks not           gen_st::p.not

	gen::put_callback callbacks comment       gen_st::commentator

	gen::put_callback callbacks if_start      gen_st::if_start
	gen::put_callback callbacks if_end        gen_st::if_end
	gen::put_callback callbacks elseif_start  gen_st::elseif_start
	gen::put_callback callbacks else_start    gen_st::else_start
	gen::put_callback callbacks while_start   gen_st::while_start
	gen::put_callback callbacks block_close   gen_st::block_close
	gen::put_callback callbacks pass          gen_st::pass
	gen::put_callback callbacks return_none   gen_st::return_none
	gen::put_callback callbacks goto          gen_st::goto
	gen::put_callback callbacks tag           gen_st::tag
	gen::put_callback callbacks break         "EXIT;"

	gen::put_callback callbacks select        gen_st::select
	gen::put_callback callbacks case_value    gen_st::case_value
	gen::put_callback callbacks case_else     gen_st::case_else
	gen::put_callback callbacks case_end      gen_st::case_end
	gen::put_callback callbacks select_end    gen_st::select_end

	gen::put_callback callbacks for_init      gen_st::foreach_init
	gen::put_callback callbacks for_check     gen_st::foreach_check
	gen::put_callback callbacks for_current   gen_st::foreach_current
	gen::put_callback callbacks for_incr      gen_st::foreach_incr
	gen::put_callback callbacks for_declare   gen_st::foreach_declare

	gen::put_callback callbacks shelf         gen_st::shelf
	gen::put_callback callbacks enforce_nogoto gen_st::enforce_nogoto

	return $callbacks
}

proc generate { db gdb filename } {
	variable closers
	set closers {}

	set callbacks [ make_callbacks ]

	set diagrams [ $gdb eval {
		select diagram_id from diagrams } ]

	foreach diagram_id $diagrams {
		if { [ mwc::is_drakon $diagram_id ] } {
			rewire_for_loops $gdb $diagram_id
			gen::fix_graph_for_diagram $gdb $callbacks 1 $diagram_id
		}
	}

	set sections { header footer }
	unpack [ gen::scan_file_description $db $sections ] header footer

	set functions [ gen::generate_functions $db $gdb $callbacks 1 ]

	if { [ graph::errors_occured ] } { return }

	set filename [ replace_extension $filename "st" ]
	set fhandle [ open_output_file $filename ]

	if { [ catch {
		print_to_file $fhandle $functions $header $footer
	} error_message ] } {
		catch { close $fhandle }
		puts $::errorInfo
		error $error_message
	}
	catch { close $fhandle }
}

proc print_to_file { fhandle functions header footer } {
	set version [ version_string ]
	puts $fhandle "// Autogenerated with DRAKON Editor $version"
	if { $header != "" } {
		puts $fhandle $header
	}
	puts $fhandle ""
	foreach function $functions {
		print_function $fhandle $function
	}
	if { $footer != "" } {
		puts $fhandle $footer
	}
}

proc split_declares { body } {
	variable decl_marker
	set marker_length [ string length $decl_marker ]
	set declares {}
	set statements {}
	foreach line $body {
		set trimmed [ string trim $line ]
		if { [ string first $decl_marker $trimmed ] == 0 } {
			set declare [ string trim \
				[ string range $trimmed $marker_length end ] ]
			lappend declares $declare
		} else {
			lappend statements $line
		}
	}
	return [ list $declares $statements ]
}

proc print_section { fhandle keyword declarations } {
	if { [ llength $declarations ] == 0 } { return }
	puts $fhandle $keyword
	foreach declaration $declarations {
		puts $fhandle "    $declaration"
	}
	puts $fhandle "END_VAR"
}

proc print_function { fhandle function } {
	unpack $function diagram_id name signature body
	unpack $signature kind prop_list parameters returns

	if { $kind == "comment" } { return }

	unpack [ split_declares $body ] framework_declares statements

	if { $kind == "program" } {
		set header "PROGRAM $name"
		set closer "END_PROGRAM"
	} elseif { $kind == "function_block" } {
		set header "FUNCTION_BLOCK $name"
		set closer "END_FUNCTION_BLOCK"
	} else {
		if { $returns == "" } {
			set returns "VOID"
		}
		set header "FUNCTION $name : $returns"
		set closer "END_FUNCTION"
	}

	set inputs {}
	set outputs {}
	set in_outs {}
	set locals {}
	foreach parameter $parameters {
		lassign $parameter section declaration
		switch -- $section {
			out { lappend outputs $declaration }
			in_out { lappend in_outs $declaration }
			var { lappend locals $declaration }
			default { lappend inputs $declaration }
		}
	}
	set locals [ concat $locals $framework_declares ]

	puts $fhandle $header
	print_section $fhandle "VAR_INPUT" $inputs
	print_section $fhandle "VAR_OUTPUT" $outputs
	print_section $fhandle "VAR_IN_OUT" $in_outs
	print_section $fhandle "VAR" $locals

	foreach line $statements {
		puts $fhandle "    $line"
	}

	puts $fhandle $closer
	puts $fhandle ""
}

}
