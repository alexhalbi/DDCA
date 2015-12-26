proc num_to_vect {num len} {
    return [format "%llb" $num]
}

proc dec2bin {i {width {}}} {
    #returns the binary representation of $i
    # width determines the length of the returned string (left truncated or added left 0)
    # use of width allows concatenation of bits sub-fields

    set res {}
    if {$i<0} {
        set sign -
        set i [expr {abs($i)}]
    } else {
        set sign {}
    }
    while {$i>0} {
        set res [expr {$i%2}]$res
        set i [expr {$i/2}]
    }
    if {$res == {}} {set res 0}

    if {$width != {}} {
        append d [string repeat 0 $width] $res
        set res [string range $d [string length $res] end]
    }
    return $sign$res
}

# http://stackoverflow.com/questions/9709257/modelsim-message-viewer-empty
proc load_testbench {name} {
    set venv [env]
    echo $venv
    if { [string match *${name}* $venv] } {
        echo "is already loaded, skip starting simulation, but restart."
        restart -force
    } else {
        vsim -t 100fs -assertdebug -msgmode both -displaymsgmode both work.${name}_tb

        set wave_path "testbench/${name}/wave.do"
        if { [file exists $wave_path] == 1} {
            do $wave_path
        } else {
            echo "Wave file not found."
        }
    }
}

proc backup {path} {
    if {[file exists ${path}.orig] == 0} {
        file copy $path ${path}.orig
    }
}

proc restore {path} {
    if {[file exists ${path}.orig] == 0} {
        error "Backup file $orig does not exist"
    }
    file copy -force ${path}.orig $path
}

proc load_program {prog_root name} {
    set src_simple "${prog_root}/${name}.mif"
    set src_imem "${prog_root}/${name}.imem.mif"
    set src_dmem "${prog_root}/${name}.dmem.mif"

    set dst_imem "../src/imem.mif"
    set dst_dmem "../src/dmem.mif"

    backup $dst_imem
    backup $dst_dmem

    if {[file exists $src_simple] == 0} {
        if {[file exists $src_imem] == 0} {
            error "Nor $src_simpl, nor $src_imem exist"
        }
        if {[file exists $src_dmem] == 0} {
            error "Nor $src_simpl, nor $src_dmem exist"
        }

        file copy -force $src_imem $dst_imem
        file copy -force $src_dmem $dst_dmem
    } else {
        file copy -force $src_simple $dst_imem
        restore $dst_dmem
    }

    after 1
}

proc load_test {path} {
    set test_path "../src/test.tc"

    if {[file exists $path] == 0} {
        error "test at $path does not exist"
    }

    file copy -force $path $test_path
}