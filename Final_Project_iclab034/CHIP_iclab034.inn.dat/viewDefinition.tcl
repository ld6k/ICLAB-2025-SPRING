if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name lib_min\
   -timing\
    [list ${::IMEX::libVar}/mmmc/fsa0m_a_generic_core_ff1p98vm40c.lib\
    ${::IMEX::libVar}/mmmc/fsa0m_a_t33_generic_io_ff1p98vm40c.lib\
    ${::IMEX::libVar}/mmmc/ID_CACHE_BC.lib]\
   -si\
    [list ${::IMEX::libVar}/mmmc/u18_ff.cdb]
create_library_set -name lib_max\
   -timing\
    [list ${::IMEX::libVar}/mmmc/fsa0m_a_generic_core_ss1p62v125c.lib\
    ${::IMEX::libVar}/mmmc/fsa0m_a_t33_generic_io_ss1p62v125c.lib\
    ${::IMEX::libVar}/mmmc/ID_CACHE_WC.lib]\
   -si\
    [list ${::IMEX::libVar}/mmmc/u18_ss.cdb]
create_rc_corner -name RC_Corner\
   -cap_table ${::IMEX::libVar}/mmmc/u18_Faraday.CapTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -qx_tech_file ${::IMEX::libVar}/mmmc/RC_Corner/icecaps.tch
create_delay_corner -name Delay_Corner_min\
   -library_set lib_min\
   -rc_corner RC_Corner
create_delay_corner -name Delay_Corner_max\
   -library_set lib_max\
   -rc_corner RC_Corner
create_constraint_mode -name func_mode\
   -sdc_files\
    [list /dev/null]
create_analysis_view -name av_func_mode_max -constraint_mode func_mode -delay_corner Delay_Corner_max -latency_file ${::IMEX::libVar}/mmmc/latency.sdc
create_analysis_view -name av_func_mode_min -constraint_mode func_mode -delay_corner Delay_Corner_min -latency_file ${::IMEX::libVar}/mmmc/latency.sdc
set_analysis_view -setup [list av_func_mode_max] -hold [list av_func_mode_min]
catch {set_interactive_constraint_mode [list func_mode] } 
