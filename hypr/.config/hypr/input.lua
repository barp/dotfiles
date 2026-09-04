-- Ported from input.conf (+ the clickfinger_behavior edit you had in default/)

hl.config({
  input = {
    kb_layout  = "us",
    kb_options = "compose:caps",

    repeat_rate  = 40,
    repeat_delay = 600,

    numlock_by_default = true,

    touchpad = {
      scroll_factor        = 0.4,
      tap_to_click         = false,
      clickfinger_behavior = true,
    },
  },
})

-- Scroll faster in the terminal (v4 still defines the "terminal" tag).
o.window({ tag = "terminal" }, { scroll_touchpad = 1.5 })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
