package main

import oc "core:sys/orca"
import "core:fmt"
import "core:log"
import "core:strings"

import "core:math"
import "core:math/linalg"
import "base:runtime"
//import sqlite "odin-sqlite"

ctx:runtime.Context

surface: oc.surface
renderer: oc.canvas_renderer
canvas: oc.canvas_context
ui_ctx: oc.ui_context
font: oc.font // font global
frame_size:[2]f32
mouse: oc.vec2
mouse_held:bool

edit_text:oc.str8
text_arena:oc.arena
log_arena:oc.arena
command_history:[dynamic]string

in_exec_command:bool

execute_command :: proc(txt:string){
    if !in_exec_command{
        wd:=strings.split(txt," ")
        switch wd[0]{
            case "hi":
                log_data("Hello there!")
            case "init":
                err:=db_init(fmt.ctprint(wd[1]))
                if err==.OK{
                    log_data(fmt.tprint("Created database",wd[1]))
                } else {
                    log_data(fmt.tprint("ERROR: ",err))
                }
            case "exec":
                in_exec_command=true
                log_data("ENTER SQL COMMAND:")
            }
    }
    else {
        err:=db_execute_simple(txt)
        if err==.OK{
            log_data("Done!")
        }else {
            log_data(fmt.tprint("ERROR:", err))
        }
        in_exec_command=false
    }

}


log_data :: proc(args:..any){
    for str in args{
        append(&command_history,fmt.aprint(str))
    }
}

main :: proc() {

  ctx=context

  renderer = oc.canvas_renderer_create()
  surface = oc.canvas_surface_create(renderer)
  canvas = oc.canvas_context_create()


  // NOTE: This is temporary and will change soon
  // Describe wanted unicode ranges to usable for rendering
  ranges := [?]oc.unicode_range {
    oc.UNICODE_BASIC_LATIN,
    oc.UNICODE_C1_CONTROLS_AND_LATIN_1_SUPPLEMENT,
    oc.UNICODE_LATIN_EXTENDED_A,
    oc.UNICODE_LATIN_EXTENDED_B,
    oc.UNICODE_SPECIALS,
  }

  // Create the font from a TTF asset that needs to be provided.
  font = oc.font_create_from_path("OpenSans-Regular.ttf", 5, &ranges[0])

  oc.ui_init(&ui_ctx)
  oc.arena_init(&text_arena)
  oc.arena_init(&log_arena)
  frame_size = {800,600}


}

@(export)
oc_on_raw_event :: proc "c" (event: ^oc.event){
    context = ctx

    if !(event.type==.KEYBOARD_KEY && event.key.scanCode==.ENTER){
        oc.ui_process_event(event)
    }

    if event.type == .MOUSE_MOVE{
        mouse = {event.mouse.x,event.mouse.y}

        if mouse_held{

        }
    }

    if event.type==.KEYBOARD_KEY{
        if event.key.scanCode==.ENTER && event.key.action==.PRESS{
            build:=strings.builder_make()
            strings.write_string(&build,">> ")
            strings.write_string(&build,edit_text)
            append(&command_history,strings.to_string(build))
            execute_command(edit_text)
            edit_text=""
        }
    } 
    if event.type == .WINDOW_RESIZE{
        frame_size.x=event.move.frame.w 
        frame_size.y=event.move.frame.h
        oc.log_info(fmt.ctprint(frame_size))
    }

}

@(export)
oc_on_frame_refresh :: proc "c" () {

  context = ctx


  scratch:=oc.scratch_begin()
  oc.ui_set_theme(&oc.UI_LIGHT_THEME)
  defstyle:oc.ui_style={font=font}
  
  {oc.ui_frame(frame_size,defstyle,{.FONT})
    {oc.ui_menu_bar("menubar")}
    {oc.ui_panel("panel",{})
        oc.ui_style_next({size = {{.PIXELS, 305, 0, 0}, {.TEXT, 0, 0, 0}}}, oc.SIZE)
        {res := oc.ui_text_box("Tbox",scratch.arena,edit_text)
            if res.changed{
                oc.arena_clear(&text_arena)
                edit_text = oc.str8_push_copy(&text_arena,res.text)
            }
        }

        //-------------------------------------------------------------------------------------
        // Scrollable panel
        //-------------------------------------------------------------------------------------
        oc.ui_style_next(
            {
                size = {{.PARENT, 1, 0, 0}, {.PARENT, 1, 1, 0}},
                bgColor = ui_ctx.theme.bg2,
                borderColor = ui_ctx.theme.border,
                borderSize = 1,
                roundness = ui_ctx.theme.roundnessSmall,
            },
            oc.SIZE + {.BG_COLOR, .BORDER_COLOR, .BORDER_SIZE, .ROUNDNESS},
        )
        {oc.ui_panel("log", {.DRAW_BACKGROUND, .DRAW_BORDER})
            scrval:f32=1.0
            logpanel:=oc.ui_box_lookup_str8("contents")
            logpanel.scroll[1]=1
            {
                oc.ui_style_next(
                    {layout = {margin = 16}},
                    oc.LAYOUT_MARGINS + {.LAYOUT_SPACING},
                )
                oc.ui_container("_contents", {})


                iter: ^oc.list_elt
                i: int
                for logLine,i in command_history{
                    id := fmt.tprintf("%d", i)

                    oc.ui_container(id, {})
                    oc.ui_label_str8(logLine)
                }
            }
        }

    }
  }
  oc.scratch_end(scratch)



  oc.canvas_context_select(canvas)
  oc.set_color_rgba(1, 1, 1, 1)
  oc.clear()

  oc.ui_draw()
  
  oc.canvas_render(renderer, canvas, surface)
  oc.canvas_present(renderer, surface)    
}
