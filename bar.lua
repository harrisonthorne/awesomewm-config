local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local helpers = require("helpers")
local keys = require("keys")

local dock = require("noodle.dock")
local dock_placement = function(w)
    return awful.placement.bottom_left(w, { margins = dpi(8) })
end

status_primary = wibox.widget {
    valign = 'center',
    align = 'center',
    markup = '',
    fg = beautiful.fg,
    widget = wibox.widget.textbox
}

status_secondary = wibox.widget {
    valign = 'center',
    align = 'right',
    markup = '',
    fg = beautiful.fg,
    widget = wibox.widget.textbox
}

awful.spawn.with_line_callback("muse-status sub p -m plain -p '" .. colors.color15 .. "' -s '" .. colors.active .. "'", {
    stdout = function(l)
        status_primary.markup = l
    end
})

awful.spawn.with_line_callback("muse-status sub s -m plain -p '" .. colors.color15 .. "' -s '" .. colors.active .. "'", {
    stdout = function(l)
        status_secondary.markup = l
    end
})

local function make_status_bar(s)
    -- Create a taglist for every screen
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.noempty,
        widget_template = {
            {
                {
                    id     = 'text_role',
                    valign = "center",
                    widget = wibox.widget.textbox,
                },
                left  = dpi(8),
                right = dpi(8),
                widget = wibox.container.margin
            },
            id     = 'background_role',
            widget = wibox.container.background
        },
    }

    -- Create the taglist wibox
    s.taglist_box = awful.wibar({
        screen = s,
        visible = true,
        ontop = false,
        type = "dock",
        position = "top",
        height = dpi(32),
        bg = beautiful.bg,
    })

    s.taglist_box:setup {
        {
            s.mytaglist,
            status_primary,
            status_secondary,
            layout = wibox.layout.align.horizontal
        },
        right = dpi(8),
        widget = wibox.container.margin
    }

    -- Makes a hitbox that raises the status bar ontop
    local bar_auto_lower = function ()
        s.taglist_box.ontop = false
    end

    s.bar_activator = wibox({ screen = s, width = s.geometry.width, height = 1, bg = "#00000000", visible = true, ontop = true })
    awful.placement.top(s.bar_activator)
    s.bar_activator:connect_signal("mouse::enter", function()
        s.taglist_box.ontop = true
    end)
    s.taglist_box:connect_signal("mouse::leave", function ()
        bar_auto_lower()
    end)
end

local function make_app_dock(s)
    -- Create the dock wibox
    s.dock = awful.popup({
        -- Size is dynamic, no need to set it here
        visible = false,
        ontop = true,
        -- type = "dock",
        placement = dock_placement,
        widget = dock,
        shape = helpers.rrect(beautiful.border_radius)
    })

    local dock_autohide = function ()
        s.dock.visible = false
    end

    -- Initialize wibox activator
    s.dock_activator = wibox({ screen = s, width = 1, height = 1, bg = "#00000000", visible = true, ontop = false })
    awful.placement.bottom_left(s.dock_activator)
    s.dock_activator:connect_signal("mouse::enter", function()
        s.dock.visible = true
    end)

    -- Keep dock activator below fullscreen clients
    local function no_dock_activator_ontop(c)
       if not s then 
            return
        elseif c.fullscreen and s.dock_activator then
            s.dock_activator.ontop = false
        elseif s.dock_activator then
            s.dock_activator.ontop = true
        end
    end
    client.connect_signal("focus", no_dock_activator_ontop)
    client.connect_signal("unfocus", no_dock_activator_ontop)
    client.connect_signal("property::fullscreen", no_dock_activator_ontop)

    local function adjust_dock()
        -- Reset position every time the number of dock items changes
        dock_placement(s.dock)
    end

    adjust_dock()
    s.dock:connect_signal("property::width", adjust_dock)

    s.dock:connect_signal("mouse::leave", function ()
        dock_autohide()
    end)
end

-- Creates a bar for every screen
awful.screen.connect_for_each_screen(function(s)
    make_status_bar(s)
    make_app_dock(s)
end)
